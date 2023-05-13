.global _Reset
_Reset:
B Reset_Handler
B . /* Undefined */
B . /* SWI */
B . /* Prefetch Abort */
B . /* Data Abort */
B . /* reserved */
B . /* IRQ */
B . /* FIQ */
 
Reset_Handler:
 LDR sp, =stack_top
 
      LDR r0, =0x00F00000
      MCR p15, 0, r0, c1, c0, 2
      ISB
      MOV r3, #0x40000000
      VMSR FPEXC, r3
 BL main
 B .
