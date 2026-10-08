# pocketnes
An NES emulator for GBA. My repo is a fork of https://github.com/catskull/pocketnes , which in turn is a mirror of the code taken from the [archive.org](https://web.archive.org/web/20160307074955/http://nes.pocketheaven.com/) mirror, last updated on July 1, 2013. The last version released was 9.98.

Credit to all original authors.

Additions:
    
- Fixed Makefile and linker scripts (.ld) to compile under modern devkitARM using a Docker container (devkitpro/devkitarm).

- Fixed strict C99/C23 pointer errors and inline assembly clobber list errors.

- Rewrote read_rom_header in loadcart.c to safely parse NES 2.0 headers (bypassing the old DiskDude hack) and extract extended ROM sizes and NTSC/PAL/Dendy timing flags.

- Upgraded the Python builder script to dynamically compile multiple .nes ROMs into a single pocketnes.gba multicart payload, automatically generating the dynamic menu and injecting the required 48-byte metadata header for each game.

- Implemented Mapper 30 (UNROM 512): PRG and CHR-RAM banking, with nametable mirroring handled as the header specifies (horizontal, vertical, mapper-switched one-screen, four-screen, and submapper 3's switchable H/V). On self-flashable boards the $8000-$BFFF flash command writes are ignored; flash saving itself isn't emulated. Tested on: Mystic Origins

- Implemented Mapper 38 (Tengen Custom): A highly specialized, single-register Famicom hardware board that hijacks the $7000 SRAM space. Example game: Crime Busters

- Implemented Mapper 41 (Caltron / Myriad): A complex multicart architecture. Fully operational including menu and multi-game selection. Example games: Caltron 6-in-1 and Myriad 6-in-1

- Implemented Mapper 89 (Sunsoft-2 IC02): A proprietary Sunsoft board utilizing a highly packed single-byte register to simultaneously command PRG banking, CHR banking, and single-screen mirroring. Example game: Tetsuwan Atom (Astro Boy)

- Implemented Mapper 113 (HES NTD-8): An expansive unlicensed hardware architecture that intercepts the native Famicom APU/IO memory space ($4100-$5FFF) to orchestrate its bank switching. Example games: Challenge of the Dragon, Mahjong, and Puzzle

- Implemented Mapper 146 (Sachen NINA-06 Alias): It was routed directly into the existing Mapper 79 logic, instantly unlocking compatibility for several specific Asian unlicensed releases. Example games: Galactic Crusader or Silver Eagle

- Implemented Mapper 185 (CNROM Bypass Alias): This board originally featured a physical copy-protection diode that locked out standard emulators. By aliasing it to standard CNROM logic, we completely bypassed the hardware lockout. Example games: Spy vs. Spy, Mighty Bomb Jack, Bird Week, and Seicross

- Implemented Mapper 11 (Color Dreams / Wisdom Tree): A single register architecture that spans the entire upper half of the memory map to command 32KB PRG blocks and 8KB CHR blocks simultaneously. Example games: Spiritual Warfare, Crystal Mines, and Bible Adventures

- Implemented Mapper 225 (various multicarts), including the 4-bit RAM at $5800. Tested on: 110-in-1 (2MB PRG, 1MB CHR); with the CHR ROM support below, the games tested (about 25 menu entries) match Mesen2, apart from one entry that also crashes in Mesen2 and FCEUX.

- Implemented Mapper 28 (Action 53, various current homebrew titles): Tested on Action 53 Volume 4; the menu works and nearly every game plays correctly, including the ones that switch CHR-RAM banks. Known exception: one golf game shows the wrong background colour.

- Fixed Mapper 228 (Action 52 / Cheetahmen II) 16KB/32KB PRG mode selection. With the CHR ROM support below, the Action 52 intro, title screen and menu display correctly, and 17 of the first 18 games tested match the reference emulators. Illuminator shows the right graphics at first but hangs on a black-and-grey screen after its opening transition; it looks like a CPU/NMI timing race rather than a mapper problem.

- Added the stable unofficial 6502 opcodes that were missing (ANC, ALR, ARR, and every addressing mode of LAX, SAX, SLO, RLA, SRE, RRA, DCP and ISC) and fixed the carry flag of AXS. Before, these ran as one-byte NOPs, so the byte after them was executed as an instruction and the game went off the rails. This fixed Star Evil, f-ff and the Dungeon game in Action 53. blargg's instr_test-v5 now passes everything except the unstable opcodes $AB, $9C and $9E.

- Fixed the automatic speed hacks treating loops that only poll $2002 (waiting for the vblank or sprite 0 flag) as idle loops, and loops that read $2007 (which advances the VRAM address). Skipping their iterations could make a game miss the vblank flag and hang, as the 110-in-1 menu sometimes did.

- Added banked CHR-RAM (up to 32KB, four 8KB banks) for mappers 28 and 30. The live bank stays in the emulator's normal 8KB CHR-RAM, and the other banks are kept in otherwise unused GBA VRAM; switching banks swaps them and re-renders the tiles. Savestates only store the live bank.

- Added support for CHR ROM larger than 256KB (up to 2MB), for any mapper. PocketNES stores CHR page numbers in single bytes, so large CHR ROMs now use 8-bit "virtual" page numbers that are assigned on demand and recycled when they run out (src/bigchr.c, src/chrram.s). Savestates for these games may show wrong graphics until the game next switches CHR banks.

- Added playback of direct $4011 writes ("raw PCM"), which games use for digitized voices and drums by writing samples to the DMC's DAC from a timed CPU loop. Before, these were ignored, so the "Lights, camera, Action 52!" intro and similar clips were silent. Each write is queued with its timestamp and played back through the GBA's DirectSound channel at about 21 kHz, about 30ms behind the game (src/dac.s). Playback follows the emulation speed, so when a game's sample loop is more than PocketNES can run at full speed, the clip plays slightly slower and lower rather than breaking up (the Action 52 intro runs at about 98% with the faster wait states below). Matches Mesen2's output for the Action 52 intro.

- PocketNES now sets the cartridge wait states (WAITCNT) to 3/1 with the prefetch buffer on, the setting commercial games use, instead of leaving the power-on default of 4/2 without prefetch. All of the emulator code that runs from ROM gets faster: the Action 52 intro goes from about 90% to about 98% speed, and startup finishes a few frames sooner. SRAM stays at 8 wait states, and the default is restored before resetting to the BIOS or a flash cart menu. If a very old flash cart can't run at these wait states, this is the change to look at.

- Added the standard save-type ID string (SRAM_V113) to the ROM. Flash carts and emulators look for it to decide which save memory a game gets; without it, some carts give no SRAM (so NES game saves and PocketNES settings are lost) or ask you to pick a save type. PocketNES still checks whether the cart has 32KB or 64KB of SRAM.

- Implemented Mapper 37 (Super Mario Bros. + Tetris + Nintendo World Cup, Europe): an MMC3 with an outer bank register at $6000-$7FFF that picks each game's PRG and CHR area; it only takes writes while the MMC3 enables PRG RAM, as on the real board. All three games boot from the menu and match Mesen2. Some dumps of this cart have mapper 4 in their header; builder.py recognises the common one by checksum and packs it as mapper 37 (the .nes file isn't changed).

- Implemented Mapper 82 (Taito X1-017): PRG and CHR banking (including the CHR A12 inversion), mirroring, and the 5KB battery RAM at $6000-$73FF. The chip's IRQ counter isn't emulated (no known game uses it), and neither are the RAM enable registers. Tested on: SD Keiji: Blader, which matches Mesen2 through the title, save file select, name entry and gameplay. Also fixed PocketNES replacing a mapper's own $6000-$7FFF handler with the battery-save handler when the game has a battery, which broke mappers with registers in that range.

- Implemented Mapper 211 (J.Y. Company): the PRG and CHR banking modes, per-nametable mirroring, the multiplier at $5800, and the IRQ counter (PPU A12 mode, run on the MMC3 scanline counter). Tested on: Tiny Toon Adventures 6, whose gameplay and status bar match Mesen2, and Donkey Kong Country 4 (the 2-in-1 with The Jungle Book 2), whose menu, title, world map and first level match Mesen2. Known issue: one scene of its intro uses a ROM nametable (nametable data read from CHR ROM), which isn't emulated, so it shows the wrong graphics for a few seconds. Mappers 90 and 209 use the same chip but aren't enabled yet.

To-do: mappers not implemented yet. Board names and example games come from each mapper's page on the NESdev wiki.

| Mapper | Board / chip | Example games | Notes |
|---|---|---|---|
| 13 | NES-CPROM | Videomation | the only known game |
| 31 | homebrew CPLD board (InfiniteNESLives Mapper 31, EverDrive N8) | 2A03 Puritans, Famicompo Pico, RNDM, EZNSF | mostly homebrew music (NSF) carts |
| 44 | MMC3-based multicart | Super Big 7-in-1 | |
| 45 | GA23C ASIC (MMC3-based multicart) | Super New Year Cart 15-in-1 (超强年度新卡) | |
| 46 | Rumble Station (Color Dreams multicart) | Rumblestation 15-in-1 | |
| 47 | MMC3-based multicart | Super Spike V'Ball + Nintendo World Cup | |
| 48 | Taito TC0690 | Don Doko Don 2, Bubble Bobble 2 (J), Captain Saver (J), The Jetsons: Cogswell's Caper! (J), Bakushou!! Jinsei Gekijou 3 | many dumps are mislabelled as mapper 33 |
| 49 | MMC3-based multicart | Super HIK 4-in-1 | |
| 52 | Realtec 8213 and similar MMC3-based multicarts | Mario Party 7-in-1, Well 8-in-1 (AB-128) | |
| 57 | NROM/CNROM-style multicart | GK 47-in-1, 6-in-1 (SuperGK) | |
| 58 | NROM/CNROM-based multicarts | 21-in-1 (AS-5321), 50-in-1 (WQ1806 B), 55-in-1 (WQ2006 B), 68-in-1 (HKX5268) | mapper 213 is a duplicate |
| 61 | GS-2017, NTDEC 0324, NTDEC BS-N032 | Tetris Family 9-in-1, HQ 15-in-1, 32-in-1 | |
| 62 | multicart | Super 700-in-1 | |
| 83 | Cony/Yoko ASIC | Street Fighter II Pro, Fatal Fury 2, World Heroes 2, Mortal Kombat II/V Pro | |
| 90 | J.Y. Company ASIC (boards without ROM nametables) | Mortal Kombat II Special, Tekken 2, Super Mario World, Aladdin, Final Fight 3 | same chip as mapper 211 |
| 91 | JY830623C, YY840238C, EJ-006-1 | Street Fighter 3, Mortal Kombat II, Dragon Ball Z 2, Mario & Sonic 2 | |
| 95 | NAMCOT-3425 | Dragon Buster (J) | |
| 96 | discrete logic | Oeka Kids: Anpanman no Hiragana Daisuki, Oeka Kids: Anpanman to Oekaki Shiyou!! | needs the Oeka Kids drawing tablet |
| 114 | MMC3 clone with scrambled registers | Aladdin, The Lion King, Super Donkey Kong, Boogerman (pirates) | mapper 182 is a duplicate |
| 121 | Kǎshèng A9711/A9713 (protected MMC3 clone) | Sonic & Knuckles 5, Sonic 3D Blast 6, Street Fighter Zero 2 '97, Super Real Bout 97 | |
| 125 | UNL-LH32 | Monty no Doki Doki Daisassou (Monty on the Run) | a Famicom Disk System game converted to cartridge |
| 153 | Bandai FCG board, LZ93D50 with 8KB battery WRAM | Famicom Jump II: Saikyou no 7-nin | the only game |
| 154 | NAMCOT-3453 | Devil Man | mapper 88 plus a nametable control bit |
| 155 | MMC1A (2ME board) | two games rely on MMC1A behaviour (not named on the wiki) | like mapper 1, but PRG RAM is always enabled |
| 157 | Bandai Datach Joint ROM System | Battle Rush, Crayon Shin-chan: Ora to Poi Poi, Dragon Ball Z: Gekitou Tenkaichi Budoukai, J-League Super Top Players, SD Gundam Wars | Datach barcode reader games |
| 159 | Bandai FCG board, LZ93D50 with 128-byte EEPROM | Dragon Ball Z: Kyoushuu! Saiya-jin, Magical Taruruuto-kun: Fantastic World!!, SD Gundam Gaiden: Knight Gundam Monogatari | |
| 188 | Bandai M60001 | Karaoke Studio | needs the cartridge's microphone |
| 189 | TXC PT8154/PT8159 MMC3 clones | Thunder Warrior, Street Fighter II: The World Warrior (pirate), Master Fighter II | |
| 200 | MG109 | 1993 Super 50-in-1 | |
| 201 | BNROM/CNROM-style multicart | 8-in-1, 21-in-1 (2006-CA) | |
| 202 | 150-in-1 pirate cart | none named | |
| 203 | multicart | 35-in-1 (Duck Hunt, Hogan's Alley, Wild Gunman, Battle City) | |
| 207 | Taito X1-005 variant | Fudou Myouou Den | a modified mapper 80 board |
| 209 | J.Y. Company ASIC | Mighty Morphin' Power Rangers III, Mike Tyson's Punch-Out!! (pirate), Shin Samurai Spirits 2 | same chip as mapper 211, plus a CHR latch |
| 210 | Namco 175 / Namco 340 | Famista '91, Famista '92, Family Circuit '91, Chibi Maruko-chan: Uki Uki Shopping, Dream Master | many dumps are set to mapper 19 |
| 212 | discrete-logic multicart ("BMC Super HiK 300-in-1") | none named | |
| 213 | multicart | 9999999-in-1, 168-in-1 | duplicate of mapper 58 |
| 218 | single PRG ROM, nametable RAM used as CHR | Magic Floor, Starfight | |
| 226 | discrete logic | 76-in-1, Super 42-in-1, 63-in-1 | |
| 227 | 810449-C-A1, FW-01, N120-72 | 1992 Contra 120-in-1 | |
| 229 | BMC 31-in-1 | none named | |
| 231 | multicart | 20-in-1 | |
| 233 | multicart | an "Unknown Multi Cart 1" (Galaxian, 10 Yard Fight, Balloon Fight, ...) | the wiki says that dump may be bad |
| 234 | Maxi 15 (CNROM and NINA-03 combination) | Maxi 15 multicart | |
| 242 | ET-113 variant (UNL-43272) | Waixing's Chinese RPGs (none named) | |
| 268 | AA6023 ASIC (COOLBOY, MINDKIDS and other boards) | 218-in-1 Real Game, MegaMan 8-in-1, Data East All-Star Collection, PocketGames 150-in-1 | NES 2.0 only; up to 32MB of PRG ROM |
| 256 and up | other NES 2.0-only boards | most newer pirate and multicart boards | |

The Famicom Disk System (mapper 20) isn't supported either; it's a disk drive add-on rather than a cartridge board.

To compile pocketnes.gba:

sudo docker run --rm -v "$PWD":/src -w /src devkitpro/devkitarm make

Please note I am using AI to help me code this, so I'm not a coder in the traditional sense.
