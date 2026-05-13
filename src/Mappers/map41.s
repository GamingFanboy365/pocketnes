.align
 .pool
 .text
 .align
 .pool

#include "../equates.h"
#include "../6502mac.h"

	global_func mapper41init

@ Layout of mapperdata for this mapper
 chr_high = mapperdata+0	@ CHR bank bits 2-3, set by outer write
 chr_low  = mapperdata+1	@ CHR bank bits 0-1, set by inner write
 outer_a2 = mapperdata+2	@ Lockout flag (Bit 2 of outer write)

@----------------------------------------------------------------------------
mapper41init:	@Caltron Industries -- "6-in-1" multicart
@----------------------------------------------------------------------------
	.word write_inner,write_inner,write_inner,write_inner

	@ Save LR for external function calls during boot
	stmfd sp!,{lr}

	@ FORCE BOOT ALIGNMENT: 32KB PRG to Bank 0, 8KB CHR to Bank 0
	mov r0,#0
	bl_long map89ABCDEF_
	mov r0,#0
	bl_long chr01234567_

	@ Initialize the custom RAM variables
	mov r0,#0
	strb_ r0,chr_high
	strb_ r0,chr_low
	strb_ r0,outer_a2

	@ Outer-bank writes land in $6000-$67FF
	adr r1,write_outer
	str_ r1,writemem_6
	.if PRG_BANK_SIZE == 4
	str_ r1,writemem_7
	.endif

	ldmfd sp!,{pc}

@----------------------------------------------------------------------------
write_outer:	@$6000-$67FF -- address bits carry the data
@----------------------------------------------------------------------------
	@ Mask out writes to $6800-$7FFF
	tst addy,#0x1800
	movne pc,lr

	stmfd sp!,{r4,lr}
	mov r4,addy

	@ Stash outer A2 for the CHR lockout
	mov r0,r4,lsr#2
	and r0,r0,#1
	strb_ r0,outer_a2

	@ Stash chr_high = (addy >> 2) & 0x0C (A4-A5)
	mov r0,r4,lsr#2
	and r0,r0,#0x0C
	strb_ r0,chr_high

	@ Mirroring from A3 (0 = V, 1 = H)
	tst r4,#0x08
	bl_long mirror2V_

	@ PRG bank from A0-A2 (32 KB units)
	and r0,r4,#7
	bl_long map89ABCDEF_

	@ Update CHR using new high + current low
	ldrb_ r0,chr_high
	ldrb_ r1,chr_low

	@ HARDWARE LOCKOUT: If A2 == 1, CHR low bits are physically forced to 0
	ldrb_ r2,outer_a2
	cmp r2,#1
	moveq r1,#0

	orr r0,r0,r1
	bl_long chr01234567_

	ldmfd sp!,{r4,pc}

@----------------------------------------------------------------------------
write_inner:	@$8000-$FFFF -- sets the CHR low bits
@----------------------------------------------------------------------------
	@ CRITICAL FIX: Save the stack and protect the written data (r0) FIRST
	stmfd sp!,{r4,lr}
	mov r4,r0

	@ Check lockout: if outer_a2 == 1, the inner writes are physically severed
	ldrb_ r1,outer_a2
	cmp r1,#1
	beq inner_abort

	@ CHR low bits = D0-D1
	and r0,r4,#3
	strb_ r0,chr_low

	@ Update CHR using current high + new low
	ldrb_ r1,chr_high
	orr r0,r0,r1
	bl_long chr01234567_

inner_abort:
	ldmfd sp!,{r4,pc}
	@.end
