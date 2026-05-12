.align
 .pool
 .text
 .align
 .pool

#include "../equates.h"
#include "../6502mac.h"

	global_func mapper30init

@----------------------------------------------------------------------------
mapper30init:
@----------------------------------------------------------------------------
	.word write30,write30,write30,write30
	mov pc,lr

@----------------------------------------------------------------------------
write30:
@----------------------------------------------------------------------------
	stmfd sp!,{r0,lr}

	@ CHR bank (bits 5-6)
	and r1,r0,#0x60
	mov r0,r1,lsr#5
	bl_long chr01234567_

	ldr r0,[sp]
	@ Mirroring (bit 7)
	tst r0,#0x80
	bl_long mirror1_

	ldr r0,[sp]
	@ PRG bank (bits 0-4)
	and r0,r0,#0x1F
	bl_long map89AB_

	ldmfd sp!,{r0,lr}
	bx lr
