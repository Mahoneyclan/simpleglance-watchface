// WatchFaceView.mc
// Main watch face view — draws everything visible on screen.
//
// Layout (top → bottom):
//   [BT icon]  [battery bar + days]
//   Day DD Mon
//   HH · MM   (custom font, frosted-glass effect)
//   ☀/🌙
//   STEPS | °C  | FLOORS
//
// Weather is read from Storage (written by WatchFaceBackground) and also
// fetched directly on first load when no cached data exists yet.
// This mirrors the pattern used in the SimpleGlance Weather Widget.

import Toybox.ActivityMonitor;
import Toybox.Application;
import Toybox.Communications;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.Position;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.WatchUi;

// ── Theme ─────────────────────────────────────────────────────────────────────
// Set DARK_MODE = false for a white/positive screen (black numbers on white).
const DARK_MODE = true;
// ─────────────────────────────────────────────────────────────────────────────

class WatchFaceView extends WatchUi.WatchFace {

    private var _screenWidth  as Number = 260;
    private var _centerX      as Number = 130;
    private var _font         as Graphics.FontReference or Null = null;

    // Home location defaults — overwritten from Settings in onLayout.
    private var _homeLat as Float = -27.3705f;
    private var _homeLon as Float = 152.8691f;

    // Guard: prevents a second foreground weather fetch while one is in flight.
    private var _weatherFetched as Boolean = false;

    // Cached outline offsets for the frosted-glass time effect.
    // These are computed once and reused every second in drawTime().
    private var _offsets as Array<Array<Number>> = [
        [-3,-3],[-2,-3],[-1,-3],[0,-3],[1,-3],[2,-3],[3,-3],
        [-3,-2],                                     [3,-2],
        [-3,-1],                                     [3,-1],
        [-3, 0],                                     [3, 0],
        [-3, 1],                                     [3, 1],
        [-3, 2],                                     [3, 2],
        [-3, 3],[-2, 3],[-1, 3],[0, 3],[1, 3],[2, 3],[3, 3],
        [-2,-2],[-1,-2],[0,-2],[1,-2],[2,-2],
        [-2,-1],                    [2,-1],
        [-2, 0],                    [2, 0],
        [-2, 1],                    [2, 1],
        [-2, 2],[-1, 2],[0, 2],[1, 2],[2, 2],
        [-1,-1],[0,-1],[1,-1],[-1,0],[1,0],[-1,1],[0,1],[1,1]
    ];

    function initialize() {
        WatchFace.initialize();
    }

    // onLayout is called once when the watch face becomes active.
    // Use it to measure the screen, load the font, cache GPS coordinates,
    // and trigger an immediate weather fetch if the cache is empty.
    function onLayout(dc as Dc) as Void {
        _screenWidth = dc.getWidth();
        _centerX     = _screenWidth / 2;

        // Load the custom time font once here rather than every second in drawTime().
        var fontRez = DARK_MODE ? Rez.Fonts.TimeFont : Rez.Fonts.TimeFontLight;
        _font = WatchUi.loadResource(fontRez) as Graphics.FontReference;

        // Read home location from Settings (set via Garmin Connect app on phone).
        var latStr = Application.Properties.getValue("home_lat") as String?;
        var lonStr = Application.Properties.getValue("home_lon") as String?;
        if (latStr != null) { _homeLat = latStr.toFloat(); }
        if (lonStr != null) { _homeLon = lonStr.toFloat(); }

        // Cache GPS coordinates so the background service can use them on its
        // next timer tick, even after this view is no longer active.
        // Position.getInfo() returns a cached fix — no extra power used.
        var posInfo = Position.getInfo();
        if (posInfo != null && posInfo.position != null) {
            var pos = posInfo.position.toDegrees();
            // Sanity-check: valid lat range is -90..+90
            if (pos[0] > -90.0 && pos[0] < 90.0) {
                Storage.setValue("gps_coords", pos);
            }
        }

        // Trigger an immediate home-location fetch only if nothing is cached yet.
        // After this first fetch the background service handles all future refreshes.
        if (!_weatherFetched && Storage.getValue("home_weather") == null) {
            _weatherFetched = true;
            fetchHomeWeather();
        }
    }

    function onShow() as Void {
    }

    function onUpdate(dc as Dc) as Void {
        var bg = DARK_MODE ? Graphics.COLOR_BLACK : Graphics.COLOR_WHITE;
        dc.setColor(bg, bg);
        dc.clear();

        drawTopIcons(dc);
        drawDate(dc);
        drawTime(dc);
        drawDayNightIcon(dc);
        drawBlocks(dc);
    }

    // ── Weather fetch (foreground / first-load only) ──────────────────────────
    // This is only called once per watch-face session when Storage has no data.
    // After that the background timer (WatchFaceBackground) handles refreshes.

    private function fetchHomeWeather() as Void {
        Communications.makeWebRequest(
            "https://api.open-meteo.com/v1/forecast",
            {
                "latitude"        => _homeLat.format("%.4f"),
                "longitude"       => _homeLon.format("%.4f"),
                "current"         => "temperature_2m,apparent_temperature,wind_speed_10m,wind_direction_10m,wind_gusts_10m,precipitation",
                "wind_speed_unit" => "kmh",
                "forecast_days"   => "1",
                "timezone"        => "auto"
            },
            { :method => Communications.HTTP_REQUEST_METHOD_GET },
            method(:onWeatherResponse)
        );
    }

    // Called when the foreground weather fetch completes.
    // Parses the response into the same 7-element array format as the
    // background service (see WatchFaceBackground.parseWeather).
    function onWeatherResponse(responseCode as Number, data as Dictionary?) as Void {
        if (responseCode != 200 || data == null) {
            return;
        }
        // Read home name from Settings, fall back to "Home"
        var name = Application.Properties.getValue("home_name") as String?;
        if (name == null) { name = "Home"; }

        var cur  = data["current"] as Dictionary;
        var gust = cur["wind_gusts_10m"];
        if (gust == null) { gust = cur["wind_speed_10m"]; }
        var deg  = cur["wind_direction_10m"];
        if (deg == null) { deg = 0; }
        var rain = cur["precipitation"];
        if (rain == null) { rain = 0.0f; }

        // Save in the same format the background service uses, so drawBlocks
        // can read from either key ("gps_weather" or "home_weather") uniformly.
        var weatherData = [
            cur["temperature_2m"],        // 0 — °C
            cur["apparent_temperature"],  // 1 — °C feels like
            cur["wind_speed_10m"],        // 2 — km/h
            gust,                         // 3 — km/h gusts
            deg,                          // 4 — direction degrees
            name,                         // 5 — location label
            rain                          // 6 — mm precipitation
        ] as Array;

        Storage.setValue("home_weather", weatherData);
        WatchUi.requestUpdate();  // redraw the face now that we have temperature data
    }

    // ── Top row: Bluetooth + Battery ─────────────────────────────────────────

    private function drawTopIcons(dc as Dc) as Void {
        var y        = 20;
        var settings = System.getDeviceSettings();
        var stats    = System.getSystemStats();

        drawBtIcon(dc, _centerX - 20, y, settings.phoneConnected);
        drawBatteryGraphic(dc, _centerX + 20, y, stats.battery.toNumber());

        // Days of charge remaining — shown to the right of the battery graphic
        if (stats.batteryInDays != null) {
            var days  = (stats.batteryInDays as Float).toNumber();
            var label = days.toString() + "d";
            var fg    = DARK_MODE ? Graphics.COLOR_DK_GRAY : Graphics.COLOR_LT_GRAY;
            dc.setColor(fg, Graphics.COLOR_TRANSPARENT);
            dc.drawText(_centerX + 34, y, Graphics.FONT_XTINY, label,
                Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }

    // Moon or sun icon centred above the colon, within the time area
    private function drawDayNightIcon(dc as Dc) as Void {
        var hour = System.getClockTime().hour;
        if (hour >= 12) {
            drawMoonIcon(dc, _centerX, 82);
        } else {
            drawSunIcon(dc, _centerX, 82);
        }
    }

    private function drawDate(dc as Dc) as Void {
        var now    = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var days   = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
        var months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun",
                      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
        var dateStr = Lang.format("$1$ $2$ $3$", [
            days[now.day_of_week - 1],
            now.day.format("%02d"),
            months[now.month - 1]
        ]);
        var fg = DARK_MODE ? Graphics.COLOR_WHITE : Graphics.COLOR_BLACK;
        dc.setColor(fg, Graphics.COLOR_TRANSPARENT);
        dc.drawText(_centerX, 40, Graphics.FONT_MEDIUM, dateStr,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    // Custom font time with frosted-glass effect (outline pass + fill pass).
    // Colon drawn manually as two small dots so it doesn't dominate.
    // Fill colour shifts from grey → white as steps progress toward daily goal.
    private function drawTime(dc as Dc) as Void {
        var clockTime = System.getClockTime();
        var hours     = clockTime.hour % 12;
        if (hours == 0) { hours = 12; }
        var hrStr  = hours.format("%02d");
        var minStr = clockTime.min.format("%02d");
        var font   = _font;
        var justL  = Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER;
        var y      = 118;
        var cx     = _centerX;

        // Measure both strings to centre the whole group precisely
        var hrDims  = dc.getTextDimensions(hrStr,  font);
        var minDims = dc.getTextDimensions(minStr, font);
        var hrW     = hrDims[0];
        var minW    = minDims[0];
        var colonW  = 20;
        var totalW  = hrW + colonW + minW;
        var startX  = cx - totalW / 2;
        var hrX     = startX;
        var minX    = startX + hrW + colonW;

        // Steps progress (0.0 – 1.0) drives the time fill colour
        var stepPct = 0.0f;
        var actInfo = ActivityMonitor.getInfo();
        if (actInfo != null && actInfo.steps != null && actInfo.stepGoal != null) {
            var pct = (actInfo.steps as Number).toFloat() / (actInfo.stepGoal as Number).toFloat();
            stepPct = pct < 0.0f ? 0.0f : (pct > 1.0f ? 1.0f : pct);
        }

        // Dark:  0xAAAAAA (170) → 0xFFFFFF (255)   channel = 170 + 85*p
        // Light: 0x555555 (85)  → 0x000000 (0)     channel = 85  - 85*p
        var outlineCol = DARK_MODE ? Graphics.COLOR_WHITE : Graphics.COLOR_BLACK;
        var ch = DARK_MODE
            ? (170 + (85.0f * stepPct).toNumber())
            : (85  - (85.0f * stepPct).toNumber());
        var fillCol = (ch * 65536) + (ch * 256) + ch;

        // Outline pass — loop over every cached offset to build the thick border
        dc.setColor(outlineCol, Graphics.COLOR_TRANSPARENT);
        for (var i = 0; i < _offsets.size(); i++) {
            var dx = _offsets[i][0];
            var dy = _offsets[i][1];
            dc.drawText(hrX  + dx, y + dy, font, hrStr,  justL);
            dc.drawText(minX + dx, y + dy, font, minStr, justL);
        }

        // Fill pass — draw at (0, 0) offset on top of the outline
        dc.setColor(fillCol, Graphics.COLOR_TRANSPARENT);
        dc.drawText(hrX,  y, font, hrStr,  justL);
        dc.drawText(minX, y, font, minStr, justL);

        // Colon: two filled circles centred between hours and minutes
        var dotX  = startX + hrW + colonW / 2;
        var dotR  = 2;
        var dotY1 = y - 10;
        var dotY2 = y + 10;

        dc.setColor(outlineCol, Graphics.COLOR_TRANSPARENT);
        for (var i = 0; i < _offsets.size(); i++) {
            var dx = _offsets[i][0];
            var dy = _offsets[i][1];
            dc.fillCircle(dotX + dx, dotY1 + dy, dotR);
            dc.fillCircle(dotX + dx, dotY2 + dy, dotR);
        }
        dc.setColor(fillCol, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(dotX, dotY1, dotR);
        dc.fillCircle(dotX, dotY2, dotR);
    }

    // ── Bottom data blocks ────────────────────────────────────────────────────
    // Three equal columns across the bottom of the face:
    //   Left   → STEPS
    //   Centre → current temperature in °C (from weather cache)
    //   Right  → FLOORS climbed
    //
    // Temperature reads from Storage every draw — lightweight dictionary lookup.
    // GPS weather is preferred; falls back to home weather; shows "--" if neither cached.

    private function drawBlocks(dc as Dc) as Void {
        var actInfo = ActivityMonitor.getInfo();

        // ── Activity values ────────────────────────────────────────────────
        var stepsVal = "--" as String;
        if (actInfo != null && actInfo.steps != null) {
            var v = actInfo.steps as Number;
            stepsVal = v >= 1000
                ? Lang.format("$1$k", [(v / 1000.0).format("%.1f")])
                : v.toString();
        }

        var floorsVal = "--" as String;
        if (actInfo != null && actInfo.floorsClimbed != null) {
            floorsVal = (actInfo.floorsClimbed as Number).toString();
        }

        // ── Weather temperature ────────────────────────────────────────────
        // Try GPS location first (most relevant), fall back to home location.
        // Index 0 of the weather array is current temperature in °C.
        var weather = Storage.getValue("gps_weather") as Array?;
        if (weather == null) {
            weather = Storage.getValue("home_weather") as Array?;
        }
        var tempVal = "--" as String;
        if (weather != null) {
            var t = Math.round(weather[0] as Float).toNumber();
            tempVal = t.format("%d") + "°";
        }

        // ── Layout: three equal columns ────────────────────────────────────
        // Dividers at 1/3 and 2/3 of screen width; block centres at 1/6, 1/2, 5/6.
        var y     = 205;
        var x1    = _screenWidth / 6;        // STEPS  (left column)
        var x2    = _centerX;                 // °C     (centre column)
        var x3    = _screenWidth * 5 / 6;    // FLOORS (right column)
        var divX1 = _screenWidth / 3;
        var divX2 = _screenWidth * 2 / 3;
        var just  = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;
        var fg      = DARK_MODE ? Graphics.COLOR_WHITE   : Graphics.COLOR_BLACK;
        var labelFg = DARK_MODE ? Graphics.COLOR_DK_GRAY : Graphics.COLOR_LT_GRAY;

        // STEPS
        dc.setColor(labelFg, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x1, y - 10, Graphics.FONT_XTINY, "STEPS", just);
        dc.setColor(fg, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x1, y + 10, Graphics.FONT_SMALL, stepsVal, just);

        // Dividers
        dc.setColor(labelFg, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(divX1, y - 18, divX1, y + 18);
        dc.drawLine(divX2, y - 18, divX2, y + 18);

        // TEMPERATURE
        dc.setColor(labelFg, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x2, y - 10, Graphics.FONT_XTINY, "°C", just);
        dc.setColor(fg, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x2, y + 10, Graphics.FONT_SMALL, tempVal, just);

        // FLOORS
        dc.setColor(labelFg, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x3, y - 10, Graphics.FONT_XTINY, "FLOORS", just);
        dc.setColor(fg, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x3, y + 10, Graphics.FONT_SMALL, floorsVal, just);
    }

    // ── Top icon helpers ──────────────────────────────────────────────────────

    private function drawMoonIcon(dc as Dc, cx as Number, cy as Number) as Void {
        var fg = DARK_MODE ? Graphics.COLOR_WHITE : Graphics.COLOR_BLACK;
        var bg = DARK_MODE ? Graphics.COLOR_BLACK : Graphics.COLOR_WHITE;
        dc.setColor(fg, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx, cy, 6);
        dc.setColor(bg, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx + 3, cy - 2, 5);
    }

    private function drawSunIcon(dc as Dc, cx as Number, cy as Number) as Void {
        var fg = DARK_MODE ? Graphics.COLOR_WHITE : Graphics.COLOR_BLACK;
        dc.setColor(fg, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx, cy, 4);
        var ix = [ 0,  3,  5,  3,  0, -3, -5, -3];
        var iy = [-5, -3,  0,  3,  5,  3,  0, -3];
        var ox = [ 0,  5,  8,  5,  0, -5, -8, -5];
        var oy = [-8, -5,  0,  5,  8,  5,  0, -5];
        for (var i = 0; i < 8; i++) {
            dc.drawLine(cx + ix[i], cy + iy[i], cx + ox[i], cy + oy[i]);
        }
    }

    private function drawBtIcon(dc as Dc, cx as Number, cy as Number, connected as Boolean) as Void {
        var disconnectedCol = DARK_MODE ? Graphics.COLOR_DK_GRAY : Graphics.COLOR_LT_GRAY;
        var color = connected ? Graphics.COLOR_BLUE : disconnectedCol;
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(cx, cy - 6, cx, cy + 6);
        dc.drawLine(cx, cy - 6, cx + 4, cy - 3);
        dc.drawLine(cx + 4, cy - 3, cx, cy);
        dc.drawLine(cx, cy, cx + 4, cy + 3);
        dc.drawLine(cx + 4, cy + 3, cx, cy + 6);
    }

    private function drawBatteryGraphic(dc as Dc, cx as Number, cy as Number, pct as Number) as Void {
        var bw = 18;
        var bh = 8;
        var x  = cx - bw / 2;
        var y  = cy - bh / 2;
        var col = pct < 10
            ? Graphics.COLOR_RED
            : pct <= 50 ? Graphics.COLOR_ORANGE : Graphics.COLOR_GREEN;
        dc.setColor(col, Graphics.COLOR_TRANSPARENT);
        dc.drawRectangle(x, y, bw, bh);
        dc.fillRectangle(x + bw, y + 2, 2, bh - 4);
        var fillW = ((bw - 4) * pct / 100).toNumber();
        dc.fillRectangle(x + 2, y + 2, fillW, bh - 4);
    }

    function onHide() as Void {
    }

    function onExitSleep() as Void {
    }

    function onEnterSleep() as Void {
        WatchUi.requestUpdate();
    }
}
