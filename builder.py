import sys, struct, os

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
        
        print(f"[+] Injected: {game_name}")
        success_count += 1

print(f"\nSuccessfully compiled {success_count} game(s) into {out_file}!")