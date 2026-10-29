/* Linker script for running the measurement binaries under the Zisk
 * zkVM emulator (ziskemu): code at 0x80000000, data in Zisk's RAM
 * region at 0xa0010000, and a private stack carved from BSS.
 * Adapted from the layout the eth-act ACT4 compliance suite uses for
 * Zisk.  Requires -mcmodel=medany. */
OUTPUT_ARCH("riscv")
ENTRY(_start)

SECTIONS
{
  . = 0x80000000;
  .text.init : { *(.text.init) }
  . = ALIGN(0x1000);
  .text : { *(.text .text.*) }
  .rodata : { *(.rodata .rodata.* .srodata .srodata.*) }
  . = 0xa0010000;
  .data : { *(.data .data.* .sdata .sdata.*) }
  .bss : { *(.bss .bss.* .sbss .sbss.* COMMON) }
  . = ALIGN(16);
  . += 0x100000;                 /* 1 MB machine stack */
  PROVIDE(__zstack_top = .);
  _end = .;
}
