// WatchFaceBackground.mc
// Background service that runs on a recurring timer — even when the watch face
// is not on-screen — to keep weather data fresh in persistent Storage.
//
// How it fits into the app:
//   WatchFaceApp.getServiceDelegate() → returns this class.
//   The Garmin OS calls onTemporalEvent() on the schedule set by
//   WatchFaceApp.scheduleBackground() (default: every 30 minutes).
//   When both HTTP requests finish, Background.exit() passes results back to
//   WatchFaceApp.onBackgroundData(), which saves them to Storage.
//   WatchFaceView then reads from Storage on every screen redraw.
//
// Ported from the SimpleGlance Weather Widget's BackgroundService.mc.
// Simplified to current conditions only — no multi-day forecast needed
// for a watch face bottom block.

import Toybox.Application;
import Toybox.Background;
import Toybox.Communications;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;

// The (:background) annotation tells the compiler to include this class in the
// background compilation target (a separate, memory-restricted execution context).
(:background)
class WatchFaceBackground extends Toybox.System.ServiceDelegate {

    // ── Settings helpers ────────────────────────────────────────────────────
    // These read values set by the user in Garmin Connect → My Device →
    // Apps → this watch face → Settings.
    // Lat/lon are stored as strings because Connect IQ settings only support
    // alphanumeric keyboard input; a plain "number" type would round the decimal.

    private function homeName() as String {
        var v = Application.Properties.getValue("home_name");
        return (v != null) ? v as String : "Home";
    }
    private function homeLat() as Float {
        var v = Application.Properties.getValue("home_lat");
        return (v != null) ? (v as String).toFloat() : -27.3705f;
    }
    private function homeLon() as Float {
        var v = Application.Properties.getValue("home_lon");
        return (v != null) ? (v as String).toFloat() : 152.8691f;
    }

    // ── Request tracking ────────────────────────────────────────────────────
    // pending counts outstanding HTTP requests. Background.exit() is called
    // only after ALL requests complete (success or failure), so the OS gets
    // one atomic result rather than partial data.

    private var pending    as Number = 2;
    private var gpsResult  as Array? = null;
    private var homeResult as Array? = null;

    function initialize() {
        System.ServiceDelegate.initialize();
    }

    // ── Main entry point ────────────────────────────────────────────────────
    // The Garmin OS calls this method when the background timer fires.
    // It always fetches home-location weather, and also fetches GPS-location
    // weather if WatchFaceView previously saved GPS coordinates to Storage.

    function onTemporalEvent() as Void {
        // Always fetch the configured home location
        fetchWeather(homeLat(), homeLon(), method(:onHomeData));

        // Only fetch GPS location if coordinates have been cached by WatchFaceView.
        // (WatchFaceView calls Position.getInfo() in onLayout and writes to Storage.)
        var stored = Storage.getValue("gps_coords") as Array<Double>?;
        if (stored != null) {
            fetchWeather(stored[0], stored[1], method(:onGpsData));
        } else {
            // No GPS fix cached yet — skip GPS request and wait for only 1 response
            pending    = 1;
            gpsResult  = null;
        }
    }

    // ── HTTP request ────────────────────────────────────────────────────────
    // Fires an Open-Meteo GET for current conditions only.
    // forecast_days=1 keeps the payload small (we don't show a forecast on the face).
    // wind_speed_unit=kmh gives km/h everywhere so we don't need to convert.
    // timezone=auto tells Open-Meteo to use the coordinates' local timezone.

    private function fetchWeather(
        lat      as Float or Double,
        lon      as Float or Double,
        callback as Method
    ) as Void {
        Communications.makeWebRequest(
            "https://api.open-meteo.com/v1/forecast",
            {
                "latitude"        => lat.format("%.4f"),
                "longitude"       => lon.format("%.4f"),
                "current"         => "temperature_2m,apparent_temperature,wind_speed_10m,wind_direction_10m,wind_gusts_10m,precipitation",
                "wind_speed_unit" => "kmh",
                "forecast_days"   => "1",
                "timezone"        => "auto"
            },
            { :method => Communications.HTTP_REQUEST_METHOD_GET },
            callback
        );
    }

    // ── Response callbacks ───────────────────────────────────────────────────

    function onGpsData(responseCode as Number, data as Dictionary?) as Void {
        gpsResult = parseWeather(responseCode, data, "GPS");
        pending--;
        if (pending == 0) {
            // Both requests done — return [gpsWeather, homeWeather] to WatchFaceApp
            Background.exit([ gpsResult, homeResult ]);
        }
    }

    function onHomeData(responseCode as Number, data as Dictionary?) as Void {
        homeResult = parseWeather(responseCode, data, homeName());
        pending--;
        if (pending == 0) {
            Background.exit([ gpsResult, homeResult ]);
        }
    }

    // ── Response parser ──────────────────────────────────────────────────────
    // Converts the Open-Meteo JSON dictionary into a compact 7-element array.
    // Returns null if the HTTP request failed or the expected fields are absent.
    //
    // Array layout (matches the weather widget format for consistency):
    //   [0] Float  — temperature_2m       current temperature in °C
    //   [1] Float  — apparent_temperature "feels like" temperature in °C
    //   [2] Float  — wind_speed_10m       wind speed in km/h
    //   [3] Float  — wind_gusts_10m       wind gusts in km/h (falls back to speed)
    //   [4] Number — wind_direction_10m   degrees (0 = N, 90 = E, 180 = S, 270 = W)
    //   [5] String — location label       "GPS" or the home name from settings
    //   [6] Float  — precipitation        current precipitation in mm

    private function parseWeather(
        responseCode as Number,
        data         as Dictionary?,
        name         as String
    ) as Array? {
        if (responseCode != 200 || data == null) {
            return null;
        }
        var cur  = data["current"] as Dictionary;
        var gust = cur["wind_gusts_10m"];
        if (gust == null) { gust = cur["wind_speed_10m"]; }  // gusts not always reported
        var deg  = cur["wind_direction_10m"];
        if (deg == null) { deg = 0; }
        var rain = cur["precipitation"];
        if (rain == null) { rain = 0.0f; }
        return [
            cur["temperature_2m"],        // 0 — °C
            cur["apparent_temperature"],  // 1 — °C feels like
            cur["wind_speed_10m"],        // 2 — km/h
            gust,                         // 3 — km/h gusts
            deg,                          // 4 — direction degrees
            name,                         // 5 — location label
            rain                          // 6 — mm precipitation
        ] as Array;
    }
}
