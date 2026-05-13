 .align
 .pool
 .text
 .align
 .pool

#include "../equates.h"
#include "../6502mac.h"

	global_func mapper225init

@----------------------------------------------------------------------------
mapper225init:	@ PCB-018 "110-in-1" and many other discrete pirate multicarts
@----------------------------------------------------------------------------
	@ All four write regions go through the single register; the address
	@ bits are the data on this board, the value on the data bus is ignored.
	.word write225,write225,write225,write225

	@ FCEUX M225Power: prg = 0, mode = 0, Sync().  With prg=0, mode=0 we
	@ end up calling setprg32($8000, 0) and setchr8(0).  Force that here
	@ so the multicart menu boots into a known state.
	stmfd sp!,{lr}
	mov r0,#0
	bl_long map89ABCDEF_
	mov r0,#0
	bl_long chr01234567_
	ldmfd sp!,{pc}

@----------------------------------------------------------------------------
write225:	@$8000-$FFFF -- address-encoded multicart latch
@----------------------------------------------------------------------------
	@ Per FCEUX M225Write:
	@   bank    = (A >> 14) & 1   -- high bit for both CHR and PRG
	@   mirr    = (A >> 13) & 1   -- 0 -> V, 1 -> H   (after the ^1 in Sync)
	@   mode    = (A >> 12) & 1   -- 0 = 32 KB PRG, 1 = 16 KB mirrored
	@   chr[7]  = (A & 0x3F) | (bank << 6)
	@   prg[7]  = ((A >> 6) & 0x3F) | (bank << 6)
	@
	@ Operand bytes (r0) are ignored.  All decoding is from addy.
	@
	@ Helpers clobber r12 (addy) so we keep our copy on the stack.
	stmfd sp!,{addy,lr}

	@ ---- CHR bank ----
	@ chr = (addy & 0x3F) | (((addy >> 14) & 1) << 6)
	@     = (addy & 0x3F) | ((addy >> 8) & 0x40)
	and r0,addy,#0x3F
	mov r1,addy,lsr#8
	and r1,r1,#0x40
	orr r0,r0,r1
	bl_long chr01234567_

	@ ---- Mirroring ----
	@ mirr bit (A13) == 0 -> V, == 1 -> H, after the FCEUX ^1.
	@ mirror2V_ has EQ -> V, NE -> H, which matches.
	ldr addy,[sp]
	tst addy,#0x2000
	bl_long mirror2V_

	@ ---- PRG bank ----
	@ prg = ((addy >> 6) & 0x3F) | (bank << 6)
	@     = ((addy >> 6) & 0x3F) | ((addy >> 8) & 0x40)
	ldr addy,[sp]
	mov r0,addy,lsr#6
	and r0,r0,#0x3F
	mov r1,addy,lsr#8
	and r1,r1,#0x40
	orr r0,r0,r1

	@ mode bit (A12): 0 = 32 KB at $8000, 1 = 16 KB mirrored at $8000 and $C000
	tst addy,#0x1000
	bne write225_mode16

	@ ---- 32 KB mode ----
	@ setprg32 with (prg >> 1) -- map89ABCDEF_ takes a 32 KB bank number.
	mov r0,r0,lsr#1
	ldmfd sp!,{addy,lr}
	b_long map89ABCDEF_

write225_mode16:
	@ ---- 16 KB mode (mirrored: $8000 = prg, $C000 = prg) ----
	@ Save the 7-bit prg value across the two 16 KB bank calls.  Pushing
	@ {r0, lr} keeps SP 8-byte aligned and lets the bl_long use lr as
	@ scratch without losing our PRG bank number.
	stmfd sp!,{r0,lr}
	bl_long map89AB_
	ldmfd sp!,{r0,lr}

	@ Restore caller's lr (lives at sp+4 in the original outer save) and
	@ pop addy; then tail-call mapCDEF_ for the second half of the mirror.
	ldmfd sp!,{addy,lr}
	b_long mapCDEF_
@----------------------------------------------------------------------------
	@.end
