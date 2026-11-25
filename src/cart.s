#include "equates.h"
#include "6502mac.h"

@	.include "equates.h"
@	.include "mappers.h"
@	.include "memory.h"
@	.include "6502mac.h"
@	.include "6502.h"
@	.include "ppu.h"
@	.include "io.h"
@	.include "sound.h"
@	.include "timeout.h"

	@IMPORT findrom @from main.c
	@IMPORT init_sprite_cache
	@IMPORT init_cache
	@IMPORT loadcart
	
	@IMPORT update_bankbuffer

	global_func im_lazy
	.if RESET_ALL
	global_func reset_all
	.endif

	global_func chr_req_

	.global _BGmirror
	.global _rommask
	.global _rompages
	.global _vrompages
	.global _fourscreen
	.global _sprite_chr_map
	global_func mirror2_
	global_func mirrorchange
	.global _nes_chr_map
	.global _agb_real_bg_map
	global_func loadcart_asm
	global_func hardreset
	global_func map67_
	global_func map89_
	global_func mapAB_
	global_func mapCD_
	global_func mapEF_
	global_func map89AB_
	global_func mapCDEF_
	global_func map89ABCDEF_
	global_func chr0_
	global_func chr1_
	global_func chr2_
	global_func chr3_
	global_func chr4_
	global_func chr5_
	global_func chr6_
	global_func chr7_
	global_func chr01_
	global_func chr23_
	global_func chr45_
	global_func chr67_
	global_func chr01_rshift_
	global_func chr23_rshift_
	global_func chr45_rshift_
	global_func chr67_rshift_
	global_func chr0123_
	global_func chr4567_
	global_func chr01234567_
	.global writeCHRTBL
	global_func updateBGCHR_
@	global_func updateOBJCHR
	global_func mirror1_
	global_func mirror2V_
	global_func mirror2H_
	global_func mirror4_
	global_func mirrorKonami_
@	global_func chrfinish
	global_func chrfinish2

	global_func map89AB_rshift_
	global_func mapCDEF_rshift_
	global_func map89ABCDEF_rshift_
	global_func chr01234567_rshift_

	.if CARTSAVE
	.global CachedConfig
	.endif
	.if SAVESTATES
	global_func loadstate_gfx
	.endif

	.global _emuflags
	.global romstart
	.global romnum
	.global _scaling
	.global _cartflags
	.global _hackflags
	.global _hackflags2
	.global _rompages
	.global _mapper_number
	.global _rombase
	.global _vrombase
	.global _vrommask
	.global _vrompages
	
	.global END_OF_EXRAM
	.global _instant_prg_banks
	.global _instant_chr_banks
	.global _bank6
	.global _bank8
	.global _Cbank0
	.global _nes_chr_map
	.global _vrompages
	.global _rompages
	.global NES_VRAM
	.global NES_VRAM2
	.global NES_VRAM4
	
	.global mapperstate

	.global _twitch
	.global _flicker

@	.global FREQTBL2
	global_func reset_buffers
	global_func render_tiles_2

	
@----------------------------------------------------------------------------
 .align
 .pool
 .text
 .align
 .pool
@----------------------------------------------------------------------------

mappertbl:
	.byte 0
	.byte 1
	.byte 2
	.byte 3
	.byte 4
	.if LESSMAPPERS
	.else
	.byte 5
	.endif
	.byte 7
	.byte 9
	.byte 10
	.byte 11
	.if LESSMAPPERS
	.else
	.byte 15
	.endif
	.byte 16
	.byte 17
	.byte 18
	.byte 19
	.byte 21
	.byte 22
	.byte 23
	.byte 24
    .byte 25
	.byte 26
	.byte 28
	.byte 30
	.byte 32
	.byte 33
	.byte 34
	.byte 37
	.byte 38
	.byte 40
    .byte 41
	.byte 42
	.byte 64
	.byte 65
	.byte 66
	.byte 67
	.byte 68
	.byte 69
	.byte 70
	.byte 71
	.byte 72
	.byte 73
	.byte 74
	.byte 75
	.byte 76
	.byte 77
	.byte 78
	.byte 79
	.byte 80
	.byte 82
	.byte 85
	.byte 86
	.byte 87
	.byte 88
    .byte 89
	.byte 92
	.byte 93
	.byte 94
	.byte 97
	.byte 99
	.if LESSMAPPERS
	.else
	.byte 105
	.endif
    .byte 113
	.byte 114
	.byte 118
	.byte 119
	.byte 140
    .byte 146
	.byte 151
	.byte 152
	.byte 158
	.if LESSMAPPERS
	.else
	.byte 163
	.endif
	.byte 178
	.byte 180
	.byte 184
    .byte 185
	.byte 187
	.byte 206
	.byte 211
	.byte 218
	.if LESSMAPPERS
	.else
	.byte 225
	.byte 228
	.endif
	.byte 232
	.byte 245
	.byte 249
	.byte 252
	.byte 254
	.byte 0
mappertbl_end:
	.align 2
mappertbl2:
	.word mapper0init 	@0
	.word mapper1init 	@1
	.word mapper2init 	@2
	.word mapper3init 	@3
	.word mapper4init 	@4
	.if LESSMAPPERS
	.else
	.word mapper5init 	@5
	.endif
	.word mapper7init 	@7
	.word mapper9init 	@9
	.word mapper10init	@10
	.word mapper11init	@11
	.if LESSMAPPERS
	.else
	.word mapper15init	@15
	.endif
	.word mapper16init	@16
	.word mapper17init	@17
	.word mapper18init	@18
	.word mapper19init	@19
	.word mapper21init	@21
	.word mapper22init	@22
	.word mapper23init	@23
	.word mapper24init	@24
    .word mapper25init	@25
	.word mapper26init	@26
    .word mapper28init  @28
	.word mapper30init	@30
	.word mapper32init	@32
	.word mapper33init	@33
	.word mapper34init	@34
	.word mapper37init	@37
    .word mapper38init	@38
	.word mapper40init	@40
    .word mapper41init	@41
	.word mapper42init	@42
	.word mapper64init	@64
	.word mapper65init	@65
	.word mapper66init	@66
	.word mapper67init	@67
	.word mapper68init	@68
	.word mapper69init	@69
	.word mapper70init	@70
	.word mapper71init	@71
	.word mapper72init	@72
	.word mapper73init	@73
	.word mapper74init	@74
	.word mapper75init	@75
	.word mapper76init	@76
	.word mapper77init	@77
	.word mapper78init	@78
	.word mapper79init	@79
	.word mapper80init	@80
	.word mapper82init	@82
	.word mapper85init	@85
	.word mapper86init	@86
	.word mapper87init	@87
	.word mapper88init	@88
    .word mapper89init	@89
	.word mapper92init	@92
	.word mapper93init	@93
	.word mapper94init	@94
	.word mapper97init	@97
	.word mapper99init	@99
	.if LESSMAPPERS
	.else
	.word mapper105init	@105
	.endif
    .word mapper113init	@113
	.word mapper114init	@114
	.word mapper118init	@118
	.word mapper119init	@119
	.word mapper66init	@140
    .word mapper79init	@146
	.word mapper151init	@151
	.word mapper152init	@152
	.word mapper64init	@158
	.if LESSMAPPERS
	.else
	.word mapper163init	@163
	.endif
	.word mapper4init 	@178
	.word mapper180init	@180
	.word mapper184init	@184
    .word mapper3init	@185
	.word mapper4init 	@187
	.word mapper206init @206
	.word mapper211init	@211
	.word mapper0init	@218 (NROM-like; from Dwedit's 2025 PocketNES)
	.if LESSMAPPERS
	.else
	.word mapper225init	@225
	.word mapper228init	@228
	.endif
	.word mapper232init	@232
	.word mapper245init	@245
	.word mapper249init	@249
	.word mapper4init 	@252
	.word mapper4init 	@254
	.word mapper0init		@default
thumbcall_r1_b:
	bx r1

@----------------------------------------------------------------------------
loadcart_asm: @called from C
@----------------------------------------------------------------------------
	stmfd sp!,{r4-r11,lr}

	ldr globalptr,=GLOBAL_PTR_BASE	@need ptr regs init'd
	ldr cpu_zpage,=NES_RAM

	@Set video memory writability
	ldr r1,=void
	ldrb_ r2,has_vram
	.if MIXED_VRAM_VROM
	ldrb_ r0,bankable_vrom
	tst r0,r2
	ldrne r1,=VRAM_chr3
	bne 0f
	.endif
	movs r2,r2
	beq 0f
	ldr r1,=VRAM_chr
	mov r2,#0x17
	b 1f
0:
	mov r2,#0xE7
1:
	ldr r0,=vram_write_modify+3
	strb r2,[r0]
	adr_ r0,vram_write_tbl
	mov r2,#8*4
	bl memset32_
	
	adrl_ r0,agb_bg_map
	mov r1,#-1			@reset all CHR
	mov r2,#12*4			@agb_bg_map, agb_bg_map_requested, agb_real_bg_map
	bl memset32_
	ldr r0,=0x0004080c
	str_ r0,bg_recent
	mov r0,#0			@default CHR mapping
	strb_ r0,chrline
	ldr r1,=0x03020100
	str_ r1,chrold
	bl_long bg_reload_reset
@	bl_long chr01234567_

	ldr_ r4,nes_chr_map
	ldr_ r5,nes_chr_map+4
@	str r4,old_chr_map
@	str r4,new_chr_map
@	str r5,old_chr_map+4
@	str r5,new_chr_map+4

	ldr_ r2,vrommask		@if vromsize=0
	tst r2,#0x80000000
	bpl lc2
	str_ r4,agb_bg_map		@setup BG map so it won't change
	str_ r5,agb_bg_map+4
lc2:
	mov m6502_pc,#0		@(eliminates any encodePC errors during mapper*init)
	str_ m6502_pc,lastbank
	adr_ m6502_mmap,memmap_tbl

	mov r0,#0			@default ROM mapping
	bl_long map89AB_			@89AB=1st 16k

	mov r0,#-1
	bl_long mapCDEF_			@CDEF=last 16k

	@no more scanline or midline hooks
@@	ldr r0,=default_scanlinehook
@	ldr r0,=pcm_scanlinehook
@	str_ r0,scanlinehook	@no mapper irq
@	ldr r0,=default_midlinehook
@	str_ r0,midlinehook
	
	ldr r0,=joy0_W
	ldr r1,=joypad_write_ptr
	str r0,[r1]				@reset 4016 write (mapper99 messes with it)
	ldr r1,=empty_W                 @mapper 249 needs address 5000
	ldr r0,=empty_io_w_hook
	str r1,[r0]
	ldr r1,=empty_R					@mapper 163 needs address 5x00
	ldr r0,=empty_io_r_hook
	str r1,[r0]

	
	.if PRG_BANK_SIZE == 8
	ldr r1,=IO_R			@reset other writes..
	str_ r1,readmem_4
	ldr r1,=sram_R			@reset other writes..
	str_ r1,readmem_6
	ldr r1,=IO_W			@reset other writes..
	str_ r1,writemem_4
	ldr r1,=sram_W
	str_ r1,writemem_6
	ldr r1,=NES_RAM-0x5800	@$6000 for mapper 40, 69 & 90 that has rom here.
	str_ r1,memmap_6
	.endif
	.if PRG_BANK_SIZE == 4
	ldr r1,=IO_R			@reset other writes..
	str_ r1,readmem_4
	str_ r1,readmem_5
	ldr r1,=sram_R			@reset other writes..
	str_ r1,readmem_6
	str_ r1,readmem_7
	ldr r1,=IO_W			@reset other writes..
	str_ r1,writemem_4
	str_ r1,writemem_5
	ldr r1,=sram_W
	str_ r1,writemem_6
	str_ r1,writemem_7
	ldr r1,=NES_RAM-0x5800	@$6000 for mapper 40, 69 & 90 that has rom here.
	str_ r1,memmap_6
	str_ r1,memmap_7
	.endif
	
	
	bl ntsc_pal_reset
	bl timeout_reset
	bl PPU_reset
	ldr r0,=_nes_chr_map	@sprites use the normal CHR page list (MMC5 changes this)
	str_ r0,sprite_chr_map
	.if LESSMAPPERS
	.else
	bl_long mmc5_unpatch	@(MMC5 extended attributes patch display_bg)
	.endif
	bl IO_reset
	bl Sound_hardware_reset
	bl sound_reset
	@move initial CHR bankswitch to come after ppu reset
	mov r0,#0
	bl_long chr01234567_
	
	ldrb_ r0,mapper_number
							@lookup mapper*init
	adr r1,mappertbl
	ldr r5,=mappertbl_end
lc0:
	ldrb r2,[r1],#1
	cmp r2,r0
	beq lc1
	cmp r1,r5
	bne lc0
lc1:				@call mapper*init
	adrl r4,mappertbl
	sub r1,r1,r4
	adr r5,mappertbl2
	add r1,r5,r1,lsl#2
	
	adr lr,0f
	adr_ r5,writemem_8
	ldr r0,[r1,#-4]
	ldmia r0!,{r1-r4}
	.if PRG_BANK_SIZE == 8
	str r1,[r5],#-4
	str r2,[r5],#-4
	str r3,[r5],#-4
	str r4,[r5],#-4
	.endif
	.if PRG_BANK_SIZE == 4
	str r1,[r5],#-4
	str r1,[r5],#-4
	str r2,[r5],#-4
	str r2,[r5],#-4
	str r3,[r5],#-4
	str r3,[r5],#-4
	str r4,[r5],#-4
	str r4,[r5],#-4
	.endif

	adr_ m6502_mmap,memmap_tbl @r4 gets clobbered, reset it here
	mov pc,r0			@Jump to MapperInit
0:
	ldrb_ r1,cartflags
	tst r1,#MIRROR		@set default mirror
	bl_long mirror2H_		@(call after mapperinit to allow mappers to set up cartflags first)
	ldr r1,=singlescreen
	ldrb r1,[r1]
	cmp r1,#0
	beq 1f
	bl_long mirror1_		@one-screen at boot if requested (mapper 218)
1:

	bl CPU_reset		@reset everything else - Call AFTER mapperinit
	
	ldmfd sp!,{r4-r11,lr}
	bx lr

hardreset:
	ldr r12,=loadcart
	ldr r0,=romnum
	ldr r0,[r0]
	ldr r1,=_emuflags
	ldr r1,[r1]
	mov r2,#0
	bx r12
	

	.if SAVESTATES
	.global tags
tags:
	.ascii "VERS"
	.ascii "CPUS"
	.ascii "GFXS"
	.ascii "RAM "
	.ascii "SRAM"
	.ascii "VRM1"
	.ascii "VRM2"
	.ascii "VRM4"
	.ascii "MAPR"
	.ascii "PAL2"
	.ascii "MIR2"
	.ascii "OAM "
	.ascii "SND0"
	.ascii "SND1"   @old SND0 no longer loaded
	.ascii "TIME"
	.ascii "NOPE"


@----------------------------------------------------------------------------
loadstate_gfx:	
@void loadstate_gfx(void)
@----------------------------------------------------------------------------
	stmfd sp!,{r0-addy,lr}
	
	ldr globalptr,=GLOBAL_PTR_BASE

	bl resetBGCHR
@	bl_long update_bankbuffer
	bl_long updateBGCHR_
	
	@restore rest of vram_map, agb_nt_map
	ldr_ r0,BGmirror
	movs r1,r0,lsr#14
	bne 0f
	@single screen
	tst r0,#0x100
	ldrne r0,=m1111
	ldreq r0,=m0000
	b 1f
0:
	cmp r1,#1
	ldreq r0,=m0101  @vertical mirroring
	cmp r1,#2
	ldreq r0,=m0011  @horizontal mirroring
	ldrgt r0,=m0123  @four screen
1:
	bl_long mirrorchange

	ldrb_ r0,ppuctrl1
	mov r1,r0
	mov r2,#0x00
	bl_long ctrl1_W_force
	
	ldrb_ r0,ppuctrl0
	tst r0,#4
	moveq r1,#1
	movne r1,#32
	strb_ r1,vramaddrinc
	ldr r0,=vramaddrinc_modify1
	strb r1,[r0]
	ldr r0,=vramaddrinc_modify2
	strb r1,[r0]
	
	ldr r0,=stat_R_clearvbl
	ldr r1,=PPU_read_tbl+8
	str r0,[r1]
	
@	bl_long findsprite0
	
	ldr_ r0,scrollX
	str_ r0,scrollXold
	ldr_ r0,scrollY
	str_ r0,scrollYold
	
	adrl_ r2,nes_chr_map
	ldmia r2,{r0,r1}
	adr_ r2,bankbuffer_last
	ldmia r2,{r0,r1}


@	ldr r5,=NES_VRAM
@	add r3,r5,#0x2000	@init nametbl+attrib
@	add r4,r3,#0x1000
@	
@ls3
@	sub addy,r3,r5
@	bl_long vram_read_direct
@	bl_long vram_write_direct
@	add r3,r3,#1
@	cmp r3,r4
@	blt ls3
	
	
@	ldrb_ r0,vrompages
@	cmp r0,#0
@	bne ls5
@	
@	ldr r5,=NES_VRAM
@	add r3,r5,#0x0000	@init nametbl+attrib
@	add r4,r3,#0x2000
@ls4	
@	sub addy,r3,r5
@	bl_long vram_read_direct
@	bl_long vram_write_direct
@	add r3,r3,#1
@	cmp r3,r4
@	blt ls4
@ls5	
	bl_long updateBGCHR_
	bl_long ntsc_pal_reset	@included so that it can reset some variables that weren't included in old mapperstate

	ldmfd sp!,{r0-addy,lr}
	bx lr

	.endif

@----------------------------------------------------------------------------
m0000:	.word 0x0C02,NES_VRAM2+0x0000,NES_VRAM2+0x0000,NES_VRAM2+0x0000,NES_VRAM2+0x0000
	.word VRAM_name0, VRAM_name0, VRAM_name0, VRAM_name0
m1111:	.word 0x0D02,NES_VRAM2+0x0400,NES_VRAM2+0x0400,NES_VRAM2+0x0400,NES_VRAM2+0x0400
	.word VRAM_name1, VRAM_name1, VRAM_name1, VRAM_name1
m0101:	.word 0x4C02,NES_VRAM2+0x0000,NES_VRAM2+0x0400,NES_VRAM2+0x0000,NES_VRAM2+0x0400
	.word VRAM_name0, VRAM_name1, VRAM_name0, VRAM_name1
m0011:	.word 0x8C02,NES_VRAM2+0x0000,NES_VRAM2+0x0000,NES_VRAM2+0x0400,NES_VRAM2+0x0400
	.word VRAM_name0, VRAM_name0, VRAM_name1, VRAM_name1
m0123:	.word 0xCC02,NES_VRAM2+0x0000,NES_VRAM2+0x0400,NES_VRAM4+0x0000,NES_VRAM4+0x0400
	.word VRAM_name0, VRAM_name1, VRAM_name2, VRAM_name3
m2222:	.word 0x0E02,NES_VRAM4+0x0000,NES_VRAM4+0x0000,NES_VRAM4+0x0000,NES_VRAM4+0x0000	@all nametables on page 2 (MMC5)
	.word VRAM_name2, VRAM_name2, VRAM_name2, VRAM_name2

	.pushsection .text, "ax", %progbits
mirror2_:	@all nametables on page 2 (MMC5 $A4/$AA; from Dwedit's 2025 PocketNES)
	ldr r0,=m2222
	b_long mirrorchange
	.pool
	.popsection

	.if SAVESTATES
@----------------------------------------------------------------------------
resetBGCHR:
@----------------------------------------------------------------------------
	mov r0,#0
	strb_ r0,chrline
	strb_ r0,bankbuffer_line
	
	ldrb_ r2,ppuctrl0
	tst r2,#0x10
	ldreq_ r0,nes_chr_map
	ldrne_ r0,nes_chr_map+4
	str_ r0,chrold
	b_long bg_reload_reset
	.endif

@----------------------------------------------------------------------------
 .align
 .pool
 .section .iwram, "ax", %progbits
 .subsection 4
 .align
 .pool
@----------------------------------------------------------------------------
mirrorKonami_:
	movs r1,r0,lsr#2
	tst r0,#1
	bcc mirror2V_
@	bcs mirror1_
mirror1_:
	ldrne r0,=m1111
	ldreq r0,=m0000
	b mirrorchange
mirror2V_:
	ldreq r0,=m0101
	ldrne r0,=m0011
	b mirrorchange
mirror2H_:
	ldreq r0,=m0011
	ldrne r0,=m0101
	b mirrorchange
mirror4_:
	ldr r0,=m0123
mirrorchange:
	ldrb_ r1,cartflags
	tst r1,#SCREEN4+VS
	ldrne r0,=m0123		@force 4way mirror for SCREEN4 or VS flags

	stmfd sp!,{r0,r3-r5,lr}

	stmfd sp!,{addy,lr}
	bl get_scanline_2
	mov r2,addy
	ldmfd sp!,{addy,lr}
	cmp r2,#240
	movhi r2,#240

	ldr_ r0,chrold
	ldrb_ r1,chrline


	bl ubg2_	@allow mid-frame change

	ldr r0,[sp],#4	@???
	ldr r3,[r0],#4
	str_ r3,BGmirror

	adr_ r1,vram_map+32
	ldmia r0!,{r2-r5}
	stmia r1,{r2-r5}
	adr_ r1,vram_write_tbl+8*4
	ldmia r0!,{r2-r5}
	stmia r1!,{r2-r5}
	stmia r1,{r2-r4}
	ldmfd sp!,{r3-r5,pc}

.if PRG_BANK_SIZE == 4
 .pushsection .text, "ax", %progbits
@code for 4k switching

 .popsection
 
@----------------------------------------------------------------------------
map67_:	@rom paging.. r0=page#
@----------------------------------------------------------------------------
	ldr_ r1,rommask
	and r0,r0,r1,lsr#SHIFT_8K
	strb_ r0,bank6
	ldr_ r1,instant_prg_banks
	ldr r2,[r1,r0,lsl#PRG_BANK_LOOKUP_SHIFT_8K]
	subs r2,r2,#0x6000
@	bmi need_to_use_cache
	str_ r2,memmap_6
	str_ r2,memmap_7
	b flush
@----------------------------------------------------------------------------
map89_:	@rom paging.. r0=page#
@----------------------------------------------------------------------------
	ldr_ r1,rommask
	and r0,r0,r1,lsr#SHIFT_8K
	strb_ r0,bank8
	ldr_ r1,instant_prg_banks
	ldr r2,[r1,r0,lsl#PRG_BANK_LOOKUP_SHIFT_8K]
	subs r2,r2,#0x8000
@	bmi need_to_use_cache
	str_ r2,memmap_8
	str_ r2,memmap_9
	b flush
@----------------------------------------------------------------------------
mapAB_:
@----------------------------------------------------------------------------
	ldr_ r1,rommask
	and r0,r0,r1,lsr#SHIFT_8K
	strb_ r0,bankA
	ldr_ r1,instant_prg_banks
	ldr r2,[r1,r0,lsl#PRG_BANK_LOOKUP_SHIFT_8K]
	subs r2,r2,#0xA000
@	bmi need_to_use_cache
	str_ r2,memmap_A
	str_ r2,memmap_B
	b flush
@----------------------------------------------------------------------------
mapCD_:
@----------------------------------------------------------------------------
	ldr_ r1,rommask
	and r0,r0,r1,lsr#SHIFT_8K
	strb_ r0,bankC
	ldr_ r1,instant_prg_banks
	ldr r2,[r1,r0,lsl#PRG_BANK_LOOKUP_SHIFT_8K]
	subs r2,r2,#0xC000
@	bmi need_to_use_cache
	str_ r2,memmap_C
	str_ r2,memmap_D
	b flush
@----------------------------------------------------------------------------
mapEF_:
@----------------------------------------------------------------------------
	ldr_ r1,rommask
	and r0,r0,r1,lsr#SHIFT_8K
	strb_ r0,bankE
	ldr_ r1,instant_prg_banks
	ldr r2,[r1,r0,lsl#PRG_BANK_LOOKUP_SHIFT_8K]
	subs r2,r2,#0xE000
@	bmi need_to_use_cache
	str_ r2,memmap_E
	str_ r2,memmap_F
	b flush

map89AB_rshift_:
	mov r0,r0,lsr#1
@----------------------------------------------------------------------------
map89AB_:
@----------------------------------------------------------------------------
	ldr_ r1,rommask
	and r0,r0,r1,lsr#SHIFT_16K
	mov r0,r0,lsl#1
	strb_ r0,bank8
	add r2,r0,#1
	strb_ r2,bankA
	ldr_ r1,instant_prg_banks
	ldr r0,[r1,r0,lsl#PRG_BANK_LOOKUP_SHIFT_8K]!
	subs r0,r0,#0x8000
@	bmi need_to_use_cache
@@don't bother with checking if page is whole
@@	ldr r2,[r1!,#4]!
@@	subs r2,r2,#0xA000
@@	cmp r0,r2
@@	bne need_to_use_cache
	str_ r0,memmap_8
	str_ r0,memmap_9
	str_ r0,memmap_A
	str_ r0,memmap_B
flush:		@update nes_pc & lastbank
	ldr_ r1,lastbank
	sub m6502_pc,m6502_pc,r1
	encodePC
	bx lr

mapCDEF_rshift_:
	mov r0,r0,lsr#1
@----------------------------------------------------------------------------
mapCDEF_:
@----------------------------------------------------------------------------
	ldr_ r1,rommask
	and r0,r0,r1,lsr#SHIFT_16K
	mov r0,r0,lsl#1
	strb_ r0,bankC
	add r2,r0,#1
	strb_ r2,bankE
	ldr_ r1,instant_prg_banks
	ldr r0,[r1,r0,lsl#PRG_BANK_LOOKUP_SHIFT_8K]!
	subs r0,r0,#0xC000
@	bmi need_to_use_cache
@@don't bother with checking if page is whole
@@	ldr r2,[r1,#4]!
@@	subs r2,r2,#0xE000
@@	cmp r0,r2
@@	bne need_to_use_cache
	str_ r0,memmap_C
	str_ r0,memmap_D
	str_ r0,memmap_E
	str_ r0,memmap_F
	b flush

map89ABCDEF_rshift_:
	mov r0,r0,lsr#1
@----------------------------------------------------------------------------
map89ABCDEF_:
@----------------------------------------------------------------------------
	ldr_ r1,rommask
	and r0,r0,r1,lsr#SHIFT_32K
	ldr r1,=0x03020100
	orr r2,r0,r0,lsl#8
	orr r2,r2,r2,lsl#16
	orr r2,r1,r2,lsl#2
	str_ r2,bank8
@	strb_ r0,bank8
@	add r2,r0,#1
@	strb_ r2,bankA
@	add r2,r2,#1
@	strb_ r2,bankC
@	add r2,r2,#1
@	strb_ r2,bankE
	ldr_ r1,instant_prg_banks
@	ldr r0,[r1,r0,lsl#2]!
	ldr r0,[r1,r0,lsl#PRG_BANK_LOOKUP_SHIFT_32K]!
	subs r0,r0,#0x8000
@	bmi need_to_use_cache
@@don't bother with checking if page is whole
@@	ldr r2,[r1,#4]!
@@	subs r2,r2,#0xA000
@@	cmp r0,r2
@@	bne need_to_use_cache
@@	ldr r2,[r1,#4]!
@@	subs r2,r2,#0xC000
@@	cmp r0,r2
@@	bne need_to_use_cache
@@	ldr r2,[r1,#4]!
@@	subs r2,r2,#0xE000
@@	cmp r0,r2
@@	bne need_to_use_cache
	str_ r0,memmap_8
	str_ r0,memmap_9
	str_ r0,memmap_A
	str_ r0,memmap_B
	ldr r0,[r1,#16]!
	subs r0,r0,#0xC000
	str_ r0,memmap_C
	str_ r0,memmap_D
	str_ r0,memmap_E
	str_ r0,memmap_F
	b flush


.endif

.if PRG_BANK_SIZE == 8
@----------------------------------------------------------------------------
map67_:	@rom paging.. r0=page#
@----------------------------------------------------------------------------
	ldr_ r1,rommask
	and r0,r0,r1,lsr#SHIFT_8K
	strb_ r0,bank6
	ldr_ r1,instant_prg_banks
	ldr r2,[r1,r0,lsl#PRG_BANK_LOOKUP_SHIFT_8K]
	subs r2,r2,#0x6000
@	bmi need_to_use_cache
	str_ r2,memmap_6
	b flush
@----------------------------------------------------------------------------
map89_:	@rom paging.. r0=page#
@----------------------------------------------------------------------------
	ldr_ r1,rommask
	and r0,r0,r1,lsr#SHIFT_8K
	strb_ r0,bank8
	ldr_ r1,instant_prg_banks
	ldr r2,[r1,r0,lsl#PRG_BANK_LOOKUP_SHIFT_8K]
	subs r2,r2,#0x8000
@	bmi need_to_use_cache
	str_ r2,memmap_8
	b flush
@----------------------------------------------------------------------------
mapAB_:
@----------------------------------------------------------------------------
	ldr_ r1,rommask
	and r0,r0,r1,lsr#SHIFT_8K
	strb_ r0,bankA
	ldr_ r1,instant_prg_banks
	ldr r2,[r1,r0,lsl#PRG_BANK_LOOKUP_SHIFT_8K]
	subs r2,r2,#0xA000
@	bmi need_to_use_cache
	str_ r2,memmap_A
	b flush
@----------------------------------------------------------------------------
mapCD_:
@----------------------------------------------------------------------------
	ldr_ r1,rommask
	and r0,r0,r1,lsr#SHIFT_8K
	strb_ r0,bankC
	ldr_ r1,instant_prg_banks
	ldr r2,[r1,r0,lsl#PRG_BANK_LOOKUP_SHIFT_8K]
	subs r2,r2,#0xC000
@	bmi need_to_use_cache
	str_ r2,memmap_C
	b flush
@----------------------------------------------------------------------------
mapEF_:
@----------------------------------------------------------------------------
	ldr_ r1,rommask
	and r0,r0,r1,lsr#SHIFT_8K
	strb_ r0,bankE
	ldr_ r1,instant_prg_banks
	ldr r2,[r1,r0,lsl#PRG_BANK_LOOKUP_SHIFT_8K]
	subs r2,r2,#0xE000
@	bmi need_to_use_cache
	str_ r2,memmap_E
	b flush

map89AB_rshift_:
	mov r0,r0,lsr#1
@----------------------------------------------------------------------------
map89AB_:
@----------------------------------------------------------------------------
	ldr_ r1,rommask
	and r0,r0,r1,lsr#SHIFT_16K
	mov r0,r0,lsl#1
	strb_ r0,bank8
	add r2,r0,#1
	strb_ r2,bankA
	ldr_ r1,instant_prg_banks
	ldr r0,[r1,r0,lsl#PRG_BANK_LOOKUP_SHIFT_8K]!
	subs r0,r0,#0x8000
@	bmi need_to_use_cache
@@don't bother with checking if page is whole
@@	ldr r2,[r1!,#4]!
@@	subs r2,r2,#0xA000
@@	cmp r0,r2
@@	bne need_to_use_cache
	str_ r0,memmap_8
	str_ r0,memmap_A
flush:		@update nes_pc & lastbank
	ldr_ r1,lastbank
	sub m6502_pc,m6502_pc,r1
	encodePC
	bx lr

mapCDEF_rshift_:
	mov r0,r0,lsr#1
@----------------------------------------------------------------------------
mapCDEF_:
@----------------------------------------------------------------------------
	ldr_ r1,rommask
	and r0,r0,r1,lsr#SHIFT_16K
	mov r0,r0,lsl#1
	strb_ r0,bankC
	add r2,r0,#1
	strb_ r2,bankE
	ldr_ r1,instant_prg_banks
	ldr r0,[r1,r0,lsl#PRG_BANK_LOOKUP_SHIFT_8K]!
	subs r0,r0,#0xC000
@	bmi need_to_use_cache
@@don't bother with checking if page is whole
@@	ldr r2,[r1,#4]!
@@	subs r2,r2,#0xE000
@@	cmp r0,r2
@@	bne need_to_use_cache
	str_ r0,memmap_C
	str_ r0,memmap_E
	b flush

map89ABCDEF_rshift_:
	mov r0,r0,lsr#1
@----------------------------------------------------------------------------
map89ABCDEF_:
@----------------------------------------------------------------------------
	ldr_ r1,rommask
	and r0,r0,r1,lsr#SHIFT_32K
	ldr r1,=0x03020100
	orr r2,r0,r0,lsl#8
	orr r2,r2,r2,lsl#16
	orr r2,r1,r2,lsl#2
	str_ r2,bank8
@	strb_ r0,bank8
@	add r2,r0,#1
@	strb_ r2,bankA
@	add r2,r2,#1
@	strb_ r2,bankC
@	add r2,r2,#1
@	strb_ r2,bankE
	ldr_ r1,instant_prg_banks
@	ldr r0,[r1,r0,lsl#2]!
	ldr r0,[r1,r0,lsl#PRG_BANK_LOOKUP_SHIFT_32K]!
	subs r0,r0,#0x8000
@	bmi need_to_use_cache
@@don't bother with checking if page is whole
@@	ldr r2,[r1,#4]!
@@	subs r2,r2,#0xA000
@@	cmp r0,r2
@@	bne need_to_use_cache
@@	ldr r2,[r1,#4]!
@@	subs r2,r2,#0xC000
@@	cmp r0,r2
@@	bne need_to_use_cache
@@	ldr r2,[r1,#4]!
@@	subs r2,r2,#0xE000
@@	cmp r0,r2
@@	bne need_to_use_cache
	str_ r0,memmap_8
	str_ r0,memmap_A
	ldr r0,[r1,#8]!
	subs r0,r0,#0xC000
	str_ r0,memmap_C
	str_ r0,memmap_E
	b flush

.endif
	
@----------------------------------------------------------------------------
writeCHRTBL:	.word chr0_,chr1_,chr2_,chr3_,chr4_,chr5_,chr6_,chr7_
@----------------------------------------------------------------------------


@----------------------------------------------------------------------------
chr0_:
@----------------------------------------------------------------------------
	ldr_ r2,vrommask
	and r0,r0,r2,lsr#10

	strb_ r0,nes_chr_map
	ldr_ r1,instant_chr_banks
	ldr r1,[r1,r0,lsl#2]
	str_ r1,vram_map
	b updateBGCHR_
@----------------------------------------------------------------------------
chr1_:
@----------------------------------------------------------------------------
	ldr_ r2,vrommask
	and r0,r0,r2,lsr#10

	strb_ r0,nes_chr_map+1
	ldr_ r1,instant_chr_banks
	ldr r1,[r1,r0,lsl#2]
	str_ r1,vram_map+4
	b updateBGCHR_
@----------------------------------------------------------------------------
chr2_:
@----------------------------------------------------------------------------
	ldr_ r2,vrommask
	and r0,r0,r2,lsr#10

	strb_ r0,nes_chr_map+2
	ldr_ r1,instant_chr_banks
	ldr r1,[r1,r0,lsl#2]
	str_ r1,vram_map+8
	b updateBGCHR_
@----------------------------------------------------------------------------
chr3_:
@----------------------------------------------------------------------------
	ldr_ r2,vrommask
	and r0,r0,r2,lsr#10

	strb_ r0,nes_chr_map+3
	ldr_ r1,instant_chr_banks
	ldr r1,[r1,r0,lsl#2]
	str_ r1,vram_map+12
	b updateBGCHR_
@----------------------------------------------------------------------------
chr4_:
@----------------------------------------------------------------------------
	ldr_ r2,vrommask
	and r0,r0,r2,lsr#10

	strb_ r0,nes_chr_map+4
	ldr_ r1,instant_chr_banks
	ldr r1,[r1,r0,lsl#2]
	str_ r1,vram_map+16
	b updateBGCHR_
@----------------------------------------------------------------------------
chr5_:
@----------------------------------------------------------------------------
	ldr_ r2,vrommask
	and r0,r0,r2,lsr#10

	strb_ r0,nes_chr_map+5
	ldr_ r1,instant_chr_banks
	ldr r1,[r1,r0,lsl#2]
	str_ r1,vram_map+20
	b updateBGCHR_
@----------------------------------------------------------------------------
chr6_:
@----------------------------------------------------------------------------
	ldr_ r2,vrommask
	and r0,r0,r2,lsr#10

	strb_ r0,nes_chr_map+6
	ldr_ r1,instant_chr_banks
	ldr r1,[r1,r0,lsl#2]
	str_ r1,vram_map+24
	b updateBGCHR_
@----------------------------------------------------------------------------
chr7_:
@----------------------------------------------------------------------------
	ldr_ r2,vrommask
	and r0,r0,r2,lsr#10

	strb_ r0,nes_chr_map+7
	ldr_ r1,instant_chr_banks
	ldr r1,[r1,r0,lsl#2]
	str_ r1,vram_map+28
	b updateBGCHR_

chr01_rshift_:
	mov r0,r0,lsr#1
@----------------------------------------------------------------------------
chr01_:
@----------------------------------------------------------------------------
	mov r0,r0,lsl#1
	ldr_ r2,vrommask
	and r0,r0,r2,lsr#10

	strb_ r0,nes_chr_map
	orr r2,r0,#1
	strb_ r2,nes_chr_map+1

	ldr_ r1,instant_chr_banks
	ldr r1,[r1,r0,lsl#2]

	str_ r1,vram_map
	add r1,r1,#0x400
	str_ r1,vram_map+4
	b updateBGCHR_

chr23_rshift_:
	mov r0,r0,lsr#1
@----------------------------------------------------------------------------
chr23_:
@----------------------------------------------------------------------------
	mov r0,r0,lsl#1
	ldr_ r2,vrommask
	and r0,r0,r2,lsr#10

	strb_ r0,nes_chr_map+2
	orr r2,r0,#1
	strb_ r2,nes_chr_map+3

	ldr_ r1,instant_chr_banks
	ldr r1,[r1,r0,lsl#2]

	str_ r1,vram_map+8
	add r1,r1,#0x400
	str_ r1,vram_map+12
	b updateBGCHR_

chr45_rshift_:
	mov r0,r0,lsr#1
@----------------------------------------------------------------------------
chr45_:
@----------------------------------------------------------------------------
	mov r0,r0,lsl#1
	ldr_ r2,vrommask
	and r0,r0,r2,lsr#10

	strb_ r0,nes_chr_map+4
	orr r2,r0,#1
	strb_ r2,nes_chr_map+5

	ldr_ r1,instant_chr_banks
	ldr r1,[r1,r0,lsl#2]

	str_ r1,vram_map+16
	add r1,r1,#0x400
	str_ r1,vram_map+20
	b updateBGCHR_

chr67_rshift_:
	mov r0,r0,lsr#1
@----------------------------------------------------------------------------
chr67_:
@----------------------------------------------------------------------------
	mov r0,r0,lsl#1
	ldr_ r2,vrommask
	and r0,r0,r2,lsr#10

	strb_ r0,nes_chr_map+6
	orr r2,r0,#1
	strb_ r2,nes_chr_map+7

	ldr_ r1,instant_chr_banks
	ldr r1,[r1,r0,lsl#2]

	str_ r1,vram_map+24
	add r1,r1,#0x400
	str_ r1,vram_map+28
	b updateBGCHR_
@----------------------------------------------------------------------------
chr0123_:
@----------------------------------------------------------------------------
	ldr_ r2,vrommask
	and r0,r0,r2,lsr#12

	orr r1,r0,r0,lsl#8
	orr r1,r1,r1,lsl#16
	ldr r2,=0x03020100
	orr r2,r2,r1,lsl#2
	str_ r2,nes_chr_map

	ldr_ r1,instant_chr_banks
	ldr r1,[r1,r0,lsl#4]

	adrl_ r0,vram_map
	add r2,r1,#0x400
	stmia r0!,{r1,r2}
	add r1,r2,#0x400
	add r2,r1,#0x400
	stmia r0!,{r1,r2}
	b updateBGCHR_

chr01234567_rshift_:
	mov r0,r0,lsr#1
@----------------------------------------------------------------------------
chr01234567_:
@----------------------------------------------------------------------------
	ldr_ r2,vrommask
	and r0,r0,r2,lsr#13

	orr r1,r0,r0,lsl#8
	orr r1,r1,r1,lsl#16
	ldr r2,=0x03020100
	orr r2,r2,r1,lsl#3
	str_ r2,nes_chr_map
	ldr r2,=0x07060504
	orr r2,r2,r1,lsl#3
	str_ r2,nes_chr_map+4

	ldr_ r1,instant_chr_banks
	ldr r1,[r1,r0,lsl#5]

	adrl_ r0,vram_map
	add r2,r1,#0x400
	stmia r0!,{r1,r2}
	add r1,r2,#0x400
	add r2,r1,#0x400
	stmia r0!,{r1,r2}
	add r1,r2,#0x400
	b _4567
@----------------------------------------------------------------------------
chr4567_:
@----------------------------------------------------------------------------
	ldr_ r2,vrommask
	and r0,r0,r2,lsr#12

	orr r1,r0,r0,lsl#8
	orr r1,r1,r1,lsl#16
	ldr r2,=0x03020100
	orr r2,r2,r1,lsl#2
	str_ r2,nes_chr_map+4

	ldr_ r1,instant_chr_banks
	ldr r1,[r1,r0,lsl#4]
	
	adrl_ r0,vram_map+16
_4567:
	add r2,r1,#0x400
	stmia r0!,{r1,r2}
	add r1,r2,#0x400
	add r2,r1,#0x400
	stmia r0!,{r1,r2}
@- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
updateBGCHR_:	@see if BG CHR needs to change, setup BGxCNTBUFF
@----------------------------------------------------------------------------
	stmfd sp!,{r3-r5,addy,lr}
	bl_long update_bankbuffer
	
	
	ldrb_ r2,ppuctrl0
	tst r2,#0x10
	ldreq_ r1,nes_chr_map
	ldrne_ r1,nes_chr_map+4	@r0=new bg chr group
	
	ldr_ r0,chrold
	str_ r1,chrold

	bl get_scanline_2
	mov r2,addy
	ldmfd sp!,{r3-r5,addy,lr}
	cmp r2,#240
	movhi r2,#240
	ldrb_ r1,chrline

	subs r1,r2,r1
	bxeq lr
	cmp r1,#4		@if(scanline-lastline<4)
	bpl ubg2_
	@We are less than 4 scanlines from the beginning of the background change
	@but let's allow background changes to a cached page at any time.
	@check if it's in the cache, if it is, keep going.  Otherwise, return.
	stmfd sp!,{r2,lr}
	adrl_ r2,agb_bg_map
	ldr r1,[r2],#4
	cmp r0,r1
	ldrne r1,[r2],#4
	cmpne r0,r1
	ldrne r1,[r2],#4
	cmpne r0,r1
	ldrne r1,[r2],#4
	cmpne r0,r1
	ldmnefd sp!,{r2,pc}
	ldmeqfd sp!,{r2,lr}
ubg2_:			@now setup BG for last request: (chrfinish,mirror* jumps here)
	@r2 = scanline end, r0 = chrold
	stmfd sp!,{r3-r7,addy,lr}
	ldrb_ r1,chrline
	strb_ r2,chrline
	cmp r2,#0
	beq ubg2_exit
	subs r2,r2,r1
	beq ubg2_exit
	addlt r2,r2,r1
	movlt r1,#0
	stmfd sp!,{r1,r2}
	bl chr_req_
	ldmfd sp!,{r0,r2}
	ldrb_ r1,bg_recent
	ldr_ r3,BGmirror
	orr r1,r1,r3
	ldr_ r7,bg0cntbuff
	add r0,r7,r0,lsl#1
	bl memset16
ubg2_exit:
	ldmfd sp!,{r3-r7,addy,pc}

@chrold:	.word 0 @last write
@chrline:	.word 0 @when?

@@----------------------------------------------------------------------------
@chrfinish	@end of frame...  finish up BGxCNTBUFF
@@----------------------------------------------------------------------------
@	mov r2,#240
chrfinish2:
	mov addy,lr

	ldr_ r0,chrold
	bl ubg2_
@	mov r0,#0
@	str_ r0,chrline

	bx addy
@@----------------------------------------------------------------------------
@updateOBJCHR	@sprite CHR update (r3-r7 killed)
@@----------------------------------------------------------------------------
@	ldrb_ r2,ppuctrl0frame
@	tst r2,#0x20	@8x16?
@	beq uc3
@	mov addy,lr
@	bl uc1
@	bl uc2
@	mov pc,addy
@uc3
@	tst r2,#0x08
@	bne uc2
@uc1
@	ldr r0,new_chr_map @use old copy (OAM lags behind 2 frames)
@	ldr r1,old_chr_map @use old copy (OAM lags behind a frame)
@	str r1,new_chr_map
@	ldr r1,agb_obj_map
@	eors r1,r1,r0
@	moveq pc,lr
@	str r0,agb_obj_map
@	ldr r5,=AGB_VRAM+0x10000
@	adrl r6,agb_obj_map
@	b im_lazy
@uc2
@	ldr r0,new_chr_map+4
@	ldr r1,old_chr_map+4
@	str r1,new_chr_map+4
@	ldr r1,agb_obj_map+4
@	eors r1,r1,r0
@	moveq pc,lr
@	str r0,agb_obj_map+4
@	ldr r5,=AGB_VRAM+0x12000
@	adrl r6,agb_obj_map+4
@	b im_lazy

@----------------------------------------------------------------------------
chr_req_:		@request BG CHR group in r0, r1=scanline start, r2=scanline count
@		r0=chr group (4 1k CHR pages)
@----------------------------------------------------------------------------
	adrl_ r6,agb_bg_map
	add r5,r1,r2

	mov r3,r6
	ldr r4,[r3]
	cmp r0,r4		@check for existing group
	ldrne r4,[r3,#4]!
	cmpne r0,r4
	ldrne r4,[r3,#4]!
	cmpne r0,r4
	ldrne r4,[r3,#4]!
	cmpne r0,r4
	bne_long notcached_vram1	@(r3-agb_bg_map)=matching group#

cached:@--------------move to the top of the list:
	adrl_ r4,bg_recent
	sub r7,r3,r6	@r7=group#*4
	ldr r3,=bg_reload_state
	mov r1,r7,lsr#2
	ldrb r2,[r3]
	mov r6,#1
	orr r2,r2,r6,lsl r1
	strb r2,[r3]
	add r3,r3,#4
	strb r5,[r3,r1]
	mov r2,r7	@r2=new xx_recent
	ldrb r0,[r4]
	cmp r7,r0
	orrne r2,r0,r2,ror#8
	ldrb r0,[r4,#1]
	cmp r7,r0
	orrne r2,r0,r2,ror#8
	ldrb r0,[r4,#2]
	cmp r7,r0
	orrne r2,r0,r2,ror#8
	ldrb r0,[r4,#3]
	cmp r7,r0
	orrne r2,r0,r2,ror#8
	mov r2,r2,ror#8
	str r2,[r4]
	bx lr

 decodeptr	.req r2 @mem_chr_decode
 tilecount	.req r3
 nesptr		.req r4 @chr src
 agbptr		.req r5 @chr dst
 bankptr		.req r6 @vrom bank lookup ptr

im_lazy:		@----------r1=old^new
	stmfd sp!,{lr}
	ldr decodeptr,=CHR_DECODE
bg0:	 tst r1,#0xff
	 ldrb r0,[bankptr],#1
	 mov r1,r1,lsr#8
	 addeq agbptr,agbptr,#0x800
	 beq bg2
	 
	ldr r3,=_agb_real_bg_map
	bl_long bank_search_vram1
	
	mov tilecount,#64
	 
	strb r0,[bankptr,#15]  @commit to "displayed bank memory" the selected chr bank
	@r0 in bank number
	@r4 output nes pointer
	ldr_ nesptr,instant_chr_banks
	ldr nesptr,[nesptr,r0,lsl#2]
	
	bl render_tiles

bg2:	tst bankptr,#3
	bne bg0
	ldmfd sp!,{pc}

	.pushsection .text, "ax", %progbits
notcached_vram1:
	ldr_ r2,bg_recent		@r2 = pre-rotation bg_recent
	mov r7,r2,lsr#24		@r7 = oldest group#*4
	mov r3,r2,ror#24
	str_ r3,bg_recent
	ldr r4,=bg_reload_state
	mov r3,r7,lsr#2			@r3 = slot (0..3)
	ldrb r12,[r4]			@bg_frame_used
	mov r2,#1
	tst r12,r2,lsl r3
	bne 0f
	str r0,[r6,r7]			@save new group
	orr r12,r12,r2,lsl r3
	strb r12,[r4]
	add r4,r4,#4
	strb r5,[r4,r3]			@bg_slot_end_line[slot] = scanline_end
	bx lr
0:
	stmfd sp!,{r5,lr}
	ldrb r12,[r4,#1]		@bg_reload_count
	cmp r12,#0
	bne 1f
	ldr_ r2,bg_recent
	mov r2,r2,ror#8			@restore pre-rotation bg_recent
	str r2,[r4,#24]			@bg_recent_init
	ldmia r6,{r2,r5,r12,lr}
	add r4,r4,#8
	stmia r4,{r2,r5,r12,lr}		@agb_bg_map_init[0..3]
	sub r4,r4,#8
	mov r12,#0
1:
	str r0,[r6,r7]			@save new group
	cmp r12,#16
	bhs 2f
	add r6,r4,#0x27000
	add r6,r6,r12,lsl#3		@&bg_reload_queue[bg_reload_count]
	add r2,r4,#4
	ldrb r2,[r2,r3]			@prev_end = bg_slot_end_line[slot]
	strb r3,[r6,#0]			@slot
	strb r2,[r6,#1]			@prev_end
	strb r1,[r6,#2]			@start_line
	str r0,[r6,#4]			@new_group
	add r12,r12,#1
	strb r12,[r4,#1]		@bg_reload_count++
2:
	ldmfd sp!,{r5,lr}
	ldrb r12,[r4]
	mov r2,#1
	orr r12,r12,r2,lsl r3
	strb r12,[r4]
	add r4,r4,#4
	strb r5,[r4,r3]			@bg_slot_end_line[slot] = scanline_end
	bx lr
	.pool
	.popsection

	.pushsection .text, "ax", %progbits
bank_search_vram1:
	@Save evicted BG bank into victim cache if eligible
	ldr r4,=bg_reload_state
	ldrb r7,[r4,#96]		@bg_victim_enabled
	cmp r7,#0
	beq 3f
	tst agbptr,#0x10000
	bne 3f
	ldrb r4,[bankptr,#15]		@old_bank
	cmp r4,#0xFF
	beq 3f
	mov r7,#0xFF
	strb r7,[bankptr,#15]		@temporarily clear current slot so active search skips it
	@Is old_bank duplicated in another active BG slot?
	mov r7,#16
0:
	ldrb r12,[r3],#1
	cmp r12,r4
	beq 3f
	subs r7,r7,#1
	bne 0b
	@Is old_bank already in bg_victim_map[0..31]?
	ldr r3,=0x02028220
	mov r7,#32
1:
	ldrb r12,[r3],#1
	cmp r12,r4
	beq 3f
	subs r7,r7,#1
	bne 1b
	@Store old_bank into victim slot bg_victim_cursor
	ldr r3,=0x02028220
	ldrb r7,[r3,#32]		@bg_victim_cursor (0..31)
	strb r4,[r3,r7]
	add r12,r7,#1
	cmp r12,#32
	movhs r12,#0
	strb r12,[r3,#32]
	stmfd sp!,{r0-r2,lr}
	cmp r7,#4
	ldrlo r0,=0x0600A000
	addlo r0,r0,r7,lsl#11
	subhs r7,r7,#4
	ldrhs r0,=0x02028800
	addhs r0,r0,r7,lsl#11
	mov r1,agbptr
	mov r2,#2048
	bl_long memcpy32
	ldmfd sp!,{r0-r2,lr}
3:
	tst agbptr,#0x10000
	bxne lr
	ldr r3,=_agb_real_bg_map
	mov r7,#16
bank_search_loop_vram1:
	ldrb r4,[r3],#1
	cmp r4,r0
	beq found_matching_bank_vram1
	subs r7,r7,#1
	bne bank_search_loop_vram1
	@Also search victim cache if enabled and updating BG VRAM
	ldr r4,=bg_reload_state
	ldrb r7,[r4,#96]
	cmp r7,#0
	bxeq lr
	ldr r3,=0x02028220
	mov r7,#32
victim_search_loop_vram1:
	ldrb r4,[r3],#1
	cmp r4,r0
	beq found_victim_bank_vram1
	subs r7,r7,#1
	bne victim_search_loop_vram1
	bx lr

found_victim_bank_vram1:
	stmfd sp!,{r1,r2}
	rsb r7,r7,#32
	cmp r7,#4
	ldrlo r1,=0x0600A000
	addlo r1,r1,r7,lsl#11
	subhs r7,r7,#4
	ldrhs r1,=0x02028800
	addhs r1,r1,r7,lsl#11
	b 0f
found_matching_bank_vram1:
	stmfd sp!,{r1,r2}
	mov r1,#BG_VRAM
	rsb r7,r7,#16
	and r2,r7,#0x0C
	and r7,r7,#0x03
	add r1,r1,r7,lsl#11
	add r1,r1,r2,lsl#12
0:
	strb r0,[bankptr,#15]
	mov r0,agbptr
	mov r2,#2048
	bl_long memcpy32
	add agbptr,agbptr,#0x800
	ldmfd sp!,{r1,r2}
	b_long bg2
	.pool
	.popsection

	.pushsection .text, "ax", %progbits
	global_func bg_reload_reset
bg_reload_reset:
	ldr r0,=bg_reload_state
	mov r1,#0
	mov r2,#100
0:
	str r1,[r0],#4
	subs r2,r2,#4
	bne 0b
	mvn r1,#0
	strb r1,[r0,#0x38]		@last_spr_scale_mode = 0xFF
bg_victim_reset:
	ldr r0,=bg_reload_state
	mvn r1,#0
	strb r1,[r0,#95]		@bg_reload_state[95] = 0xFF (initialized magic)
	ldr r0,=0x02028220
	mov r2,#32
1:
	str r1,[r0],#4
	subs r2,r2,#4
	bne 1b
	strb r2,[r0]			@bg_victim_cursor = 0
	bx lr

	global_func bg_reload_commit_frame
bg_reload_commit_frame:
	@Called in newframe_nes_vblank with GBA VBlank IRQ disabled
	@Preserves r2 and addy (r12)!
	stmfd sp!,{r2,r4-r9,r12,lr}
	ldr r4,=bg_reload_state
	ldrb r5,[r4,#1]			@bg_reload_count
	strb r5,[r4,#2]			@dma_bg_reload_count = bg_reload_count
	adrl_ r0,agb_bg_map
	adrl_ r1,agb_bg_map_requested
	ldr r8,=agb_bg_map_req_init
	cmp r5,#0
	beq 0f
	add r6,r4,#8			@agb_bg_map_init
	ldmia r6,{r2,r3,r7,r9}
	stmia r1,{r2,r3,r7,r9}
	stmia r8,{r2,r3,r7,r9}
	stmia r0,{r2,r3,r7,r9}		@restore agb_bg_map to frame-start state
	ldr r2,[r4,#24]			@bg_recent_init
	str_ r2,bg_recent
	@copy bg_reload_queue to dma_bg_reload_queue (2 entries per iteration)
	add r6,r4,#0x27000
	add r8,r6,#0x80
2:
	ldmia r6!,{r0,r1,r2,r3}
	stmia r8!,{r0,r1,r2,r3}
	subs r5,r5,#2
	bgt 2b
	b 1f
0:
	ldmia r0,{r2,r3,r7,r9}
	stmia r1,{r2,r3,r7,r9}
	stmia r8,{r2,r3,r7,r9}
1:
	mov r0,#0
	strh r0,[r4,#0]			@bg_frame_used = 0, bg_reload_count = 0
	str r0,[r4,#4]			@bg_slot_end_line = 0
	ldmfd sp!,{r2,r4-r9,r12,pc}

	global_func bg_reload_prepare_vblank
bg_reload_prepare_vblank:
	stmfd sp!,{r4-r9,lr}
	ldr r4,=bg_reload_state
	ldrb r0,[r4,#95]
	cmp r0,#0
	bleq bg_victim_reset
	@Update bg_victim_enabled
	mov r0,#0
	ldrb_ r1,bankable_vrom
	ldrb_ r2,has_vram
	bics r1,r1,r2
	ldrneb_ r1,mapper_number
	cmpne r1,#5
	beq 0f
	ldr r1,=rom_is_compressed
	ldr r1,[r1]
	cmp r1,#0
	moveq r0,#1
0:
	strb r0,[r4,#96]		@bg_victim_enabled
	mov r0,#0
	strb r0,[r4,#98]		@active_bg_reload_idx = 0
	strb r0,[r4,#99]		@bg_vcount_mode = 0
	ldrb r5,[r4,#2]			@dma_bg_reload_count
	strb r5,[r4,#97]		@active_bg_reload_count = dma_bg_reload_count
	cmp r5,#0
	beq 9f
	ldr r6,=agb_bg_map_req_init
	adrl_ r7,agb_bg_map_requested
	ldmia r6,{r0,r1,r2,r3}
	stmia r7,{r0,r1,r2,r3}
	ldr r7,=0x02028194		@active_bg_reloads_ext
	sub r6,r7,#0x80			@dma_bg_reload_queue_ext
	ldrb_ r8,emuflags+1
	ldrb_ r9,windowtop
1:
	ldrb r0,[r6,#0]			@slot
	ldrb r1,[r6,#1]			@prev_end (NES scanline)
	ldrb r2,[r6,#2]			@start_line (NES scanline)
	ldr r3,[r6,#4]			@new_group
	@Convert r1 (prev_end) and r2 (start_line) to GBA scanline
	cmp r8,#SCALED
	bcc 2f
	@Scaled: gba = (nes * 3) >> 2 - 12
	add r1,r1,r1,lsl#1
	mov r1,r1,lsr#2
	subs r1,r1,#12
	movlt r1,#0
	add r2,r2,r2,lsl#1
	mov r2,r2,lsr#2
	subs r2,r2,#12
	movlt r2,#0
	b 3f
2:
	@Unscaled: gba = nes - windowtop
	subs r1,r1,r9
	movlt r1,#0
	subs r2,r2,r9
	movlt r2,#0
3:
	@Choose trigger scanline in [r1, r2-1], preferring r2 - 12
	subs r2,r2,#12
	movlt r2,#0
	cmp r2,r1
	movlt r2,r1
	cmp r2,#SCREEN_HEIGHT-2
	movgt r2,#SCREEN_HEIGHT-2
	strb r0,[r7,#0]			@slot
	strb r2,[r7,#1]			@trigger_gba
	str r3,[r7,#4]			@new_group
	add r6,r6,#8
	add r7,r7,#8
	subs r5,r5,#1
	bne 1b
9:
	ldmfd sp!,{r4-r9,pc}

	global_func bg_reload_arm_vcount
bg_reload_arm_vcount:
	ldr r4,=bg_reload_state
	ldrb r5,[r4,#97]
	cmp r5,#0
	bxeq lr
	ldr r3,=REG_BASE + REG_DISPSTAT
	ldrb r5,[r3]
	tst r5,#0x20
	bxne lr
	mov r6,#1
	strb r6,[r4,#99]
	ldr r6,=0x02028194
	ldrb r2,[r6,#1]
	orr r5,r5,#0x20
	strb r5,[r3]
	strb r2,[r3,#1]
	bx lr
	.pool
	.popsection

	.pushsection .text, "ax", %progbits
	global_func bg_vcount_handler
bg_vcount_handler:
	@Called from vcountinterrupt when bg_vcount_mode != 0
	@Switch to System mode (0x9F) with IRQs disabled so we use sp_usr
	mrs r3,cpsr
	bic r1,r3,#0x1F
	orr r1,r1,#0x9F
	msr cpsr_cf,r1
	stmfd sp!,{r3-r11,lr}
	ldr globalptr,=GLOBAL_PTR_BASE
	ldr r4,=bg_reload_state
	ldr r7,=0x02028194
0:
	ldrb r8,[r4,#98]		@active_bg_reload_idx
	ldrb r9,[r4,#97]		@active_bg_reload_count
	cmp r8,r9
	bhs 2f
	add r11,r7,r8,lsl#3
	ldrb r0,[r11,#0]		@slot (0..3)
	ldrb r2,[r11,#1]		@trigger_gba
	ldr r3,[r11,#4]			@new_group
	add r8,r8,#1
	strb r8,[r4,#98]
	adrl_ r6,agb_bg_map_requested
	add r6,r6,r0,lsl#2
	str r3,[r6]
	ldr r1,[r6,#16]			@agb_real_bg_map[slot]
	eors r1,r1,r3
	beq 1f
	mov r5,#BG_VRAM
	add r5,r5,r0,lsl#14		@0x06000000 + slot * 0x4000
	bl_long im_lazy
	ldr r4,=bg_reload_state
	ldr r7,=0x02028194
1:
	ldrb r8,[r4,#98]
	ldrb r9,[r4,#97]
	cmp r8,r9
	bhs 2f
	add r11,r7,r8,lsl#3
	ldrb r2,[r11,#1]		@next trigger_gba
	ldr r0,=REG_BASE
	ldrb r1,[r0,#REG_VCOUNT]
	cmp r1,r2
	bge 0b
	strb r2,[r0,#REG_DISPSTAT+1]
	b 3f
2:
	ldr r0,=REG_BASE
	ldrb r1,[r0,#REG_DISPSTAT]
	bic r1,r1,#0x20
	strb r1,[r0,#REG_DISPSTAT]
	mov r2,#0xFF
	strb r2,[r0,#REG_DISPSTAT+1]
	mov r1,#0
	strb r1,[r4,#99]		@bg_vcount_mode = 0
3:
	ldmfd sp!,{r3-r11,lr}
	msr cpsr_cf,r3
	bx lr
	.pool
	.popsection

	.pushsection .sbss
	.align 2
	.global bg_reload_state
	.global agb_bg_map_req_init
	.global active_bg_reloads
	.global bg_victim_map
	.global last_spr_scale_mode
bg_reload_state:
	.skip 100
agb_bg_map_req_init:
	.skip 16
active_bg_reloads:
	.skip 32
bg_victim_map:
	.skip 8
last_spr_scale_mode:
	.skip 4
	.popsection
@	mov pc,lr


@bg1	  ldrb r0,[nesptr],#1
@	  ldrb r7,[nesptr,#7]
@	  ldr r0,[decodeptr,r0,lsl#2]
@	  ldr r7,[decodeptr,r7,lsl#2]
@	  orr r0,r0,r7,lsl#1
@	  str r0,[agbptr],#4
@	  tst agbptr,#0x1f
@	  bne bg1
@	 subs tilecount,tilecount,#1
@	 add nesptr,nesptr,#8
@	 bne bg1

 dest0		.req r0	@words to write to agb vram
 dest1		.req r1
@r2 = chr_decode
@r3 = tilecount
@r4 = nesptr
@r5 = agbptr
 dest2		.req r6
 pixels0		.req r7	@word processed to write to agb vram (also dest3)
 pixels1		.req r8
 nesword0	.req r9	@sets of 4 bytes read from nesptr
 nesword1	.req r10
 nesword2	.req r11
 nesword3	.req r12
 mask		.req lr	@0xFF

render_tiles:
	@in: r2 = chr_decode, r3 = tilecount, r4 = nesptr, r5 = agbptr
	@regs: r0=dest0, r1=dest1, r6=dest2, r7=pixels0, r8=pixels1, r9=nesword0, r10=nesword1, r11=nesword2, r12=nesword3
	@destroys: r0,r2,r6,r7,r8,r9,r11
	@out: encodes NES character data as GBA character data, r3 = 0, r4+=r3*16, r5+=r3*32
	stmfd sp!,{r1,r6,r10,r12,lr}
	stmfd sp!,{r5}
	mov mask,#0xFF
bg1:
	ldmia nesptr!,{nesword0,nesword1,nesword2,nesword3}
	ands pixels0,mask,nesword0
	ldrne pixels0,[decodeptr,pixels0,lsl#2]
	ands pixels1,mask,nesword2
	ldrne pixels1,[decodeptr,pixels1,lsl#2]
	orr dest0,pixels0,pixels1,lsl#1
	ands pixels0,mask,nesword0,lsr#8
	ldrne pixels0,[decodeptr,pixels0,lsl#2]
	ands pixels1,mask,nesword2,lsr#8
	ldrne pixels1,[decodeptr,pixels1,lsl#2]
	orr dest1,pixels0,pixels1,lsl#1
	ands pixels0,mask,nesword0,lsr#16
	ldrne pixels0,[decodeptr,pixels0,lsl#2]
	ands pixels1,mask,nesword2,lsr#16
	ldrne pixels1,[decodeptr,pixels1,lsl#2]
	orr dest2,pixels0,pixels1,lsl#1
	ands pixels0,mask,nesword0,lsr#24
	ldrne pixels0,[decodeptr,pixels0,lsl#2]
	ands pixels1,mask,nesword2,lsr#24
	ldrne pixels1,[decodeptr,pixels1,lsl#2]
	orr pixels0,pixels0,pixels1,lsl#1
	stmia agbptr!,{dest0,dest1,dest2,pixels0}
	ands pixels0,mask,nesword1
	ldrne pixels0,[decodeptr,pixels0,lsl#2]
	ands pixels1,mask,nesword3
	ldrne pixels1,[decodeptr,pixels1,lsl#2]
	orr dest0,pixels0,pixels1,lsl#1
	ands pixels0,mask,nesword1,lsr#8
	ldrne pixels0,[decodeptr,pixels0,lsl#2]
	ands pixels1,mask,nesword3,lsr#8
	ldrne pixels1,[decodeptr,pixels1,lsl#2]
	orr dest1,pixels0,pixels1,lsl#1
	ands pixels0,mask,nesword1,lsr#16
	ldrne pixels0,[decodeptr,pixels0,lsl#2]
	ands pixels1,mask,nesword3,lsr#16
	ldrne pixels1,[decodeptr,pixels1,lsl#2]
	orr dest2,pixels0,pixels1,lsl#1
	ands pixels0,mask,nesword1,lsr#24
	ldrne pixels0,[decodeptr,pixels0,lsl#2]
	ands pixels1,mask,nesword3,lsr#24
	ldrne pixels1,[decodeptr,pixels1,lsl#2]
	orr pixels0,pixels0,pixels1,lsl#1
	stmia agbptr!,{dest0,dest1,dest2,pixels0}
	subs tilecount,tilecount,#1
	bne bg1
	ldmfd sp!,{r0}
	mov r1,agbptr
	bl_long scale_spr_tiles_range
	ldmfd sp!,{r1,r6,r10,r12,pc}

	.unreq agbptr	@r4
	.unreq pixels0	@r7
	.unreq pixels1	@r8
	agbptr .req r7
	agbptr2 .req r8
	pixels0 .req r5
	pixels1 .req r12
render_tiles_2:
	@renders tiles to two destination addresses
	@in: r2 = chr_decode, r3 = tilecount, r4 = nesptr, r7 = agbptr, r8 = agbptr2
	@regs: r0=dest0, r1=dest1, r6=dest2, r7=pixels0, r8=pixels1, r9=nesword0, r10=nesword1, r11=nesword2, r12=pixels1
	@destroys: r0,r1,r6,r7,r8,r9,r11
	@out: encodes NES character data as GBA character data, r3 = 0, r4+=r3*16, r5+=r3*32
	stmfd sp!,{r6,r9,lr}
	stmfd sp!,{r7,r8}
	mov mask,#0xFF
render_tiles_2_loop:
	ldmia nesptr!,{nesword0,nesword1,nesword2}
	ands pixels0,mask,nesword0
	ldrne pixels0,[decodeptr,pixels0,lsl#2]
	ands pixels1,mask,nesword2
	ldrne pixels1,[decodeptr,pixels1,lsl#2]
	orr dest0,pixels0,pixels1,lsl#1
	ands pixels0,mask,nesword0,lsr#8
	ldrne pixels0,[decodeptr,pixels0,lsl#2]
	ands pixels1,mask,nesword2,lsr#8
	ldrne pixels1,[decodeptr,pixels1,lsl#2]
	orr dest1,pixels0,pixels1,lsl#1
	ands pixels0,mask,nesword0,lsr#16
	ldrne pixels0,[decodeptr,pixels0,lsl#2]
	ands pixels1,mask,nesword2,lsr#16
	ldrne pixels1,[decodeptr,pixels1,lsl#2]
	orr dest2,pixels0,pixels1,lsl#1
	ands pixels0,mask,nesword0,lsr#24
	ldrne pixels0,[decodeptr,pixels0,lsl#2]
	ands pixels1,mask,nesword2,lsr#24
	ldrne pixels1,[decodeptr,pixels1,lsl#2]
	orr pixels1,pixels0,pixels1,lsl#1
	stmia agbptr!,{dest0,dest1,dest2,pixels1}
	stmia agbptr2!,{dest0,dest1,dest2,pixels1}
	ldmia nesptr!,{nesword0}
	ands pixels0,mask,nesword1
	ldrne pixels0,[decodeptr,pixels0,lsl#2]
	ands pixels1,mask,nesword0
	ldrne pixels1,[decodeptr,pixels1,lsl#2]
	orr dest0,pixels0,pixels1,lsl#1
	ands pixels0,mask,nesword1,lsr#8
	ldrne pixels0,[decodeptr,pixels0,lsl#2]
	ands pixels1,mask,nesword0,lsr#8
	ldrne pixels1,[decodeptr,pixels1,lsl#2]
	orr dest1,pixels0,pixels1,lsl#1
	ands pixels0,mask,nesword1,lsr#16
	ldrne pixels0,[decodeptr,pixels0,lsl#2]
	ands pixels1,mask,nesword0,lsr#16
	ldrne pixels1,[decodeptr,pixels1,lsl#2]
	orr dest2,pixels0,pixels1,lsl#1
	ands pixels0,mask,nesword1,lsr#24
	ldrne pixels0,[decodeptr,pixels0,lsl#2]
	ands pixels1,mask,nesword0,lsr#24
	ldrne pixels1,[decodeptr,pixels1,lsl#2]
	orr pixels1,pixels0,pixels1,lsl#1
	stmia agbptr!,{dest0,dest1,dest2,pixels1}
	stmia agbptr2!,{dest0,dest1,dest2,pixels1}
	subs tilecount,tilecount,#1
	bne render_tiles_2_loop
	ldmfd sp!,{r0}
	mov r1,agbptr
	bl_long scale_spr_tiles_range
	ldmfd sp!,{r0}
	mov r1,agbptr2
	bl_long scale_spr_tiles_range
	ldmfd sp!,{r6,r9,pc}

	.pushsection .text, "ax", %progbits
	global_func scale_spr_tiles_range
scale_spr_tiles_range:
	@in: r0 = start_ptr in BG_VRAM or SPR_VRAM, r1 = end_ptr
	@preserves all registers r0-r12, lr
	stmfd sp!,{r0-r12,lr}
	ldr r2,=_scaling
	ldrb r2,[r2]
	and r2,r2,#3
	tst r0,#0x10000
	beq scale_bg_tiles_entry
	cmp r2,#SCALED_SPRITES
	bne scale_spr_tiles_done

	ldr r2,=GLOBAL_PTR_BASE
	ldrb r12,[r2,#ppuctrl0frame]
	and r12,r12,#0x20			@r12 = 0 (8x8) or 0x20 (8x16)
	ldr r11,=0x11111111
	b scale_spr_tile_loop

scale_bg_tiles_entry:
	cmp r2,#SCALED
	blo scale_spr_tiles_done
	ldr r11,=0x11111111
scale_bg_tile_loop:
	cmp r0,r1
	bhs scale_spr_tiles_done
	ldmia r0,{r2-r9}			@r2..r9 = w0..w7
	cmp r3,r4
	beq 1f
	eor r10,r3,r2				@w1 ^ w0
	orr r10,r10,r10,lsr#2
	orr r10,r10,r10,lsr#1
	bic r10,r11,r10				@m10: bit 0 of each nibble is 1 iff p1 == p0
	eor r12,r4,r5				@w2 ^ w3
	orr r12,r12,r12,lsr#2
	orr r12,r12,r12,lsr#1
	bic r12,r11,r12				@m23: bit 0 of each nibble is 1 iff p2 == p3
	bic lr,r10,r12				@a = m10 & ~m23 (copy p2 -> p1)
	bic r12,r12,r10				@b = m23 & ~m10 (copy p1 -> p2)
	orr lr,lr,lr,lsl#1
	orr lr,lr,lr,lsl#2			@ma
	orr r12,r12,r12,lsl#1
	orr r12,r12,r12,lsl#2		@mb
	mov r10,r3
	bic r3,r3,lr
	and lr,r4,lr
	orr r3,r3,lr
	bic r4,r4,r12
	and r12,r10,r12
	orr r4,r4,r12
	str r3,[r0,#4]
	str r4,[r0,#8]
1:
	cmp r7,r8
	beq 2f
	eor r10,r7,r6				@w5 ^ w4
	orr r10,r10,r10,lsr#2
	orr r10,r10,r10,lsr#1
	bic r10,r11,r10				@m54
	eor r12,r8,r9				@w6 ^ w7
	orr r12,r12,r12,lsr#2
	orr r12,r12,r12,lsr#1
	bic r12,r11,r12				@m67
	bic lr,r10,r12				@a = m54 & ~m67
	bic r12,r12,r10				@b = m67 & ~m54
	orr lr,lr,lr,lsl#1
	orr lr,lr,lr,lsl#2			@ma
	orr r12,r12,r12,lsl#1
	orr r12,r12,r12,lsl#2		@mb
	mov r10,r7
	bic r7,r7,lr
	and lr,r8,lr
	orr r7,r7,lr
	bic r8,r8,r12
	and r12,r10,r12
	orr r8,r8,r12
	str r7,[r0,#20]
	str r8,[r0,#24]
2:
	add r0,r0,#32
	b scale_bg_tile_loop

scale_spr_tile_loop:
	cmp r0,r1
	bhs scale_spr_tiles_done
	ldmia r0,{r2-r9}			@r2..r9 = w0..w7
	orr r10,r2,r3
	orr r10,r10,r4
	orr r10,r10,r5
	orr r10,r10,r6
	orr r10,r10,r7
	orr r10,r10,r8
	orrs r10,r10,r9
	addeq r0,r0,#32
	beq scale_spr_tile_loop

	@Step 1: Outer Empty-Row Trimming
	orrs r10,r2,r3				@w0 == 0 && w1 == 0?
	bne 1f
	mov r2,r4
	mov r3,r5
	mov r4,r6
	mov r5,r7
	mov r6,r8
	mov r7,r9
	b scale_spr_store
1:
	orrs r10,r8,r9				@w6 == 0 && w7 == 0?
	beq scale_spr_store			@r2..r7 already hold w0..w5
	orrs r10,r2,r9				@w0 == 0 && w7 == 0?
	bne 2f
	mov r2,r3
	mov r3,r4
	mov r4,r5
	mov r5,r6
	mov r6,r7
	mov r7,r8
	b scale_spr_store
2:
	@Step 2a: Top half (w0..w3 in r2..r5) -> (s0..s2 in r2..r4)
	cmp r2,#0					@w0 == 0?
	moveq r2,r3
	moveq r3,r4
	moveq r4,r5
	beq 3f
	cmp r5,#0					@w3 == 0?
	beq 3f						@r2,r3,r4 stay w0,w1,w2
	cmp r3,#0					@w1 == 0?
	cmpne r3,r2					@w1 == w0?
	cmpne r3,r4					@w1 == w2?
	moveq r3,r4
	moveq r4,r5
	beq 3f
	cmp r4,#0					@w2 == 0?
	cmpne r4,r5					@w2 == w3?
	moveq r4,r5
	beq 3f
	@Compare pixel diff d(w0,w1) vs d(w2,w3)
	eor r10,r2,r3
	orr r10,r10,r10,lsr#1
	and r10,r10,r11
	add r10,r10,r10,lsr#4
	add r10,r10,r10,lsr#8
	add r10,r10,r10,lsr#16
	and r10,r10,#0xF
	eor lr,r4,r5
	orr lr,lr,lr,lsr#1
	and lr,lr,r11
	add lr,lr,lr,lsr#4
	add lr,lr,lr,lsr#8
	add lr,lr,lr,lsr#16
	and lr,lr,#0xF
	cmp r10,lr
	movle r3,r4
	mov r4,r5
3:
	@Step 2b: Bottom half (w4..w7 in r6..r9) -> (s3..s5 in r5..r7)
	cmp r9,#0					@w7 == 0?
	moveq r5,r6
	moveq r6,r7
	moveq r7,r8
	beq scale_spr_store
	cmp r6,#0					@w4 == 0?
	moveq r5,r7
	moveq r6,r8
	moveq r7,r9
	beq scale_spr_store
	cmp r8,#0					@w6 == 0?
	cmpne r8,r9					@w6 == w7?
	cmpne r8,r7					@w6 == w5?
	moveq r5,r6
	moveq r6,r7
	moveq r7,r9
	beq scale_spr_store
	cmp r7,#0					@w5 == 0?
	cmpne r7,r6					@w5 == w4?
	moveq r5,r6
	moveq r6,r8
	moveq r7,r9
	beq scale_spr_store
	@Compare pixel diff d(w6,w7) vs d(w4,w5)
	eor r10,r8,r9
	orr r10,r10,r10,lsr#1
	and r10,r10,r11
	add r10,r10,r10,lsr#4
	add r10,r10,r10,lsr#8
	add r10,r10,r10,lsr#16
	and r10,r10,#0xF
	eor lr,r6,r7
	orr lr,lr,lr,lsr#1
	and lr,lr,r11
	add lr,lr,lr,lsr#4
	add lr,lr,lr,lsr#8
	add lr,lr,lr,lsr#16
	and lr,lr,#0xF
	mov r5,r6
	cmp r10,lr
	movle r6,r7
	movgt r6,r8
	mov r7,r9

scale_spr_store:
	mov r8,#0
	cmp r12,#0
	bne 4f
	@8x8 mode: [0, s0, s1, s2, s3, s4, s5, 0]
	str r8,[r0],#4
	stmia r0!,{r2-r8}
	b scale_spr_tile_loop
4:
	@8x16 mode: even tile -> [0, 0, s0..s5], odd tile -> [s0..s5, 0, 0]
	mov r9,#0
	tst r0,#0x20
	bne 5f
	stmia r0!,{r8,r9}
	stmia r0!,{r2-r7}
	b scale_spr_tile_loop
5:
	stmia r0!,{r2-r9}
	b scale_spr_tile_loop

scale_spr_tiles_done:
	ldmfd sp!,{r0-r12,pc}
	.pool
	.popsection



.unreq decodeptr
.unreq tilecount
.unreq nesptr
.unreq agbptr
.unreq agbptr2
.unreq bankptr
.unreq dest0
.unreq dest1
.unreq dest2
.unreq pixels0
.unreq pixels1
.unreq nesword0
.unreq nesword1
.unreq nesword2
.unreq nesword3
.unreq mask

@----------------------------------------------------------------------------

@----------------------------------------------------------------------------

	.if RESET_ALL

 .align
 .pool
 .text
 .align
 .pool

erase_r1_to_r2:
	mov r0,r1
	sub r2,r2,r1
	mov r1,#0
	b memset32_
reset_all:
	stmfd sp!,{r4-r12,lr}
	
	@bl reset_buffers
	
	ldr globalptr,=GLOBAL_PTR_BASE	@need ptr regs init'd
	
	adrl_ r1,cpuregs
	adrl_ r2,nexttimeout+4
	bl erase_r1_to_r2
	
	adrl_ r1,vramaddr_dummy
	adrl_ r2,y_in_sprite0
	bl erase_r1_to_r2

	.if USE_BG_CACHE
	adrl_ r1,bg_cache_produce_cursor
	adrl_ r2,bg_cache_updateok+1
	bl erase_r1_to_r2
	.endif
	
	mov r3,#1
	strb_ r3,vramaddrinc
	
	adrl_ r1,mapperdata
	adrl_ r2,chrline_previous3+1
	bl erase_r1_to_r2

	adrl_ r1,reg_4000
	adrl_ r2,dmc_remaining_bits+4
	bl erase_r1_to_r2
	
	adrl_ r1,nesoamdirty
	adrl_ r2,firstframeready+1
	bl erase_r1_to_r2
	
	adrl_ r1,vram_map
	adrl_ r2,vram_map+32
	bl erase_r1_to_r2
	
	adrl_ r0,nes_palette
	ldr r1,=0x0F0F0F0F
	mov r2,#32
	bl memset32_

	adrl_ r1,screen_off
	adrl_ r2,suppress_vbl+1
	bl erase_r1_to_r2

	adrl_ r1,cycles_to_run
	adrl_ r2,_dontstop
	bl erase_r1_to_r2
	
	mov r0,#0
	str_ r0,bankbuffer_last
	str_ r0,bankbuffer_last+4
	strb_ r0,bankbuffer_line
	strb_ r0,ctrl1line
	ldr r1,=0x0440
	str_ r1,ctrl1old
	
	@reset self-modifying code for vram increment
	ldrb_ r0,ppuctrl0
	tst r0,#4
	moveq r1,#1
	movne r1,#32
	strb_ r1,vramaddrinc
	ldr r0,=vramaddrinc_modify1
	strb r1,[r0]
	ldr r0,=vramaddrinc_modify2
	strb r1,[r0]
	
	.if USE_BG_CACHE
	mov r0,#0
	bl set_bg_cache_produce_limit_consume_begin
	bl set_bg_cache_available
	.endif
	
	mov r0,#0xFFFFFF00
	str_ r0,ctrl1line
	str_ r0,scrollXline
	str_ r0,scrollYline
	str_ r0,bankbuffer_line
	
	ldmfd sp!,{r4-r12,lr}
	bx lr

reset_buffers:
	stmfd sp!,{r10,lr}
	ldr r10,=GLOBAL_PTR_BASE

	ldr r1,=0x04400440
	@clear dispcnt buffers
	ldr_ r0,dmadispcntbuff
	mov r2,#240*2
	bl memset32_
	ldr_ r0,dispcntbuff
	mov r2,#240*2
	bl memset32_
	mov r1,#0
	ldr_ r0,dmabg0cntbuff
	mov r2,#240*2
	bl memset32_
	ldr_ r0,bg0cntbuff
	mov r2,#240*2
	bl memset32_
	
	
	ldmfd sp!,{r10,lr}
	bx lr
	.endif


 .section .data.102, "w", %progbits

mapperstate:
	.skip 32	@mapperdata
	.skip 3     @padding
_bank6:
	.skip 1	@nes_prg_map
_bank8:
	.skip 1
_bankA:
	.skip 1
_bankC:
	.skip 1
_bankE:
	.skip 1



_Cbank0:
_nes_chr_map:
	.skip 8	@nes_chr_map	vrom paging map for NES VRAM $0000-1FFF
@ 16 bytes removed
_agb_bg_map:
	.word 0,0,0,0	@agb_bg_map		vrom paging map for AGB BG CHR
_agb_bg_map_requested:
	.word 0,0,0,0	@agb_bg_map_requested		coped at end of NES frame, real_bg_map derives from this
_agb_real_bg_map:
	.word 0,0,0,0	@agb_real_bg_map	what's actually sitting in VRAM
@ 8 bytes removed
	.byte 0,0,0,0	@bg_recent	AGB BG CHR group#s ordered by most recently used
romstart:
_rombase:
	.word 0 @rombase
romnum:
	.word 0 @romnumber
rominfo:                 @keep emuflags/BGmirror together for savestate/loadstate
_emuflags:	.byte 0 @emuflags        (label this so UI.C can take a peek) see equates.h for bitfields
_scaling:	.byte SCALED_SPRITES @(display type)
	.skip 2   @(sprite follow val)
_BGmirror:	.word 0 @BGmirror		(BG size for BG0CNT)

_rommask:
	.word 0 @rommask
_vrombase:
	.word 0 @vrombase
_vrommask:
	.word 0 @vrommask
_instant_prg_banks:
	.word 0 @instant_prg_banks
_instant_chr_banks:
	.word 0 @instant_chr_banks

_cartflags:
	.byte 0 @cartflags
_hackflags:
	.byte 0 @hackflags
_hackflags2:
	.byte 0 @hackflags2
_mapper_number:
	.byte 0 @mapper_number

_rompages:
	.byte 0 @rompages
_vrompages:
	.byte 0 @vrompages
_fourscreen:
	.byte 0 @fourscreen
	.byte 0

	.word 0 @chrold

_chrline: .byte 0 @chrline
_chrline_previous: .byte 0 @chrline_previous
_chrline_previous2: .byte 0 @chrline_previous2
_chrline_previous3:	.byte 0 @chrline_previous3

_twitch:	.byte 0
_flicker: .byte 1
@padding
	.byte 0,0
@padding:
	.word 0
_sprite_chr_map:	@for MMC5 (sprites use different mapping than backgrounds)
	.word _nes_chr_map

@----------------------------------------------------------------------------
	@.end
