/* Freestanding runtime shared by the interpreter and the AOT output.
 *
 * No libc: _start, two syscalls, a hex printer.  The program's code
 * and calldata are linked in from a generated prog_data.c.  Keeping
 * the runtime this small makes the instruction counts pure: the
 * count is the EVM execution and nothing else.
 *
 * Two targets from one file.  Default: Linux user mode under
 * qemu-riscv64 (write and exit syscalls).  With -DZISK (and zisk.ld,
 * -mcmodel=medany): the Zisk zkVM emulator, where output is a
 * memory-mapped UART at 0xa0000200, exit is the same ecall 93, and
 * _start must set up its own stack.
 */
typedef unsigned long u64;

extern void evm_entry(void);

unsigned char MEM[1 << 20];            /* EVM memory                   */
unsigned char FRAME[1024 * 32];        /* 256-bit AOT data stack       */

static long sys(long n, long a, long b, long c)
{
    register long a7 asm("a7") = n;
    register long a0 asm("a0") = a;
    register long a1 asm("a1") = b;
    register long a2 asm("a2") = c;
    asm volatile("ecall" : "+r"(a0) : "r"(a7), "r"(a1), "r"(a2) : "memory");
    return a0;
}

#ifdef ZISK
static void out(const char *s, u64 n)
{
    volatile unsigned char *uart = (volatile unsigned char *)0xa0000200;
    for (u64 i = 0; i < n; i++)
        *uart = (unsigned char)s[i];
}
#else
static void out(const char *s, u64 n) { sys(64, 1, (long)s, n); }
#endif

static u64 slen(const char *s) { u64 n = 0; while (s[n]) n++; return n; }

/* Terminate with the EVM's result: RETURN prints returndata as hex. */
void __rt_return(const unsigned char *p, u64 n)
{
    static const char hex[] = "0123456789abcdef";
    static char buf[4096];
    u64 i;
    if (n > 2047) n = 2047;
    for (i = 0; i < n; i++) {
        buf[2 * i] = hex[p[i] >> 4];
        buf[2 * i + 1] = hex[p[i] & 15];
    }
    buf[2 * n] = '\n';
    out(buf, 2 * n + 1);
    sys(93, 0, 0, 0);
}

void __rt_stop(void) { out("stop\n", 5); sys(93, 0, 0, 0); }

void __rt_revert(void) { out("revert\n", 7); sys(93, 2, 0, 0); }

void __rt_trap(const char *msg)
{
    out("trap: ", 6);
    out(msg, slen(msg));
    out("\n", 1);
    sys(93, 1, 0, 0);
}

#ifdef ZISK
/* ziskemu enters at 0x80000000 with no stack: point sp at the region
 * zisk.ld reserves, then proceed as usual. */
asm(".section .text.init, \"ax\"\n"
    ".globl _start\n"
    "_start:\n"
    "\tla sp, __zstack_top\n"
    "\tcall zisk_start\n"
    "1:\tj 1b\n"
    ".text\n");

void zisk_start(void)
{
    evm_entry();
    __rt_trap("fell off the end of evm_entry");
}
#else
void _start(void)
{
    evm_entry();
    __rt_trap("fell off the end of evm_entry");
}
#endif
