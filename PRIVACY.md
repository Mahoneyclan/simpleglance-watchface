# Privacy Policy — SimpleGlance Watch Face

**Last updated: 20 May 2026**

## Overview

SimpleGlance Watch Face ("the app") is a Connect IQ watch face that displays the current time, date, activity stats, and live weather conditions. This policy explains what data the app accesses and how it is used.

## Data Collected

### Location Data

The app accesses your device's GPS coordinates solely to fetch weather data for your current location. Coordinates are:

- Read from the device's Position API (a cached fix — no continuous GPS tracking)
- Stored temporarily on the device (Garmin Application Storage) to allow the background weather service to fetch weather between watch face sessions
- Never transmitted to any server other than the weather API described below
- Never shared with third parties

### Weather Data

Weather data is retrieved from [Open-Meteo](https://open-meteo.com), a free and open-source weather API. The only information sent to Open-Meteo is your GPS latitude and longitude (rounded to 4 decimal places, approximately ±11 m precision). Open-Meteo does not require account registration and does not track users. See [Open-Meteo's privacy policy](https://open-meteo.com/en/terms) for details.

### Activity Data

The app reads step count and floors-climbed data from your device's ActivityMonitor. This data is:

- Used only for on-screen display (steps progress drives the clock face colour)
- Never transmitted, stored externally, or shared

## Data Not Collected

The app does **not** collect, store, or transmit:

- Personal identification information
- Device identifiers or serial numbers
- Usage analytics or telemetry
- Heart rate, sleep, or any health data beyond steps and floors
- Any data beyond GPS coordinates for weather requests

## Data Storage

Weather data, GPS coordinates, and cached weather results are stored locally on your Garmin device using Garmin's Application Storage API. This data is used only to display weather on the watch face. It is not accessible to or shared with any third party.

## Third-Party Services

| Service    | Purpose      | Privacy Policy                         |
|------------|--------------|----------------------------------------|
| Open-Meteo | Weather data | https://open-meteo.com/en/terms        |

## Contact

For questions about this privacy policy, open an issue at:
https://github.com/Mahoneyclan/simpleglance-watchface/issues
