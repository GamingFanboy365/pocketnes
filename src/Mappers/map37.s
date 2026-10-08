 .align
 .pool
 .text
 .align
 .pool

#include "../equates.h"
#include "../6502mac.h"

	global_func mapper37init

@ Mapper 37: Nintendo's Super Mario Bros. + Tetris + Nintendo World Cup
@ (Europe), per the NESdev wiki.  An MMC3 plus an outer bank register in
@ place of PRG RAM at $6000-$7FFF, so it only takes writes while the MMC3's
@ $A001 enables (bit 7) and doesn't write-protect (bit 6) PRG RAM.
@ Outer value xxxx xQBB:
@   PRG A13-A15 from the MMC3, A16 = (MMC3 A16 & Q) | (BB==3), A17 = Q
@   CHR A10-A16 from the MMC3, A17 = Q
@ i.e. 0-2: PRG 64K at 0, 3: 64K at 64K, 4-6: 128K at 128K, 7: 64K at 192K;
@ CHR is the first or second 128K.
@ The MMC3 code in map4.s does the rest; this wraps its bank switches.

 cmd	= mapperdata+4		@shared with map4.s
 bank0	= mapperdata+5		@shared with map4.s
 m37_outer = mapperdata+10
 m37_wram  = mapperdata+11	@last $A001 value
 m37_bank7 = mapperdata+12	@MMC3 R7 (map4.s doesn't keep it)

@----------------------------------------------------------------------------
mapper37init:
@----------------------------------------------------------------------------
	.word write0_37,write1_37,mmc3_write2,mmc3_write3
	stmfd sp!,{lr}
	bl_long mmc3_init_code

	adr r1,write_outer
	str_ r1,writemem_6
	.if PRG_BANK_SIZE == 4
	str_ r1,writemem_7
	.endif
	mov r0,#0
	strb_ r0,m37_outer
	strb_ r0,m37_wram
	strb_ r0,bank0
	mov r0,#1
	strb_ r0,m37_bank7
	bl remap_all
	ldmfd sp!,{pc}

@----------------------------------------------------------------------------
prg37:	@r0 = MMC3 8K bank -> ROM 8K bank.  Changes r1, r2.
@----------------------------------------------------------------------------
	ldrb_ r1,m37_outer
	and r2,r1,#3
	tst r1,#4
	andeq r0,r0,#7		@Q=0: MMC3 A16 is masked off
	andne r0,r0,#15
	orrne r0,r0,#16		@Q=1: A17
	cmp r2,#3
	orreq r0,r0,#8		@BB=3: A16 forced high
	bx lr

@----------------------------------------------------------------------------
chr37:	@r0 = MMC3 1K bank -> ROM 1K bank.  Changes r1.
@----------------------------------------------------------------------------
	ldrb_ r1,m37_outer
	and r0,r0,#0x7F
	tst r1,#4
	orrne r0,r0,#0x80
	bx lr

	@CHR bank switch: apply the outer bank, then the normal function
 .macro chr37_wrap name, target
\name:
	stmfd sp!,{lr}
	bl chr37
	ldmfd sp!,{lr}
	b_long \target
 .endm
	chr37_wrap c37_chr01, chr01_rshift_
	chr37_wrap c37_chr23, chr23_rshift_
	chr37_wrap c37_chr45, chr45_rshift_
	chr37_wrap c37_chr67, chr67_rshift_
	chr37_wrap c37_chr0, chr0_
	chr37_wrap c37_chr1, chr1_
	chr37_wrap c37_chr2, chr2_
	chr37_wrap c37_chr3, chr3_
	chr37_wrap c37_chr4, chr4_
	chr37_wrap c37_chr5, chr5_
	chr37_wrap c37_chr6, chr6_
	chr37_wrap c37_chr7, chr7_

@----------------------------------------------------------------------------
write0_37:	@$8000-$9FFF
@----------------------------------------------------------------------------
	tst addy,#1
	beq write0_37_even
	ldrb_ r1,cmd
	tst r1,#0x80		@reverse CHR?
	and r1,r1,#7
	orrne r1,r1,#8
	ldr pc,[pc,r1,lsl#2]
	.word 0
commandlist_37:
	.word c37_chr01,c37_chr23,c37_chr4,c37_chr5,c37_chr6,c37_chr7,c37_cmd6,c37_cmd7
	.word c37_chr45,c37_chr67,c37_chr0,c37_chr1,c37_chr2,c37_chr3,c37_cmd6,c37_cmd7

write0_37_even:	@bank select: like map4.s, but a PRG mode change goes through romswitch_37
	ldrb_ r1,cmd
	eors r2,r0,r1
	bxeq lr
	strb_ r0,cmd
	stmfd sp!,{r2,lr}
	tst r2,#0x40
	blne romswitch_37
	ldmfd sp!,{r2,lr}
	tst r2,#0x80
	bxeq lr
	b_long mmc3_chr_base_switch	@swap the $0000/$1000 CHR halves

c37_cmd7:	@R7: $A000
	strb_ r0,m37_bank7
	stmfd sp!,{lr}
	bl prg37
	ldmfd sp!,{lr}
	b_long mapAB_

c37_cmd6:	@R6: $8000 or $C000
	strb_ r0,bank0
romswitch_37:	@R6 and the second-last bank at $8000/$C000, by PRG mode
	stmfd sp!,{r3,lr}
	ldrb_ r0,bank0
	bl prg37
	mov r3,r0
	mov r0,#-2
	bl prg37
	ldrb_ r1,cmd
	tst r1,#0x40
	beq 0f
	bl_long map89_		@mode 1: $8000 = -2, $C000 = R6
	mov r0,r3
	bl_long mapCD_
	ldmfd sp!,{r3,pc}
0:
	bl_long mapCD_		@mode 0: $8000 = R6, $C000 = -2
	mov r0,r3
	bl_long map89_
	ldmfd sp!,{r3,pc}

@----------------------------------------------------------------------------
write1_37:	@$A000-$BFFF
@----------------------------------------------------------------------------
	tst addy,#1
	strneb_ r0,m37_wram	@$A001: PRG RAM enable/protect, which gates the outer register
	bxne lr
	tst r0,#1
	b_long mirror2V_

@----------------------------------------------------------------------------
write_outer:	@$6000-$7FFF
@----------------------------------------------------------------------------
	ldrb_ r1,m37_wram
	and r1,r1,#0xC0
	cmp r1,#0x80		@enabled and not write-protected
	bxne lr
	and r0,r0,#7
	strb_ r0,m37_outer
@----------------------------------------------------------------------------
remap_all:	@apply the outer bank to every PRG and CHR bank
@----------------------------------------------------------------------------
	stmfd sp!,{r3,r4,lr}
	bl romswitch_37
	ldrb_ r0,m37_bank7
	bl prg37
	bl_long mapAB_
	mov r0,#-1
	bl prg37
	bl_long mapEF_

	@CHR: nes_chr_map holds the ROM 1K bank of each PPU slot; swap the outer half
 .macro remap_chr slot
	adrl_ r1,nes_chr_map
	ldrb r0,[r1,#\slot]
	bl chr37
	bl_long chr\slot\()_
 .endm
	remap_chr 0
	remap_chr 1
	remap_chr 2
	remap_chr 3
	remap_chr 4
	remap_chr 5
	remap_chr 6
	remap_chr 7
	ldmfd sp!,{r3,r4,pc}
@----------------------------------------------------------------------------
 .pool
