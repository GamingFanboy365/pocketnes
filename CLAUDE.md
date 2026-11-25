# PocketNES (GBA) fork: working rules

## Every pull request
- Rebuild before opening or updating a PR, and commit the results: `pocketnes.gba` and `pocketnes.elf` must match the sources in the PR. Build: `docker run --rm -v "$PWD":/src -w /src devkitpro/devkitarm make` (start `dockerd` first in a cloud session). Build in a scratch copy if you don't want to touch the tracked `build/` directory; only the two binaries need committing.
- Update `README.md` ("Additions" list) for every user-visible change: new or fixed mappers, core features, known limitations.
- Never commit NES ROMs or built multicarts. `.gitignore` blocks `*.nes`, `roms/` and `play_me.gba`; ROMs the owner shares for testing stay outside the repo.

## Code rules that have caused bugs
- `writemem_X` / `readmem_X` are offsets from `globalptr` (r10): write them with `str_`, never `ldr rN,=writemem_X`. This build uses `PRG_BANK_SIZE == 8`, so each slot covers 8KB; `$5000` shares `writemem_4` with the APU/joypad, so pass `$4000-$4FFF` on to `IO_W`.
- Mapper handlers keep their return address in `addy` (r12) across calls to `chr*_`, `map*_`, `mirror*_`. Any helper they call must preserve r12 (push/pop `addy`); C code does not.
- r3-r11 hold 6502 state. Handlers may use r0-r2 freely; save anything else.
- IWRAM is nearly full (about 620 bytes of stack left). Put new code in `.text` (ROM), not `.iwram`, unless it runs thousands of times a frame: even with the 3/1 wait states `set_fast_waitstates` (`waitcnt.s`) sets in `WAITCNT` on carts that can take them, ARM code in ROM takes several cycles per instruction. The `$4011` handler and DAC sample loop (`dac.s`) are in IWRAM for that reason; the space came from rolling up `pcm_mix`.
- Never set `WAITCNT` ($4000204) anywhere but `set_fast_waitstates` (`src/waitcnt.s`). The SuperCard can't be read at 3/1 wait states and SuperFW doesn't patch PocketNES, so a direct `$4317` write makes it crash at boot (forum report, fixed in PR 15/16). The probe checks the cart first and runs from a copy on the stack, so it must not fetch from ROM and must take no static RAM (PR 14's buffers depend on the EWRAM layout). The Makefiles stop the build if `REG_WAITCNT`, `0x4000204` or `0x4317` appears in any other source file (`equates.h` and the reset code in `io.s` excepted).
- MMC5 PRG RAM banks 1-3 (NES 2.0 games with more than 8KB, such as the Super Mario All-Stars port) are 24KB just below `instant_prg_banks` (`loadcart.c`). For that game they overlap PR 14's decoded-tile victim cache, which uses fixed EWRAM addresses (data at 0x02028800-0x02036800); the victim cache is off for mapper 5 (`bg_reload_prepare_vblank`), so keep it off there. BUFFER1-3 (`main.c`) are packed below them: don't move BUFFER3 back up.
- Many files use CRLF line endings (`cart.s`, `ppu.s`, `6502.s`, `loadcart.c` …). Keep them CRLF when editing.

## Testing
- mGBA (libmgba) runs `pocketnes.gba` headlessly; Mesen2 is the reference NES emulator for side-by-side screenshots (it supports far more mappers than FCEUX). Running Mesen2 2.1.1 headlessly (`Mesen --testrunner ROM script.lua` under `xvfb-run`) needed:
  - `~/.config/Mesen2/settings.json` present, or it opens a setup wizard: `{"Debug":{"ScriptWindow":{"AllowIoOsAccess":true}},"Nes":{"Port1":{"Type":"NesController"}}}` (Lua file I/O and a controller on port 1).
  - On Ubuntu 24.04 the bundled `MesenCore.so` crashes loading (static libstdc++ clash). Build the core from the matching source tag (`make core` after removing `-static-libgcc -static-libstdc++` from the makefile), copy it over `~/.config/Mesen2/MesenCore.so`, and `chattr +i` it so Mesen doesn't re-extract its own copy.
  - `LANG=C.UTF-8`, and absolute paths (Mesen changes its working directory).
- Scripted menu navigation must hold each button for about 4 frames with gaps; shorter presses get missed by PocketNES and the cursor lands on a different game.
- NESdev wiki exports shared for reference (`NESdevWiki*.xml`) are internal only and are git-ignored; never commit them.
- blargg's `instr_test-v5` (in the public nes-test-roms collection) checks the CPU, including unofficial opcodes. Everything passes except the unstable opcodes `$AB`, `$9C`, `$9E`.
- Sound can be checked headlessly too: libmgba's `core->getAudioChannel(core, 0/1)` returns blip buffers (`blip_set_rates`, then `blip_read_samples` after each frame) to write a WAV, and a Mesen2 Lua write callback on `$4000-$4017` logs what the game sends to the APU, with `cpu.cycleCount` for timing.
- Battery saves can be tested headlessly by loading and storing GBA SRAM through libmgba's bus (`busRead8`/`busWrite8` at 0x0E000000) before and after a run. mGBA gives 32KB of SRAM, so PocketNES uses its 32KB layout there: saves and states from 0x0000, the live NES SRAM at 0x6000.
- After touching `waitcnt.s` or the boot code, check both paths in mGBA: `WAITCNT` reads `$4317` after boot (gbarun `peek32 04000204`), and a test-only build that flips the first checksum (`eor r9,r9,#1` after `mov r9,r0`) goes back to the original setting and still runs a game.
- When changing core code, compare old and new builds pixel for pixel on a set of CHR-ROM test ROMs to catch regressions.
