#!/usr/bin/env python3
"""
switch_font.py — regenerate the time font atlas and rebuild the watch face.

Usage:
    python3 tools/switch_font.py              # uses ACTIVE_FONT below
    python3 tools/switch_font.py bebas        # override via CLI arg
    python3 tools/switch_font.py list         # show all presets

After running, the simulator will launch automatically.
"""

import sys, os, subprocess
from PIL import ImageFont, ImageDraw, Image

# ── Change this to try a different font ───────────────────────────────────────
ACTIVE_FONT = "hv_thin"
# ─────────────────────────────────────────────────────────────────────────────

TOOLS_DIR   = os.path.dirname(os.path.abspath(__file__))
PROJECT_DIR = os.path.dirname(TOOLS_DIR)
FONTS_DIR   = os.path.join(PROJECT_DIR, "resources", "fonts")
SDK         = "/Users/mahoney/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-8.1.1-2025-03-27-66dae750f"

# Each preset is a dict with:
#   path        — path to the TTF/OTF/TTC font file
#   name        — human-readable name written into the .fnt descriptor
#   index       — font index inside a TTC collection (0 for regular TTF/OTF)
#   width       — horizontal squeeze factor (1.0 = natural width, 0.78 = condensed)
#
# TTC font indices for HelveticaNeue.ttc on macOS (may vary by OS version):
#   0=Regular  2=Bold  4=Light  6=Thin/UltraLight
#
# SF Pro: download the "SF Pro" font package from https://developer.apple.com/fonts/
# and install it. The Thin weight will then appear at /Library/Fonts/SF-Pro-Display-Thin.otf
PRESETS = {
    "bebas":    {
        "path":  os.path.join(TOOLS_DIR, "fonts/BebasNeue-Regular.ttf"),
        "name":  "Bebas Neue",
        "index": 0,
        "width": 0.78,
    },
    "oswald":   {
        "path":  os.path.join(TOOLS_DIR, "fonts/Oswald-Bold.ttf"),
        "name":  "Oswald Bold",
        "index": 0,
        "width": 0.78,
    },
    "din":      {
        "path":  "/System/Library/Fonts/Supplemental/DIN Condensed Bold.ttf",
        "name":  "DIN Condensed Bold",
        "index": 0,
        "width": 0.78,
    },
    "arial":    {
        "path":  "/System/Library/Fonts/Supplemental/Arial Narrow Bold.ttf",
        "name":  "Arial Narrow Bold",
        "index": 0,
        "width": 0.78,
    },
    # ── Thin / Apple-style presets ─────────────────────────────────────────────
    "hv_thin":  {
        # Helvetica Neue Thin — built into every Mac, no download needed.
        # Very close to SF Pro Display Ultralight in style.
        "path":  "/System/Library/Fonts/HelveticaNeue.ttc",
        "name":  "Helvetica Neue Thin",
        "index": 6,   # index 6 = Thin/UltraLight in the TTC collection
        "width": 0.95,
    },
    "sfpro":    {
        # SF Pro Display Thin — Apple's exact lock-screen font.
        # Download from https://developer.apple.com/fonts/ then install.
        # After installing you will find the file at the path below.
        "path":  "/Library/Fonts/SF-Pro-Display-Thin.otf",
        "name":  "SF Pro Display Thin",
        "index": 0,
        "width": 0.95,
    },
}

DIGITS  = "0123456789"
CAP_H   = 110   # target capital-height in pixels
PAD     = 2     # padding around each glyph cell

# ─────────────────────────────────────────────────────────────────────────────

def load_at_capheight(path, index, target_h):
    """Find the smallest point size that produces glyphs at least target_h px tall."""
    for pt in range(10, 400):
        f = ImageFont.truetype(path, pt, index=index)
        bb = f.getbbox("0")
        if bb[3] - bb[1] >= target_h:
            return f, pt
    raise RuntimeError(f"Could not reach {target_h}px height with {path}")

def make_atlas(font, glyphs, cell_w, atlas_w, atlas_h, color, width_scale):
    atlas = Image.new("RGBA", (atlas_w, atlas_h), (0, 0, 0, 0))
    chars = []
    x = 0
    for ch in DIGITS:
        g = glyphs[ch]
        tmp = Image.new("RGBA", (g["w"] + PAD * 2, atlas_h), (0, 0, 0, 0))
        ImageDraw.Draw(tmp).text((PAD + g["xoff"], PAD + g["yoff"]), ch, font=font, fill=color)
        squeezed_w = max(1, int(tmp.width * width_scale))
        tmp = tmp.resize((squeezed_w, atlas_h), Image.LANCZOS)
        indent = (cell_w - squeezed_w) // 2
        atlas.paste(tmp, (x + indent, 0), tmp)
        chars.append({
            "id": ord(ch), "x": x, "y": 0,
            "width": cell_w, "height": atlas_h,
            "xoffset": 0, "yoffset": 0, "xadvance": cell_w,
        })
        x += cell_w
    return atlas, chars

def write_fnt(path, png_name, chars, face_name, pt, pad, line_h, base, atlas_w, atlas_h):
    with open(path, "w") as f:
        f.write(f'info face="{face_name}" size={pt} bold=1 italic=0 charset="" unicode=1 stretchH=100 smooth=1 aa=1 padding={pad},{pad},{pad},{pad} spacing=1,1 outline=0\n')
        f.write(f'common lineHeight={line_h} base={base} scaleW={atlas_w} scaleH={atlas_h} pages=1 packed=0 alphaChnl=1 redChnl=0 greenChnl=0 blueChnl=0\n')
        f.write(f'page id=0 file="{png_name}"\n')
        f.write(f'chars count={len(DIGITS)}\n')
        for g in chars:
            f.write(f"char id={g['id']}   x={g['x']} y={g['y']} width={g['width']} height={g['height']} xoffset={g['xoffset']} yoffset={g['yoffset']} xadvance={g['xadvance']} page=0 chnl=15\n")
        f.write("kernings count=0\n")

def next_pow2(n):
    p = 1
    while p < n: p <<= 1
    return p

def generate(preset_key):
    preset      = PRESETS[preset_key]
    path        = preset["path"]
    name        = preset["name"]
    index       = preset["index"]
    width_scale = preset["width"]

    print(f"Font: {name}  ({path})")
    font, pt = load_at_capheight(path, index, CAP_H)
    print(f"  pt={pt}  width_scale={width_scale}")

    glyphs = {}
    for ch in DIGITS:
        bb = font.getbbox(ch)
        glyphs[ch] = {"w": bb[2]-bb[0], "h": bb[3]-bb[1], "xoff": -bb[0], "yoff": -bb[1]}

    widths = [g["w"] for g in glyphs.values()]
    print(f"  digit widths: min={min(widths)} max={max(widths)}")

    cell_w  = int((max(widths) + PAD * 2) * width_scale) + PAD * 2
    line_h  = max(g["h"] for g in glyphs.values()) + PAD * 2
    base    = max(g["h"] + g["yoff"] for g in glyphs.values()) + PAD
    atlas_w = next_pow2(cell_w * len(DIGITS))
    atlas_h = next_pow2(line_h)
    print(f"  cell={cell_w}  atlas={atlas_w}x{atlas_h}")

    # Dark atlas (white glyphs — used in DARK_MODE)
    a, c = make_atlas(font, glyphs, cell_w, atlas_w, atlas_h, (255, 255, 255, 255), width_scale)
    a.save(os.path.join(FONTS_DIR, "time_font_0.png"))
    write_fnt(os.path.join(FONTS_DIR, "time_font.fnt"), "time_font_0.png",
              c, name, pt, PAD, line_h, base, atlas_w, atlas_h)

    # Light atlas (black glyphs — used when DARK_MODE = false)
    a, c = make_atlas(font, glyphs, cell_w, atlas_w, atlas_h, (0, 0, 0, 255), width_scale)
    a.save(os.path.join(FONTS_DIR, "time_font_light_0.png"))
    write_fnt(os.path.join(FONTS_DIR, "time_font_light.fnt"), "time_font_light_0.png",
              c, f"{name} Light", pt, PAD, line_h, base, atlas_w, atlas_h)

    print(f"  Atlases written → resources/fonts/")

def build_and_run():
    jar = os.path.join(SDK, "bin/monkeybrains.jar")
    prg = os.path.join(PROJECT_DIR, "bin/garminwatchface.prg")
    key = os.path.join(PROJECT_DIR, "developer_key")
    jng = os.path.join(PROJECT_DIR, "monkey.jungle")

    print("\nBuilding...")
    result = subprocess.run(
        ["java", "-Xms1g", "-Dfile.encoding=UTF-8", "-Dapple.awt.UIElement=true",
         "-jar", jar, "-o", prg, "-f", jng, "-y", key, "-d", "fenix6pro_sim", "-w"],
        capture_output=True, text=True
    )
    out = result.stdout + result.stderr
    for line in out.splitlines():
        if "ERROR" in line or "WARNING" in line or "BUILD" in line:
            print(" ", line)

    if result.returncode != 0:
        print("Build FAILED — not launching simulator")
        return

    print("Launching simulator...")
    subprocess.Popen([os.path.join(SDK, "bin/monkeydo"), prg, "fenix6pro"])

# ─────────────────────────────────────────────────────────────────────────────

if __name__ == "__main__":
    arg = sys.argv[1].lower() if len(sys.argv) > 1 else ACTIVE_FONT

    if arg == "list":
        print("Available font presets:")
        for k, v in PRESETS.items():
            exists = "✓" if os.path.exists(v["path"]) else "✗ MISSING"
            print(f"  {k:12s}  {v['name']:30s}  {exists}")
        sys.exit(0)

    if arg not in PRESETS:
        print(f"Unknown preset '{arg}'. Run with 'list' to see options.")
        sys.exit(1)

    generate(arg)
    build_and_run()
