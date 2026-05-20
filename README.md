# SimpleGlance Watchface — fenix 6 Pro

A clean digital watch face for the Garmin fenix 6 Pro.

> **Preview:** open `mockup.html` in your browser to see a pixel-accurate rendering.
> After taking a screenshot, save it as `store_assets/preview_face_500x500.png` to embed it here.

```
       🌙  🔵  🔋 2d
       Mon 09 Mar
         10 · 42
      ☀/🌙
    STEPS  |  FLOORS
     8.2k  |    12
```

## Features

- **Time** — custom DIN Condensed Bold font at 100px, frosted-glass effect (outlined + filled), small dot colon
- **Date** — `DDD DD MMM` format (e.g. `Mon 09 Mar`)
- **Top icons** — Moon/Sun (time of day), Bluetooth status, battery bar + days remaining
- **Battery** — colour-coded: green >50%, orange 10–50%, red <10%
- **Bottom blocks** — Steps (left) and Floors climbed (right)
- **Theme** — dark (white on black) or light/positive (black on white), toggled by one constant

## Supported Devices

| Device | Screen size | Tested |
|--------|-------------|--------|
| Garmin fenix 6 Pro | 260 × 260 px | ✓ |
| Garmin fenix 6 | 260 × 260 px | ✓ |

The watch face targets the fenix 6 series (260 × 260 px circular display). Other devices with the same screen dimensions may work but are not officially supported.

## Theme

Switch between dark and light mode by editing one line in `source/WatchFaceView.mc`:

```monkeyc
const DARK_MODE = true;   // white text on black (default)
const DARK_MODE = false;  // black text on white (positive/paper screen)
```

| Element | Dark | Light |
|---|---|---|
| Background | Black | White |
| Time | Grey fill, white outline | Dark grey fill, black outline |
| Date / values | White | Black |
| Labels / dividers | Dark grey | Light grey |
| Battery | Red / orange / green | Red / orange / green |

## Architecture

**WatchFaceApp.mc** — App entry point. Returns the initial view to the Garmin OS.

**WatchFaceView.mc** — All drawing logic. Renders the top icons (Bluetooth, battery), date, custom-font time with frosted-glass effect, day/night icon, and the two bottom data blocks (steps and floors). The time fill colour shifts from grey to white as steps progress toward the daily goal.

## Prerequisites

- [Garmin Connect IQ SDK](https://developer.garmin.com/connect-iq/sdk/) 8.1.1+
- Java 11+ (Amazon Corretto 11 recommended on M1 Mac)
- A Garmin developer key (see below)

## Developer Key

Generate once:

```bash
openssl genrsa -out ~/.garmin_dev.key 4096
openssl pkcs8 -topk8 -inform PEM -outform DER -nocrypt \
  -in ~/.garmin_dev.key -out developer_key
```

The `developer_key` file (DER format) must be in the project root.

## Build

```bash
java -Xms1g -Dfile.encoding=UTF-8 -Dapple.awt.UIElement=true \
  -jar "$SDK/bin/monkeybrains.jar" \
  -o bin/garminwatchface.prg \
  -f monkey.jungle \
  -y developer_key \
  -d fenix6pro_sim \
  -w
```

Where `$SDK` is the path to your Connect IQ SDK, e.g.:
```
/Users/$USER/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-8.1.1-2025-03-27-66dae750f
```

## Run in Simulator

```bash
$SDK/bin/monkeydo bin/garminwatchface.prg fenix6pro
```

## Install on Device

**1. Build a release package:**

```bash
java -Xms1g -Dfile.encoding=UTF-8 -Dapple.awt.UIElement=true \
  -jar "$SDK/bin/monkeybrains.jar" \
  -o bin/garminwatchface.iq \
  -f monkey.jungle \
  -y developer_key \
  -d fenix6pro \
  -e -r
```

**2. Copy to watch via USB:**

```bash
cp bin/garminwatchface.iq /Volumes/GARMIN/GARMIN/APPS/
```

Eject the device — the watch installs it on reboot.

## Project Structure

```
├── manifest.xml                      # App metadata, permissions, target device
├── monkey.jungle                     # Build config
├── developer_key                     # DER signing key (not committed)
├── mockup.html                       # Browser-based watch face preview
├── PRIVACY.md                        # Privacy policy for Connect IQ store
├── source/
│   ├── WatchFaceApp.mc               # App entry point
│   └── WatchFaceView.mc              # All drawing logic
├── resources/
│   ├── drawables/
│   │   ├── drawables.xml             # Launcher icon declaration
│   │   └── launcher_icon.png         # 40×40 launcher icon
│   ├── fonts/
│   │   ├── fonts.xml                 # Font resource declarations
│   │   ├── time_font.fnt / .png      # White glyphs — dark mode
│   │   ├── time_font_light.fnt / .png # Black glyphs — light mode
│   │   └── time_font.ttf             # Source TTF (DIN Condensed Bold)
│   ├── layouts/
│   │   └── layout.xml
│   └── strings/
│       └── strings.xml               # App name string
├── store_assets/                     # Connect IQ store images (see store_assets/README.md)
├── image-generators/                 # Python script to generate store images
│   ├── generate_store_assets.py
│   ├── Cover/                        # Source screenshots for cover image
│   ├── Hero/                         # Source screenshots for hero banner
│   └── Preview/                      # Source screenshots for preview tiles
└── tools/
    ├── switch_font.py                # Utility: regenerate font atlases
    └── fonts/                        # Source TTF files
```

## Customisation

| Thing | Where |
|---|---|
| Theme (dark/light) | `const DARK_MODE` at top of `WatchFaceView.mc` |
| Font size | Regenerate atlases via `tools/switch_font.py`, update `resources/fonts/fonts.xml` |
| Battery thresholds | `drawBatteryGraphic()` in `WatchFaceView.mc` |
| Date format | `drawDate()` in `WatchFaceView.mc` |
| Bottom fields | `drawBlocks()` in `WatchFaceView.mc` |

## License

© 2026 Mahoneyclan. All rights reserved.
