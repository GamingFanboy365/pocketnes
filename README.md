# pocketnes
An NES emulator for GBA. My repo is a fork of https://github.com/catskull/pocketnes , which in turn is a mirror of the code taken from the [archive.org](https://web.archive.org/web/20160307074955/http://nes.pocketheaven.com/) mirror, last updated on July 1, 2013. The last version released was 9.98.

Credit to all original authors.

Additions:
    
- Fixed Makefile and linker scripts (.ld) to compile under modern devkitARM using a Docker container (devkitpro/devkitarm).

- Fixed strict C99/C23 pointer errors and inline assembly clobber list errors.

- Rewrote read_rom_header in loadcart.c to safely parse NES 2.0 headers (bypassing the old DiskDude hack) and extract extended ROM sizes and NTSC/PAL/Dendy timing flags.

- Upgraded the Python builder script to dynamically compile multiple .nes ROMs into a single pocketnes.gba multicart payload, automatically generating the dynamic menu and injecting the required 48-byte metadata header for each game.

- Implemented Mapper 30 (UNROM 512)

- Implemented Mapper 38 (Tengen Custom): A highly specialized, single-register Famicom hardware board that hijacks the $7000 SRAM space. Example game: Crime Busters

- Implemented Mapper 41 (Caltron / Myriad): A complex multicart architecture. Fully operational including menu and multi-game selection. Example games: Caltron 6-in-1 and Myriad 6-in-1

- Implemented Mapper 89 (Sunsoft-2 IC02): A proprietary Sunsoft board utilizing a highly packed single-byte register to simultaneously command PRG banking, CHR banking, and single-screen mirroring. Example game: Tetsuwan Atom (Astro Boy)

- Implemented Mapper 113 (HES NTD-8): An expansive unlicensed hardware architecture that intercepts the native Famicom APU/IO memory space ($4100-$5FFF) to orchestrate its bank switching. Example games: Challenge of the Dragon, Mahjong, and Puzzle

- Implemented Mapper 146 (Sachen NINA-06 Alias): It was routed directly into the existing Mapper 79 logic, instantly unlocking compatibility for several specific Asian unlicensed releases. Example games: Galactic Crusader or Silver Eagle

- Implemented Mapper 185 (CNROM Bypass Alias): This board originally featured a physical copy-protection diode that locked out standard emulators. By aliasing it to standard CNROM logic, we completely bypassed the hardware lockout. Example games: Spy vs. Spy, Mighty Bomb Jack, Bird Week, and Seicross

- Implemented Mapper 11 (Color Dreams / Wisdom Tree): A single register architecture that spans the entire upper half of the memory map to command 32KB PRG blocks and 8KB CHR blocks simultaneously. Example games: Spiritual Warfare, Crystal Mines, and Bible Adventures

- Implemented Mapper 225 (various multicarts): Menu boots but some individual game graphics are currently garbled, so it doesn't fully work yet. Tested on: 110-in-1

- Implemented Mapper 28 (various current homebrew titles): Tested on Action 53 Volume 4; menu boots but attempting to load individual games causes a crash dump message to occur.

To compile pocketnes.gba:

sudo docker run --rm -v "$PWD":/src -w /src devkitpro/devkitarm make

Please note I am using AI to help me code this, so I'm not a coder in the traditional sense.
