.align
 .pool
 .text
 .align
 .pool

#include "../equates.h"
#include "../6502mac.h"

	global_func mapper30init

@ UNROM 512 (mapper 30), per the NESdev wiki.
@ Latch: D~[NCCP PPPP]  P = 16K PRG bank at $8000 ($C000 fixed to the last bank),
@ CC = 8K CHR-RAM bank, N = nametable bit.  N only matters when the header asks
@ for mapper-controlled one-screen mirroring, or on submapper 3, where it picks
@ horizontal/vertical.  Otherwise the header's H/V/four-screen setting stands.
@ Self-flashable boards (and submappers 1, 3, 4) only latch at $C000-$FFFF;
@ $8000-$BFFF is the flash command port (flash saving isn't emulated).

 m30_mode = mapperdata+0	@copy of mapper30_mode (loadcart.c)

@----------------------------------------------------------------------------
mapper30init:
@----------------------------------------------------------------------------
	.word write30,write30,write30,write30

	ldr r0,=mapper30_mode
	ldrb r0,[r0]
	strb_ r0,m30_mode
	tst r0,#0x80
	ldrne r1,=void
	strne_ r1,writemem_8
	strne_ r1,writemem_A
	mov pc,lr

@----------------------------------------------------------------------------
write30:
@----------------------------------------------------------------------------
	stmfd sp!,{r0,lr}

	@ CHR bank (bits 5-6)
	and r1,r0,#0x60
	mov r0,r1,lsr#5
	bl_long chr_ram_bank8_

	@ Nametable bit (bit 7), only where the header gives the mapper control
	ldrb_ r1,m30_mode
	and r1,r1,#0x7F
	ldr r0,[sp]
	cmp r1,#1
	bne 0f
	tst r0,#0x80		@one-screen: 0 = lower, 1 = upper
	bl_long mirror1_
	b 1f
0:
	cmp r1,#2
	bne 1f
	tst r0,#0x80		@submapper 3: 0 = horizontal, 1 = vertical mirroring
	bl_long mirror2H_
1:
	ldr r0,[sp]
	@ PRG bank (bits 0-4)
	and r0,r0,#0x1F
	bl_long map89AB_

	ldmfd sp!,{r0,lr}
	bx lr
@----------------------------------------------------------------------------
 .pool
