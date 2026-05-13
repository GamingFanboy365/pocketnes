.align
 .pool
 .text
 .align
 .pool

#include "../equates.h"
#include "../6502mac.h"

	global_func mapper89init

@----------------------------------------------------------------------------
mapper89init:	@Sunsoft-2 IC02 -- "Tetsuwan Atom" (Astro Boy)
@----------------------------------------------------------------------------
	.word write89,write89,write89,write89

	@ Save LR for external function calls during boot
	stmfd sp!,{lr}

	@ FORCE BOOT ALIGNMENT: 
	@ 16KB PRG Bank 0 to $8000
	@ 16KB PRG Last Bank to $C000 (Required for Reset Vector!)
	@ 8KB CHR Bank 0 to PPU
	mov r0,#0
	bl_long map89AB_
	mvn r0,#0
	bl_long mapCDEF_
	mov r0,#0
	bl_long chr01234567_

	ldmfd sp!,{pc}

@----------------------------------------------------------------------------
write89:	@$8000-$FFFF
@----------------------------------------------------------------------------
	stmfd sp!,{r4,lr}
	mov r4,r0

	@ PRG bank from bits 4-6 (16 KB at $8000-$BFFF)
	mov r0,r4,lsr#4
	and r0,r0,#7
	bl_long map89AB_

	@ CHR bank from bits 0-2 (low) and bit 7 (high)
	and r0,r4,#7
	tst r4,#0x80
	orrne r0,r0,#8
	bl_long chr01234567_

	@ 1-screen mirroring select (0 = NT0, 1 = NT1)
	tst r4,#0x08
	moveq r0,#0
	movne r0,#1
	bl_long mirror1_

	ldmfd sp!,{r4,pc}
	@.end
