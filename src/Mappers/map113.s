.align
 .pool
 .text
 .align
 .pool

#include "../equates.h"
#include "../6502mac.h"

	global_func mapper113init

@----------------------------------------------------------------------------
mapper113init:	@HES NTD-8 -- HES, AVE unlicensed games
@----------------------------------------------------------------------------
	.word void,void,void,void

	@ Save LR for external function calls during boot
	stmfd sp!,{lr}

	@ FORCE BOOT ALIGNMENT: 32KB PRG to Bank 0, 8KB CHR to Bank 0
	mov r0,#0
	bl_long map89ABCDEF_
	mov r0,#0
	bl_long chr01234567_

	@ Hook the I/O write region ($4000-$5FFF)
	adr r1,write113
	str_ r1,writemem_4
	.if PRG_BANK_SIZE == 4
	str_ r1,writemem_5
	.endif

	ldmfd sp!,{pc}

@----------------------------------------------------------------------------
write113:
@----------------------------------------------------------------------------
	@ Pass standard APU/IO writes ($4000-$40FF) back to the emulator core
	cmp addy,#0x4100
	blo_long IO_W

	@ Register decoded at $4100-$5FFF matching (A & $E100) == $4100
	and r1,addy,#0xE100
	cmp r1,#0x4100
	movne pc,lr

	stmfd sp!,{r4,lr}
	mov r4,r0

	@ PRG 32KB bank from bits 3-5
	mov r0,r4,lsr#3
	and r0,r0,#7
	bl_long map89ABCDEF_

	@ CHR 8KB bank from bits 0-2
	and r0,r4,#7
	bl_long chr01234567_

	@ Mirroring from bit 7 (0=H, 1=V)
	@ OPUS BUG FIX: mirror2H_ correctly defaults to Horizontal on 0 (EQ)
	tst r4,#0x80
	bl_long mirror2H_

	ldmfd sp!,{r4,pc}
	@.end
