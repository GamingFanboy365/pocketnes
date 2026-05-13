.align
 .pool
 .text
 .align
 .pool

#include "../equates.h"
#include "../6502mac.h"

	global_func mapper28init

@ Variables mapped to PocketNES memory
 m28_select = mapperdata+0
 m28_prg    = mapperdata+1
 m28_chr    = mapperdata+2

@----------------------------------------------------------------------------
mapper28init:	@ Action 53 (Mapper 28)
@----------------------------------------------------------------------------
	.word write28,write28,write28,write28

	stmfd sp!,{lr}

	@ Anchor PRG to the final bank for the Reset Vector
	mvn r0,#0
	bl_long map89ABCDEF_

	@ Anchor CHR to Bank 0 to prevent Sprite 0 crashes
	mov r0,#0
	bl_long chr01234567_

	@ Initialize hardware variables to zero
	mov r0,#0
	strb_ r0,m28_select
	strb_ r0,m28_prg
	strb_ r0,m28_chr

	@ THE ARCHIVAL HEIST (LINKER BYPASS): 
	@ writemem_5 was never exported as a global symbol by the original devs!
	@ But the pointers sit consecutively in RAM. We load the physical address
	@ of writemem_6 (which we know exists) and subtract 4 bytes to hijack Bank 5.
	adr r1,write_select
	ldr r2,=writemem_6
	str r1,[r2,#-4]

	ldmfd sp!,{pc}

@----------------------------------------------------------------------------
write_select:	@ $5000-$5FFF (Outer Write)
@----------------------------------------------------------------------------
	@ Only intercept writes specifically aimed at $5000
	cmp addy,#0x5000
	movne pc,lr

	stmfd sp!,{addy,lr}

	@ The low byte defines the target internal register
	strb_ r0,m28_select

	ldmfd sp!,{addy,pc}

@----------------------------------------------------------------------------
write28:	@ $8000-$FFFF (Inner Write)
@----------------------------------------------------------------------------
	@ Protect the memory address across destructive macro calls
	stmfd sp!,{addy,lr}

	ldrb_ r1,m28_select

	@ Register 0x01: PRG Bank Selection
	cmp r1,#0x01
	beq exec_prg

	@ Register 0x00: CHR Bank Selection
	cmp r1,#0x00
	beq exec_chr
	
	@ Register 0x80: Mode / Mirroring
	cmp r1,#0x80
	beq exec_mirror

	b exec_end

exec_prg:
	@ Extract and apply the program ROM bank index
	and r0,r0,#0x3F
	strb_ r0,m28_prg
	bl_long map89ABCDEF_
	b exec_end

exec_chr:
	@ Extract and apply the graphics ROM bank index
	and r0,r0,#0x0F
	strb_ r0,m28_chr
	bl_long chr01234567_
	b exec_end

exec_mirror:
	@ Map Action 53 mirroring (Bit 1 toggle)
	tst r0,#0x02
	bl_long mirror2V_
	b exec_end

exec_end:
	ldmfd sp!,{addy,pc}
	@.end
