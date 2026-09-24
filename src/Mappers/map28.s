 .align
 .pool
 .text
 .align
 .pool

#include "../equates.h"
#include "../6502mac.h"

	global_func mapper28init

@ Action 53 (Mapper 28), per NESdev wiki and FCEUX boards/28.cpp.
@
@ $5000-$5FFF: register select, value & $81:
@   $00 = CHR bank (bits 0-1), $01 = inner PRG bank (bits 0-3),
@   $80 = mode ..GGPSMM, $81 = outer PRG bank (32K units)
@ $8000-$FFFF: write to the selected register.
@
@ Mode: MM = mirroring (0/1 = one-screen A/B, 2 = vertical, 3 = horizontal)
@       P  = 0: 32K banks, 1: 16K banks (UNROM style)
@       S  = which 16K half is fixed when P=1 (0: $8000, 1: $C000)
@       GG = game size (32K/64K/128K/256K), i.e. how many low bank bits
@            come from the inner bank instead of the outer bank.
@ In one-screen modes, bit 4 of a $00/$01 write also selects the nametable.

 m28_reg   = mapperdata+0
 m28_chr   = mapperdata+1
 m28_prg   = mapperdata+2
 m28_mode  = mapperdata+3
 m28_outer = mapperdata+4

@----------------------------------------------------------------------------
mapper28init:
@----------------------------------------------------------------------------
	.word write28,write28,write28,write28

	@ $5000-$5FFF shares a writemem slot with the APU/joypad registers,
	@ so the handler passes $4000-$4FFF through to IO_W.
	adr r1,write28_lo
	str_ r1,writemem_4
	.if PRG_BANK_SIZE == 4
	str_ r1,writemem_5
	.endif

	@ Power-on state (FCEUX M28Reset): outer bank all ones and inner bank
	@ $0F, so the last 32K (menu and reset vector) is mapped at $8000.
	stmfd sp!,{lr}
	mov r0,#0
	strb_ r0,m28_reg
	strb_ r0,m28_chr
	strb_ r0,m28_mode
	mov r0,#0x0F
	strb_ r0,m28_prg
	mov r0,#0xFF
	strb_ r0,m28_outer
	bl sync_prg
	mov r0,#0
	bl_long chr01234567_
	ldmfd sp!,{pc}

@----------------------------------------------------------------------------
write28_lo:	@ $4000-$5FFF
@----------------------------------------------------------------------------
	cmp addy,#0x5000
	blo_long IO_W
	and r0,r0,#0x81
	strb_ r0,m28_reg
	mov pc,lr

@----------------------------------------------------------------------------
write28:	@ $8000-$FFFF
@----------------------------------------------------------------------------
	ldrb_ r1,m28_reg
	cmp r1,#0x01
	beq w28_prg
	cmp r1,#0x80
	beq w28_mode
	cmp r1,#0x81
	beq w28_outer

w28_chr:	@ reg $00
	and r2,r0,#0x03
	strb_ r2,m28_chr
	stmfd sp!,{r0,lr}
	mov r0,r2
	bl_long chr_ram_bank8_
	ldmfd sp!,{r0,lr}
	b w28_screen

w28_prg:	@ reg $01
	and r2,r0,#0x0F
	strb_ r2,m28_prg
	stmfd sp!,{r0,lr}
	bl sync_prg
	ldmfd sp!,{r0,lr}

w28_screen:	@ one-screen modes: bit 4 picks the nametable
	ldrb_ r1,m28_mode
	tst r1,#0x02
	movne pc,lr
	bic r1,r1,#0x01
	tst r0,#0x10
	orrne r1,r1,#0x01
	strb_ r1,m28_mode
	b sync_mirror

w28_mode:	@ reg $80
	and r0,r0,#0x3F
	strb_ r0,m28_mode
	stmfd sp!,{lr}
	bl sync_prg
	ldmfd sp!,{lr}
	b sync_mirror

w28_outer:	@ reg $81
	strb_ r0,m28_outer
	b sync_prg

@----------------------------------------------------------------------------
sync_mirror:
@----------------------------------------------------------------------------
	ldrb_ r0,m28_mode
	tst r0,#0x02
	beq sync_mirror_1
	tst r0,#0x01		@ 2 = vertical, 3 = horizontal
	b_long mirror2V_
sync_mirror_1:
	tst r0,#0x01		@ 0 = one-screen A, 1 = one-screen B
	b_long mirror1_

@----------------------------------------------------------------------------
sync_prg:
@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldrb_ r0,m28_mode
	ldrb_ r1,m28_outer
	ldrb_ r2,m28_prg
	and addy,r0,#0x30
	mov addy,addy,lsr#4	@ game size 0-3
	tst r0,#0x08
	bne sync_prg_16k

	@ 32K modes: low GG bits of the 32K bank come from the inner bank
	mov r0,#1
	mov r0,r0,lsl addy
	sub r0,r0,#1
	bic r1,r1,r0
	and r2,r2,r0
	orr r0,r1,r2
	ldmfd sp!,{lr}
	b_long map89ABCDEF_

sync_prg_16k:
	@ 16K modes: low GG+1 bits of the swappable 16K bank come from the
	@ inner bank; the fixed half is the outer bank's matching half.
	mov r1,r1,lsl#1
	stmfd sp!,{r0,r1}
	mov r0,#2
	mov r0,r0,lsl addy
	sub r0,r0,#1
	and r2,r2,r0
	bic r0,r1,r0
	orr r0,r0,r2
	ldr r1,[sp]
	tst r1,#0x04
	beq sync_prg_fix8

	bl_long map89AB_	@ $8000 swappable, $C000 fixed
	ldmfd sp!,{r0,r1}
	orr r0,r1,#1
	ldmfd sp!,{lr}
	b_long mapCDEF_

sync_prg_fix8:
	bl_long mapCDEF_	@ $C000 swappable, $8000 fixed
	ldmfd sp!,{r0,r1}
	mov r0,r1
	ldmfd sp!,{lr}
	b_long map89AB_
@----------------------------------------------------------------------------
 .pool
	@.end
