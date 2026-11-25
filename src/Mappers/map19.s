 .align
 .pool
 .text
 .align
 .pool

#include "../equates.h"
#include "../6502mac.h"

	global_func mapper19init
	global_func mapper210init
@	global_func mapper_19_hook
	global_func map19_irq_handler
	global_func map19_handler

 counter = mapperdata+0
 irqen = mapperdata+4
 mirror = mapperdata+8
 counter_last_timestamp = mapperdata+16

 IRQ_ENABLE = 0x80

@IRQ increments to 7FFF, then stops there, repeatedly triggering IRQs until someone stops it

@IRQs may be buggy, not sure


@----------------------------------------------------------------------------
mapper210init:
@----------------------------------------------------------------------------
	.word map19_8,map19_A,void,map19_E
	b 0f

@----------------------------------------------------------------------------
mapper19init:
@----------------------------------------------------------------------------
	.word map19_8,map19_A,map19_C,map19_E
0:
	mvn r0,#0
	str_ r0,mirror

	adr r1,write0
	str_ r1,writemem_4
	.if PRG_BANK_SIZE == 4
	str_ r1,writemem_5
	.endif

	adr r1,map19_r
	str_ r1,readmem_4
	.if PRG_BANK_SIZE == 4
	str_ r1,readmem_5
	.endif


@	adr r0,mapper_19_hook
@	str_ r0,scanlinehook

	mov pc,lr
@----------------------------------------------------------------------------

map19_irq_handler:
	ldr_ r0,counter
	ldr r1,=0x7FFF
	cmp r0,r1
	bne_long _GO
	
	ldrb_ r0,wantirq
	orr r0,r0,#IRQ_MAPPER
	strb_ r0,wantirq
	b_long CheckI




map19_handler:
	ldr_ r1,mapper_timestamp
	bl run_2
	cmp r0,#0x8000
	blt_long _GO
	adr r0,map19_irq_handler
	adrl_ addy,mapper_irq_timeout
	bl_long replace_timeout_2
	b_long _GO

run_counter:
	@get timestamp
	ldr_ r2,cycles_to_run
0:
	sub r2,r2,cycles,asr#CYC_SHIFT
	ldr_ r1,timestamp
	add r1,r1,r2
run_2:
	add r1,r1,#12
	ldr_ r2,counter_last_timestamp
	str_ r1,counter_last_timestamp

	ldrb_ r0,irqen
	tst r0,#IRQ_ENABLE
	moveq r0,#0
	bxeq lr

	sub r2,r1,r2
	@r2 = elapsed cycles
	
	@divide time difference by 3
	ldr r0,=0x55555556 @1/3
	umull addy,r2,r0,r2
	
	ldr_ r0,counter
	add r0,r0,r2
	cmp r0,#0x8000
	strlt_ r0,counter
	bxlt lr
	ldr r2,=0x7FFF
	str_ r2,counter
	bx lr
	
find_next_irq:
	ldrb_ r0,irqen
	tst r0,#IRQ_ENABLE
	bxeq lr

	ldr_ r2,cycles_to_run
	sub r2,r2,cycles,asr#CYC_SHIFT
	ldr_ r1,timestamp
	add r1,r1,r2
	add r1,r1,#12
	str_ r1,counter_last_timestamp
	
	ldr_ r0,counter
0:
	@get count up until 0x8000
	rsb r0,r0,#0x8000
	adds r0,r0,r0,lsl#1
	
	add r1,r1,r0
	sub r1,r1,#12
	adr r0,map19_handler
	adrl_ addy,mapper_timeout
	b_long replace_timeout_2

@-------------------------------------------------------
write0:
	@4800 is sound registers
	
	cmp addy,#0x5000
	blo_long IO_W

	@run counter
	stmfd sp!,{r0,addy,lr}
	bl run_counter
	ldmfd sp!,{r0,addy,lr}
	
	@all reads and writes clear IRQ flag
	ldrb_ r1,wantirq
	bic r1,r1,#IRQ_MAPPER
	strb_ r1,wantirq
	
	and r1,addy,#0x7800
	cmp r1,#0x5000
	streqb_ r0,counter+0
	beq find_next_irq

	cmp r1,#0x5800
	movne pc,lr
	and r1,r0,#0x7F
	strb_ r1,counter+1
	and r0,r0,#0x80
	strb_ r0,irqen
	b find_next_irq
@-------------------------------------------------------
map19_r:
	@4800 is sound registers

	cmp addy,#0x5000
	blo_long IO_R

	@run counter
	stmfd sp!,{r0,addy,lr}
	bl run_counter
	ldmfd sp!,{r0,addy,lr}
	
	@all reads and writes clear IRQ flag
	ldrb_ r1,wantirq
	bic r1,r1,#IRQ_MAPPER
	strb_ r1,wantirq
	
	and r1,addy,#0x7800

	cmp r1,#0x5000
	ldreqb_ r0,counter+0
	moveq pc,lr

	cmp r1,#0x5800
	bxne lr
	ldrb_ r0,counter+1
	ldrb_ r1,irqen
	orr r0,r0,r1
	bx lr

@-------------------------------------------------------
map19_8:
map19_A:
	and r1,addy,#0x7800
	ldr r2,=writeCHRTBL
	ldr pc,[r2,r1,lsr#9]
map19_C:
	@ Do NameTable RAMROM change, for mirroring.
	and r2,addy,#0x1800
	adrl_ r1,mirror
	ldrb r12,[r1,r2,lsr#11]
	cmp r0,r12
	beq map19_C_same
	strb r0,[r1,r2,lsr#11]
	
	ldr_ r1,mirror
	and r0,r1,#0x01
	tst r1,#0x00000100
	orrne r0,r0,#0x04
	tst r1,#0x00010000
	orrne r0,r0,#0x10
	tst r1,#0x01000000
	orrne r0,r0,#0x40
	b_long m5_ntmapping
@-------------------------------------------------------

@-------------------------------------------------------
map19_E:
@-------------------------------------------------------
	and r1,addy,#0x7800
	cmp r1,#0x6000
	beq_long map89_
	cmp r1,#0x6800
	beq map19_6800
	cmp r1,#0x7000
	beq_long mapCD_
	mov pc,lr

@-------------------------------------------------------
map19_6800:
@-------------------------------------------------------
	@ Detect sango.nes main-thread idle loop ($E066 -> $E17D/$E221 -> $E87A -> $F24B -> $A000 -> $E066)
	@ At $F25A: STA $E800, m6502_pc - lastbank == 0xF25D
	ldr_ r1,lastbank
	sub r1,m6502_pc,r1
	ldr r2,=0xF25D
	cmp r1,r2
	bne_long mapAB_
	add r1,cpu_zpage,#0x1700
	ldrb r1,[r1,#0x8B]		@ r1 = NES_SRAM[0x0F8B] ($6F8B)
	ldrb r2,[cpu_zpage,#0x7A]	@ r2 = NES_RAM[0x007A] ($007A)
	cmp r2,#2
	cmpeq r0,#0xEA
	bne 1f
	tst r1,#0x80
	beq_long mapAB_
	movs r1,cycles,asr#CYC_SHIFT
	ble_long mapAB_
	ldr r2,=0x00A1D13A		@ ceil(2^32 / 405)
	umull r2,addy,r1,r2		@ addy = N = (cycles >> CYC_SHIFT) / 405
	ldr r1,=405			@ 135 CPU cycles * 3 PPU dots
	b 2f
1:
	cmp r2,#4
	cmpeq r0,#0xE8
	cmpeq r1,#0xFF
	bne_long mapAB_
	movs r1,cycles,asr#CYC_SHIFT
	ble_long mapAB_
	ldr r2,=0x00A0A0A1		@ ceil(2^32 / 408)
	umull r2,addy,r1,r2		@ addy = N = (cycles >> CYC_SHIFT) / 408
	mov r1,#408			@ 136 CPU cycles * 3 PPU dots
2:
	cmp addy,#0
	beq_long mapAB_
	ldrb r2,[cpu_zpage,#0x50]
	add r2,r2,addy
	strb r2,[cpu_zpage,#0x50]	@ NES_RAM[0x0050] += N
	mul r1,addy,r1
	sub cycles,cycles,r1,lsl#CYC_SHIFT
	b_long mapAB_

@-------------------------------------------------------
map19_C_same:
@-------------------------------------------------------
	@ Fast-forward wait-for-sprite-0-clear loop ($FB22: BIT $2002; BVS $FB22) after $FB1F: STA $D800
	cmp r2,#0x1800
	bxne lr
	ldr r1,=ppustat_
	ldrb r1,[r1]
	tst r1,#0x40
	bxeq lr
	ldrb r1,[m6502_pc]
	cmp r1,#0x2C
	ldreqb r1,[m6502_pc,#2]
	cmpeq r1,#0x20
	ldreqb r1,[m6502_pc,#3]
	cmpeq r1,#0x70
	ldreqb r1,[m6502_pc,#4]
	cmpeq r1,#0xFB
	bxne lr
	mov r0,cycles,asr#CYC_SHIFT
	cmp r0,#42
	bxlt lr
	ldr r1,=0x0C30C30D		@ ceil(2^32 / 21)
	umull r2,r0,r1,r0		@ r0 = N = (cycles >> CYC_SHIFT) / 21
	sub r0,r0,#1			@ leave 1 iteration + STA $D800 fetch
	mov r1,#21
	mul r0,r1,r0
	sub cycles,cycles,r0,lsl#CYC_SHIFT
	bx lr

@-------------------------------------------------------
	global_func sprite_zero_quickhackfinder
sprite_zero_quickhackfinder:
@-------------------------------------------------------
	ldr addy,=speedhacks
	ldrb r1,[addy,#16+5]		@ speedhacks[1].hack_was_used
	cmp r1,#0
	beq_long call_quickhackfinder
	ldr r1,[addy,#0]		@ speedhacks[0].hack_pc
	cmp r1,#0
	bne_long call_quickhackfinder
	mov r1,#0
	strb r1,[addy,#16+5]		@ clear hack_was_used
	strb r1,[addy,#16+6]		@ clear frames_hack_not_used
	bx lr

@@-------------------------------------------------------
@mapper_19_hook:
@@------------------------------------------------------
@	ldrb_ r0,irqen
@	cmp r0,#0
@	beq h1
@
@	ldr_ r0,counter
@@	adds r0,r0,#0x71aaab		@113.66667
@	adds r0,r0,#0x720000
@	str_ r0,counter
@	bcc h1
@	mov r0,#0
@	strb_ r0,irqen
@	sub r0,r0,#0x10000
@	str_ r0,counter
@@	b irq6502
@	b_long CheckI
@h1:
@	fetch 0

@----------------------------------------------------------------------------
	@.end
