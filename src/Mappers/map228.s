#include "../equates.h"

	.if LESSMAPPERS
	.else

 .align
 .pool
 .text
 .align
 .pool


	global_func mapper228init

 mapbyte1 = mapperdata
@----------------------------------------------------------------------------
mapper228init:@		Action 52 & Cheetahmen 2. nes_chr_map holds 8-bit 1K page numbers, so only
				@ the first 256K of CHR is reachable; Action 52 has 512K.
@----------------------------------------------------------------------------
	.word write0,write0,write0,write0

	ldr_ r0,rommask
	cmp r0,#0x40000
	addhi r0,r0,#0x80000
	str_ r0,rommask		@rommask=romsize-1

	mov r0,#0
	b_long map89ABCDEF_
@-------------------------------------------------------
write0:
@-------------------------------------------------------
	str_ addy,mapbyte1
	and r0,r0,#0x03
	orr r0,r0,addy,lsl#2
	mov addy,lr

	bl_long chr01234567_

	ldr_ r0,mapbyte1
	tst r0,#0x2000
	bl_long mirror2V_

	ldr_ r0,mapbyte1
	tst r0,#0x1000		@chip 3 -> chip 2 (1.5MB dumps omit the empty chip 2)
	bicne r0,r0,#0x800
	tst r0,#0x20		@A5: 0 = 32K mode, 1 = 16K mode (mirrored)
	bne swap16k
	mov r0,r0,lsr#7
	and r0,r0,#0x3F		@drop A13 (mirroring)
	mov lr,addy
	b_long map89ABCDEF_
swap16k:
	mov r0,r0,lsr#6		@16K bank = page*2 + A6
	and r0,r0,#0x7F		@drop A13 (mirroring)
	str_ r0,mapbyte1
	bl_long mapCDEF_
	ldr_ r0,mapbyte1
	mov lr,addy
	b_long map89AB_
@-------------------------------------------------------
	.endif
	@.end
