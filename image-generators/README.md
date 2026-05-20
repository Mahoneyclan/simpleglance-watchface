# Image Generators

Python scripts that produce all Connect IQ store images in one pass.

## What it generates

All output goes into `../store_assets/`:

| Output file | Size |
|-------------|------|
| `cover_500x500.png` | 500 × 500 |
| `hero_1440x720.png` | 1440 × 720 |
| `preview_face_500x500.png` | 500 × 500 |
| `preview_face_with_watch_500x500.png` | 500 × 500 |

## Prerequisites

Python 3.9+ and the following packages:

```bash
pip install pillow numpy
```

## Input images (place these before running)

```
image-generators/
├── Cover/
│   └── Watch.png          # Simulator screenshot of watch face — portrait crop
├── Hero/
│   └── Watch.png          # Same or wider crop for the banner
└── Preview/
    ├── Face.png            # Plain simulator screenshot (no watch frame)
    └── Face with Watch.png # Screenshot composited onto a watch photo
```

### How to get the simulator screenshot

1. Build for simulator: `monkeydo bin/garminwatchface.prg fenix6pro`
2. Garmin Simulator → File → Export Screenshot
3. Save to the appropriate folder above

## Run

```bash
# From the repo root:
python image-generators/generate_store_assets.py
```

Output files appear in `store_assets/`.

## Customise

Edit the constants at the top of `generate_store_assets.py` to change:
- `APP_TITLE` — text shown on the cover and hero images
- `BG_DARK` / `BG_RGB` — background gradient colour
- Font sizes and positions
