# Garmin Watch Face — fenix6pro

A clean digital watch face for the Garmin fenix 6 Pro, built with Monkey C / Connect IQ SDK 8.x.

## Features

- **Time** — DIN Condensed Bold custom font at 100px, frosted glass effect (outlined + filled), small dot colon
- **Date** — `DDD DD MMM` format (e.g. `Mon 09 Mar`)
- **Top icons** — Moon/Sun (time of day), Bluetooth status, Battery level
- **Battery** — colour-coded: green >50%, orange 10–50%, red <10%
- **Bottom fields** — Steps (left) and Floors climbed (right)
- **Theme** — dark (white on black) or light/positive (black on white), toggled by one constant

## Layout

```
       🌙  🔵  🔋
       Mon 09 Mar
        10 · 42
      STEPS | FLOORS
      8.2k  |   12
```

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
| Labels / divider | Dark grey | Light grey |
| Battery | Red / orange / green (unchanged) | Red / orange / green (unchanged) |

## Prerequisites

- [Garmin Connect IQ SDK](https://developer.garmin.com/connect-iq/sdk/) 8.1.1+
- Java 11+
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
  -o bin/garminwatchface.prg \
  -f monkey.jungle \
  -y developer_key \
  -d fenix6pro \
  -e -r
```

This produces `bin/garminwatchface.iq`.

**2. Copy to watch via USB:**

```bash
cp bin/garminwatchface.iq /Volumes/GARMIN/GARMIN/APPS/
```

Eject the device — the watch installs it on reboot.

## Project Structure

```
├── manifest.xml                  # App metadata, permissions, target device
├── monkey.jungle                 # Build config
├── developer_key                 # DER-format signing key (not committed)
├── source/
│   ├── WatchFaceApp.mc           # App entry point
│   └── WatchFaceView.mc          # All drawing logic (theme constant at top)
└── resources/
    ├── drawables/
    │   ├── drawables.xml         # Launcher icon declaration
    │   └── launcher_icon.png     # 40x40 launcher icon
    ├── fonts/
    │   ├── fonts.xml             # Font resource declarations
    │   ├── time_font.fnt         # BMFont descriptor — white glyphs (dark mode)
    │   ├── time_font_0.png       # Glyph sprite atlas — white (dark mode)
    │   ├── time_font_light.fnt   # BMFont descriptor — black glyphs (light mode)
    │   ├── time_font_light_0.png # Glyph sprite atlas — black (light mode)
    │   └── time_font.ttf         # Source TTF (DIN Condensed Bold)
    ├── layouts/
    │   └── layout.xml
    └── strings/
        └── strings.xml           # App name string
```

## Customisation

| Thing | Where |
|---|---|
| Theme | `const DARK_MODE` at top of `WatchFaceView.mc` |
| Font size | Regenerate atlases via Python script (change `SIZE`), update `fonts.xml` |
| Battery thresholds | `drawBatteryGraphic()` in `WatchFaceView.mc` |
| Date format | `drawDate()` in `WatchFaceView.mc` |
| Bottom fields | `drawBlocks()` in `WatchFaceView.mc` |
