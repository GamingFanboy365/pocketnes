.align
 .pool
 .text
 .align
 .pool

#include "../equates.h"
#include "../6502mac.h"

	global_func mapper11init

@----------------------------------------------------------------------------
mapper11init:	@Color Dreams / Wisdom Tree
@----------------------------------------------------------------------------
	@ The register listens across the entire $8000-$FFFF range
	.word write11,write11,write11,write11

	@ Save LR for external function calls during boot
	stmfd sp!,{lr}

	@ FORCE BOOT ALIGNMENT: 32KB PRG to the LAST bank, 8KB CHR to Bank 0
	mvn r0,#0
	bl_long map89ABCDEF_
	mov r0,#0
	bl_long chr01234567_

	ldmfd sp!,{pc}

@----------------------------------------------------------------------------
write11:	@$8000-$FFFF
@----------------------------------------------------------------------------
	stmfd sp!,{r4,lr}
	mov r4,r0

	@ PRG bank from bits 4-7 (32 KB at $8000-$FFFF)
	mov r0,r4,lsr#4
	and r0,r0,#0x0F
	bl_long map89ABCDEF_

	@ CHR bank from bits 0-3 (8 KB)
	and r0,r4,#0x0F
	bl_long chr01234567_

	ldmfd sp!,{r4,pc}
	@.end
