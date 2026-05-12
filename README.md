# pocketnes
An NES emulator for GBA

This is a mirror of the code taken from the [archive.org](https://web.archive.org/web/20160307074955/http://nes.pocketheaven.com/) mirror. It was last updated on July 1, 2013. The last version released was 9.98.

While this is mostly for posterity's sake, there is a goal to implement the NES 2.0 iNES format. If you can help in any way, it would be greatly appreciated!


Additions:
    
- Fixed Makefile and linker scripts (.ld) to compile under modern devkitARM using a Docker container (devkitpro/devkitarm).

- Fixed strict C99/C23 pointer errors and inline assembly clobber list errors.

- Rewrote read_rom_header in loadcart.c to safely parse NES 2.0 headers (bypassing the old DiskDude hack) and extract extended ROM sizes and NTSC/PAL/Dendy timing flags.

- Implemented Mapper 30 (UNROM 512) by creating map30.s and adding it to the mappertbl in cart.s.

- Wrote a Python builder script to inject the required 48-byte PocketNES metadata header and append .nes ROMs to the compiled pocketnes.gba binary.


To compile pocketnes.gba:

sudo docker run --rm -v "$PWD":/src -w /src devkitpro/devkitarm make

Please note I am using AI to help me code this, so I'm not a coder in the traditional sense.
