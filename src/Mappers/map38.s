.align
 .pool
 .text
 .align
 .pool

#include "../equates.h"

	global_func mapper38init

@----------------------------------------------------------------------------
mapper38init:	@Bit Corp PCI556 -- "Crime Busters"
@----------------------------------------------------------------------------
	.word void,void,void,void	@no writes to $8000-$FFFF

	@ Save LR for external function calls during boot
	stmfd sp!,{lr}

	@ FORCE BOOT ALIGNMENT: 32KB PRG to the LAST bank, 8KB CHR to Bank 0
	mvn r0,#0
	bl_long map89ABCDEF_
	mov r0,#0
	bl_long chr01234567_

	@ Hook $6000-$7FFF for register writes.
	@ writemem_6 correctly targets the $6000 hex prefix!
	adr r1,write38
	str_ r1,writemem_6
	.if PRG_BANK_SIZE == 4
	str_ r1,writemem_7
	.endif

	ldmfd sp!,{pc}

@----------------------------------------------------------------------------
write38:
@----------------------------------------------------------------------------
	@ The register only responds at $7000-$7FFF; $6000-$6FFF is ignored
	tst addy,#0x1000
	moveq pc,lr

	@ value layout: ..ccpp
	@   bits 0-1 -> PRG bank (32 KB at $8000-$FFFF)
	@   bits 2-3 -> CHR bank (8 KB)
	stmfd sp!,{r0,lr}
	mov r0,r0,lsr#2
	and r0,r0,#3
	bl_long chr01234567_
	ldmfd sp!,{r0,lr}

	and r0,r0,#3
	b_long map89ABCDEF_
@----------------------------------------------------------------------------
	@.end
