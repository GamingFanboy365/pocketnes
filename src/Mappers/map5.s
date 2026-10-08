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
@	global_func mapper_5_hook
	global_func mmc5_handler
	global_func mmc5_handler_2

 counter = mapperdata+0
 enable = mapperdata+1
 prgsize = mapperdata+2
 chrsize = mapperdata+3
 prgpage0 = mapperdata+4
 prgpage1 = mapperdata+5
 prgpage2 = mapperdata+6
 prgpage3 = mapperdata+7

 chrpage0 = mapperdata+8
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

 chrbank = mapperdata+20
 m5mirror = mapperdata+21
 mmc5mul1 = mapperdata+22
 mmc5mul2 = mapperdata+23
 m5_spr = mapperdata+24	@8 bytes: sprite 1K pages when they differ from the background
@----------------------------------------------------------------------------
mapper5init:
@----------------------------------------------------------------------------
	.word void,void,void,void

	adr r1,write0
	str_ r1,writemem_4
	.if PRG_BANK_SIZE == 4
	str_ r1,writemem_5
	.endif

	adr r1,mmc5_r
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

@	adr r0,mapper_5_hook
@	str_ r0,scanlinehook

	mov r0,#0
	strb_ r0,chrbank
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
	cmp r2,#0x05
	beq _05
	cmp r2,#0x14
	movlt pc,lr		@ get out.
	cmp r2,#0x17
	ble _17
	cmp r2,#0x20
	movlt pc,lr		@ get out.
	cmp r2,#0x27
	ble _20
	cmp r2,#0x2b
	ble _28
	mov pc,lr		@ get out.

_00:
	and r0,r0,#0x03
	strb_ r0,prgsize
	b mmc5prg
_01:
	and r0,r0,#0x03
	strb_ r0,chrsize
	b mmc5chr
_05:
	strb_ r0,m5mirror
	cmp r0,#0x55
	beq_long mirror5_1
	cmp r0,#0
	beq_long mirror5_1
	cmp r0,#0xE4
	beq_long mirror4_
	cmp r0,#0xAA
	cmpne r0,#0xA4   @castlevania 3 uses this value (from Dwedit's 2025 PocketNES)
	beq_long mirror2_
	eor r1,r0,r0,lsr#4
	ands r1,r1,#0x0C
	b_long mirror2V_
@	b_long mirrorKonami_


mirror5_1:
	cmp r0,#0
	b_long mirror1_

_14:
_15:
_16:
_17:
	sub r2,r2,#0x14
	adrl_ r1,prgpage0
	strb r0,[r1,r2]
mmc5prg:
	ldrb_ r1,prgsize
	cmp r1,#0x00
	bne not0
	ldrb_ r0,prgpage1
	mov r0,r0,lsr#2
	b_long map89ABCDEF_
not0:
	str lr,[sp,#-4]!
	cmp r1,#0x01
	bne not1
	ldrb_ r0,prgpage1
	bl_long map89AB_rshift_
	ldrb_ r0,prgpage3
	ldr lr,[sp],#4
	b_long mapCDEF_rshift_
not1:
	cmp r1,#0x02
	bne not2
	ldrb_ r0,prgpage1
	bl_long map89AB_rshift_
	ldrb_ r0,prgpage2
	bl_long mapCD_
	ldrb_ r0,prgpage3
	ldr lr,[sp],#4
	b_long mapEF_
not2:
	ldrb_ r0,prgpage0
	bl_long map89_
	ldrb_ r0,prgpage1
	bl_long mapAB_
	ldrb_ r0,prgpage2
	bl_long mapCD_
	ldrb_ r0,prgpage3
	ldr lr,[sp],#4
	b_long mapEF_

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
	@PocketNES, here also for 2K/4K/8K modes and CHR over 256K).
	@Not emulated: $5130 (CHR bank bits 8-9).
	stmfd sp!,{r3-r6,lr}
	ldrb_ r0,chrsize
	rsb r4,r0,#3		@r4 = page shift: 8K 3, 4K 2, 2K 1, 1K 0
	mov r5,#1
	mov r5,r5,lsl r4
	sub r5,r5,#1		@r5 = 1K pages per bank - 1
	ldrb_ r0,ppuctrl0
	tst r0,#0x20
	adrl_ r0,nes_chr_map
	ldreqb_ r6,chrbank	@8x8: everything from the last set
	beq 1f
	@8x16: sprites from set A
	mov r3,#0
0:
	mov r6,#0
	bl chr_page
	bl_long chr_page_number
	adrl_ r1,m5_spr
	strb r0,[r1,r3]
	add r3,r3,#1
	cmp r3,#8
	bne 0b
	adrl_ r0,m5_spr
	mov r6,#1		@background from set B
1:
	str_ r0,sprite_chr_map
	mov r3,#0
2:
	bl chr_page
	adr r1,writeCHRTBL_5
	mov lr,pc
	ldr pc,[r1,r3,lsl#2]
	add r3,r3,#1
	cmp r3,#8
	bne 2b
	ldmfd sp!,{r3-r6,pc}

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

	@ExRAM ($5C00-$5FFF) as plain RAM: 1K at NES_VRAM4, the page that
	@mirror2_/mirror4_ show as the ExRAM nametable.  Games that use it as work
	@RAM (Metal Slader Glory) work; a CPU write doesn't redraw a nametable
	@shown from it.
exram_w:
	ldr r1,=NES_VRAM4-0x5C00
	strb r0,[r1,addy]
	mov pc,lr
exram_r:
	ldr r1,=NES_VRAM4-0x5C00
	ldrb r0,[r1,addy]
	mov pc,lr

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

@@-------------------------------------------------------
@mapper_5_hook:
@@------------------------------------------------------
@	ldrb_ r0,counter
@	ldr_ r1,scanline
@	ldrb_ r2,mmc5irqr
@	cmp r1,#239
@	blt h2
@	orr r2,r2,#0x40
@h2:
@	cmp r1,#245
@	bge h1
@
@	cmp r1,r0
@	ble h1
@
@	orr r2,r2,#0x80
@	strb_ r2,mmc5irqr
@
@	ldrb_ r0,enable
@	cmp r0,#0
@@	bne irq6502
@	bne_long CheckI
@h1:
@	strb_ r2,mmc5irqr
@	fetch 0

@-------------------------------------------------------
	.pool

	.endif
	
	@.end
