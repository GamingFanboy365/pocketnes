 .align
 .pool
 .text
 .align
 .pool

#include "../equates.h"
#include "../6502mac.h"

	global_func mapper114init

@ Mapper 114: an MMC3 clone with scrambled register addresses and bank-select
@ indexes (Super Donkey Kong, The Lion King, Aladdin and other SuperGame /
@ Hosenkan pirates), per the NESdev wiki.
@   $6000 (even addresses): bit 7 = replace the MMC3's PRG banking with a
@     16K bank (bits 0-3) at both $8000 and $C000, or a 32K bank when bit 5
@     is set (NROM-128 / NROM-256)
@   $6001 (odd addresses): bit 0 = CHR A18 (outer 256K of CHR)
@   $8000-$DFFF: the MMC3 registers, at swapped addresses and with the bank
@     select index scrambled; submapper 1 (Boogerman) scrambles differently.
@     $E000/$E001 are the normal MMC3 IRQ registers.
@ The MMC3 code in map4.s does the work.  Not emulated: the MMC3A IRQ quirk
@ (latch 0 disables the IRQ, which Aladdin relies on); a change of the CHR
@ outer bit applies from the next CHR bank write.

 cmd	= mapperdata+4		@shared with map4.s (the real, unscrambled index)
 bank0	= mapperdata+5		@shared with map4.s (MMC3 R6)
 m114_r7  = mapperdata+10	@MMC3 R7 (map4.s doesn't keep it)
 m114_prg = mapperdata+11	@$6000
 m114_chr = mapperdata+12	@$6001
 m114_sub = mapperdata+13	@submapper

@----------------------------------------------------------------------------
mapper114init:
@----------------------------------------------------------------------------
	.word write114,write114,write114,mmc3_write3
	stmfd sp!,{lr}
	bl_long mmc3_init_code

	adr r1,write114_6
	str_ r1,writemem_6
	.if PRG_BANK_SIZE == 4
	str_ r1,writemem_7
	.endif
	ldr r0,=nes_submapper
	ldrb r0,[r0]
	strb_ r0,m114_sub
	mov r0,#0
	strb_ r0,m114_prg
	strb_ r0,m114_chr
	mov r0,#1
	strb_ r0,m114_r7
	ldmfd sp!,{pc}

@----------------------------------------------------------------------------
write114:	@$8000-$DFFF: unscramble the address
@----------------------------------------------------------------------------
	ldrb_ r1,m114_sub
	cmp r1,#1
	adrne r2,addrs_sub0
	adreq r2,addrs_sub1
	mov r1,addy,lsr#13
	sub r1,r1,#4		@0 = $8000, 1 = $A000, 2 = $C000
	add r1,r1,r1
	tst addy,#1
	addne r1,r1,#1
	ldr pc,[r2,r1,lsl#2]

	@what each of $8000,$8001,$A000,$A001,$C000,$C001 really is
addrs_sub0:	.word h_wram,h_mirror,h_select,h_latch,h_data,h_reload
addrs_sub1:	.word h_wram,h_data,h_select,h_reload,h_mirror,h_latch
	@bank select index written -> real MMC3 index
index_sub0:	.byte 0,3,1,5,6,7,2,4
index_sub1:	.byte 0,2,5,3,6,1,7,4

h_wram:		@MMC3 $A001 (PRG RAM enable): nothing to do
	bx lr
h_mirror:	@MMC3 $A000
	tst r0,#1
	b_long mirror2V_
h_latch:	@MMC3 $C000
	bic addy,addy,#1
	b_long mmc3_write2
h_reload:	@MMC3 $C001
	orr addy,addy,#1
	b_long mmc3_write2
h_select:	@MMC3 $8000
	ldrb_ r1,m114_sub
	cmp r1,#1
	adrne r2,index_sub0
	adreq r2,index_sub1
	and r1,r0,#7
	ldrb r1,[r2,r1]
	bic r0,r0,#7
	orr r0,r0,r1
	stmfd sp!,{lr}
	bic addy,addy,#1
	bl_long mmc3_write0
	ldmfd sp!,{lr}
	b reapply_nrom		@(a PRG mode change remaps PRG)
h_data:		@MMC3 $8001
	ldrb_ r1,cmd
	and r1,r1,#7
	cmp r1,#7
	streqb_ r0,m114_r7
	cmp r1,#6
	blo 0f
	@PRG bank
	stmfd sp!,{lr}
	orr addy,addy,#1
	bl_long mmc3_write0
	ldmfd sp!,{lr}
	b reapply_nrom
0:	@CHR bank: add the outer bit
	ldrb_ r2,m114_chr
	tst r2,#1
	orrne r0,r0,#0x100
	orr addy,addy,#1
	b_long mmc3_write0

@----------------------------------------------------------------------------
write114_6:	@$6000-$7FFF (no PRG RAM)
@----------------------------------------------------------------------------
	tst addy,#1
	strneb_ r0,m114_chr	@$6001
	bxne lr
	strb_ r0,m114_prg	@$6000
	tst r0,#0x80
	bne reapply_nrom
	@back to the MMC3's PRG banks: R6 and the second-last bank by PRG mode,
	@R7 at $A000, the last bank at $E000
	stmfd sp!,{lr}
	ldrb_ r1,cmd
	tst r1,#0x40
	ldrb_ r0,bank0
	beq 0f
	bl_long mapCD_
	mvn r0,#1
	bl_long map89_
	b 1f
0:
	bl_long map89_
	mvn r0,#1
	bl_long mapCD_
1:
	ldrb_ r0,m114_r7
	bl_long mapAB_
	mvn r0,#0
	bl_long mapEF_
	ldmfd sp!,{pc}

@----------------------------------------------------------------------------
reapply_nrom:	@if $6000 bit 7 is set, its PRG bank replaces the MMC3's
@----------------------------------------------------------------------------
	ldrb_ r1,m114_prg
	tst r1,#0x80
	bxeq lr
	and r0,r1,#0x0F
	tst r1,#0x20
	movne r0,r0,lsr#1
	bne_long map89ABCDEF_	@NROM-256: 32K
	stmfd sp!,{r0,lr}	@NROM-128: the 16K bank twice
	bl_long map89AB_
	ldmfd sp!,{r0,lr}
	b_long mapCDEF_
@----------------------------------------------------------------------------
 .pool
