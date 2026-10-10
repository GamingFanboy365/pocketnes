#include "../equates.h"

	.if LESSMAPPERS
	.else

 .align
 .pool
 .text
 .align
 .pool

#include "../6502mac.h"

	global_func mapper5init
	global_func mmc5_handler
	global_func mmc5_handler_2
	global_func mmc5_unpatch
	global_func mmc5_restore

@ MMC5 (mapper 5).  Emulated: PRG banking including RAM in $6000-$DFFF,
@ CHR banking (sets A and B), nametable mapping ($5105), ExRAM as RAM,
@ nametable or extended attributes ($5104), the scanline IRQ and the
@ multiplier.  Not emulated: split screen, fill mode, sound, and CHR bank
@ bits 8-9 outside extended attribute mode.

 counter = mapperdata+0
 enable = mapperdata+1
 prgsize = mapperdata+2
 chrsize = mapperdata+3
 prgpage0 = mapperdata+4	@$5114-$5117 (bit 7 set = ROM)
 prgpage1 = mapperdata+5
 prgpage2 = mapperdata+6
 prgpage3 = mapperdata+7

 chrpage0 = mapperdata+8	@$5120-$512B
 chrpage1 = mapperdata+9
 chrpage2 = mapperdata+10
 chrpage3 = mapperdata+11
 chrpage4 = mapperdata+12
 chrpage5 = mapperdata+13
 chrpage6 = mapperdata+14
 chrpage7 = mapperdata+15

 chrpage8 = mapperdata+16
 chrpage9 = mapperdata+17
 chrpage10 = mapperdata+18
 chrpage11 = mapperdata+19

 chrbank = mapperdata+20	@last CHR set written: 0 = A, 1 = B
 m5_exmode = mapperdata+21	@$5104
 mmc5mul1 = mapperdata+22
 mmc5mul2 = mapperdata+23
 m5_prgram = mapperdata+24	@$5113
 m5_ntmap = mapperdata+25	@$5105
 m5_chrhi = mapperdata+26	@$5130
 m5_ramslots = mapperdata+27	@RAM (not ROM) in: bit 0 $8000, bit 1 $A000, bit 2 $C000;
				@bits 4-6: that RAM is chip 0 (NES SRAM); bit 7: $6000 shows chip 1
 m5_prot = mapperdata+28	@bits 0-1 $5102, bits 2-3 $5103 (RAM writable when 2 and 1);
				@bit 7: writemem_6 is m5_w6x
 m5_ext = mapperdata+29		@1 while extended attributes are drawn

@ PRG RAM: MMC5 boards have up to two RAM chips, banks 0-3 on one and 4-7 on
@ the other (as in Mesen2, the first is the battery-backed one).  Chip 0 is
@ NES SRAM, so its battery saves work as before, also when a game maps it
@ into $8000-$DFFF; chip 1 is mmc5_mem, the 8KB NES_VRAM that CHR-ROM games
@ don't use (init_cache sets it; savestates include it).  Each chip holds
@ one 8KB bank (a 32KB chip isn't emulated).  Writes obey the $5102/$5103
@ write protection.
 EXT_HASH = BG_VRAM		@extended attribute tile cache: 2048 halfwords, slot+1 (0 = free),
 EXT_KEYS = BG_VRAM+0x1000	@and 1024 halfwords, the (4K bank << 8 | tile) in each slot.
				@In BG CHR group 0, which is unused while the cache is.
 EXT_SLOTS = 1024
 EXT_VRAM = BG_VRAM+0x8000	@GBA tiles for extended attributes: BG char blocks 2-3

@----------------------------------------------------------------------------
mapper5init:
@----------------------------------------------------------------------------
	.word m5_w8,m5_wA,m5_wC,void

	ldr r1,=write0
	str_ r1,writemem_4
	.if PRG_BANK_SIZE == 4
	str_ r1,writemem_5
	.endif

	ldr r1,=mmc5_r
	str_ r1,readmem_4
	.if PRG_BANK_SIZE == 4
	str_ r1,readmem_5
	.endif

	mov r0,#3
	strb_ r0,prgsize
	strb_ r0,chrsize

	mov r0,#0x7f
	strb_ r0,prgpage0
	strb_ r0,prgpage1
	strb_ r0,prgpage2
	strb_ r0,prgpage3

	mov r0,#0
	strb_ r0,chrbank
	strb_ r0,m5_exmode
	strb_ r0,m5_prgram
	strb_ r0,m5_ntmap
	strb_ r0,m5_chrhi
	strb_ r0,m5_ramslots
	strb_ r0,m5_ext
	strb_ r0,m5_prot
	@(sprite_chr_map starts at nes_chr_map; mmc5chr points it at m5_spr)

	mov pc,lr
@-------------------------------------------------------
write0:
@-------------------------------------------------------
	cmp addy,#0x5000
	blo_long IO_W
	cmp addy,#0x5100
	blo map5Sound
	cmp addy,#0x5200
	bge mmc5_200

	ands r2,addy,#0xff
	beq _00
	cmp r2,#0x01
	beq _01
	cmp r2,#0x02
	beq _02
	cmp r2,#0x03
	beq _03
	cmp r2,#0x04
	beq _04
	cmp r2,#0x05
	beq _05
	cmp r2,#0x13
	beq _13
	cmp r2,#0x14
	movlt pc,lr		@ get out.
	cmp r2,#0x17
	ble _17
	cmp r2,#0x20
	movlt pc,lr		@ get out.
	cmp r2,#0x2b
	ble _20
	cmp r2,#0x30
	beq _30
	mov pc,lr		@ get out.

_00:
	and r0,r0,#0x03
	strb_ r0,prgsize
	b mmc5prg
_01:
	and r0,r0,#0x03
	strb_ r0,chrsize
	b mmc5chr
_02:	@PRG RAM write protection
	and r0,r0,#0x03
	ldrb_ r1,m5_prot
	bic r1,r1,#0x03
	orr r1,r1,r0
	strb_ r1,m5_prot
	b m5_install6
_03:
	and r0,r0,#0x03
	ldrb_ r1,m5_prot
	bic r1,r1,#0x0C
	orr r1,r1,r0,lsl#2
	strb_ r1,m5_prot
	b m5_install6
_04:	@ExRAM mode: 1 = extended attributes
	and r0,r0,#0x03
	strb_ r0,m5_exmode
	cmp r0,#1
	beq mmc5_ext_on
	b mmc5_ext_off
_05:
	strb_ r0,m5_ntmap
	cmp r0,#0xA4		@castlevania 3 uses this value (from Dwedit's 2025 PocketNES)
	beq_long mirror2_
	b m5_ntmapping
_13:	@$6000 RAM bank
	strb_ r0,m5_prgram
	b m5_map6
_30:	@CHR bank bits 8-9 (used here by extended attributes only)
	and r0,r0,#3
	strb_ r0,m5_chrhi
	ldrb_ r1,m5_ext
	cmp r1,#0
	movne r0,#1
	strneb_ r0,bg_cache_full	@redraw with the new banks
	mov pc,lr

_14:
_15:
_16:
_17:
	sub r2,r2,#0x14
	adrl_ r1,prgpage0
	strb r0,[r1,r2]
@-------------------------------------------------------
mmc5prg:	@remap PRG after a $5100 or $5114-$5117 write
@-------------------------------------------------------
	stmfd sp!,{lr}
	ldrb_ r1,prgsize
	cmp r1,#0x00
	bne 1f
	ldrb_ r0,prgpage3	@32K at $8000: $5117
	mov r0,r0,lsr#2
	bl_long map89ABCDEF_
	b 9f
1:
	cmp r1,#0x01
	bne 2f
	ldrb_ r0,prgpage1	@16K at $8000: $5115, 16K at $C000: $5117
	bl_long map89AB_rshift_
	ldrb_ r0,prgpage3
	bl_long mapCDEF_rshift_
	b 9f
2:
	cmp r1,#0x02
	bne 3f
	ldrb_ r0,prgpage1	@16K at $8000: $5115, 8K: $5116, $5117
	bl_long map89AB_rshift_
	ldrb_ r0,prgpage2
	bl_long mapCD_
	ldrb_ r0,prgpage3
	bl_long mapEF_
	b 9f
3:
	ldrb_ r0,prgpage0	@8K banks: $5114-$5117
	bl_long map89_
	ldrb_ r0,prgpage1
	bl_long mapAB_
	ldrb_ r0,prgpage2
	bl_long mapCD_
	ldrb_ r0,prgpage3
	bl_long mapEF_
9:
	bl m5_prg_ram		@RAM slots replace the ROM banks just mapped
	ldmfd sp!,{lr}
	ldr_ r1,lastbank	@(flush: the PC's bank may now be RAM)
	sub m6502_pc,m6502_pc,r1
	encodePC
	bx lr

@-------------------------------------------------------
m5_prg_ram:	@point the $8000-$DFFF slots that select RAM at it.  Changes r0-r2.
@-------------------------------------------------------
	stmfd sp!,{r3,lr}
	mov r3,#0		@RAM slot bits
	ldrb_ r1,prgsize
	cmp r1,#1
	blo 9f			@32K mode: ROM only
	cmp r1,#3
	beq 3f
	@16K at $8000 ($5115), then in mode 2 8K at $C000 ($5116)
	ldrb_ r0,prgpage1
	bic r0,r0,#1
	mov r1,#0
	bl ram8k
	ldrb_ r0,prgpage1
	orr r0,r0,#1
	mov r1,#1
	bl ram8k
	ldrb_ r1,prgsize
	cmp r1,#2
	bne 9f
	ldrb_ r0,prgpage2
	mov r1,#2
	bl ram8k
	b 9f
3:
	ldrb_ r0,prgpage0
	mov r1,#0
	bl ram8k
	ldrb_ r0,prgpage1
	mov r1,#1
	bl ram8k
	ldrb_ r0,prgpage2
	mov r1,#2
	bl ram8k
9:
	ldrb_ r0,m5_ramslots
	and r0,r0,#0x80
	orr r0,r0,r3
	strb_ r0,m5_ramslots
	ldmfd sp!,{r3,pc}

ram8k:	@r0 = $5114-$5116 value, r1 = slot (0 $8000, 1 $A000, 2 $C000).  If
	@bit 7 is clear, map RAM there and set the slot's bits in r3.  Changes r0-r2.
	tst r0,#0x80
	bxne lr
	mov r2,#1
	orr r3,r3,r2,lsl r1
	stmfd sp!,{r1,lr}
	bl m5_ram_ptr
	ldmfd sp!,{r1,lr}
	ldr r2,=NES_RAM+0x800
	cmp r0,r2
	moveq r2,#0x10
	orreq r3,r3,r2,lsl r1	@chip 0: writes go through the SRAM handler
	cmp r1,#1
	blo 0f
	beq 1f
	sub r0,r0,#0xC000
	str_ r0,memmap_C
	bx lr
0:
	sub r0,r0,#0x8000
	str_ r0,memmap_8
	bx lr
1:
	sub r0,r0,#0xA000
	str_ r0,memmap_A
	bx lr

m5_ram_ptr:	@r0 = RAM bank number -> r0 = address of that chip's 8KB.  Changes r1.
	tst r0,#4
	ldrne r1,=mmc5_mem
	ldrne r0,[r1]
	cmpne r0,#0
	ldreq r0,=NES_RAM+0x800	@chip 0 (or no EWRAM for chip 1): NES SRAM
	bx lr

@-------------------------------------------------------
m5_map6:	@$6000-$7FFF: chip 0 (NES SRAM, the normal handlers) or chip 1.  Changes r0-r2.
@-------------------------------------------------------
	ldrb_ r0,m5_prgram
	stmfd sp!,{lr}
	bl m5_ram_ptr
	ldmfd sp!,{lr}
	ldr r1,=NES_RAM+0x800
	ldrb_ r2,m5_ramslots
	cmp r0,r1
	bne 1f
	tst r2,#0x80
	bxeq lr
	bic r2,r2,#0x80
	strb_ r2,m5_ramslots
	ldr r0,=NES_RAM-0x5800
	str_ r0,memmap_6
	ldr r0,=sram_R
	str_ r0,readmem_6
	bx lr
1:
	orr r2,r2,#0x80
	strb_ r2,m5_ramslots
	sub r0,r0,#0x6000
	str_ r0,memmap_6
	ldr r0,=m5_r6
	str_ r0,readmem_6
m5_install6:	@writemem_6 = m5_w6x, keeping the original.  Changes r1, r2.
	ldrb_ r1,m5_prot
	tst r1,#0x80
	bxne lr
	orr r1,r1,#0x80
	strb_ r1,m5_prot
	ldr_ r1,writemem_6	@sram_W, or sram_W2 for battery saves
	ldr r2,=m5_w6_orig
	str r1,[r2]
	ldr r1,=m5_w6x
	str_ r1,writemem_6
	bx lr

m5_r6:	@$6000-$7FFF read from chip 1
	ldr_ r1,memmap_6
	ldrb r0,[r1,addy]
	bx lr
m5_w6x:	@$6000-$7FFF write
	ldrb_ r1,m5_prot
	and r1,r1,#0x0F
	cmp r1,#6
	bxne lr			@write protected
	ldrb_ r1,m5_ramslots
	tst r1,#0x80
	ldreq r1,=m5_w6_orig
	ldreq pc,[r1]		@chip 0: the SRAM handler
	ldr_ r1,memmap_6
	strb r0,[r1,addy]
	bx lr

	@$8000-$DFFF writes: RAM if $5114-$5116 selects it, else nothing
 .macro m5_wslot bit, memmap
	ldrb_ r1,m5_ramslots
	tst r1,#\bit
	bxeq lr
	ldrb_ r2,m5_prot
	tst r2,#0x80
	beq 1f
	and r2,r2,#0x0F
	cmp r2,#6
	bxne lr			@write protected
1:
	tst r1,#\bit<<4
	bne m5_wsram
	ldr_ r1,\memmap
	strb r0,[r1,addy]
	bx lr
 .endm
m5_w8:	m5_wslot 1, memmap_8
m5_wA:	m5_wslot 2, memmap_A
m5_wC:	m5_wslot 4, memmap_C
m5_wsram:	@chip 0 in $8000-$DFFF: write through the $6000 handler (battery saves)
	mov addy,addy,lsl#19
	mov addy,addy,lsr#19
	orr addy,addy,#0x6000
	ldrb_ r1,m5_prot
	tst r1,#0x80
	ldreq_ pc,writemem_6
	ldr r1,=m5_w6_orig
	ldr pc,[r1]
	.pool

@-------------------------------------------------------
m5_ntmapping:	@$5105: each nametable from CIRAM page 0/1, ExRAM (2) or fill mode (3)
@-------------------------------------------------------
	@Builds a mirroring table like cart.s's m0000..m0123: BG layout word,
	@4 read pointers, 4 write handlers.  The GBA can only show 2x2 screens
	@in order, so the layout comes from the pages at $2000 and $2400/$2800:
	@side by side if $2400 shows the next page, one above the other if
	@$2800 does, else the $2000 page alone.  SimCity's $08 (ExRAM at $2400)
	@shows $2000; its $24/$84 (ExRAM at $2800/$2C00) show $2000 and $2400.
	@Fill mode is not emulated (page 3 is RAM).
	stmfd sp!,{r3-r6,lr}
	ldr r6,=m5_mtab
	mov r3,#0
0:
	mov r1,r0,lsr r3
	and r1,r1,#3		@page of nametable r3/2
	adr r2,m5_ntptrs
	ldr r2,[r2,r1,lsl#2]
	add r4,r6,#4
	str r2,[r4,r3,lsl#1]
	adr r2,m5_nthandlers
	ldr r2,[r2,r1,lsl#2]
	add r4,r6,#20
	str r2,[r4,r3,lsl#1]
	add r3,r3,#2
	cmp r3,#8
	bne 0b
	@layout: r1-r4 = pages of nametables 0-3
	and r1,r0,#3
	mov r2,r0,lsr#2
	and r2,r2,#3
	mov r3,r0,lsr#4
	and r3,r3,#3
	mov r4,r0,lsr#6
	add r5,r1,#0x0C		@screen base block of nametable 0
	mov r5,r5,lsl#8
	orr r5,r5,#0x02
	cmp r0,#0xE4
	orreq r5,r5,#0xC000	@four screen
	beq 9f
	add r0,r1,#1
	cmp r2,r0
	orreq r5,r5,#0x4000	@$2400 = next page: side by side (vertical mirroring)
	beq 9f
	cmp r3,r0
	orreq r5,r5,#0x8000	@$2800 = next page: one above the other
9:
	str r5,[r6]
	mov r0,r6
	ldmfd sp!,{r3-r6,lr}
	b_long mirrorchange

m5_ntptrs:	.word NES_VRAM2+0x0000,NES_VRAM2+0x0400,NES_VRAM4+0x0000,NES_VRAM4+0x0400
m5_nthandlers:	.word VRAM_name0,VRAM_name1,VRAM_name2,VRAM_name3

_20:				@$5120-$5127: set A
_21:
_22:
_23:
_24:
_25:
_26:
_27:
_28:				@$5128-$512B: set B
_29:
_2a:
_2b:
	adrl_ r1,chrpage0
	sub r2,r2,#0x20
	strb r0,[r1,r2]
	cmp r2,#8
	movlo r0,#0
	movhs r0,#1
	strb_ r0,chrbank	@last set written
@-------------------------------------------------------
mmc5chr:	@remap CHR after a $5101 or $5120-$512B write
@-------------------------------------------------------
	@Like Mesen: with 8x16 sprites, sprites use set A and the background
	@set B; with 8x8 sprites, both use the last set written.  Sprites get
	@their own page list (m5_spr) when they differ (from Dwedit's 2025
	@PocketNES, here also for 2K/4K/8K modes and CHR over 256K).  With
	@extended attributes on, the background ignores these banks, and only
	@the sprite list is updated.
	stmfd sp!,{r3-r6,lr}
	ldrb_ r0,chrsize
	rsb r4,r0,#3		@r4 = page shift: 8K 3, 4K 2, 2K 1, 1K 0
	mov r5,#1
	mov r5,r5,lsl r4
	sub r5,r5,#1		@r5 = 1K pages per bank - 1
	ldrb_ r2,ppuctrl0
	tst r2,#0x20
	ldreqb_ r6,chrbank	@sprite set: 8x8 the last set written, 8x16 set A
	movne r6,#0
	ldrb_ r1,m5_ext
	cmp r1,#0
	bne 1f			@extended attributes: sprites only
	tst r2,#0x20
	beq 4f			@8x8: background and sprites from the same set
1:
	@sprites from set r6 into m5_spr
	mov r3,#0
0:
	bl chr_page
	bl_long chr_page_number
	ldr r1,=m5_spr
	strb r0,[r1,r3]
	add r3,r3,#1
	cmp r3,#8
	bne 0b
	ldr r0,=m5_spr
	str_ r0,sprite_chr_map
	ldrb_ r1,m5_ext
	cmp r1,#0
	moveq r6,#1		@8x16: background from set B
	beq 5f
	bl m5_cpu_chr
	stmfd sp!,{addy}
	bl_long update_bankbuffer	@(changes r3-r5)
	ldmfd sp!,{addy}
	ldmfd sp!,{r3-r6,pc}
4:
	adrl_ r0,nes_chr_map
	str_ r0,sprite_chr_map
5:
	mov r3,#0
0:
	bl chr_page
	adr r1,writeCHRTBL_5
	mov lr,pc
	ldr pc,[r1,r3,lsl#2]
	add r3,r3,#1
	cmp r3,#8
	bne 0b
	bl m5_cpu_chr
	ldmfd sp!,{r3-r6,pc}

m5_cpu_chr:	@vram_map, which $2007 and the sprite 0 check read CHR through: the set
	@written last, as for MMC5 accesses outside rendering (SimCity unpacks
	@its maps from CHR ROM this way).  r4, r5 as in mmc5chr.  Changes r0-r3, r6.
	stmfd sp!,{lr}
	ldrb_ r6,chrbank
	mov r3,#0
0:
	bl chr_page
	bl_long chr_page_number
	ldr_ r1,instant_chr_banks
	ldr r0,[r1,r0,lsl#2]
	adrl_ r1,vram_map
	str r0,[r1,r3,lsl#2]
	add r3,r3,#1
	cmp r3,#8
	bne 0b
	ldmfd sp!,{pc}

chr_page:	@r3 = PPU 1K slot, r6 = set (0 A, 1 B) -> r0 = 1K CHR page.  Changes r1.
	orr r1,r3,r5
	cmp r6,#0
	andne r1,r1,#3		@set B covers 4K, repeated for $1000-$1FFF
	addne r1,r1,#8
	adrl_ r0,chrpage0
	ldrb r0,[r0,r1]
	and r1,r3,r5
	add r0,r1,r0,lsl r4
	mov pc,lr

writeCHRTBL_5:	.word chr0_,chr1_,chr2_,chr3_,chr4_,chr5_,chr6_,chr7_
	.pool

map5Sound:
	mov pc,lr
@-------------------------------------------------------
mmc5_200:
	cmp addy,#0x5C00
	bhs exram_w
	ldr r2,=0x5207		@only $5203-$5206 below are registers
	cmp addy,r2
	movhs pc,lr
	and r2,addy,#0xff
	cmp r2,#0x03
	beq setCounter

	cmp r2,#0x04
	beq setEnIrq

	cmp r2,#0x05
	streqb_ r0,mmc5mul1
	moveq pc,lr

	cmp r2,#0x06
	streqb_ r0,mmc5mul2
	mov pc,lr

setEnIrq:
	ands r0,r0,#0x80
	strb_ r0,enable
	
	ldreqb_ r0,wantirq
	biceq r0,r0,#IRQ_MAPPER
	streqb_ r0,wantirq
	
	b find_mmc5_irq
setCounter:
	strb_ r0,counter
	b find_mmc5_irq

@-------------------------------------------------------
mmc5_r:		@5204,5205,5206, ExRAM
	cmp addy,#0x5200
	blo_long IO_R
	cmp addy,#0x5C00
	bhs exram_r
	ldr r2,=0x5207
	cmp addy,r2
	movhs r0,#0xff
	movhs pc,lr
	and r2,addy,#0xff
	cmp r2,#0x04
	beq MMC5IRQR
	cmp r2,#0x05
	beq MMC5MulA
	cmp r2,#0x06
	beq MMC5MulB

	mov r0,#0xff
	mov pc,lr

MMC5IRQR:
	@Acknowledge IRQ
	ldrb_ r0,wantirq
	tst r0,#IRQ_MAPPER
	bic r0,r0,#IRQ_MAPPER
	strb_ r0,wantirq
	
	mov r0,#0
	orrne r0,r0,#0x80
	@return 0x80 if we acknowledged an IRQ
	
	@Return 0x40 if PPU is rendering
	ldr_ r1,timestamp
	ldr_ r2,cycles_to_run
	sub r2,r2,cycles,asr#CYC_SHIFT
	add r1,r1,r2
	ldr_ r2,frame_timestamp
	sub r1,r1,r2
	
	ldr_ addy,timestamp_div
	umull r2,addy,r1,addy
	cmp r2,#0xC0000000
	orrlo r0,r0,#0x40
	cmp addy,#241
	bichi r0,r0,#0x40

	mov pc,lr

MMC5MulA:
	ldrb_ r1,mmc5mul1
	ldrb_ r2,mmc5mul2
	mul r0,r1,r2
	and r0,r0,#0xff
	mov pc,lr
MMC5MulB:
	ldrb_ r1,mmc5mul1
	ldrb_ r2,mmc5mul2
	mul r0,r1,r2
	mov r0,r0,lsr#8
	mov pc,lr

	@ExRAM ($5C00-$5FFF): 1K at NES_VRAM4, the page the nametable mapping
	@calls 2.  In modes 0 and 1 it holds nametable or attribute data, so
	@writes go through VRAM_name2, which queues the redraw; mode 2 is plain
	@RAM (Metal Slader Glory), mode 3 is read-only.
exram_w:
	ldrb_ r1,m5_exmode
	cmp r1,#2
	blo_long VRAM_name2
	bxne lr
	ldr r1,=NES_VRAM4-0x5C00
	strb r0,[r1,addy]
	mov pc,lr
exram_r:
	ldr r1,=NES_VRAM4-0x5C00
	ldrb r0,[r1,addy]
	mov pc,lr
	.pool

@----------------------------------------------------------------------------
@ Extended attributes ($5104 = 1): each background tile takes its palette
@ (bits 6-7) and a 4K CHR bank (bits 0-5, plus $5130 as bits 6-7) from the
@ ExRAM byte at its nametable offset, instead of the attribute table and
@ the CHR bank registers.  SimCity uses this on every screen.
@
@ PocketNES normally shows one 4K CHR set at a time from GBA char blocks
@ 0-3.  Here, tiles are cached one by one: each (4K bank, tile) gets one of
@ 1024 GBA tiles in char blocks 2-3 the first time it is drawn, and the map
@ entries point at those.  A hash table (EXT_HASH) finds the cached tiles.
@ When all 1024 are used, the cache is emptied and the screen redrawn.
@ The normal BG CHR cache is told that group 2 holds a CHR set nothing else
@ asks for (pages $FE), so it keeps the BG char base at block 2 and never
@ loads anything over these tiles or the hash table in group 0, and
@ display_bg is patched to jump to ext_display_bg, which builds the map
@ entries.
@----------------------------------------------------------------------------
mmc5_ext_on:
	ldrb_ r1,m5_ext
	cmp r1,#0
	bxne lr
	stmfd sp!,{r3-r5,addy,lr}
	ldr r4,=REG_BASE+REG_IME
	ldrh r5,[r4]
	mov r0,#0
	strh r0,[r4]

	mov r0,#1
	strb_ r0,m5_ext
	@the normal BG CHR cache: group 2 = pages $FE, the rest empty
	ldr r0,=0xFEFEFEFE
	str_ r0,nes_chr_map
	str_ r0,nes_chr_map+4
	str_ r0,chrold
	mvn r1,#0
	adrl_ r2,agb_bg_map	@agb_bg_map, agb_bg_map_requested, agb_real_bg_map
	mov r3,#3
0:
	str r1,[r2],#4
	str r1,[r2],#4
	str r0,[r2],#4
	str r1,[r2],#4
	subs r3,r3,#1
	bne 0b
	ldr r0,=0x0C040008	@group 2 most recent
	str_ r0,bg_recent
	bl m5_flush_tiles
	ldr r0,=m5_whole
	mov r1,#0
	str r1,[r0]
	mov r0,#1
	strb_ r0,bg_cache_full	@draw everything
	ldr r0,=display_bg
	ldr r1,=0xE51FF004	@ldr pc,[pc,#-4]
	ldr r2,=ext_display_bg
	stmia r0,{r1,r2}

	strh r5,[r4]
	bl mmc5chr		@sprite banks
	ldmfd sp!,{r3-r5,addy,pc}

mmc5_ext_off:
	ldrb_ r1,m5_ext
	cmp r1,#0
	bxeq lr
	stmfd sp!,{r3-r5,addy,lr}
	ldr r4,=REG_BASE+REG_IME
	ldrh r5,[r4]
	mov r0,#0
	strh r0,[r4]

	strb_ r0,m5_ext
	bl mmc5_unpatch
	@empty the normal BG CHR cache, so the next request loads its tiles
	mvn r1,#0
	adrl_ r2,agb_bg_map
	mov r3,#12
0:
	str r1,[r2],#4
	subs r3,r3,#1
	bne 0b
	str_ r1,chrold
	@the map entries hold extended attribute tile numbers: clear them
	ldr r0,=AGB_BG
	mov r1,#0
	mov r2,#0x2000
	bl_long memset32
	mov r0,#1
	strb_ r0,bg_cache_full

	strh r5,[r4]
	bl mmc5chr		@normal BG and sprite banks
	ldmfd sp!,{r3-r5,addy,pc}

mmc5_unpatch:	@put display_bg back.  Changes r0-r2.  (cart.s calls this for every game)
	ldr r0,=display_bg
	adr r1,display_bg_start
	ldmia r1,{r1,r2}
	stmia r0,{r1,r2}
	bx lr
display_bg_start:	@display_bg's first two instructions
	ldrb_ r0,bg_cache_updateok
	movs r0,r0

m5_flush_tiles:	@empty the extended attribute tile cache.  Changes r0-r2, r12.
	ldr r0,=m5_nextslot
	mov r1,#0
	str r1,[r0]
	ldr r0,=EXT_HASH
	mov r2,#0x1000
	b_long memset32
	.pool

@----------------------------------------------------------------------------
ext_display_bg:	@display_bg while extended attributes are on (GBA vblank)
@----------------------------------------------------------------------------
	ldrb_ r0,bg_cache_updateok
	movs r0,r0
	bxeq lr
	mov r0,#0
	strb_ r0,bg_cache_updateok
	stmfd sp!,{r4-r9,r11,lr}
	ldrb_ r0,bg_cache_full
	movs r0,r0
	bne ext_whole_map

	@queued nametable writes (offset | page << 10)
	ldr_ r6,bg_cache_produce_limit_consume_begin
	ldr_ r7,bg_cache_produce_base_consume_end
	ldr r8,=BG_CACHE
0:
	cmp r6,r7
	beq 2f
	ldrh r9,[r8,r6]
	add r6,r6,#2
	bic r6,r6,#BG_CACHE_SIZE
	bic r1,r9,#0xFC00
	cmp r1,#0x3C0
	bhs 0b			@attribute tables aren't used
	and r0,r9,#0xC00
	cmp r0,#0x800
	bhi 0b			@page 3 isn't shown
	beq 1f
	mov r0,r0,lsr#10
	bl ext_tile		@CIRAM page 0 or 1
	b 0b
1:	@ExRAM: the tile at this offset on both CIRAM pages
	mov r0,#0
	bic r1,r9,#0xFC00
	bl ext_tile
	mov r0,#1
	bic r1,r9,#0xFC00
	bl ext_tile
	b 0b
2:
	mov r0,r6
	bl_long set_bg_cache_produce_limit_consume_begin
	ldmfd sp!,{r4-r9,r11,pc}

ext_whole_map:	@like display_whole_map
	mov r0,#0
	str_ r0,bg_cache_produce_cursor
	str_ r0,bg_cache_produce_base_consume_end
	bl_long set_bg_cache_produce_limit_consume_begin
	bl_long set_bg_cache_available
	ldr r6,=m5_whole
	mov r0,#1
	strb r0,[r6]
	mov r7,#0		@page
1:
	mov r8,#0		@offset
0:
	mov r0,r7
	mov r1,r8
	bl ext_tile
	add r8,r8,#1
	cmp r8,#0x3C0
	bne 0b
	add r7,r7,#1
	cmp r7,#2
	bne 1b
	mov r0,#0
	strb r0,[r6]
	ldmfd sp!,{r4-r9,r11,pc}

ext_tile:	@r0 = CIRAM page (0/1), r1 = offset: write the GBA map entry.
	@Changes r0-r5, r11, r12.
	stmfd sp!,{lr}
	ldr r2,=NES_VRAM2
	add r2,r2,r0,lsl#10
	ldrb r3,[r2,r1]		@tile number
	ldr r2,=NES_VRAM4
	ldrb r4,[r2,r1]		@ExRAM: palette, 4K bank
	ldr r2,=AGB_BG
	add r2,r2,r0,lsl#11
	add r5,r2,r1,lsl#1
	and r0,r4,#0x3F
	ldrb_ r2,m5_chrhi
	orr r0,r0,r2,lsl#6
	orr r0,r3,r0,lsl#8	@key = 4K bank << 8 | tile
	bl ext_slot
	mov r4,r4,lsr#6
	orr r0,r0,r4,lsl#12
	strh r0,[r5]
	ldmfd sp!,{pc}

ext_slot:	@r0 = key -> r0 = GBA tile number, rendering it if new.
	@Changes r1-r3, r11, r12 (and r4, r5 while rendering, saved here).
	ldr r12,=EXT_HASH
	ldr r1,=0x9E37
	mul r2,r0,r1
	mov r2,r2,lsl#16
	mov r2,r2,lsr#21	@11-bit hash
0:
	add r3,r12,r2,lsl#1
	ldrh r1,[r3]
	cmp r1,#0
	beq 1f			@not cached
	sub r1,r1,#1
	add r11,r12,#EXT_KEYS-EXT_HASH
	add r11,r11,r1,lsl#1
	ldrh r11,[r11]
	cmp r11,r0
	moveq r0,r1
	bxeq lr
	add r2,r2,#1
	mov r2,r2,lsl#21
	mov r2,r2,lsr#21
	b 0b
1:
	ldr r11,=m5_nextslot
	ldr r1,[r11]
	cmp r1,#EXT_SLOTS
	bhs 2f
	add r2,r1,#1
	str r2,[r11]
	strh r2,[r3]		@hash entry = slot + 1
	add r11,r12,#EXT_KEYS-EXT_HASH
	add r11,r11,r1,lsl#1
	strh r0,[r11]
	stmfd sp!,{r1,r4,r5,lr}
	bl ext_render
	ldmfd sp!,{r0,r4,r5,pc}
2:	@cache full: empty it.  The tiles already on screen now point at
	@slots that will be reused, so redraw everything (unless this is
	@the whole-map redraw already, which would never finish)
	stmfd sp!,{r0,lr}
	bl m5_flush_tiles
	ldr r1,=m5_whole
	ldrb r1,[r1]
	cmp r1,#0
	moveq r1,#1
	streqb_ r1,bg_cache_full
	ldmfd sp!,{r0,lr}
	b ext_slot

ext_render:	@r0 = key, r1 = slot: convert the NES tile to GBA 4bpp.
	@Changes r0-r5, r12.
	mov r2,r0,lsr#6		@1K page = 4K bank * 4 + tile / 64
	ldr_ r3,vrommask
	and r2,r2,r3,lsr#10
	ldr r3,=bigchr_patched	@CHR over 256K: real pages from bigchr_base
	ldrb r3,[r3]
	cmp r3,#1
	ldreq r3,=bigchr_base
	ldreq r3,[r3]
	addeq r3,r3,r2,lsl#10
	ldrne_ r3,instant_chr_banks
	ldrne r3,[r3,r2,lsl#2]
	and r0,r0,#0x3F
	add r3,r3,r0,lsl#4	@NES tile: 16 bytes
	ldr r4,=EXT_VRAM
	add r4,r4,r1,lsl#5	@GBA tile: 32 bytes
	ldr r5,=CHR_DECODE
	mov r12,#8
0:
	ldrb r0,[r3,#8]		@second plane
	ldrb r2,[r3],#1		@first plane
	ldr r0,[r5,r0,lsl#2]
	ldr r2,[r5,r2,lsl#2]
	orr r2,r2,r0,lsl#1
	str r2,[r4],#4
	subs r12,r12,#1
	bne 0b
	bx lr
	.pool

@----------------------------------------------------------------------------
mmc5_restore:	@after a savestate loads (from C): redo what the registers set
@----------------------------------------------------------------------------
	stmfd sp!,{r3-r11,lr}
	ldr globalptr,=GLOBAL_PTR_BASE
	bl mmc5_unpatch
	mov r0,#0
	strb_ r0,m5_ext
	ldrb_ r0,m5_ramslots
	bic r0,r0,#0x80		@$6000 handlers are the defaults again
	strb_ r0,m5_ramslots
	ldrb_ r0,m5_prot
	bic r0,r0,#0x80
	strb_ r0,m5_prot
	bl m5_install6
	ldrb_ r0,m5_ntmap
	cmp r0,#0xA4
	bne 0f
	bl_long mirror2_
	b 1f
0:
	bl m5_ntmapping
1:
	bl m5_prg_ram
	bl m5_map6
	ldrb_ r0,m5_exmode
	cmp r0,#1
	bne 2f
	bl mmc5_ext_on
	b 3f
2:
	bl mmc5chr
3:
	ldmfd sp!,{r3-r11,lr}
	bx lr
	.pool

mmc5_handler_2: @disable IRQ automatically if it reaches the next scanline after an IRQ
	ldrb_ r0,wantirq
	bic r0,r0,#IRQ_MAPPER
	strb_ r0,wantirq
0:	
	bl find_mmc5_irq
	b_long _GO
	
mmc5_handler:
	ldrb_ r0,enable
	tst r0,#0x80
	beq_long _GO
	
	ldrb_ r0,screen_off
	movs r0,r0
	bne 0b
	
	ldr_ r1,mapper_timestamp
	add r1,r1,#12
	ldr r0,=mapper_irq_handler
	adrl_ r12,mapper_irq_timeout
	bl_long replace_timeout_2
	
	ldr_ r1,mapper_timestamp
	ldr_ r0,timestamp_mult
	add r1,r1,r0,lsr#4
	adr r0,mmc5_handler_2
	adrl_ r12,mapper_timeout
	bl_long replace_timeout_2
	b_long _GO

	
find_mmc5_irq:
	ldrb_ r0,enable
	tst r0,#0x80
	bxeq lr
	ldrb_ r0,counter
	movs r0,r0
	bxeq lr
	cmp r0,#0xF0
	bxge lr
	
	add r0,r0,#1
	
	ldr_ r1,timestamp_mult
	mul r1,r0,r1
	ldr_ r0,frame_timestamp
	add r1,r0,r1,lsr#4
	sub r1,r1,#12
	
	@if target timestamp is BEFORE now, add xxxxx to the target timestamp
	ldr_ r0,cycles_to_run
	sub r0,r0,cycles,asr#CYC_SHIFT
	ldr_ r2,timestamp
	add r2,r2,r0
	
	@target timestamp BEFORE now?
	cmp r1,r2
	ldrmi_ r0,cyclesperframe
	addmi r1,r1,r0
	
	adr r0,mmc5_handler
	adrl_ r12,mapper_timeout
	b_long replace_timeout_2

@-------------------------------------------------------
	.pool

 .section .sbss, "aw", %nobits
 .align 2
m5_spr:		.space 8	@sprite 1K pages when they differ from the background
m5_mtab:	.space 36	@nametable mapping table for mirrorchange
m5_w6_orig:	.space 4	@the $6000 write handler m5_w6x replaced
m5_nextslot:	.space 4	@extended attribute tiles in use
m5_whole:	.space 4	@1 during ext_whole_map

	.endif
	
	@.end
