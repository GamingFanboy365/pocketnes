 .align
 .pool
 .text
 .align
 .pool

#include "../equates.h"
#include "../6502mac.h"

	global_func mapper40init
	global_func mapper40_restore

@ Mapper 40 (NTDEC 2722): the Disk System's Super Mario Bros. 2 (The Lost
@ Levels) converted to a cartridge.  $6000-$7FFF is PRG ROM bank 6,
@ $8000-$BFFF banks 4-5, $C000-$DFFF the bank chosen at $E000, $E000-$FFFF
@ bank 7.  A write to $A000-$BFFF starts a 4096 CPU cycle countdown that
@ ends in an IRQ (the status bar split); a write to $8000-$9FFF stops it and
@ acknowledges the IRQ.
@ The game's code was written for the Disk System's RAM at $6000-$DFFF, and
@ runs on from one 8KB bank into the next ($7FFF to $8000, $BFFF to $C000).
@ The 6502 PC is a pointer into the bank it is in, so the banks have to
@ follow each other in GBA memory too:
@ - bank 6 is copied into NES SRAM (which this board doesn't have) and
@   $6000-$7FFF runs from there; the guard after NES SRAM (6502.s _02)
@   carries code on to $8000.  Writes to $6000-$7FFF still do nothing
@   (m40_w6, which also keeps get_rom_map off $6000 after a savestate).
@ - $8000-$DFFF runs from a 24KB copy of banks 4, 5 and the $C000 bank, just
@   below instant_prg_banks (init_cache leaves the room); the $C000 bank is
@   copied again when $E000 selects another (rarely: once per world).

 irqen = mapperdata+4		@1 while the countdown runs
@----------------------------------------------------------------------------
mapper40init:		@SMB2j
@----------------------------------------------------------------------------
	.word write0,write1,void,m40_wE

	mov addy,lr

	ldr r0,=m40_w6			@ROM: writes do nothing
	str_ r0,writemem_6
	.if PRG_BANK_SIZE == 4
	str_ r0,writemem_7
	.endif

	bl write0

	mov r0,#-1
	bl_long map89ABCDEF_

	bl m40_sram
	bl m40_prg
	mov lr,addy
	bx lr

m40_prg:	@$8000-$DFFF from the copy: banks 4 and 5, then the $C000 bank.  Changes r0-r2.
	stmfd sp!,{r3,addy,lr}
	ldr_ r2,instant_prg_banks
	ldr r1,[r2,#4<<PRG_BANK_LOOKUP_SHIFT_8K]
	sub r0,r2,#0x6000
	mov r2,#0x2000
	bl_long memcpy32
	ldr_ r2,instant_prg_banks
	ldr r1,[r2,#5<<PRG_BANK_LOOKUP_SHIFT_8K]
	sub r0,r2,#0x4000
	mov r2,#0x2000
	bl_long memcpy32
	ldmfd sp!,{r3,addy,lr}
m40_copyC:	@the $C000 bank (bankC) into the copy, then point $8000-$DFFF at it.  Changes r0-r2.
	stmfd sp!,{r3,addy,lr}
	ldr_ r2,instant_prg_banks
	ldrb_ r0,bankC
	ldr r1,[r2,r0,lsl#PRG_BANK_LOOKUP_SHIFT_8K]
	sub r0,r2,#0x2000
	mov r2,#0x2000
	bl_long memcpy32
	ldr_ r0,instant_prg_banks
	sub r0,r0,#0x6000+0x8000
	str_ r0,memmap_8
	str_ r0,memmap_A
	str_ r0,memmap_C
	.if PRG_BANK_SIZE == 4
	str_ r0,memmap_9
	str_ r0,memmap_B
	str_ r0,memmap_D
	.endif
	ldr_ r1,lastbank	@(the PC may be in $8000-$DFFF)
	sub m6502_pc,m6502_pc,r1
	encodePC
	ldmfd sp!,{r3,addy,pc}

m40_wE:		@$E000-$FFFF: the 8KB PRG ROM bank at $C000
	stmfd sp!,{r3,lr}
	ldrb_ r1,bankC
	ldr_ r2,rommask
	and r0,r0,r2,lsr#SHIFT_8K
	cmp r0,r1
	ldmeqfd sp!,{r3,pc}	@(already there)
	bl_long mapCD_		@(bankC, for savestates)
	bl m40_copyC
	ldmfd sp!,{r3,pc}

m40_sram:	@NES SRAM = PRG ROM bank 6, read and run at $6000-$7FFF.  Changes r0-r2.
	stmfd sp!,{r3,addy,lr}
	ldr_ r1,instant_prg_banks
	.if PRG_BANK_SIZE == 8
	ldr r1,[r1,#6*4]
	.endif
	.if PRG_BANK_SIZE == 4
	ldr r1,[r1,#12*4]
	.endif
	ldr r0,=NES_SRAM
	mov r2,#0x2000
	bl_long memcpy32
	ldr r0,=NES_RAM-0x5800
	str_ r0,memmap_6
	ldr r1,=sram_R
	str_ r1,readmem_6
	.if PRG_BANK_SIZE == 4
	str_ r0,memmap_7
	str_ r1,readmem_7
	.endif
	mov r0,#0xFF			@(not ROM-mapped, for get_rom_map)
	strb_ r0,bank6
	ldmfd sp!,{r3,addy,pc}

m40_w6:		@$6000-$7FFF write: ROM
	bx lr

@----------------------------------------------------------------------------
mapper40_restore:	@after a savestate loads (from C)
@----------------------------------------------------------------------------
	stmfd sp!,{r4-r11,lr}
	ldr globalptr,=GLOBAL_PTR_BASE
	adr_ m6502_mmap,memmap_tbl	@(m40_copyC re-encodes the PC: the C code redoes it)
	bl m40_sram
	bl m40_prg
	ldmfd sp!,{r4-r11,lr}
	bx lr

@----------------------------------------------------------------------------
write0:		@$8000-$9FFF: stop the countdown, acknowledge the IRQ.  Changes r0, r1.
@----------------------------------------------------------------------------
	mov r0,#0
	strb_ r0,irqen
	ldrb_ r1,wantirq
	bic r1,r1,#IRQ_MAPPER
	strb_ r1,wantirq
	mov pc,lr
@----------------------------------------------------------------------------
write1:		@$A000-$BFFF: IRQ 4096 CPU cycles from now
@----------------------------------------------------------------------------
	mov r0,#1
	strb_ r0,irqen
	ldr_ r2,cycles_to_run
	sub r2,r2,cycles,asr#CYC_SHIFT
	ldr_ r1,timestamp
	add r1,r1,r2			@now (timestamps count 3 per CPU cycle)
	add r1,r1,#4096*3
	adr r0,m40_handler
	adrl_ addy,mapper_timeout
	b_long replace_timeout_2

m40_handler:	@(timeout) the countdown has run out
	ldrb_ r0,irqen
	cmp r0,#0
	beq_long _GO			@stopped meanwhile
	mov r0,#0
	strb_ r0,irqen
	ldr_ r1,mapper_timestamp
	ldr r0,=mapper_irq_handler
	adrl_ addy,mapper_irq_timeout
	bl_long replace_timeout_2
	b_long _GO
	.pool
@----------------------------------------------------------------------------
	@.end
