import sys, struct, os

if len(sys.argv) < 2:
    print("Usage: python3 builder.py mygame.nes")
    sys.exit(1)

emu_file = "pocketnes.gba"
nes_file = sys.argv[1]
out_file = "play_me.gba"

# Read the NES ROM
nes_data = open(nes_file, "rb").read()

# Get the filename without the .nes extension to use as the menu title
game_name = os.path.basename(nes_file).replace(".nes", "")
# Truncate to 31 chars and pad with null bytes to fill the 32-byte array
game_name_bytes = game_name[:31].encode('ascii', 'ignore').ljust(32, b'\0')

# Pack the 48-byte header: 
# 32s (name), I (filesize), I (flags), I (spritefollow), I (reserved)
header = struct.pack('<32sIIII', game_name_bytes, len(nes_data), 0, 0, 0)

# Glue it all together!
with open(out_file, "wb") as f:
    f.write(open(emu_file, "rb").read())
    f.write(header)
    f.write(nes_data)

print(f"Successfully built {out_file}!")
