// WatchFaceGlanceView.mc
// Compact glance view shown in the watch glance loop — the small preview
// displayed when the user swipes to browse faces, or in ambient glance mode.
//
// Displays a one-line summary:  TIME (left)    TEMPERATURE (right)
// e.g.                          10:42          18°C
//
// Temperature comes from the last cached GPS weather written by WatchFaceBackground
// or WatchFaceView. If no data has been fetched yet, the temperature slot shows "--".
//
// Modelled on WeatherGlanceView.mc from the SimpleGlance Weather Widget.

import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;
import Toybox.WatchUi;

// (:glance) annotation: compiled into the glance-mode target only.
// Glance mode has a small memory budget, so keep this class minimal.
(:glance)
class WatchFaceGlanceView extends WatchUi.GlanceView {

    function initialize() {
        GlanceView.initialize();
    }

    function onUpdate(dc as Dc) as Void {
        GlanceView.onUpdate(dc);

        var W = dc.getWidth();
        var H = dc.getHeight();

        // Clear to black (glance surfaces are always dark)
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        // ── Time ──────────────────────────────────────────────────────────────
        // Read the current clock time and format as 12-hour "H:MM".
        var clockTime = System.getClockTime();
        var hours     = clockTime.hour % 12;
        if (hours == 0) { hours = 12; }
        var timeStr = hours.format("%d") + ":" + clockTime.min.format("%02d");

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            0, H / 2,
            Graphics.FONT_NUMBER_MEDIUM,
            timeStr,
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER
        );

        // ── Temperature ───────────────────────────────────────────────────────
        // Try GPS weather first (most relevant to the user's current location),
        // fall back to home weather, then show "--" if nothing is cached yet.
        var weather = Storage.getValue("gps_weather") as Array?;
        if (weather == null) {
            weather = Storage.getValue("home_weather") as Array?;
        }

        var tempStr = "--";
        if (weather != null && weather.size() >= 1) {
            // Index 0 of the weather array is the temperature in °C (see WatchFaceBackground)
            var temp = Math.round(weather[0] as Float).toNumber();
            tempStr  = temp.format("%d") + "°C";
        }

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            W - 2, H / 2,
            Graphics.FONT_SMALL,
            tempStr,
            Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }
}
