ENTRY(_Reset)
SECTIONS
{
 . = 0x0000;
 .startup . : { startup.o(.text) }
 . = 0x80000000;
 .text : { *(.text) }
 .data : { *(.data) }
 .bss : { *(.bss COMMON) }
 . = ALIGN(8);
 . = . + 0x1000; /* 4kB of stack memory */
 stack_top = .;
}
