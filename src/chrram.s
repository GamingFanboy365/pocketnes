 .align
 .pool
 .text
 .align
 .pool

#include "equates.h"

	global_func chr_ram_bank8_

@ Banked CHR-RAM (see chr_ram_shadow in loadcart.c).
@
@ The PPU, $2007 writes and the dirty-tile renderer all work on the fixed 8K at
@ NES_VRAM, so a bank switch copies the live bank back to its home in the
@ shadow, copies the new bank in, and marks every tile dirty so the GBA copies
@ of the tiles are re-rendered.  Games switch CHR banks between screens, so the
@ 16K of copying per switch is not a problem; a mid-frame switch shows the new
@ bank for the whole frame.

@----------------------------------------------------------------------------
chr_ram_bank8_:	@r0 = 8K CHR-RAM bank.  Mapper write handlers call this in
				@place of chr01234567_ for their CHR bank bits.
@----------------------------------------------------------------------------
	ldr r1,=chr_ram_shadow
	ldr r1,[r1]
	cmp r1,#0
	ldreq pc,=chr01234567_		@CHR-RAM is not banked

	stmfd sp!,{r3-r5,addy,lr}	@preserve addy like chr01234567_ does
	ldr r2,=chr_ram_bank_mask
	ldrb r2,[r2]
	and r0,r0,r2
	ldr r5,=chr_ram_bank
	ldrb r4,[r5]
	cmp r4,r0
	beq 0f
	strb r0,[r5]
	add r3,r1,r0,lsl#13		@r3 = incoming bank's home
	add r4,r1,r4,lsl#13		@r4 = outgoing bank's home

	mov r0,r4
	ldr r1,=NES_VRAM
	mov r2,#0x2000
	bl_long memcpy32

	ldr r0,=NES_VRAM
	mov r1,r3
	mov r2,#0x2000
	bl_long memcpy32

	ldr r0,=dirty_tiles
	mvn r1,#0
	mov r2,#512
	bl_long memset32
	ldr r0,=dirty_rows
	mvn r1,#0
	mov r2,#32
	bl_long memset32
0:
	ldmfd sp!,{r3-r5,addy,lr}
	mov r0,#0
	ldr pc,=chr01234567_
@----------------------------------------------------------------------------
 .pool

	global_func big_chr0_
	global_func big_chr1_
	global_func big_chr2_
	global_func big_chr3_
	global_func big_chr4_
	global_func big_chr5_
	global_func big_chr6_
	global_func big_chr7_
	global_func big_chr01_
	global_func big_chr23_
	global_func big_chr45_
	global_func big_chr67_
	global_func big_chr0123_
	global_func big_chr4567_
	global_func big_chr01234567_

@ CHR ROM larger than 256K (see bigchr.c).  bigchr_setup patches the chr*_
@ functions in cart.s to jump here.  Same inputs as the originals: r0 = bank
@ number in the function's own bank size.

big_chr0_:	mov r1,#0
	b big_chr_1k
big_chr1_:	mov r1,#1
	b big_chr_1k
big_chr2_:	mov r1,#2
	b big_chr_1k
big_chr3_:	mov r1,#3
	b big_chr_1k
big_chr4_:	mov r1,#4
	b big_chr_1k
big_chr5_:	mov r1,#5
	b big_chr_1k
big_chr6_:	mov r1,#6
	b big_chr_1k
big_chr7_:	mov r1,#7
big_chr_1k:
	mov r2,#1
	b big_chr_map

big_chr01_:	mov r1,#0
	b big_chr_2k
big_chr23_:	mov r1,#2
	b big_chr_2k
big_chr45_:	mov r1,#4
	b big_chr_2k
big_chr67_:	mov r1,#6
big_chr_2k:
	mov r0,r0,lsl#1
	mov r2,#2
	b big_chr_map

big_chr0123_:	mov r1,#0
	b big_chr_4k
big_chr4567_:	mov r1,#4
big_chr_4k:
	mov r0,r0,lsl#2
	mov r2,#4
	b big_chr_map

big_chr01234567_:
	mov r0,r0,lsl#3
	mov r1,#0
	mov r2,#8
@----------------------------------------------------------------------------
big_chr_map:	@r0 = first real 1K page, r1 = first PPU 1K slot, r2 = page count
@----------------------------------------------------------------------------
	@Like the originals, preserve addy: mapper handlers keep their return
	@address in it across CHR calls (e.g. map228).
	stmfd sp!,{r3-r7,addy,lr}
	ldr_ r7,vrommask
	mov r7,r7,lsr#10		@r7 = real page mask
	mov r4,r0
	mov r5,r1
	mov r6,r2
0:
	and r4,r4,r7
	ldr r1,=bigchr_real_to_virtual
	ldrb r0,[r1,r4]
	cmp r0,#0xFF
	bne 1f
	mov r0,r4
	ldr r12,=bigchr_page		@no virtual page yet: assign one (Thumb C)
	mov lr,pc
	bx r12
1:
	adrl_ r1,nes_chr_map
	strb r0,[r1,r5]
	ldr_ r2,instant_chr_banks
	ldr r2,[r2,r0,lsl#2]
	adrl_ r1,vram_map
	str r2,[r1,r5,lsl#2]
	add r4,r4,#1
	add r5,r5,#1
	subs r6,r6,#1
	bne 0b
	ldmfd sp!,{r3-r7,addy,lr}
	ldr pc,=updateBGCHR_
@----------------------------------------------------------------------------
 .pool
	@.end
