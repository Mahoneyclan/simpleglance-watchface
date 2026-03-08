# Garmin Watch Face — fenix6pro

A clean digital watch face for the Garmin fenix 6 Pro, built with Monkey C / Connect IQ SDK 8.x.

## Features

- **Time** — DIN Condensed Bold custom font at 100px, frosted glass effect (white outline, grey fill), small dot colon
- **Date** — `DDD DD MMM` format (e.g. `Mon 09 Mar`)
- **Top icons** — Moon/Sun (time of day), Bluetooth status, Battery level
- **Battery** — colour-coded: green >50%, orange 10–50%, red <10%
- **Bottom fields** — Steps (left) and Floors climbed (right)

## Layout

```
       🌙  🔵  🔋
       Mon 09 Mar
        10 : 42
      STEPS | FLOORS
      8.2k  |   12
```

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
│   └── WatchFaceView.mc          # All drawing logic
└── resources/
    ├── drawables/
    │   ├── drawables.xml         # Launcher icon declaration
    │   └── launcher_icon.png     # 40x40 launcher icon
    ├── fonts/
    │   ├── fonts.xml             # Custom font resource declaration
    │   ├── time_font.fnt         # BMFont descriptor for DIN Condensed Bold
    │   ├── time_font_0.png       # Glyph sprite atlas (digits 0–9)
    │   └── time_font.ttf         # Source TTF (used to generate .fnt)
    ├── layouts/
    │   └── layout.xml
    └── strings/
        └── strings.xml           # App name string
```

## Customisation

| Thing | Where |
|---|---|
| Font size | Regenerate `time_font.fnt` / `time_font_0.png` via the Python script, change `SIZE` variable |
| Battery thresholds | `drawBatteryGraphic()` in `WatchFaceView.mc` |
| Date format | `drawDate()` in `WatchFaceView.mc` |
| Bottom fields | `drawBlocks()` in `WatchFaceView.mc` |

### Regenerating the font atlas

```bash
python3 << 'EOF'
# Edit SIZE to change glyph height in pixels
SIZE = 100
# ... (see full script in project history)
EOF
```
