 .align
 .pool
 .text
 .align
 .pool

#include "../equates.h"
#include "../6502mac.h"

	global_func mapper211init

@ Mapper 211: J.Y. Company ASIC (Tiny Toon Adventures 6 and other J.Y.
@ games), per the NESdev wiki and Mesen2.  Mappers 90 and 209 are the same
@ chip with different nametable wiring; only 211 is enabled for now.
@
@ $8000-$8003: PRG banks.  $D000 bits 0-1 select 32K/16K/8K/8K-reversed
@   modes, bit 2 makes the last bank switchable through $8003.
@ $9000-$9007 / $A000-$A007: CHR bank low/high bytes.  $D000 bits 3-4 select
@   8K/4K/2K/1K CHR modes; $D003 can replace the high byte with an outer bank.
@ $B000-$B003: nametable registers.  Mapper 211 always uses bit 0 of each as
@   the CIRAM page for that nametable; PocketNES has the standard layouts
@   (single-screen, horizontal, vertical), so other combinations use the
@   closest one.  ROM nametables (bit 7) are not emulated.
@ $C000-$C007: IRQ.  Only the PPU A12 source is used by the known games
@   (one count per scanline with the usual pattern-table layout), so the
@   counter is run on map4.s's MMC3 scanline IRQ: a J.Y. counter value of N
@   fires after N+1 counts, which is an MMC3 reload with latch N (or 255-N
@   when counting up).  The prescaler, CPU-clock and PPU-read sources aren't
@   emulated.
@ $5800/$5801: 8x8 multiplier, $5803: a read/write register, $5000: DIP
@   switches (read as 0).  Not emulated: PRG ROM at $6000 ($D000 bit 7), the
@   $5802 accumulator, mapper 209's MMC4-like CHR latch.

 jy_prg	= mapperdata+4		@4 PRG registers ($8000-$8003)
 jy_d000	= mapperdata+8
 jy_d001	= mapperdata+9
 jy_d003	= mapperdata+10
 jy_xor	= mapperdata+11		@$C006
 jy_mul1	= mapperdata+12
 jy_mul2	= mapperdata+13
 jy_ram	= mapperdata+14		@$5803
 jy_irqmode	= mapperdata+15	@$C001
	@(mapperdata+0-3 and +16-31 belong to the MMC3 IRQ code)
 JY_REGS_SIZE = 20		@jy_chrlo, jy_chrhi, jy_ntlo (EWRAM, below)

@----------------------------------------------------------------------------
mapper211init:
@----------------------------------------------------------------------------
	.word write89,writeAB,writeCD,void
	stmfd sp!,{lr}
	bl_long mmc3_init_code		@MMC3 scanline IRQ hooks

	ldr r0,=read5
	ldr r1,=empty_io_r_hook
	str r0,[r1]
	ldr r0,=write5
	ldr r1,=empty_io_w_hook
	str r0,[r1]

	mov r0,#0
	str_ r0,jy_prg
	str_ r0,jy_d000
	str_ r0,jy_mul1
	ldr r1,=jy_regs
	mov r2,#JY_REGS_SIZE
0:
	subs r2,r2,#4
	str r0,[r1,r2]
	bne 0b

	bl sync_prg
	bl sync_chr
	bl sync_mirror
	ldmfd sp!,{pc}

@----------------------------------------------------------------------------
write89:	@$8000-$9FFF
@----------------------------------------------------------------------------
	tst addy,#0x0800		@A11 set: ignored
	bxne lr
	tst addy,#0x1000
	bne 0f
	and r1,addy,#3		@$8000-$8003: PRG
	and r0,r0,#0x7F
	adrl_ r2,jy_prg
	strb r0,[r2,r1]
	b sync_prg
0:
	and r1,addy,#7		@$9000-$9007: CHR low
	ldr r2,=jy_chrlo
	strb r0,[r2,r1]
	b sync_chr
@----------------------------------------------------------------------------
writeAB:	@$A000-$BFFF
@----------------------------------------------------------------------------
	tst addy,#0x0800
	bxne lr
	tst addy,#0x1000
	bne 0f
	and r1,addy,#7		@$A000-$A007: CHR high
	ldr r2,=jy_chrhi
	strb r0,[r2,r1]
	b sync_chr
0:
	tst addy,#4		@$B004-$B007: ROM nametable high bytes (not emulated)
	bxne lr
	and r1,addy,#3		@$B000-$B003
	ldr r2,=jy_ntlo
	strb r0,[r2,r1]
	b sync_mirror
@----------------------------------------------------------------------------
writeCD:	@$C000-$DFFF
@----------------------------------------------------------------------------
	tst addy,#0x1000
	bne writeD
	and r1,addy,#7		@$C000-$C007 (A11 doesn't matter here)
	ldr pc,[pc,r1,lsl#2]
	.word 0
	.word wC0,wC1,wC2,wC3,void,wC5,wC6,void
wC0:	@bit 0: enable or disable
	tst r0,#1
	bne wC3
wC2:	@disable and acknowledge: MMC3 $E000
	bic addy,addy,#1
	b_long mmc3_write3
wC3:	@enable: MMC3 $E001
	orr addy,addy,#1
	b_long mmc3_write3
wC1:
	strb_ r0,jy_irqmode
	bx lr
wC6:
	strb_ r0,jy_xor
	bx lr
wC5:	@counter: MMC3 latch + reload
	ldrb_ r1,jy_xor
	eor r0,r0,r1
	and r0,r0,#0xFF
	ldrb_ r1,jy_irqmode
	and r1,r1,#0xC0
	cmp r1,#0x40		@counting up: fires after 256-N counts
	rsbeq r0,r0,#0xFF
	stmfd sp!,{lr}
	bic addy,addy,#1
	bl_long mmc3_write2	@latch
	ldmfd sp!,{lr}
	orr addy,addy,#1
	b_long mmc3_write2	@reload

writeD:	@$D000-$D003
	tst addy,#0x0800
	bxne lr
	and r1,addy,#3
	ldr pc,[pc,r1,lsl#2]
	.word 0
	.word wD0,wD1,void,wD3
wD0:
	strb_ r0,jy_d000
	stmfd sp!,{lr}
	bl sync_prg
	bl sync_chr
	ldmfd sp!,{lr}
	b sync_mirror
wD1:
	strb_ r0,jy_d001
	b sync_mirror
wD3:
	strb_ r0,jy_d003
	b sync_chr

@----------------------------------------------------------------------------
read5:	@$4018-$5FFF reads.  Must not change addy (r12).
@----------------------------------------------------------------------------
	mov r1,addy,lsr#11
	cmp r1,#0x5800>>11
	bne 1f
	and r2,addy,#3
	cmp r2,#1
	bhi 0f
	ldrb_ r1,jy_mul1
	ldrb_ r0,jy_mul2
	mul r2,r0,r1
	moveq r0,r2,lsr#8	@$5801: high byte
	andne r0,r2,#0xFF	@$5800: low byte
	bx lr
0:
	cmp r2,#3
	ldreqb_ r0,jy_ram	@$5803
	moveq pc,lr
	mov r0,#0		@$5802: accumulator (not emulated)
	bx lr
1:
	cmp r1,#0x5000>>11
	bne_long empty_R
	mov r0,#0		@$5000-$57FF: DIP switches
	bx lr
@----------------------------------------------------------------------------
write5:	@$4018-$5FFF writes
@----------------------------------------------------------------------------
	mov r1,addy,lsr#11
	cmp r1,#0x5800>>11
	bxne lr
	and r1,addy,#3
	cmp r1,#0
	streqb_ r0,jy_mul1
	cmp r1,#1
	streqb_ r0,jy_mul2
	cmp r1,#3
	streqb_ r0,jy_ram
	bx lr

@----------------------------------------------------------------------------
prgreg:	@r0 = register number -> r0 = value (bit-reversed in PRG mode 3).
	@Changes r1, r2.
@----------------------------------------------------------------------------
	adrl_ r1,jy_prg
	ldrb r0,[r1,r0]
	ldrb_ r1,jy_d000
	and r1,r1,#3
	cmp r1,#3
	bxne lr
	@bits 0-2 and 4-6 swap ends; bit 3 stays
	and r2,r0,#0x08
	tst r0,#0x01
	orrne r2,r2,#0x40
	tst r0,#0x02
	orrne r2,r2,#0x20
	tst r0,#0x04
	orrne r2,r2,#0x10
	tst r0,#0x10
	orrne r2,r2,#0x04
	tst r0,#0x20
	orrne r2,r2,#0x02
	tst r0,#0x40
	orrne r2,r2,#0x01
	mov r0,r2
	bx lr

@----------------------------------------------------------------------------
sync_prg:
@----------------------------------------------------------------------------
	stmfd sp!,{r3,lr}
	ldrb_ r3,jy_d000
	ands r1,r3,#3
	bne 1f
	@mode 0: one 32K bank
	mov r0,#3
	bl prgreg
	tst r3,#4
	mvneq r0,#0		@last bank unless $D000 bit 2
	bl_long map89ABCDEF_
	ldmfd sp!,{r3,pc}
1:
	cmp r1,#1
	bne 2f
	@mode 1: two 16K banks
	mov r0,#1
	bl prgreg
	bl_long map89AB_
	mov r0,#3
	bl prgreg
	tst r3,#4
	mvneq r0,#0
	bl_long mapCDEF_
	ldmfd sp!,{r3,pc}
2:
	@modes 2 and 3: four 8K banks
	mov r0,#0
	bl prgreg
	bl_long map89_
	mov r0,#1
	bl prgreg
	bl_long mapAB_
	mov r0,#2
	bl prgreg
	bl_long mapCD_
	mov r0,#3
	bl prgreg
	tst r3,#4
	mvneq r0,#0
	bl_long mapEF_
	ldmfd sp!,{r3,pc}

@----------------------------------------------------------------------------
chrreg:	@r0 = register number -> r0 = bank, in units of the CHR mode's size.
	@Changes r1, r2.
@----------------------------------------------------------------------------
	stmfd sp!,{r3,r4}
	ldrb_ r3,jy_d000
	mov r3,r3,lsr#3
	and r3,r3,#3		@r3 = CHR mode
	ldrb_ r4,jy_d003
	@$D003 bit 7 in 2K/1K modes: registers 2-3 repeat 0-1
	cmp r3,#2
	blo 0f
	tst r4,#0x80
	beq 0f
	cmp r0,#2
	blo 0f
	cmp r0,#3
	subls r0,r0,#2
0:
	ldr r1,=jy_chrlo
	ldrb r2,[r1,r0]
	tst r4,#0x20
	beq 1f
	@$D003 bit 5 set: low and high bytes
	ldr r1,=jy_chrhi
	ldrb r0,[r1,r0]
	orr r0,r2,r0,lsl#8
	ldmfd sp!,{r3,r4}
	bx lr
1:
	@outer block from $D003 bits 0 and 3-4, above the mode's bank bits
	mov r1,#0x20
	mov r1,r1,lsl r3
	sub r1,r1,#1
	and r2,r2,r1		@low byte & (32 << mode) - 1
	and r0,r4,#0x18
	mov r0,r0,lsr#2
	and r4,r4,#1
	orr r0,r0,r4		@block
	add r3,r3,#5
	orr r0,r2,r0,lsl r3
	ldmfd sp!,{r3,r4}
	bx lr

@----------------------------------------------------------------------------
sync_chr:
@----------------------------------------------------------------------------
	stmfd sp!,{r3,lr}
	ldrb_ r3,jy_d000
	mov r3,r3,lsr#3
	and r3,r3,#3
	cmp r3,#1
	bhi 2f
	beq 1f
	mov r0,#0		@mode 0: 8K
	bl chrreg
	bl_long chr01234567_
	ldmfd sp!,{r3,pc}
1:
	mov r0,#0		@mode 1: 4K (mapper 209's latch isn't emulated)
	bl chrreg
	bl_long chr0123_
	mov r0,#4
	bl chrreg
	bl_long chr4567_
	ldmfd sp!,{r3,pc}
2:
	cmp r3,#3
	beq 3f
	mov r0,#0		@mode 2: 2K
	bl chrreg
	bl_long chr01_
	mov r0,#2
	bl chrreg
	bl_long chr23_
	mov r0,#4
	bl chrreg
	bl_long chr45_
	mov r0,#6
	bl chrreg
	bl_long chr67_
	ldmfd sp!,{r3,pc}
3:
	@mode 3: 1K
 .macro jy_chr1k n
	mov r0,#\n
	bl chrreg
	bl_long chr\n\()_
 .endm
	jy_chr1k 0
	jy_chr1k 1
	jy_chr1k 2
	jy_chr1k 3
	jy_chr1k 4
	jy_chr1k 5
	jy_chr1k 6
	jy_chr1k 7
	ldmfd sp!,{r3,pc}

@----------------------------------------------------------------------------
sync_mirror:	@CIRAM page per nametable from $B000-$B003 bit 0
@----------------------------------------------------------------------------
	ldr r2,=jy_ntlo
	ldrb r0,[r2,#0]
	and r1,r0,#1
	ldrb r0,[r2,#1]
	and r0,r0,#1
	orr r1,r1,r0,lsl#1
	ldrb r0,[r2,#2]
	and r0,r0,#1
	orr r1,r1,r0,lsl#2
	ldrb r0,[r2,#3]
	and r0,r0,#1
	orr r1,r1,r0,lsl#3	@r1 = pages of nametables 3210
	cmp r1,#0x0
	beq_long mirror1_	@all page 0 (Z set)
	cmp r1,#0xF
	beq 0f
	@horizontal when nametables 0 and 1 share a page, otherwise vertical
	and r0,r1,#3
	cmp r0,#1
	cmpne r0,#2
	beq 1f
	cmp r0,r0		@Z set: horizontal
	b_long mirror2H_
1:
	cmp r0,r0		@Z set: vertical
	b_long mirror2V_
0:
	movs r0,#1		@all page 1 (Z clear)
	b_long mirror1_
@----------------------------------------------------------------------------
 .pool

 .section .sbss, "aw", %nobits
 .align 2
jy_regs:
jy_chrlo:	.space 8
jy_chrhi:	.space 8
jy_ntlo:	.space 4
