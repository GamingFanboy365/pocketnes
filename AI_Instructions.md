# AI Collaboration Guide: Implementing NES Mappers for PocketNES (GBA)

## The Core Problem
Standard AI models (Claude, GPT, etc.) understand Famicom hardware logic but lack the "Environmental Knowledge" of the Game Boy Advance. If you ask an AI to write a mapper based only on NESdev Wiki specifications, the resulting code will almost always result in a **Black Screen** on boot.

This happens because the AI ignores the physical state of the machine at power-on.

## The 3 Golden Rules of GBA Implementation
To ensure a mapper boots on the first try, the following "High-Fidelity Anchors" must be enforced during the `mapperXXinit` sequence:

### 1. The Reset Vector Anchor (PRG Boot)
The NES looks for its starting instructions (Reset Vector) at `$FFFC-$FFFD`. In a multi-bank ROM, this location only exists in the **last** bank. 
* **The Fix:** You must force-map the last PRG bank on boot using the `mvn r0,#0` instruction. This targets bank `-1`, which the emulator masks to the highest valid bank for that ROM.
* **Assembly:**
    ```assembly
    mvn r0,#0
    bl_long map89ABCDEF_  @ For 32KB mappers
    @ OR
    bl_long mapCDEF_      @ For 16KB mappers
    ```

### 2. The Sprite 0 Hit Anchor (CHR Boot)
Many games hang in an infinite loop waiting for "Sprite 0" to collide with a background pixel. If CHR memory is empty on boot, the PPU renders nothing, the collision never occurs, and the game hard-locks on a black screen.
* **The Fix:** Always initialize CHR Bank 0 explicitly.
* **Assembly:**
    ```assembly
    mov r0,#0
    bl_long chr01234567_
    ```

### 3. The GBA Memory Map Hook (Hex Prefixes)
PocketNES routes writes based on the high nibble (the first digit) of the address. Use the `writemem_X` naming convention to target the correct hardware register:
* `writemem_4`: Targets `$4000-$5FFF` (Standard for HES/AVE mappers).
* `writemem_6`: Targets `$6000-$7FFF` (Standard for Tengen/BitCorp mappers).
* `writemem_8` through `writemem_F`: Standard `$8000-$FFFF` range.

## Implementation Template (The "Armored Skeleton")
When asking an AI for a new mapper, provide this skeleton to ensure compatibility:

```assembly
@ 1. Save LR for external calls
stmfd sp!,{lr}

@ 2. Force Boot PRG (Last Bank)
mvn r0,#0
bl_long map89ABCDEF_

@ 3. Force Boot CHR (Bank 0)
mov r0,#0
bl_long chr01234567_

@ 4. Register the Write Hook
@ Hooking $6000 range for Mapper 38/41 as an example:
adr r1,write_handler
str_ r1,writemem_6 

@ 5. Restore PC to return
ldmfd sp!,{pc}
```

## The "Register Preservation" Rule

In the `write_handler`, the written data arrives in `r0`. PocketNES internal macros (like `strb_` or `bl_long`) frequently overwrite `r0` for their own calculations.

* **The Fix:** Immediately push `r4` to the stack and move the written data (`r0`) into `r4`. Use `r4` for your bit-shifting logic to prevent data corruption.

Code snippet

```write_handler:
    stmfd sp!,{r4,lr}
    mov r4,r0      @ Protect data in r4
    @ ... logic ...
    ldmfd sp!,{r4,pc}```
