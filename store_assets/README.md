# Store Assets

This folder holds all images required for the Garmin Connect IQ store listing.

## Required files

| File | Size | Purpose |
|------|------|---------|
| `icon_128x128.png` | 128 × 128 px | Small app icon (used in device app list) |
| `icon_500x500.png` | 500 × 500 px | Store listing icon |
| `cover_500x500.png` | 500 × 500 px | Store cover / hero tile |
| `hero_1440x720.png` | 1440 × 720 px | Wide banner image (optional but recommended) |
| `preview_face_500x500.png` | 500 × 500 px | Screenshot — main watch face (dark mode) |
| `preview_face_light_500x500.png` | 500 × 500 px | Screenshot — light mode (optional) |
| `preview_face_with_watch_500x500.png` | 500 × 500 px | Watch face composited onto a photo of the device |

Up to **4 screenshots** (500 × 500 px each) can be uploaded in the Connect IQ store developer portal.

## How to generate the screenshots

### Option 1 — Simulator screenshot

1. Build the watch face for the simulator (`fenix6pro_sim`)
2. Run it with `monkeydo`
3. Use the Garmin Connect IQ Simulator File → Export Screenshot
4. Resize to 500 × 500 px in any image editor

### Option 2 — mockup.html

The `mockup.html` file in the repo root renders a pixel-accurate watch face preview in your browser:

```bash
open mockup.html          # macOS — opens in default browser
```

Screenshot the rendered face, then save the output here.

### Option 3 — Python generator (see image-generators/)

The `image-generators/generate_store_assets.py` script composites simulator screenshots
onto a watch photograph and adds styled title text, producing all store images in one pass.
See `image-generators/README.md` for setup and usage.

## Upload checklist

- [ ] `icon_500x500.png` — square, no transparency
- [ ] At least 1 screenshot (500 × 500 px)
- [ ] `hero_1440x720.png` — recommended for featured placement
- [ ] App description text written (keep it under 4 000 chars)
- [ ] Privacy policy URL added (link to `PRIVACY.md` hosted on GitHub or a web page)
