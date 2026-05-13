.align
 .pool
 .text
 .align
 .pool

#include "../equates.h"
#include "../6502mac.h"

	global_func mapper71init

@----------------------------------------------------------------------------
mapper71init:	@Camerica / Codemasters
@----------------------------------------------------------------------------
	@ $8000-$9FFF: Ignored
	@ $A000-$BFFF: Mirroring (Used primarily by Fire Hawk)
	@ $C000-$FFFF: PRG Bank Select
	.word void,write71_A,write71_C,write71_C

	@ Save LR for external function calls during boot
	stmfd sp!,{lr}

	@ FORCE BOOT ALIGNMENT: 
	@ 16KB PRG Bank 0 to $8000
	@ 16KB PRG Last Bank to $C000 (Required for Reset Vector!)
	@ 8KB CHR Bank 0 to PPU (Camerica uses CHR-RAM)
	mov r0,#0
	bl_long map89AB_
	mvn r0,#0
	bl_long mapCDEF_
	mov r0,#0
	bl_long chr01234567_

	ldmfd sp!,{pc}

@----------------------------------------------------------------------------
write71_C:	@$C000-$FFFF -- PRG Bank Select
@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	
	@ PRG bank from bits 0-3 (16 KB at $8000-$BFFF)
	and r0,r0,#0x0F
	bl_long map89AB_
	
	ldmfd sp!,{pc}

@----------------------------------------------------------------------------
write71_A:	@$A000-$BFFF -- Mirroring (Fire Hawk)
@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	
	@ Bit 4 determines single screen mirroring (0 = NT0, 1 = NT1)
	tst r0,#0x10
	moveq r0,#0
	movne r0,#1
	bl_long mirror1_
	
	ldmfd sp!,{pc}
	@.end
