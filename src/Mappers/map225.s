 .align
 .pool
 .text
 .align
 .pool

#include "../equates.h"
#include "../6502mac.h"

	global_func mapper225init

@ Layout of mapperdata for this mapper
 extra_ram = mapperdata+0	@ 4-byte "extraRAM" latch latched on writes to
				@ $5800-$5FFF and read back from the same
				@ region.  Indexed by (A & 3).  Without it
				@ the 110-in-1 menu reads back open bus
				@ instead of the game-state byte and ends
				@ up selecting wrong PRG+CHR for each title.

@----------------------------------------------------------------------------
mapper225init:	@ PCB-018 "110-in-1" and many other discrete pirate multicarts
@----------------------------------------------------------------------------
	@ All four write regions go through the single register; the address
	@ bits are the data on this board, the value on the data bus is ignored.
	.word write225,write225,write225,write225

	@ Install extra-RAM read/write handler at $5000-$5FFF.  With
	@ PRG_BANK_SIZE == 8 this single slot covers $4000-$5FFF -- the
	@ handler must internally pass APU/joypad addresses ($4000-$4FFF)
	@ through to IO_R / IO_W.
	adr r1,write225_lo
	str_ r1,writemem_4
	.if PRG_BANK_SIZE == 4
	str_ r1,writemem_5
	.endif

	adr r1,read225_lo
	str_ r1,readmem_4
	.if PRG_BANK_SIZE == 4
	str_ r1,readmem_5
	.endif

	@ FCEUX M225Power: prg = 0, mode = 0, Sync() -> setprg32($8000, 0),
	@ setchr8(0).  Force the same boot state here.  Zero the extraRAM
	@ too so the first menu read doesn't see leftover stack noise.
	stmfd sp!,{lr}
	mov r0,#0
	bl_long map89ABCDEF_
	mov r0,#0
	bl_long chr01234567_
	mov r0,#0
	strb_ r0,extra_ram+0
	strb_ r0,extra_ram+1
	strb_ r0,extra_ram+2
	strb_ r0,extra_ram+3
	ldmfd sp!,{pc}

@----------------------------------------------------------------------------
write225:	@$8000-$FFFF -- address-encoded multicart latch
@----------------------------------------------------------------------------
	@ Per FCEUX M225Write:
	@   bank    = (A >> 14) & 1   -- high bit for both CHR and PRG
	@   mirr    = (A >> 13) & 1   -- 0 -> V, 1 -> H   (after the ^1 in Sync)
	@   mode    = (A >> 12) & 1   -- 0 = 32 KB PRG, 1 = 16 KB mirrored
	@   chr[7]  = (A & 0x3F) | (bank << 6)
	@   prg[7]  = ((A >> 6) & 0x3F) | (bank << 6)
	stmfd sp!,{addy,lr}

	@ ---- CHR bank ----
	and r0,addy,#0x3F
	mov r1,addy,lsr#8
	and r1,r1,#0x40
	orr r0,r0,r1
	bl_long chr01234567_

	@ ---- Mirroring ----  (A13 == 0 -> V, == 1 -> H, after FCEUX ^1)
	ldr addy,[sp]
	tst addy,#0x2000
	bl_long mirror2V_

	@ ---- PRG bank ----
	ldr addy,[sp]
	mov r0,addy,lsr#6
	and r0,r0,#0x3F
	mov r1,addy,lsr#8
	and r1,r1,#0x40
	orr r0,r0,r1

	tst addy,#0x1000
	bne write225_mode16

	@ ---- 32 KB mode ----
	mov r0,r0,lsr#1
	ldmfd sp!,{addy,lr}
	b_long map89ABCDEF_

write225_mode16:
	@ ---- 16 KB mode (mirrored) ----
	stmfd sp!,{r0,lr}
	bl_long map89AB_
	ldmfd sp!,{r0,lr}
	ldmfd sp!,{addy,lr}
	b_long mapCDEF_

@----------------------------------------------------------------------------
write225_lo:	@$4000-$5FFF -- APU passthrough below $5000, extraRAM above
@----------------------------------------------------------------------------
	@ Below $5000: APU / joypad / DMA registers.  Tail-call IO_W so all
	@ existing sound and controller handling keeps working.
	cmp addy,#0x5000
	blo_long IO_W

	@ $5000-$57FF: discrete-board open bus.  Ignore.
	tst addy,#0x800
	moveq pc,lr

	@ $5800-$5FFF: extraRAM[A & 3] = V & 0x0F.  FCEUX masks to the low
	@ nibble; the high nibble is not present on the hardware (likely a
	@ 4-bit latch chip such as a 74LS173).
	add r1,globalptr,#mapperdata
	and r2,addy,#3
	and r0,r0,#0x0F
	strb r0,[r1,r2]
	mov pc,lr

@----------------------------------------------------------------------------
read225_lo:	@$4000-$5FFF -- APU passthrough below $5000, extraRAM above
@----------------------------------------------------------------------------
	@ Note: per memory.s convention, reads must NOT clobber r12 (addy).
	@ Tail-call IO_R below $5000 -- it preserves addy by contract.
	cmp addy,#0x5000
	blo_long IO_R

	@ $5000-$57FF: open bus.  Return high byte of address bus, matching
	@ what empty_R does for unmapped reads.
	tst addy,#0x800
	moveq r0,addy,lsr#8
	moveq pc,lr

	@ $5800-$5FFF: return extraRAM[A & 3].
	add r1,globalptr,#mapperdata
	and r2,addy,#3
	ldrb r0,[r1,r2]
	mov pc,lr
@----------------------------------------------------------------------------
	@.end
