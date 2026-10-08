import sys, struct, os, zlib

# Known dumps whose iNES header has the wrong mapper number, by CRC32 of the
# data after the 16-byte header.  The packed copy gets the right mapper; the
# .nes file itself isn't changed.
HEADER_FIXES = {
    0xF46EF39A: 37,  # Super Mario Bros. + Tetris + Nintendo World Cup (Europe) (Rev A): header says 4
    0x848DC2A4: 114, # The Lion King (1995) (Unl): header says 4
}

def fix_header(nes_data):
    mapper = HEADER_FIXES.get(zlib.crc32(nes_data[16:]))
    if mapper is None or nes_data[:4] != b"NES\x1a":
        return nes_data, None
    fixed = bytearray(nes_data)
    fixed[6] = (fixed[6] & 0x0F) | ((mapper & 0x0F) << 4)
    fixed[7] = (fixed[7] & 0x0F) | (mapper & 0xF0)
    return bytes(fixed), mapper

if len(sys.argv) < 2:
    print("Usage: python3 builder.py game1.nes [game2.nes ...]")
    sys.exit(1)

emu_file = "pocketnes.gba"
out_file = "play_me.gba"

# Open output file and write the emulator core first
with open(out_file, "wb") as f_out:
    try:
        with open(emu_file, "rb") as f_emu:
            f_out.write(f_emu.read())
    except FileNotFoundError:
        print(f"CRITICAL ERROR: {emu_file} not found. Run 'make' first.")
        sys.exit(1)

    print(f"Building multicart payload into {out_file}...\n")
    
    success_count = 0

    # Loop through every NES file provided in the command arguments
    for nes_file in sys.argv[1:]:
        try:
            nes_data = open(nes_file, "rb").read()
        except FileNotFoundError:
            print(f"[-] ERROR: {nes_file} not found. Skipping.")
            continue

        nes_data, fixed_mapper = fix_header(nes_data)

        # Extract filename without extension for the ROM menu title
        game_name = os.path.basename(nes_file).replace(".nes", "")
        
        # Truncate to 31 chars and pad with null bytes for the 32-byte array
        game_name_bytes = game_name[:31].encode('ascii', 'ignore').ljust(32, b'\0')

        # Pack the 48-byte header: 
        # 32s (name), I (filesize), I (flags), I (spritefollow), I (reserved)
        header = struct.pack('<32sIIII', game_name_bytes, len(nes_data), 0, 0, 0)

        # Inject this game's header and ROM data into the compilation
        f_out.write(header)
        f_out.write(nes_data)
        
        print(f"[+] Injected: {game_name}" + (f" (header fixed: mapper {fixed_mapper})" if fixed_mapper is not None else ""))
        success_count += 1

print(f"\nSuccessfully compiled {success_count} game(s) into {out_file}!")