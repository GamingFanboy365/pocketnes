 .align
 .pool
 .text
 .align
 .pool

#include "../equates.h"
#include "../6502mac.h"

	global_func mapper41init

@ Layout of mapperdata for this mapper
 chr_high  = mapperdata+0	@ CHR bank bits 2-3 (set by outer write)
 chr_low   = mapperdata+1	@ CHR bank bits 0-1 (set by inner write)
 outer_a2  = mapperdata+2	@ A2 of last outer write -- inner CHR
				@ writes are GATED by this (1 = allow,
				@ 0 = block) per FCEUX 41.cpp.

@----------------------------------------------------------------------------
mapper41init:	@Caltron Industries -- "6-in-1" multicart
@----------------------------------------------------------------------------
	.word write_inner,write_inner,write_inner,write_inner

	@ Hook outer-bank writes at $6000-$67FF
	adr r1,write_outer
	str_ r1,writemem_6
	.if PRG_BANK_SIZE == 4
	str_ r1,writemem_7
	.endif

	@ M41Power() in FCEUX: setprg32($8000, 0), setchr8(0), syncs mirror.
	@ We do the same explicitly here so the menu boots into a known
	@ state (bank 0 + 8K CHR 0 + last-set mirror).  The mirror call is
	@ implicit -- cart.s applies the iNES header mirror after mapperinit.
	stmfd sp!,{lr}
	mov r0,#0
	bl_long map89ABCDEF_
	mov r0,#0
	bl_long chr01234567_
	mov r0,#0
	strb_ r0,chr_high
	strb_ r0,chr_low
	strb_ r0,outer_a2
	ldmfd sp!,{pc}

@----------------------------------------------------------------------------
write_outer:	@$6000-$67FF -- address bits carry the data
@----------------------------------------------------------------------------
	@ Outer-bank encoding (matches FCEUX M41Write0, address bits NOT value):
	@   A0-A2 -> 32 KB PRG bank at $8000-$FFFF
	@   A2    -> also: lockout flag.  Inner CHR writes are ENABLED when
	@            A2 == 1, BLOCKED when A2 == 0.
	@   A3-A4 -> CHR bank bits 2-3   (chrreg high = (A >> 1) & 0xC)
	@   A5    -> mirroring (0 = V, 1 = H)   (mirror = ((A >> 5) & 1) ^ 1)
	@
	@ The full bus address is in addy.  Both helpers we call below
	@ treat r12 (addy) as scratch, so we keep our copy on the stack.
	@
	@ IMPORTANT: do NOT use r4 as a scratch register.  r4 is m6502_mmap,
	@ the CPU's memory-map base pointer that encodePC reads from at the
	@ end of every PRG bank update (inside flush, which map89ABCDEF_
	@ tail-calls).  Clobbering r4 here -- even when restored at function
	@ exit -- corrupts the CPU's PC translation WHILE the bank update is
	@ in flight, dropping the bank switch and stranding execution.

	@ Ignore writes outside $6000-$67FF.  $6800-$7FFF on this board is
	@ either open bus or PRG-RAM and must not trigger a bank change.
	tst addy,#0x1800
	movne pc,lr

	stmfd sp!,{addy,lr}

	@ Stash A2 of the outer write for the inner-CHR lockout.
	mov r1,addy,lsr#2
	and r1,r1,#1
	strb_ r1,outer_a2

	@ Stash chr_high = (addy >> 1) & 0xC   (extracts A3-A4, places them
	@ at bits 2-3 of the 4-bit CHR bank).
	mov r1,addy,lsr#1
	and r1,r1,#0x0C
	strb_ r1,chr_high

	@ Mirroring from A5 (NOT A3 -- that was a wrong reading of the spec
	@ in the earlier draft).  mirror2V_ EQ -> V, NE -> H, which lines up
	@ with A5=0 -> V, A5=1 -> H.
	tst addy,#0x20
	bl_long mirror2V_

	@ mirror2V_ may have clobbered addy; reload from the saved slot.
	ldr addy,[sp]

	@ PRG bank from A0-A2 (32 KB)
	and r0,addy,#7
	bl_long map89ABCDEF_

	@ Re-issue the 8 KB CHR bank using updated high + current low.
	ldrb_ r0,chr_high
	ldrb_ r1,chr_low
	orr r0,r0,r1

	ldmfd sp!,{addy,lr}
	b_long chr01234567_

@----------------------------------------------------------------------------
write_inner:	@$8000-$FFFF -- sets the CHR low bits
@----------------------------------------------------------------------------
	@ Per FCEUX M41Write1: only respond when outer A2 was 1 the last time
	@ the outer bank was written.  The Caltron menu specifically uses
	@ this -- it primes "STA $6004" (A2=1) just before "STA $FFF0,Y" so
	@ the CHR-low update is accepted, then writes the real outer bank
	@ "STA $6000,X" afterwards.  Blocking when A2=1 (the bug in the
	@ earlier draft) drops every CHR-low update the menu makes and
	@ leaves CHR-low = 0, producing garbled tiles.
	ldrb_ r1,outer_a2
	cmp r1,#1
	movne pc,lr

	@ Per FCEUX: chrreg low = A & 3 (address bits).  For Caltron this is
	@ equivalent to the value's low 2 bits because the menu does
	@ "LDA $F47F,Y / TAY / STA $FFF0,Y" -- A and the address low byte
	@ end up identical -- but using the address matches the canonical
	@ reference and will Do The Right Thing for any other mapper-41 ROM
	@ that doesn't happen to set them equal.
	and r0,addy,#3
	strb_ r0,chr_low

	@ Re-issue CHR with current high + new low.
	ldrb_ r1,chr_high
	orr r0,r0,r1
	b_long chr01234567_
@----------------------------------------------------------------------------
	@.end
