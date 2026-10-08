 .align
 .pool
 .text
 .align
 .pool

#include "../equates.h"
#include "../6502mac.h"

	global_func mapper82init

@ Mapper 82: Taito X1-017, per the NESdev wiki.  Registers at $7EF0-$7EFF:
@   $7EF0/$7EF1: 2K CHR banks (bit 0 ignored), $7EF2-$7EF5: 1K CHR banks.
@     The 2K banks are at $0000-$0FFF and the 1K banks at $1000-$1FFF, or
@     the other way round when $7EF6 bit 1 (CHR A12 inversion) is set.
@   $7EF6: bit 0 mirroring (0 = horizontal, 1 = vertical), bit 1 CHR inversion
@   $7EF7-$7EF9: RAM enables, $7EFD-$7EFF: IRQ (not emulated; no known game uses it)
@   $7EFA/$7EFB/$7EFC: 8K PRG banks at $8000/$A000/$C000, from bits 2-5 of
@     the value (iNES 082 bank order).  $E000 is fixed to the last bank.
@ $6000-$73FF is the chip's 5K of (battery) RAM, kept in the normal SRAM
@ (CPU_reset leaves this handler in place); the RAM enables aren't emulated.

 m82_chr  = mapperdata+0	@6 CHR registers
 m82_ctrl = mapperdata+6

@----------------------------------------------------------------------------
mapper82init:
@----------------------------------------------------------------------------
	.word void,void,void,void

	adr r0,write82
	str_ r0,writemem_6
	.if PRG_BANK_SIZE == 4
	str_ r0,writemem_7
	.endif
	mov r0,#0
	str_ r0,m82_chr
	str_ r0,m82_chr+4
	mov pc,lr
@----------------------------------------------------------------------------
write82:	@$6000-$7FFF
@----------------------------------------------------------------------------
	mov r1,#0x7F0
	sub r1,r1,#1
	teq r1,addy,lsr#4
	bne write82_ram		@not a register: the internal RAM

	and r1,addy,#0xF
	ldr pc,[pc,r1,lsl#2]
	.word 0
write82tbl:
	.word wchr,wchr,wchr,wchr,wchr,wchr,wF6,void
	.word void,void,wFA,wFB,wFC,void,void,void

write82_ram:	@battery RAM goes straight to cart SRAM, like the default handler
	.if CARTSAVE
	ldrb_ r1,cartflags
	tst r1,#SRAM
	bne_long sram_W2
	.endif
	b_long sram_W

wchr:	@$7EF0-$7EF5
	adrl_ r2,m82_chr
	strb r0,[r2,r1]
	b sync_chr
wF6:
	strb_ r0,m82_ctrl
	stmfd sp!,{lr}
	ands r0,r0,#1
	bl_long mirror2H_
	ldmfd sp!,{lr}
	b sync_chr
wFA:
	mov r0,r0,lsr#2
	and r0,r0,#0x0F
	b_long map89_
wFB:
	mov r0,r0,lsr#2
	and r0,r0,#0x0F
	b_long mapAB_
wFC:
	mov r0,r0,lsr#2
	and r0,r0,#0x0F
	b_long mapCD_

@----------------------------------------------------------------------------
sync_chr:
@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrb_ r0,m82_ctrl
	tst r0,#2
	bne 1f
	ldrb_ r0,m82_chr+0
	bl_long chr01_rshift_
	ldrb_ r0,m82_chr+1
	bl_long chr23_rshift_
	ldrb_ r0,m82_chr+2
	bl_long chr4_
	ldrb_ r0,m82_chr+3
	bl_long chr5_
	ldrb_ r0,m82_chr+4
	bl_long chr6_
	ldrb_ r0,m82_chr+5
	bl_long chr7_
	ldmfd sp!,{pc}
1:
	ldrb_ r0,m82_chr+0
	bl_long chr45_rshift_
	ldrb_ r0,m82_chr+1
	bl_long chr67_rshift_
	ldrb_ r0,m82_chr+2
	bl_long chr0_
	ldrb_ r0,m82_chr+3
	bl_long chr1_
	ldrb_ r0,m82_chr+4
	bl_long chr2_
	ldrb_ r0,m82_chr+5
	bl_long chr3_
	ldmfd sp!,{pc}
@----------------------------------------------------------------------------
 .pool
