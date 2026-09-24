# PocketNES (GBA) fork: working rules

## Every pull request
- Rebuild before opening or updating a PR, and commit the results: `pocketnes.gba` and `pocketnes.elf` must match the sources in the PR. Build: `docker run --rm -v "$PWD":/src -w /src devkitpro/devkitarm make` (start `dockerd` first in a cloud session). Build in a scratch copy if you don't want to touch the tracked `build/` directory; only the two binaries need committing.
- Update `README.md` ("Additions" list) for every user-visible change: new or fixed mappers, core features, known limitations.
- Never commit NES ROMs or built multicarts. `.gitignore` blocks `*.nes`, `roms/` and `play_me.gba`; ROMs the owner shares for testing stay outside the repo.

## Code rules that have caused bugs
- `writemem_X` / `readmem_X` are offsets from `globalptr` (r10): write them with `str_`, never `ldr rN,=writemem_X`. This build uses `PRG_BANK_SIZE == 8`, so each slot covers 8KB; `$5000` shares `writemem_4` with the APU/joypad, so pass `$4000-$4FFF` on to `IO_W`.
- Mapper handlers keep their return address in `addy` (r12) across calls to `chr*_`, `map*_`, `mirror*_`. Any helper they call must preserve r12 (push/pop `addy`); C code does not.
- r3-r11 hold 6502 state. Handlers may use r0-r2 freely; save anything else.
- IWRAM is nearly full (about 636 bytes of stack left). Put new code in `.text` (ROM), not `.iwram`.
- Many files use CRLF line endings (`cart.s`, `ppu.s`, `6502.s`, `loadcart.c` …). Keep them CRLF when editing.

## Testing
- mGBA (libmgba) runs `pocketnes.gba` headlessly; a reference NES emulator runs the same ROM for side-by-side screenshots. FCEUX was used so far, but it does not support every mapper; Mesen2 has wider mapper coverage.
- blargg's `instr_test-v5` (in the public nes-test-roms collection) checks the CPU, including unofficial opcodes. Everything passes except the unstable opcodes `$AB`, `$9C`, `$9E`.
- When changing core code, compare old and new builds pixel for pixel on a set of CHR-ROM test ROMs to catch regressions.
