/* A C port of the bounds-proving validator (magic_validator.py),
 * for one purpose: measuring what native validation costs — above
 * all its worst case, the recursion pump that drives the inputs
 * relaxation through O(1024 * n) work.  The port follows the Python
 * line for line; correctness is established by running the shared
 * vectors and a fuzz corpus against both (measure.py).
 *
 * Usage:  validator FILE [STACK_LIMIT]           -> prints 0 or 1
 *         validator -b FILE REPS [STACK_LIMIT]   -> ns/byte on stdout
 *
 * Placeholder opcodes: CALLSUB=0xB0, CALLDEST=0xB1, RETURNSUB=0xB2.
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include "opcodes.h"

#define MAXN   24576
#define ARENA  (4 * MAXN + 8)
#define RINGSZ 32768                    /* > MAXN + 2, power of two   */

enum { CALLSUB = 0xB0, CALLDEST = 0xB1, RETURNSUB = 0xB2,
       JUMP = 0x56, JUMPI = 0x57, JUMPDEST = 0x5B };
enum { REQ_NONE, REQ_LABEL, REQ_ENTRY };

typedef struct { int32_t pc, off, entry, framed, push; } Item;

/* per position (entry id = its pc; top-level code = index n) */
static uint8_t  vis[MAXN + 2], vfr[MAXN + 2], required[MAXN + 2];
static int32_t  voff[MAXN + 2], vent[MAXN + 2];
static uint8_t  net_known[MAXN + 2], seen[MAXN + 2], queued[MAXN + 2];
static int32_t  net[MAXN + 2], inputs[MAXN + 2], growth[MAXN + 2], calldep[MAXN + 2];
static int32_t  pend_head[MAXN + 2], entp_head[MAXN + 2], chld_head[MAXN + 2];
static int32_t  unfin[MAXN + 2];
static int32_t  nodes[MAXN + 2], ready[MAXN + 2], ring[RINGSZ];
/* arenas: linked lists, heads store index + 1 */
static struct { int32_t ret_pc, off, caller, framed, next; } pend[ARENA];
static struct { int32_t parent, off, next; }                 entp[ARENA];
static struct { int32_t parent, off, is_call, next; }        chld[ARENA];
static Item work[ARENA];
static struct { int32_t e, v; } settle[ARENA];
static int32_t npend, nentp, nchld, nwork, nnodes;

static void touch(int32_t e)
{
    if (!seen[e]) { seen[e] = 1; nodes[nnodes++] = e; }
}

/* Record an entry's net: release the return points waiting on it,
 * and settle the entries that jump or fall into it.  0 on conflict. */
static int resolve(int32_t e0, int32_t v0)
{
    int32_t top = 0;
    settle[top].e = e0; settle[top].v = v0; top++;
    while (top > 0) {
        int32_t e = settle[--top].e, v = settle[top].v;
        if (net_known[e]) {
            if (net[e] != v) return 0;  /* Constraint 5: one net per entry */
            continue;
        }
        net_known[e] = 1; net[e] = v;
        for (int32_t h = pend_head[e]; h; ) {
            work[nwork].pc = pend[h-1].ret_pc;
            work[nwork].off = pend[h-1].off + v;
            work[nwork].entry = pend[h-1].caller;
            work[nwork].framed = pend[h-1].framed;
            work[nwork].push = -1;
            nwork++;
            h = pend[h-1].next;
        }
        pend_head[e] = 0;
        for (int32_t h = entp_head[e]; h; ) {
            settle[top].e = entp[h-1].parent;
            settle[top].v = entp[h-1].off + v;
            top++;
            h = entp[h-1].next;
        }
    }
    return 1;
}

static int validate(const uint8_t *code, int32_t n, int32_t limit)
{
    if (n == 0 || n > MAXN) return 0;
    size_t bytes = (size_t)(n + 2);
    memset(vis, 0, bytes);      memset(vfr, 0, bytes);
    memset(required, 0, bytes); memset(net_known, 0, bytes);
    memset(seen, 0, bytes);     memset(queued, 0, bytes);
    memset(inputs, 0, bytes * 4);    memset(growth, 0, bytes * 4);
    memset(calldep, 0, bytes * 4);   memset(unfin, 0, bytes * 4);
    memset(pend_head, 0, bytes * 4); memset(entp_head, 0, bytes * 4);
    memset(chld_head, 0, bytes * 4);
    npend = nentp = nchld = nnodes = 0;
    const int32_t outer = n;
    touch(outer);
    work[0] = (Item){0, 0, outer, 0, -1};
    nwork = 1;

    /* Phase 1, the traversal: visit every reachable instruction once. */
    while (nwork > 0) {
        Item it = work[--nwork];
        int32_t pc = it.pc, off = it.off, entry = it.entry;
        int32_t framed = it.framed, push = it.push;
        if (pc >= n) continue;          /* implicit STOP: a valid end */
        int op = code[pc];
        if (!OPSIZE[op]) return 0;      /* Constraint 1: not a valid opcode */

        /* A CALLDEST is visited at offset 0, as its own entry; arriving
         * any other way first records the link between the subroutines. */
        if (op == CALLDEST && (entry != pc || off != 0)) {
            entp[nentp].parent = entry; entp[nentp].off = off;
            entp[nentp].next = entp_head[pc]; nentp++;
            entp_head[pc] = nentp;
            touch(entry); touch(pc);
            chld[nchld].parent = entry; chld[nchld].off = off;
            chld[nchld].is_call = 0; chld[nchld].next = chld_head[pc]; nchld++;
            chld_head[pc] = nchld;
            unfin[entry]++;
            if (net_known[pc] && !resolve(entry, off + net[pc])) return 0;
            off = 0; entry = pc;
        }

        if (vis[pc]) {                  /* Constraint 5: paths must agree */
            if (voff[pc] != off || vent[pc] != entry || vfr[pc] != framed)
                return 0;
            continue;
        }
        vis[pc] = 1; voff[pc] = off; vent[pc] = entry; vfr[pc] = (uint8_t)framed;

        /* Constraints 2 and 3: a required destination type, if any. */
        if (required[pc] == REQ_LABEL && op != JUMPDEST && op != CALLDEST)
            return 0;
        if (required[pc] == REQ_ENTRY && op != CALLDEST)
            return 0;

        /* Constraint 4: items used below the start; growth above it. */
        int32_t cand = OPPOPS[op] - off;
        if (cand > inputs[entry]) {
            if (cand > limit) return 0;
            inputs[entry] = cand;
        }
        off += OPPUSH[op] - OPPOPS[op];
        if (off > growth[entry]) growth[entry] = off;
        int32_t nxt = pc + OPSIZE[op];

        if (op == CALLSUB) {
            if (push < 0) return 0;     /* Constraint 3: PUSH before CALLSUB */
            int32_t dest = push;
            if (dest >= n) return 0;
            if (vis[dest] && code[dest] != CALLDEST) return 0;
            required[dest] = REQ_ENTRY; /* a jump's LABEL upgrades to ENTRY */
            touch(entry); touch(dest);
            chld[nchld].parent = entry; chld[nchld].off = off;
            chld[nchld].is_call = 1; chld[nchld].next = chld_head[dest]; nchld++;
            chld_head[dest] = nchld;
            unfin[entry]++;
            work[nwork++] = (Item){dest, 0, dest, 1, -1};
            if (net_known[dest]) {      /* return point: offset plus net */
                work[nwork++] = (Item){nxt, off + net[dest], entry, framed, -1};
            } else {
                pend[npend].ret_pc = nxt; pend[npend].off = off;
                pend[npend].caller = entry; pend[npend].framed = framed;
                pend[npend].next = pend_head[dest]; npend++;
                pend_head[dest] = npend;
            }
        } else if (op == RETURNSUB) {
            if (!framed) return 0;      /* no CALLSUB to return from */
            if (!resolve(entry, off)) return 0;
        } else if (op == JUMP || op == JUMPI) {
            if (push < 0) return 0;     /* Constraint 2: PUSH before JUMP/JUMPI */
            int32_t dest = push;
            if (dest >= n) return 0;
            if (vis[dest] && code[dest] != JUMPDEST && code[dest] != CALLDEST)
                return 0;
            if (!required[dest]) required[dest] = REQ_LABEL;
            work[nwork++] = (Item){dest, off, entry, framed, -1};
            if (op == JUMPI)            /* and the fall-through arm */
                work[nwork++] = (Item){nxt, off, entry, framed, -1};
        } else if (!OPTERM[op]) {       /* everything else falls through */
            int32_t val = -1;
            if (op >= 0x5F && op <= 0x7F) {
                val = 0;
                for (int32_t j = 0; j < op - 0x5F; j++) {
                    int b = pc + 1 + j < n ? code[pc + 1 + j] : 0;
                    val = val <= MAXN ? (val << 8) | b : val;
                    if (val > MAXN) val = MAXN + 1;   /* invalid as any dest */
                }
            }
            work[nwork++] = (Item){nxt, off, entry, framed, val};
        }
    }

    /* Phase 2, the combining: fold each subroutine's stack use into
     * everyone who calls or enters it.  Children before parents:
     * without recursion, one exact pass. */
    int32_t nready = 0, finished = 0;
    for (int32_t i = 0; i < nnodes; i++)
        if (unfin[nodes[i]] == 0) ready[nready++] = nodes[i];
    while (nready > 0) {
        int32_t e = ready[--nready];
        finished++;
        for (int32_t h = chld_head[e]; h; h = chld[h-1].next) {
            int32_t p = chld[h-1].parent, d = chld[h-1].off;
            int32_t ci = inputs[e] - d;
            if (ci > inputs[p]) {
                if (ci > limit) return 0;
                inputs[p] = ci;
            }
            if (d + growth[e] > growth[p]) growth[p] = d + growth[e];
            if (calldep[e] + chld[h-1].is_call > calldep[p])
                calldep[p] = calldep[e] + chld[h-1].is_call;
            if (--unfin[p] == 0) ready[nready++] = p;
        }
    }

    if (finished == nnodes) {
        /* No recursion: reject code that must overflow a stack. */
        if (growth[outer] > limit || calldep[outer] > limit) return 0;
    } else {
        /* Recursion: overflow is left to the runtime checks.  Repeat
         * the inheritance step until no inputs rise. */
        int32_t qh = 0, qt = 0;
        for (int32_t i = 0; i < nnodes; i++) {
            ring[qt++ & (RINGSZ - 1)] = nodes[i];
            queued[nodes[i]] = 1;
        }
        while (qh != qt) {
            int32_t e = ring[qh++ & (RINGSZ - 1)];
            queued[e] = 0;
            for (int32_t h = chld_head[e]; h; h = chld[h-1].next) {
                int32_t p = chld[h-1].parent;
                int32_t need = inputs[e] - chld[h-1].off;
                if (need > inputs[p]) {
                    if (need > limit) return 0;
                    inputs[p] = need;
                    if (!queued[p]) { queued[p] = 1; ring[qt++ & (RINGSZ - 1)] = p; }
                }
            }
        }
    }

    /* Top-level code has no caller to take items from. */
    return inputs[outer] == 0;
}

int main(int argc, char **argv)
{
    int bench = argc > 1 && strcmp(argv[1], "-b") == 0;
    const char *path = argv[bench ? 2 : 1];
    long reps = bench ? atol(argv[3]) : 1;
    int32_t limit = 1024;
    if (!bench && argc > 2) limit = atoi(argv[2]);
    if (bench && argc > 4) limit = atoi(argv[4]);

    static uint8_t code[MAXN + 34];
    FILE *f = fopen(path, "rb");
    if (!f) { perror(path); return 2; }
    int32_t n = (int32_t)fread(code, 1, sizeof code, f);
    fclose(f);

    if (!bench) { printf("%d\n", validate(code, n, limit)); return 0; }

    int r = validate(code, n, limit);   /* warm caches */
    volatile int sink = 0;
    struct timespec t0, t1;
    clock_gettime(CLOCK_MONOTONIC, &t0);
    for (long i = 0; i < reps; i++) sink ^= validate(code, n, limit);
    clock_gettime(CLOCK_MONOTONIC, &t1);
    (void)sink;
    double ns = (t1.tv_sec - t0.tv_sec) * 1e9 + (t1.tv_nsec - t0.tv_nsec);
    printf("%.2f ns/byte  (valid=%d, %d bytes, %ld reps)\n",
           ns / reps / n, r, n, reps);
    return 0;
}
