/* Baseline EVM interpreter for the 2x2 measurement.
 *
 * This is the status quo cell: bytecode interpreted at run time, with
 * everything a mainnet client must do — JUMPDEST analysis before the
 * first instruction, a dynamic destination check at every jump, a gas
 * charge and stack bounds check at every step, and 256-bit arithmetic
 * carried in four 64-bit limbs.  Dispatch is a computed goto, the
 * respectable technique; the point of comparison is what
 * interpretation itself costs, so the interpreter must not be a
 * strawman.
 *
 * The EVM64 opcodes are placeholders for measurement: the 64-bit twin
 * of an arithmetic opcode x in 0x01..0x1C is 0xC0+x, operating modulo
 * 2^64 with the upper limbs of the result zero; CALLDATALOAD64=0xE0,
 * MLOAD64=0xE1, MSTORE64=0xE2 move words whose value fits 64 bits.
 * Stack items remain 256-bit words: EVM64's saving is arithmetic, not
 * item width.
 *
 * Implemented: the instructions the yul7979 compiler emits, plus
 * their twins.  Anything else traps.
 */
typedef unsigned long u64;
typedef unsigned int u32;
typedef unsigned char u8;
typedef unsigned __int128 u128;

extern const u8 CODE[];
extern const u64 CODE_LEN;
extern const u8 CALLDATA[];
extern const u64 CALLDATA_LEN;
extern u8 MEM[];
#define MEM_SIZE (1UL << 20)

void __rt_return(const u8 *p, u64 n);
void __rt_stop(void);
void __rt_revert(void);
void __rt_trap(const char *msg);

typedef struct { u64 w[4]; } u256;     /* little-endian limbs */

#define GAS_LIMIT 10000000000UL
#define STACK_LIMIT 1024
#define RSTACK_LIMIT 1024

static u256 stk[STACK_LIMIT];
static u32 rstack[RSTACK_LIMIT];
static u8 jd[65536];                   /* JUMPDEST/CALLDEST bitmap */

/* ---- 256-bit helpers ---------------------------------------------- */

static int zero256(const u256 *a)
{
    return !(a->w[0] | a->w[1] | a->w[2] | a->w[3]);
}

static int lt256(const u256 *a, const u256 *b)
{
    for (int i = 3; i >= 0; i--) {
        if (a->w[i] < b->w[i]) return 1;
        if (a->w[i] > b->w[i]) return 0;
    }
    return 0;
}

static int slt256(const u256 *a, const u256 *b)
{
    u64 sa = a->w[3] >> 63, sb = b->w[3] >> 63;
    if (sa != sb) return sa;
    return lt256(a, b);
}

static void add256(u256 *r, const u256 *a, const u256 *b)
{
    u128 c = 0;
    for (int i = 0; i < 4; i++) {
        c += (u128)a->w[i] + b->w[i];
        r->w[i] = (u64)c;
        c >>= 64;
    }
}

static void sub256(u256 *r, const u256 *a, const u256 *b)
{
    u128 br = 0;
    for (int i = 0; i < 4; i++) {
        u128 t = (u128)a->w[i] - b->w[i] - br;
        r->w[i] = (u64)t;
        br = (t >> 64) & 1;
    }
}

static void mul256(u256 *r, const u256 *a, const u256 *b)
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

static void shl256(u256 *r, const u256 *a, u64 s)
{
    u256 t = {{0, 0, 0, 0}};
    u64 limb = s >> 6, bit = s & 63;
    for (int i = 3; (int)(i - limb) >= 0; i--) {
        t.w[i] = a->w[i - limb] << bit;
        if (bit && (int)(i - limb - 1) >= 0)
            t.w[i] |= a->w[i - limb - 1] >> (64 - bit);
    }
    *r = t;
}

static void shr256(u256 *r, const u256 *a, u64 s)
{
    u256 t = {{0, 0, 0, 0}};
    u64 limb = s >> 6, bit = s & 63;
    for (u64 i = 0; i + limb < 4; i++) {
        t.w[i] = a->w[i + limb] >> bit;
        if (bit && i + limb + 1 < 4)
            t.w[i] |= a->w[i + limb + 1] << (64 - bit);
    }
    *r = t;
}

/* Long division: fast path when both operands fit one limb (the
 * common case on mainnet), 256-step shift-subtract otherwise. */
static void divmod256(u256 *q, u256 *rem, const u256 *a, const u256 *b)
{
    static const u256 z = {{0, 0, 0, 0}};
    if (zero256(b)) { *q = z; *rem = z; return; }
    if (!(a->w[1] | a->w[2] | a->w[3] | b->w[1] | b->w[2] | b->w[3])) {
        *q = z; *rem = z;
        q->w[0] = a->w[0] / b->w[0];
        rem->w[0] = a->w[0] % b->w[0];
        return;
    }
    u256 r = z, qq = z;
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

/* ---- memory and calldata (big-endian words) ------------------------ */

static void load_word(u256 *r, const u8 *base, u64 len, const u256 *idx)
{
    u64 i = idx->w[0];
    int far = (idx->w[1] | idx->w[2] | idx->w[3]) != 0;
    for (int limb = 3; limb >= 0; limb--) {
        u64 v = 0;
        for (int b = 0; b < 8; b++) {
            u64 at = i + (3 - limb) * 8 + b;
            v = (v << 8) | ((!far && at < len) ? base[at] : 0);
        }
        r->w[limb] = v;
    }
}

static u64 mem_index(const u256 *idx, u64 span)
{
    if (idx->w[1] | idx->w[2] | idx->w[3] || idx->w[0] + span > MEM_SIZE)
        __rt_trap("memory out of range");
    return idx->w[0];
}

static void store_word(u64 i, const u256 *v)
{
    for (int limb = 3; limb >= 0; limb--)
        for (int b = 7; b >= 0; b--)
            MEM[i + (3 - limb) * 8 + (7 - b)] = (u8)(v->w[limb] >> (8 * b));
}

/* ---- gas ------------------------------------------------------------ */

static const u8 GASTBL[256] = {
    [0x00] = 0, [0x01] = 3, [0x02] = 5, [0x03] = 3, [0x04] = 5, [0x06] = 5,
    [0x10] = 3, [0x11] = 3, [0x12] = 3, [0x13] = 3, [0x14] = 3, [0x15] = 3,
    [0x16] = 3, [0x17] = 3, [0x18] = 3, [0x19] = 3, [0x1B] = 3, [0x1C] = 3,
    [0x35] = 3, [0x36] = 2, [0x50] = 2, [0x51] = 3, [0x52] = 3,
    [0x56] = 8, [0x57] = 10, [0x5B] = 1,
    [0xB0] = 8, [0xB1] = 1, [0xB2] = 5,
    [0xF3] = 0, [0xFD] = 0,
    [0xC1] = 3, [0xC2] = 5, [0xC3] = 3, [0xC4] = 5, [0xC6] = 5,
    [0xD0] = 3, [0xD1] = 3, [0xD2] = 3, [0xD3] = 3, [0xD4] = 3, [0xD5] = 3,
    [0xD6] = 3, [0xD7] = 3, [0xD8] = 3, [0xD9] = 3, [0xDB] = 3, [0xDC] = 3,
    [0xE0] = 3, [0xE1] = 3, [0xE2] = 3,
    /* PUSH/DUP/SWAP filled by the 3s below */
    [0x5F] = 2,
};

/* ---- the interpreter ------------------------------------------------ */

#define NEED(n)  do { if (sp < (n)) __rt_trap("stack underflow"); } while (0)
#define ROOM(n)  do { if (sp + (n) > STACK_LIMIT) __rt_trap("stack overflow"); } while (0)

void evm_entry(void)
{
    static const void *J[256] = {
        [0 ... 255] = &&op_bad,
        [0x00] = &&op_stop, [0x01] = &&op_add, [0x02] = &&op_mul,
        [0x03] = &&op_sub, [0x04] = &&op_div, [0x06] = &&op_mod,
        [0x10] = &&op_lt, [0x11] = &&op_gt, [0x12] = &&op_slt,
        [0x13] = &&op_sgt, [0x14] = &&op_eq, [0x15] = &&op_iszero,
        [0x16] = &&op_and, [0x17] = &&op_or, [0x18] = &&op_xor,
        [0x19] = &&op_not, [0x1B] = &&op_shl, [0x1C] = &&op_shr,
        [0x35] = &&op_cdload, [0x36] = &&op_cdsize, [0x50] = &&op_pop,
        [0x51] = &&op_mload, [0x52] = &&op_mstore,
        [0x56] = &&op_jump, [0x57] = &&op_jumpi, [0x5B] = &&op_jumpdest,
        [0x5F ... 0x7F] = &&op_push,
        [0x80 ... 0x8F] = &&op_dup,
        [0x90 ... 0x9F] = &&op_swap,
        [0xB0] = &&op_callsub, [0xB1] = &&op_calldest, [0xB2] = &&op_returnsub,
        [0xF3] = &&op_return, [0xFD] = &&op_revert,
        [0xC1] = &&op_add64, [0xC2] = &&op_mul64, [0xC3] = &&op_sub64,
        [0xC4] = &&op_div64, [0xC6] = &&op_mod64,
        [0xD0] = &&op_lt64, [0xD1] = &&op_gt64, [0xD2] = &&op_slt64,
        [0xD3] = &&op_sgt64, [0xD4] = &&op_eq64, [0xD5] = &&op_iszero64,
        [0xD6] = &&op_and64, [0xD7] = &&op_or64, [0xD8] = &&op_xor64,
        [0xD9] = &&op_not64, [0xDB] = &&op_shl64, [0xDC] = &&op_shr64,
        [0xE0] = &&op_cdload64, [0xE1] = &&op_mload64, [0xE2] = &&op_mstore64,
    };

    u64 pc = 0, gas = 0, sp = 0, rsp = 0;
    u8 op;
    u256 t;

    /* JUMPDEST analysis: the pre-run scan every client performs on
     * legacy code, and exactly the work validated code retires. */
    {
        u64 i = 0;
        while (i < CODE_LEN) {
            u8 o = CODE[i];
            if (o == 0x5B || o == 0xB1) jd[i] = 1;
            i += (o > 0x5F && o <= 0x7F) ? o - 0x5E : 1;
        }
    }

next:
    if (pc >= CODE_LEN) __rt_stop();
    op = CODE[pc];
    gas += GASTBL[op] ? GASTBL[op] : 3;
    if (gas > GAS_LIMIT) __rt_trap("out of gas");
    goto *J[op];

op_stop:   __rt_stop();
op_bad:    __rt_trap("invalid opcode");

op_add:    NEED(2); add256(&stk[sp-2], &stk[sp-1], &stk[sp-2]); sp--; pc++; goto next;
op_mul:    NEED(2); mul256(&stk[sp-2], &stk[sp-1], &stk[sp-2]); sp--; pc++; goto next;
op_sub:    NEED(2); sub256(&stk[sp-2], &stk[sp-1], &stk[sp-2]); sp--; pc++; goto next;
op_div:    NEED(2); { u256 q, r; divmod256(&q, &r, &stk[sp-1], &stk[sp-2]);
                      stk[sp-2] = q; } sp--; pc++; goto next;
op_mod:    NEED(2); { u256 q, r; divmod256(&q, &r, &stk[sp-1], &stk[sp-2]);
                      stk[sp-2] = r; } sp--; pc++; goto next;

#define CMP(name, expr) \
op_##name: NEED(2); { u64 v = (expr); \
    stk[sp-2].w[0] = v; stk[sp-2].w[1] = stk[sp-2].w[2] = stk[sp-2].w[3] = 0; } \
    sp--; pc++; goto next;

CMP(lt,  lt256(&stk[sp-1], &stk[sp-2]))
CMP(gt,  lt256(&stk[sp-2], &stk[sp-1]))
CMP(slt, slt256(&stk[sp-1], &stk[sp-2]))
CMP(sgt, slt256(&stk[sp-2], &stk[sp-1]))
CMP(eq,  (stk[sp-1].w[0] == stk[sp-2].w[0]) & (stk[sp-1].w[1] == stk[sp-2].w[1])
       & (stk[sp-1].w[2] == stk[sp-2].w[2]) & (stk[sp-1].w[3] == stk[sp-2].w[3]))

op_iszero: NEED(1); { u64 v = zero256(&stk[sp-1]);
    stk[sp-1].w[0] = v; stk[sp-1].w[1] = stk[sp-1].w[2] = stk[sp-1].w[3] = 0; }
    pc++; goto next;

#define BITOP(name, sym) \
op_##name: NEED(2); for (int i = 0; i < 4; i++) \
        stk[sp-2].w[i] = stk[sp-1].w[i] sym stk[sp-2].w[i]; \
    sp--; pc++; goto next;

BITOP(and, &)
BITOP(or,  |)
BITOP(xor, ^)

op_not:    NEED(1); for (int i = 0; i < 4; i++) stk[sp-1].w[i] = ~stk[sp-1].w[i];
           pc++; goto next;

op_shl:    NEED(2); { u64 s = stk[sp-1].w[0];
    if ((stk[sp-1].w[1] | stk[sp-1].w[2] | stk[sp-1].w[3]) || s >= 256)
        stk[sp-2] = (u256){{0,0,0,0}};
    else shl256(&stk[sp-2], &stk[sp-2], s); } sp--; pc++; goto next;
op_shr:    NEED(2); { u64 s = stk[sp-1].w[0];
    if ((stk[sp-1].w[1] | stk[sp-1].w[2] | stk[sp-1].w[3]) || s >= 256)
        stk[sp-2] = (u256){{0,0,0,0}};
    else shr256(&stk[sp-2], &stk[sp-2], s); } sp--; pc++; goto next;

op_cdload: NEED(1); load_word(&t, CALLDATA, CALLDATA_LEN, &stk[sp-1]);
           stk[sp-1] = t; pc++; goto next;
op_cdsize: ROOM(1); stk[sp] = (u256){{CALLDATA_LEN, 0, 0, 0}}; sp++;
           pc++; goto next;
op_pop:    NEED(1); sp--; pc++; goto next;
op_mload:  NEED(1); { u64 i = mem_index(&stk[sp-1], 32);
    u256 mi = {{i, 0, 0, 0}};
    load_word(&t, MEM, MEM_SIZE, &mi); stk[sp-1] = t; } pc++; goto next;
op_mstore: NEED(2); { u64 i = mem_index(&stk[sp-1], 32);
    store_word(i, &stk[sp-2]); } sp -= 2; pc++; goto next;

op_jump:   NEED(1); { u64 d = stk[sp-1].w[0];
    if ((stk[sp-1].w[1] | stk[sp-1].w[2] | stk[sp-1].w[3]) || d >= CODE_LEN
        || !jd[d]) __rt_trap("bad jump destination");
    sp--; pc = d; } goto next;
op_jumpi:  NEED(2); { u64 d = stk[sp-1].w[0]; int taken = !zero256(&stk[sp-2]);
    int bad = (stk[sp-1].w[1] | stk[sp-1].w[2] | stk[sp-1].w[3]) || d >= CODE_LEN
        || !jd[d];
    sp -= 2;
    if (taken) { if (bad) __rt_trap("bad jump destination"); pc = d; }
    else pc++; } goto next;
op_jumpdest: pc++; goto next;

op_push:   { u64 n = op - 0x5F; ROOM(1);
    u256 v = {{0, 0, 0, 0}};
    for (u64 b = 0; b < n; b++) {
        u64 byte = (pc + 1 + b < CODE_LEN) ? CODE[pc + 1 + b] : 0;
        /* shift the 256-bit accumulator left 8 and or in the byte */
        for (int i = 3; i > 0; i--)
            v.w[i] = (v.w[i] << 8) | (v.w[i-1] >> 56);
        v.w[0] = (v.w[0] << 8) | byte;
    }
    stk[sp++] = v; pc += 1 + n; } goto next;

op_dup:    { u64 n = op - 0x7F; NEED(n); ROOM(1);
    stk[sp] = stk[sp - n]; sp++; pc++; } goto next;
op_swap:   { u64 n = op - 0x8F; NEED(n + 1);
    t = stk[sp-1]; stk[sp-1] = stk[sp-1-n]; stk[sp-1-n] = t; pc++; } goto next;

op_callsub: NEED(1); { u64 d = stk[sp-1].w[0];
    if ((stk[sp-1].w[1] | stk[sp-1].w[2] | stk[sp-1].w[3]) || d >= CODE_LEN
        || CODE[d] != 0xB1) __rt_trap("CALLSUB to non-CALLDEST");
    if (rsp >= RSTACK_LIMIT) __rt_trap("return stack overflow");
    rstack[rsp++] = (u32)(pc + 1);
    sp--; pc = d; } goto next;
op_calldest: pc++; goto next;
op_returnsub: if (!rsp) __rt_trap("return stack underflow");
    pc = rstack[--rsp]; goto next;

op_return: NEED(2); { u64 i = mem_index(&stk[sp-1], stk[sp-2].w[0]);
    __rt_return(MEM + i, stk[sp-2].w[0]); }
op_revert: __rt_revert();

/* ---- EVM64 twins: same stack, one-limb arithmetic ------------------- */

#define BIN64(name, stmt) \
op_##name: NEED(2); { u64 a = stk[sp-1].w[0], b = stk[sp-2].w[0], r; \
    stmt; \
    stk[sp-2].w[0] = r; stk[sp-2].w[1] = stk[sp-2].w[2] = stk[sp-2].w[3] = 0; } \
    sp--; pc++; goto next;

BIN64(add64, r = a + b)
BIN64(mul64, r = a * b)
BIN64(sub64, r = a - b)
BIN64(div64, r = b ? a / b : 0)
BIN64(mod64, r = b ? a % b : 0)
BIN64(lt64,  r = a < b)
BIN64(gt64,  r = a > b)
BIN64(slt64, r = (long)a < (long)b)
BIN64(sgt64, r = (long)a > (long)b)
BIN64(eq64,  r = a == b)
BIN64(and64, r = a & b)
BIN64(or64,  r = a | b)
BIN64(xor64, r = a ^ b)
BIN64(shl64, r = a < 64 ? b << a : 0)
BIN64(shr64, r = a < 64 ? b >> a : 0)

op_iszero64: NEED(1); stk[sp-1].w[0] = !stk[sp-1].w[0];
    stk[sp-1].w[1] = stk[sp-1].w[2] = stk[sp-1].w[3] = 0; pc++; goto next;
op_not64:  NEED(1); stk[sp-1].w[0] = ~stk[sp-1].w[0];
    stk[sp-1].w[1] = stk[sp-1].w[2] = stk[sp-1].w[3] = 0; pc++; goto next;

op_cdload64: NEED(1); { u64 i = stk[sp-1].w[0], v = 0;
    int far = (stk[sp-1].w[1] | stk[sp-1].w[2] | stk[sp-1].w[3]) != 0;
    for (int b = 0; b < 8; b++) {
        u64 at = i + 24 + b;
        v = (v << 8) | ((!far && at < CALLDATA_LEN) ? CALLDATA[at] : 0);
    }
    stk[sp-1].w[0] = v; stk[sp-1].w[1] = stk[sp-1].w[2] = stk[sp-1].w[3] = 0; }
    pc++; goto next;
op_mload64: NEED(1); { u64 i = mem_index(&stk[sp-1], 32), v = 0;
    for (int b = 0; b < 8; b++) v = (v << 8) | MEM[i + 24 + b];
    stk[sp-1].w[0] = v; stk[sp-1].w[1] = stk[sp-1].w[2] = stk[sp-1].w[3] = 0; }
    pc++; goto next;
op_mstore64: NEED(2); { u64 i = mem_index(&stk[sp-1], 32), v = stk[sp-2].w[0];
    for (int b = 0; b < 24; b++) MEM[i + b] = 0;
    for (int b = 0; b < 8; b++) MEM[i + 24 + b] = (u8)(v >> (8 * (7 - b))); }
    sp -= 2; pc++; goto next;
}
