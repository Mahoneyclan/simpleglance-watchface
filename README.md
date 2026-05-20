# SimpleGlance Watchface — fenix 6 Pro

A clean digital watch face for the Garmin fenix 6 Pro with live weather.

> **Preview:** open `mockup.html` in your browser to see a pixel-accurate rendering.
> After taking a screenshot, save it as `store_assets/preview_face_500x500.png` to embed it here.

```
       🌙  🔵  🔋 2d
       Mon 09 Mar
         10 · 42
      ☀/🌙
  STEPS  |  °C  |  FLOORS
   8.2k  |  18° |    12
```

## Features

- **Time** — custom DIN Condensed Bold font at 100px, frosted-glass effect (outlined + filled), small dot colon
- **Date** — `DDD DD MMM` format (e.g. `Mon 09 Mar`)
- **Top icons** — Moon/Sun (time of day), Bluetooth status, battery bar + days remaining
- **Battery** — colour-coded: green >50%, orange 10–50%, red <10%
- **Weather** — current temperature shown in the centre bottom block, refreshed in the background via Open-Meteo (no API key needed)
- **Bottom blocks** — Steps (left) · Temperature in °C (centre) · Floors climbed (right)
- **Glance view** — compact time + temperature shown when browsing watch faces
- **Theme** — dark (white on black) or light/positive (black on white), toggled by one constant

## Supported Devices

| Device | Screen size | Tested |
|--------|-------------|--------|
| Garmin fenix 6 Pro | 260 × 260 px | ✓ |
| Garmin fenix 6 | 260 × 260 px | ✓ |

The watch face targets the fenix 6 series (260 × 260 px circular display). Other devices with the same screen dimensions may work but are not officially supported.

## Weather

Temperature is fetched from [Open-Meteo](https://open-meteo.com) — a free, open-source API with no registration or API key required.

- A background service fetches fresh weather on a configurable interval (default: every 30 minutes)
- GPS coordinates are cached from the last known fix, so weather refreshes even when the watch face is not on screen
- The centre bottom block shows your current temperature: GPS location preferred, falls back to your configured home location
- The glance view also shows the current temperature

### Settings

Change via **Garmin Connect app** → My Device → Watch Faces → SimpleGlance Watch Face → Settings.

| Setting | Default | Options |
|---------|---------|---------|
| Weather Refresh Interval | 30 min | 15 / 30 / 60 min |
| Home Location Name | Home | Any text (max 32 chars) |
| Home Latitude | -27.3705 | Decimal degrees, e.g. `-27.3705` |
| Home Longitude | 152.8691 | Decimal degrees, e.g. `152.8691` |

To find your home coordinates: open [Google Maps](https://maps.google.com), right-click your home → **Copy coordinates**.

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

**WatchFaceApp.mc** — App entry point. Starts the background weather timer (`Background.registerForTemporalEvent`), receives background data via `onBackgroundData()`, writes it to persistent Storage, and serves the glance view and background service delegate to the OS.

**WatchFaceBackground.mc** — Runs on the background timer (no UI, memory-restricted). Fetches current weather from Open-Meteo for the home location and the cached GPS location. Passes a compact array to `WatchFaceApp.onBackgroundData()` via `Background.exit()`. Ported from the SimpleGlance Weather Widget's `BackgroundService.mc`.

**WatchFaceView.mc** — Main watch face UI. Reads weather from Storage on each draw (lightweight dictionary lookup). Also fires a one-shot foreground fetch on first load when no cached data exists. Draws all UI elements: icons, date, custom-font time, and the three bottom data blocks (steps / temperature / floors).

**WatchFaceGlanceView.mc** — Compact preview shown when browsing watch faces or in glance mode. Reads system time and cached weather from Storage. Displays time (left, large) and temperature (right, smaller). Modelled on `WeatherGlanceView.mc` from the weather widget.

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
│   ├── WatchFaceApp.mc               # App entry point, background scheduler
│   ├── WatchFaceView.mc              # All drawing logic + foreground weather fetch
│   ├── WatchFaceBackground.mc        # Background weather service (Open-Meteo)
│   └── WatchFaceGlanceView.mc        # Compact glance view (time + temperature)
├── resources/
│   ├── properties.xml                # Weather settings (home location, refresh rate)
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
| Home weather location | Garmin Connect app → Settings, or default coords in `resources/properties.xml` |
| Weather refresh rate | Garmin Connect app → Settings |
| Font size | Regenerate atlases via `tools/switch_font.py`, update `resources/fonts/fonts.xml` |
| Battery thresholds | `drawBatteryGraphic()` in `WatchFaceView.mc` |
| Bottom block layout | `drawBlocks()` in `WatchFaceView.mc` |

## Data Source

Weather data provided by [Open-Meteo](https://open-meteo.com) — free, no API key required.

See [PRIVACY.md](PRIVACY.md) for the full privacy policy.

## License

© 2026 Mahoneyclan. All rights reserved.
