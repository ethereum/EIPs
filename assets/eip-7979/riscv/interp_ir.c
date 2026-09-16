/* Interpreter for the register IR of ir.py: the deployable middle
 * path between interpreting bytecode and compiling it to native
 * code.  One computed-goto dispatch per operation, but no stack
 * traffic, no destination checks, no per-op bookkeeping — those were
 * paid once, at translation, under the validation proofs.  Gas is
 * charged per basic block, precomputed by the translator; the sums
 * match the baseline interpreter's per-op charges exactly.  The
 * checks validation cannot retire — stack overflow, return depth —
 * cost one compare each per call.
 *
 * Compile with -DWIDTH64 for EVM64 programs (registers are single
 * 64-bit words) or without (registers are 256-bit, four little-
 * endian limbs, same arithmetic as the baseline interp.c — the limb
 * helpers are repeated here verbatim so the file stands alone).
 */
typedef unsigned long u64;
typedef unsigned char u8;
typedef unsigned __int128 u128;

#include "ir_ops.h"

extern const IR IRC[];
extern const u64 IRC_LEN;
extern const u8 CALLDATA[];
extern const u64 CALLDATA_LEN;
extern u8 MEM[];
#define MEM_SIZE (1UL << 20)

void __rt_return(const u8 *p, u64 n);
void __rt_stop(void);
void __rt_revert(void);
void __rt_trap(const char *msg);

#define GAS_LIMIT 10000000000UL
#define STACK_LIMIT 1024
#define RSTACK_LIMIT 1024

#ifdef WIDTH64

typedef u64 word;
static word R[STACK_LIMIT + 64];
#define IS_ZERO(x)   ((x) == 0)
#define SET(dst, v)  (dst) = (v)

#else

typedef struct { u64 w[4]; } word;
static word R[STACK_LIMIT + 64];
#define IS_ZERO(x)   (!((x).w[0] | (x).w[1] | (x).w[2] | (x).w[3]))

static void set_low(word *r, u64 v)
{
    r->w[0] = v; r->w[1] = r->w[2] = r->w[3] = 0;
}

static int lt256(const word *a, const word *b)
{
    for (int i = 3; i >= 0; i--) {
        if (a->w[i] < b->w[i]) return 1;
        if (a->w[i] > b->w[i]) return 0;
    }
    return 0;
}

static int slt256(const word *a, const word *b)
{
    u64 sa = a->w[3] >> 63, sb = b->w[3] >> 63;
    if (sa != sb) return sa;
    return lt256(a, b);
}

static void add256(word *r, const word *a, const word *b)
{
    u128 c = 0;
    for (int i = 0; i < 4; i++) {
        c += (u128)a->w[i] + b->w[i];
        r->w[i] = (u64)c;
        c >>= 64;
    }
}

static void sub256(word *r, const word *a, const word *b)
{
    u128 br = 0;
    for (int i = 0; i < 4; i++) {
        u128 t = (u128)a->w[i] - b->w[i] - br;
        r->w[i] = (u64)t;
        br = (t >> 64) & 1;
    }
}

static void mul256(word *r, const word *a, const word *b)
{
    u64 out[4] = {0, 0, 0, 0};
    for (int i = 0; i < 4; i++) {
        u128 carry = 0;
        for (int j = 0; i + j < 4; j++) {
            u128 t = (u128)a->w[i] * b->w[j] + out[i + j] + carry;
            out[i + j] = (u64)t;
            carry = t >> 64;
        }
    }
    for (int i = 0; i < 4; i++) r->w[i] = out[i];
}

static void shl256(word *r, const word *a, u64 s)
{
    word t = {{0, 0, 0, 0}};
    u64 limb = s >> 6, bit = s & 63;
    for (int i = 3; (int)(i - limb) >= 0; i--) {
        t.w[i] = a->w[i - limb] << bit;
        if (bit && (int)(i - limb - 1) >= 0)
            t.w[i] |= a->w[i - limb - 1] >> (64 - bit);
    }
    *r = t;
}

static void shr256(word *r, const word *a, u64 s)
{
    word t = {{0, 0, 0, 0}};
    u64 limb = s >> 6, bit = s & 63;
    for (u64 i = 0; i + limb < 4; i++) {
        t.w[i] = a->w[i + limb] >> bit;
        if (bit && i + limb + 1 < 4)
            t.w[i] |= a->w[i + limb + 1] << (64 - bit);
    }
    *r = t;
}

static void divmod256(word *q, word *rem, const word *a, const word *b)
{
    static const word z = {{0, 0, 0, 0}};
    if (IS_ZERO(*b)) { *q = z; *rem = z; return; }
    if (!(a->w[1] | a->w[2] | a->w[3] | b->w[1] | b->w[2] | b->w[3])) {
        *q = z; *rem = z;
        q->w[0] = a->w[0] / b->w[0];
        rem->w[0] = a->w[0] % b->w[0];
        return;
    }
    word r = z, qq = z;
    for (int i = 255; i >= 0; i--) {
        shl256(&r, &r, 1);
        r.w[0] |= (a->w[i >> 6] >> (i & 63)) & 1;
        if (!lt256(&r, b)) {
            sub256(&r, &r, b);
            qq.w[i >> 6] |= 1UL << (i & 63);
        }
    }
    *q = qq; *rem = r;
}

#endif /* !WIDTH64 */

static u64 checked_index(u64 i)
{
    if (i + 32 > MEM_SIZE) __rt_trap("memory out of range");
    return i;
}

void evm_entry(void)
{
    static const void *J[IR_NOPS] = {
        [IR_GAS] = &&op_gas, [IR_LI] = &&op_li, [IR_MV] = &&op_mv,
        [IR_XCHG] = &&op_xchg,
        [IR_ADD] = &&op_add, [IR_SUB] = &&op_sub, [IR_MUL] = &&op_mul,
        [IR_DIV] = &&op_div, [IR_MOD] = &&op_mod,
        [IR_LT] = &&op_lt, [IR_GT] = &&op_gt,
        [IR_SLT] = &&op_slt, [IR_SGT] = &&op_sgt, [IR_EQ] = &&op_eq,
        [IR_ISZERO] = &&op_iszero,
        [IR_AND] = &&op_and, [IR_OR] = &&op_or, [IR_XOR] = &&op_xor,
        [IR_NOT] = &&op_not, [IR_SHL] = &&op_shl, [IR_SHR] = &&op_shr,
        [IR_CDLOAD] = &&op_cdload, [IR_CDSIZE] = &&op_cdsize,
        [IR_MLOAD] = &&op_mload, [IR_MSTORE] = &&op_mstore,
        [IR_J] = &&op_j, [IR_BNZ] = &&op_bnz, [IR_CALL] = &&op_call,
        [IR_RET] = &&op_ret, [IR_RETURNDATA] = &&op_returndata,
        [IR_REVERT] = &&op_revert, [IR_STOP] = &&op_stop,
    };
    static unsigned ret_pc[RSTACK_LIMIT];
    static unsigned ret_k[RSTACK_LIMIT];
    u64 pc = 0, gas = 0, base = 0, rsp = 0;
    const IR *i;
    word t;

#define A R[base + i->a]
#define B R[base + i->b]
#define C R[base + i->c]

next:
    if (pc >= IRC_LEN) __rt_stop();
    i = &IRC[pc];
    goto *J[i->op];

op_gas:    gas += i->imm; if (gas > GAS_LIMIT) __rt_trap("out of gas");
           pc++; goto next;
op_li:
#ifdef WIDTH64
           A = (u64)i->imm;
#else
           set_low(&A, (u64)i->imm);
#endif
           pc++; goto next;
op_mv:     A = B; pc++; goto next;
op_xchg:   t = A; A = B; B = t; pc++; goto next;

#ifdef WIDTH64

op_add:    A = B + C; pc++; goto next;
op_sub:    A = B - C; pc++; goto next;
op_mul:    A = B * C; pc++; goto next;
op_div:    A = C ? B / C : 0; pc++; goto next;
op_mod:    A = C ? B % C : 0; pc++; goto next;
op_lt:     A = B < C; pc++; goto next;
op_gt:     A = B > C; pc++; goto next;
op_slt:    A = (long)B < (long)C; pc++; goto next;
op_sgt:    A = (long)B > (long)C; pc++; goto next;
op_eq:     A = B == C; pc++; goto next;
op_iszero: A = B == 0; pc++; goto next;
op_and:    A = B & C; pc++; goto next;
op_or:     A = B | C; pc++; goto next;
op_xor:    A = B ^ C; pc++; goto next;
op_not:    A = ~B; pc++; goto next;
op_shl:    A = B < 64 ? C << B : 0; pc++; goto next;
op_shr:    A = B < 64 ? C >> B : 0; pc++; goto next;

op_cdload: { u64 idx = B, v = 0;
    for (int b = 0; b < 8; b++) {
        u64 at = idx + 24 + b;
        v = (v << 8) | (at < CALLDATA_LEN ? CALLDATA[at] : 0);
    }
    A = v; } pc++; goto next;
op_cdsize: A = CALLDATA_LEN; pc++; goto next;
op_mload:  { u64 idx = checked_index(B), v = 0;
    for (int b = 0; b < 8; b++) v = (v << 8) | MEM[idx + 24 + b];
    A = v; } pc++; goto next;
op_mstore: { u64 idx = checked_index(A), v = B;
    for (int b = 0; b < 24; b++) MEM[idx + b] = 0;
    for (int b = 0; b < 8; b++) MEM[idx + 24 + b] = (u8)(v >> (8 * (7 - b)));
    } pc++; goto next;
op_bnz:    if (A) { pc = i->imm; goto next; } pc++; goto next;
op_returndata: { u64 off = A, len = B;
    if (off + len > MEM_SIZE) __rt_trap("memory out of range");
    __rt_return(MEM + off, len); }

#else /* 256-bit */

op_add:    add256(&A, &B, &C); pc++; goto next;
op_sub:    sub256(&A, &B, &C); pc++; goto next;
op_mul:    mul256(&A, &B, &C); pc++; goto next;
op_div:    { word q, r; divmod256(&q, &r, &B, &C); A = q; }
           pc++; goto next;
op_mod:    { word q, r; divmod256(&q, &r, &B, &C); A = r; }
           pc++; goto next;
op_lt:     { u64 v = lt256(&B, &C); set_low(&A, v); } pc++; goto next;
op_gt:     { u64 v = lt256(&C, &B); set_low(&A, v); } pc++; goto next;
op_slt:    { u64 v = slt256(&B, &C); set_low(&A, v); } pc++; goto next;
op_sgt:    { u64 v = slt256(&C, &B); set_low(&A, v); } pc++; goto next;
op_eq:     { u64 v = (B.w[0] == C.w[0]) & (B.w[1] == C.w[1])
                   & (B.w[2] == C.w[2]) & (B.w[3] == C.w[3]);
             set_low(&A, v); } pc++; goto next;
op_iszero: { u64 v = IS_ZERO(B); set_low(&A, v); } pc++; goto next;
op_and:    for (int l = 0; l < 4; l++) A.w[l] = B.w[l] & C.w[l];
           pc++; goto next;
op_or:     for (int l = 0; l < 4; l++) A.w[l] = B.w[l] | C.w[l];
           pc++; goto next;
op_xor:    for (int l = 0; l < 4; l++) A.w[l] = B.w[l] ^ C.w[l];
           pc++; goto next;
op_not:    for (int l = 0; l < 4; l++) A.w[l] = ~B.w[l];
           pc++; goto next;
op_shl:    { u64 s = B.w[0];
    if ((B.w[1] | B.w[2] | B.w[3]) || s >= 256) set_low(&t, 0);
    else shl256(&t, &C, s);
    A = t; } pc++; goto next;
op_shr:    { u64 s = B.w[0];
    if ((B.w[1] | B.w[2] | B.w[3]) || s >= 256) set_low(&t, 0);
    else shr256(&t, &C, s);
    A = t; } pc++; goto next;

op_cdload: { u64 far = B.w[1] | B.w[2] | B.w[3], idx = B.w[0];
    for (int limb = 3; limb >= 0; limb--) {
        u64 v = 0;
        for (int b = 0; b < 8; b++) {
            u64 at = idx + (3 - limb) * 8 + b;
            v = (v << 8) | ((!far && at < CALLDATA_LEN) ? CALLDATA[at] : 0);
        }
        t.w[limb] = v;
    }
    A = t; } pc++; goto next;
op_cdsize: set_low(&A, CALLDATA_LEN); pc++; goto next;
op_mload:  { if (A.w[1] | A.w[2] | A.w[3]) __rt_trap("memory out of range");
    u64 idx = checked_index(B.w[0]);
    for (int limb = 3; limb >= 0; limb--) {
        u64 v = 0;
        for (int b = 0; b < 8; b++)
            v = (v << 8) | MEM[idx + (3 - limb) * 8 + b];
        t.w[limb] = v;
    }
    A = t; } pc++; goto next;
op_mstore: { if (A.w[1] | A.w[2] | A.w[3]) __rt_trap("memory out of range");
    u64 idx = checked_index(A.w[0]);
    for (int limb = 3; limb >= 0; limb--)
        for (int b = 0; b < 8; b++)
            MEM[idx + (3 - limb) * 8 + b] = (u8)(B.w[limb] >> (8 * (7 - b)));
    } pc++; goto next;
op_bnz:    if (!IS_ZERO(A)) { pc = i->imm; goto next; } pc++; goto next;
op_returndata: { u64 off = A.w[0], len = B.w[0];
    if (off + len > MEM_SIZE) __rt_trap("memory out of range");
    __rt_return(MEM + off, len); }

#endif

op_j:      pc = i->imm; goto next;
op_call:   if (rsp >= RSTACK_LIMIT) __rt_trap("return stack overflow");
           if (base + i->a + i->b > STACK_LIMIT) __rt_trap("stack overflow");
           ret_pc[rsp] = (unsigned)(pc + 1);
           ret_k[rsp] = i->a;
           rsp++;
           base += i->a;
           pc = i->imm; goto next;
op_ret:    if (!rsp) __rt_trap("return stack underflow");
           rsp--;
           base -= ret_k[rsp];
           pc = ret_pc[rsp]; goto next;
op_revert: __rt_revert();
op_stop:   __rt_stop();
}
