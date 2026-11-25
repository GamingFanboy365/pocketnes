#include "equates.h"

	global_func set_fast_waitstates

@ Cartridge wait states.  PocketNES runs much of its code from ROM, and 3/1
@ wait states with the prefetch buffer on (WAITCNT = $4317, what commercial
@ games use) make it about 8% faster than the power-on 4/2.  Some flash carts
@ can't be read that fast: the SuperCard's SDRAM needs the slow setting, and
@ SuperFW only patches the WAITCNT writes of games in its database, so an
@ unpatched PocketNES crashes at boot (white or black screen).
@
@ So before switching, read part of the ROM at the current setting (whatever
@ the BIOS or the cart's menu left), then twice at 3/1, and keep 3/1 only if
@ all three reads agree.  A cart that is too slow returns wrong or stale data
@ when read too fast.  The check can't run from ROM, as its own instruction
@ fetches would go wrong too, so it is copied onto the stack (IWRAM) and run
@ there.  That way it takes no IWRAM or EWRAM of its own.

 FAST_WAITCNT = 0x4317
 PROBE_SIZE = 0x8000		@bytes of ROM read in bursts

 .text
 .align 2
 .arm
@----------------------------------------------------------------------------
set_fast_waitstates:	@int set_fast_waitstates(void): 1 if 3/1 is now set
@----------------------------------------------------------------------------
	stmfd sp!,{r4-r11,lr}
	adr r0,probe
	adr r1,probe_end
	sub r10,r1,r0		@size of the probe code
	sub sp,sp,r10
	mov r2,sp
0:
	ldr r3,[r0],#4		@copy it onto the stack
	str r3,[r2],#4
	cmp r0,r1
	blo 0b
	mov lr,pc
	mov pc,sp		@run the copy
	add sp,sp,r10
	ldmfd sp!,{r4-r11,lr}
	bx lr

probe:	@position independent: runs from its copy on the stack.  Changes r1-r9,
	@r11, r12 (not r10); returns r0 = 1 if 3/1 is now set.
	ldr r12,=REG_BASE+REG_IME
	ldrh r11,[r12]
	mov r0,#0
	strh r0,[r12]		@no interrupts while the ROM may misread
	stmfd sp!,{r11,r12,lr}

	ldr r12,=REG_WAITCNT
	ldrh r11,[r12]		@the current setting
	bl rom_checksum
	mov r9,r0
	ldr r0,=FAST_WAITCNT
	strh r0,[r12]
	bl rom_checksum
	cmp r0,r9
	bne 0f
	bl rom_checksum
	cmp r0,r9
0:
	strneh r11,[r12]	@mismatch: back to the setting that works
	moveq r0,#1
	movne r0,#0

	ldmfd sp!,{r11,r12,lr}
	strh r11,[r12]		@interrupts as they were
	bx lr

rom_checksum:	@r0 = checksum of ROM reads: bursts, then scattered halfwords.
	@Changes r1-r6.
	mov r0,#0
	mov r1,#0x08000000
	add r2,r1,#PROBE_SIZE
1:
	ldmia r1!,{r3-r6}	@sequential accesses
	add r0,r3,r0,ror#31
	add r0,r4,r0,ror#31
	add r0,r5,r0,ror#31
	add r0,r6,r0,ror#31
	cmp r1,r2
	blo 1b
	mov r1,#0x08000000
	mov r2,#512
2:
	ldrh r3,[r1],#0x7E	@non-sequential accesses
	add r0,r3,r0,ror#31
	subs r2,r2,#1
	bne 2b
	bx lr
	.pool
	.align 2
probe_end:
