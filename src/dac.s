 .align
 .pool
 .text
 .align
 .pool

#include "equates.h"

	global_func _4011w
	global_func dac_frame
	global_func dac_irq_fill
	global_func dac_reset

@ Direct $4011 writes ("raw PCM").  Games like Action 52 play voice clips by
@ writing samples to the DMC's DAC from a timed CPU loop, thousands of times a
@ second, without using DMC sample playback at all.
@
@ _4011w puts each write in dac_queue with its timestamp (in PPU dots).
@ While no DMC sample is playing, the DirectSound refill interrupt
@ (timer1interrupt in sound.s) plays the queue back through dac_irq_fill: it
@ walks a playback time through the queue, one output sample per 256 dots
@ (about 21 kHz), and each output sample takes the level of the last write at
@ or before that time.  Playback runs about DAC_LAG samples behind the newest
@ write, and steps slightly faster or slower to keep that distance, so it
@ follows the emulation speed instead of running dry when the emulator can't
@ keep up.  dac_frame starts playback, keeps the time moving while the game
@ isn't writing, and stops playback after DAC_IDLE_FRAMES frames without a
@ write.  Like the NES's own output, playback is AC-coupled: a slowly tracked
@ DC level (dac_dc) is subtracted, so a game that writes $4011 once, or leaves
@ it at some level, doesn't click when playback starts and stops.  These loops are about as much as the emulator can run at full speed,
@ so the write handler and the per-sample loop are in IWRAM.

 DAC_QUEUE	= 1024		@entries, power of two
 DAC_LAG	= 640		@samples between the newest write and playback (about 30ms)
 DAC_MAXLAG	= 1856		@further behind than this: jump back to DAC_LAG
 DAC_IDLE_FRAMES = 120

 dac_widx	= 0		@newest time known (last write, or start of this frame)
 dac_ridx	= 4		@playback time of the next output sample
 dac_level	= 8		@playback level: last value played - 64
 dac_on		= 9		@1 while $4011 writes are being played (sound.s reads this too)
 dac_idle	= 10		@frames since the last $4011 write
 dac_head	= 12		@bytes of dac_queue written (free-running)
 dac_tail	= 16		@bytes of dac_queue played (free-running)
 dac_seen	= 20		@dac_head at the last dac_frame
 dac_acc	= 24		@playback rate control: accumulated distance error
 dac_dc		= 28		@DC level (same units as dac_level, 8 fraction bits)
 DAC_STATE_SIZE = 32		@dac_queue follows

	@lr = level - DC level (r1), scaled to about the DMC's +-96 range and
	@clamped to 8 bits
 .macro dac_output
	sub lr,lr,r1
	add lr,lr,lr,asr#1
	cmp lr,#127
	movgt lr,#127
	cmn lr,#128
	mvnlt lr,#127
 .endm

	@timer 0 reload for one sample per 256 PPU dots, at one NES frame per GBA
	@frame: NTSC 89342/256 * 59.73 Hz = 20845 Hz, PAL 106392/256 * 59.73 = 24823 Hz
 DAC_TIMER_NTSC = 0x10000-805
 DAC_TIMER_PAL = 0x10000-676

@----------------------------------------------------------------------------
dac_reset:	@new game
@----------------------------------------------------------------------------
	ldr r1,=dac_state
	mov r0,#0
	mov r2,#DAC_STATE_SIZE
0:
	subs r2,r2,#4
	str r0,[r1,r2]
	bne 0b
	bx lr

@----------------------------------------------------------------------------
dac_frame:	@r0 = timestamp of the frame start.  Preserves r0 and r3-r12.
@----------------------------------------------------------------------------
	stmfd sp!,{r0,r3,lr}
	ldr r3,=dac_state
	ldr r1,[r3,#dac_head]
	ldr r2,[r3,#dac_seen]
	cmp r1,r2
	beq 1f
	@written to this frame: make sure it plays
	str r1,[r3,#dac_seen]
	mov r1,#0
	strb r1,[r3,#dac_idle]
	mov r1,#1
	strb r1,[r3,#dac_on]
	ldr r1,=REG_BASE+REG_TM0CNT_L
	ldrh r2,[r1,#2]
	tst r2,#0x80
	bne 2f
	@starting from silence: start at the first write's level, with the DC
	@level there too, so playback starts silent
	ldr r2,[r3,#dac_tail]
	mov r2,r2,lsl#20
	add r2,r3,r2,lsr#20
	ldr r2,[r2,#DAC_STATE_SIZE]
	and r2,r2,#0x7F
	sub r2,r2,#64
	strb r2,[r3,#dac_level]
	mov r2,r2,lsl#8
	str r2,[r3,#dac_dc]
	mov r2,#0x80000000	@no DMC sample: timer1interrupt goes to the DAC path
	str_ r2,pcmcount
	ldrb_ r2,emuflags
	tst r2,#PALTIMING
	ldreq r2,=DAC_TIMER_NTSC
	ldrne r2,=DAC_TIMER_PAL
	strh r2,[r1]
	mov r2,#0x80
	strh r2,[r1,#2]
	b 2f
1:
	ldrb r1,[r3,#dac_on]
	movs r1,r1
	beq 2f
	ldrb r1,[r3,#dac_idle]
	add r1,r1,#1
	strb r1,[r3,#dac_idle]
	cmp r1,#DAC_IDLE_FRAMES
	movhs r1,#0
	strhsb r1,[r3,#dac_on]
2:
	@the level holds until the next write, so time is known up to now
	ldr r1,[r3,#dac_widx]
	sub r1,r0,r1
	cmp r1,#0
	bicgt r1,r0,#0xFF
	strgt r1,[r3,#dac_widx]
	ldmfd sp!,{r0,r3,pc}

@----------------------------------------------------------------------------
dac_irq_fill:	@from timer1interrupt: r0 = PCMWAV write position.
				@globalptr is set.  Changes r0-r8, r12.
@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldr r2,=REG_BASE+REG_TM0CNT_L
	ldrb_ r3,emuflags
	tst r3,#PALTIMING
	ldreq r3,=DAC_TIMER_NTSC
	ldrne r3,=DAC_TIMER_PAL
	strh r3,[r2]		@DAC rate (a DMC sample may have used another)

	ldr r7,=dac_state
	ldr r2,[r7,#dac_widx]
	ldr r3,[r7,#dac_ridx]
	sub r2,r2,r3		@r2 = distance behind the newest write, in dots
	cmp r2,#64<<8
	blt 1f
	cmp r2,#DAC_MAXLAG<<8
	ble 2f
1:	@ran dry or fell far behind: jump back to the normal distance
	ldr r3,[r7,#dac_widx]
	sub r3,r3,#DAC_LAG<<8
	mov r2,#DAC_LAG<<8
	mov r6,#0
	str r6,[r7,#dac_acc]
2:
	@step (dots per sample) = 256 + error/16 + accumulated error/128
	mov r2,r2,asr#8
	sub r2,r2,#DAC_LAG
	ldr r6,[r7,#dac_acc]
	add r6,r6,r2
	cmp r6,#8192
	movgt r6,#8192
	cmn r6,#8192
	movlt r6,#0
	sublt r6,r6,#8192
	str r6,[r7,#dac_acc]
	mov r6,r6,asr#7
	add r6,r6,r2,asr#4
	add r6,r6,#256
	cmp r6,#160
	movlt r6,#160
	cmp r6,#320
	movgt r6,#320

	ldr r8,[r7,#dac_tail]
	ldr r12,[r7,#dac_head]
	sub r2,r12,r8
	cmp r2,#DAC_QUEUE*4
	subhi r8,r12,#DAC_QUEUE*2	@overrun (nothing played for a while): drop the oldest
	@DC level follows the playback level with a time constant of 64 refills
	@(0.4s), slow enough that sampling the level once per refill adds no
	@audible noise
	ldrsb lr,[r7,#dac_level]
	ldr r1,[r7,#dac_dc]
	mov r2,lr,lsl#8
	sub r2,r2,r1
	add r1,r1,r2,asr#6
	str r1,[r7,#dac_dc]
	mov r1,r1,asr#8
	dac_output
	add r5,r7,#DAC_STATE_SIZE	@dac_queue
	cmp r8,r12
	addeq r4,r3,#0x40000000	@queue empty: next write is far in the future
	movne r2,r8,lsl#20
	ldrne r4,[r5,r2,lsr#20]
	ldr pc,=dac_fill_loop
dac_fill_done:
	ldr r7,=dac_state
	str r3,[r7,#dac_ridx]
	str r8,[r7,#dac_tail]
	ldmfd sp!,{pc}
@----------------------------------------------------------------------------
 .pool

 .section .iwram, "ax", %progbits
 .align 2
@----------------------------------------------------------------------------
_4011w:	@Delta Counter load register.  r0 = value, changes r0-r2.
@----------------------------------------------------------------------------
	and r0,r0,#0x7F
	mov r1,r0,lsl#1
	sub r1,r1,#0x80		@GBA has -128 -> +127
	str_ r1,pcmlevel		@Start level for DMC samples

	@queue entry: timestamp (low 8 bits cleared) | value
	ldr_ r1,cycles_to_run
	sub r1,r1,cycles,asr#CYC_SHIFT
	ldr_ r2,timestamp
	add r1,r1,r2
	bic r1,r1,#0xFF
	orr r0,r0,r1
	ldr r2,=dac_state
	str r1,[r2,#dac_widx]
	ldr r1,[r2,#dac_head]
	add r2,r2,#DAC_STATE_SIZE
	mov r1,r1,lsl#20
	str r0,[r2,r1,lsr#20]	@entry first, then the count the interrupt reads
	sub r2,r2,#DAC_STATE_SIZE
	ldr r1,[r2,#dac_head]
	add r1,r1,#4
	str r1,[r2,#dac_head]
	bx lr

@----------------------------------------------------------------------------
dac_fill_loop:	@from dac_irq_fill.  r0 = PCMWAV write position, r1 = DC level,
	@r3 = playback time, r4 = next queue entry, r5 = dac_queue, r6 = step,
	@r8 = tail, r12 = head, lr = output level.  r2, r7 scratch.
@----------------------------------------------------------------------------
	@PCMWAV is in palette RAM, which has no byte writes: collect 4 samples
	@in r2, until the marker bit shifts out
	mov r2,#0x80000000
0:
	bic r7,r4,#0xFF
	subs r7,r7,r3
	ble 2f			@next write is due
1:
	movs r2,r2,lsr#8
	orr r2,r2,lr,lsl#24
	add r3,r3,r6
	bcc 0b
	str r2,[r0],#4
	mov r2,#0x80000000
	tst r0,#0xFF		@PCMWAV ends on a 256-byte boundary
	bne 0b
	ldr pc,=dac_fill_done
2:
	and lr,r4,#0x7F
	sub lr,lr,#64
	strb lr,[r5,#dac_level-DAC_STATE_SIZE]
	dac_output
	add r8,r8,#4
	cmp r8,r12
	addeq r4,r3,#0x40000000
	movne r7,r8,lsl#20
	ldrne r4,[r5,r7,lsr#20]
	b 0b
 .pool

 .if ((PCMWAV+PCMWAVSIZE) & 0xFF) != 0
 .error "dac_fill_loop expects PCMWAV to end on a 256-byte boundary"
 .endif

 .section .sbss, "aw", %nobits
 .align 2
	.global dac_state
dac_state:
	.space DAC_STATE_SIZE
dac_queue:
	.space DAC_QUEUE*4
