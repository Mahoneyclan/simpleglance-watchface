import Toybox.ActivityMonitor;
import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.WatchUi;
import Toybox.Weather;

// ── Field identifiers — match listEntry values in settings.xml ────────────────
const FIELD_NONE       = 0 as Number;
const FIELD_STEPS      = 1 as Number;
const FIELD_CALORIES   = 2 as Number;
const FIELD_DISTANCE   = 3 as Number;
const FIELD_FLOORS     = 4 as Number;
const FIELD_ACTIVE_MIN = 5 as Number;
// ─────────────────────────────────────────────────────────────────────────────

class WatchFaceView extends WatchUi.WatchFace {

    private var _screenWidth as Number = 260;
    private var _centerX     as Number = 130;
    private var _font        as Graphics.FontReference or Null = null;

    // Cached settings — updated in onShow() and onSettingsChanged() only,
    // not on every onUpdate() call.
    private var _bgColor    as Number  = 0x000000;
    private var _hourColor  as Number  = 0xFFFFFF;
    private var _minColor   as Number  = 0xFF8000;
    private var _fgColor    as Number  = Graphics.COLOR_WHITE;
    private var _dimColor   as Number  = Graphics.COLOR_DK_GRAY;
    private var _leftField  as Number  = FIELD_STEPS;
    private var _rightField as Number  = FIELD_FLOORS;
    private var _use24h     as Boolean = false;

    function initialize() {
        WatchFace.initialize();
    }

    function onLayout(dc as Dc) as Void {
        _screenWidth = dc.getWidth();
        _centerX     = _screenWidth / 2;
        // White-glyph atlas — dc.setColor() tints it to any colour at draw time.
        _font = WatchUi.loadResource(Rez.Fonts.TimeFont) as Graphics.FontReference;
    }

    function onShow() as Void {
        loadSettings();
    }

    // Called by WatchFaceApp when the user changes settings in Garmin Connect.
    function onSettingsChanged() as Void {
        loadSettings();
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(_bgColor, _bgColor);
        dc.clear();
        drawBatteryArc(dc);
        drawDate(dc);
        drawTime(dc);
        drawBottomBar(dc);
    }

    // Read and cache all user-configurable values from Application.Properties.
    // Also pre-computes _fgColor and _dimColor so isDark() isn't called per frame.
    private function loadSettings() as Void {
        _bgColor    = Application.Properties.getValue("BgColor")    as Number;
        _hourColor  = Application.Properties.getValue("HourColor")  as Number;
        _minColor   = Application.Properties.getValue("MinColor")   as Number;
        _leftField  = Application.Properties.getValue("LeftField")  as Number;
        _rightField = Application.Properties.getValue("RightField") as Number;
        _use24h     = Application.Properties.getValue("Use24h")     as Boolean;
        var dark  = isDark(_bgColor);
        _fgColor  = dark ? Graphics.COLOR_WHITE   : Graphics.COLOR_BLACK;
        _dimColor = dark ? Graphics.COLOR_DK_GRAY : Graphics.COLOR_LT_GRAY;
    }

    // True when the given 0xRRGGBB colour is perceptually dark.
    private function isDark(color as Number) as Boolean {
        var r = (color >> 16) & 0xFF;
        var g = (color >>  8) & 0xFF;
        var b =  color        & 0xFF;
        return (r * 299 + g * 587 + b * 114) < 128000;
    }

    // Returns a formatted string for the given FIELD_* constant.
    private function fieldValue(field as Number, actInfo as ActivityMonitor.Info or Null) as String {
        if (actInfo == null) { return "--"; }
        if (field == FIELD_STEPS) {
            if (actInfo.steps == null) { return "--"; }
            var s = actInfo.steps as Number;
            return s >= 1000
                ? Lang.format("$1$k stp", [(s / 1000.0).format("%.1f")])
                : s.toString() + " stp";
        }
        if (field == FIELD_CALORIES) {
            if (actInfo.calories == null) { return "--"; }
            return (actInfo.calories as Number).toString() + " cal";
        }
        if (field == FIELD_DISTANCE) {
            if (actInfo.distance == null) { return "--"; }
            var km = (actInfo.distance as Long).toFloat() / 100000.0;
            return km.format("%.1f") + " km";
        }
        if (field == FIELD_FLOORS) {
            if (actInfo.floorsClimbed == null) { return "--"; }
            return (actInfo.floorsClimbed as Number).toString() + " fl";
        }
        if (field == FIELD_ACTIVE_MIN) {
            if (actInfo.activeMinutesDay == null) { return "--"; }
            return (actInfo.activeMinutesDay as ActivityMonitor.ActiveMinutes).total.toString() + " min";
        }
        return "--";
    }

    // "SAT 20 MAY" — day-of-week, date number, month (no comma)
    private function drawDate(dc as Dc) as Void {
        var now    = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var days   = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"];
        var months = ["JAN", "FEB", "MAR", "APR", "MAY", "JUN",
                      "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"];
        var dateStr = Lang.format("$1$ $2$ $3$", [
            days[now.day_of_week - 1],
            now.day.format("%d"),
            months[now.month - 1]
        ]);
        dc.setColor(_fgColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(_centerX, 43, Graphics.FONT_MEDIUM, dateStr,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    // Arc from 10 o'clock (150°) to 2 o'clock (30°) through the top.
    // Garmin angles: 0°=3 o'clock, 90°=12 o'clock, CCW positive.
    // 10 o'clock = 150°, 2 o'clock = 30°, total span = 120°.
    // Fill grows from 2 o'clock CCW; drains by retreating from 10 o'clock side.
    private function drawBatteryArc(dc as Dc) as Void {
        var stats   = System.getSystemStats();
        var battPct = stats.battery.toNumber();
        var cx      = _centerX;
        var cy      = _centerX;          // screen is square on all supported devices
        var r       = (_screenWidth / 2) - 7;

        // Dim background track (10 o'clock → 2 o'clock through top)
        dc.setPenWidth(5);
        dc.setColor(_dimColor, Graphics.COLOR_TRANSPARENT);
        dc.drawArc(cx, cy, r, Graphics.ARC_COUNTER_CLOCKWISE, 30, 150);

        // Coloured fill: grows from 30° (2 o'clock) CCW toward 150° (10 o'clock)
        if (battPct > 0) {
            var battCol = battPct < 10  ? Graphics.COLOR_RED
                        : battPct <= 50 ? Graphics.COLOR_ORANGE
                        :                 Graphics.COLOR_GREEN;
            dc.setColor(battCol, Graphics.COLOR_TRANSPARENT);
            var endAngle = 30 + battPct * 120 / 100;
            dc.drawArc(cx, cy, r, Graphics.ARC_COUNTER_CLOCKWISE, 30, endAngle);
        }
        dc.setPenWidth(1);
    }

    // Large two-tone time centred on screen.
    // Hours (_hourColor) left of colon; minutes (_minColor) right of colon.
    // Left panel: weather icon (top) + temperature °C (bottom).
    // Right panel: 3-sided box with mini bell + notification count overlaid on minutes.
    private function drawTime(dc as Dc) as Void {
        var clockTime = System.getClockTime();
        var hours = _use24h
            ? clockTime.hour
            : (clockTime.hour % 12 == 0 ? 12 : clockTime.hour % 12);
        var hrStr  = hours.format("%02d");
        var minStr = clockTime.min.format("%02d");
        var font   = _font;
        var y      = 135;
        var cx     = _centerX;
        var justL  = Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER;

        var hrW      = dc.getTextDimensions(hrStr, font)[0];
        var minW     = dc.getTextDimensions(minStr, font)[0];
        var colonGap = 12;
        var totalW   = hrW + colonGap + minW;
        var hrX      = cx - totalW / 2;
        var minX     = hrX + hrW + colonGap;
        var colonX   = hrX + hrW + colonGap / 2;

        // Hours
        dc.setColor(_hourColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(hrX, y, font, hrStr, justL);

        // Minutes
        dc.setColor(_minColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(minX, y, font, minStr, justL);

        // Colon — two filled dots, same colour as hours
        dc.setColor(_hourColor, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(colonX, y - 20, 7);
        dc.fillCircle(colonX, y + 20, 7);

        // ── Left: weather icon (top) · divider · temperature °C (bottom) ───
        var leftX  = 20;
        var wxCond = Weather.getCurrentConditions();
        if (wxCond != null) {
            if (wxCond.condition != null) {
                drawWeatherIcon(dc, leftX, y - 18, wxCond.condition as Number);
            }
            dc.setColor(_dimColor, Graphics.COLOR_TRANSPARENT);
            dc.drawLine(leftX - 10, y + 2, leftX + 10, y + 2);
            if (wxCond.temperature != null) {
                dc.setColor(_fgColor, Graphics.COLOR_TRANSPARENT);
                dc.drawText(leftX, y + 26, Graphics.FONT_SMALL,
                    (wxCond.temperature as Number).format("%d") + "°",
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            }
        }

        // ── Right: notification box (bell icon + count) overlaid on minutes ──
        var settings   = System.getDeviceSettings();
        var notifCount = (settings.notificationCount != null)
            ? (settings.notificationCount as Number) : 0;
        drawNotifBox(dc, _screenWidth - 30, y, notifCount);
    }

    // Single data row below the time digits, driven by LeftField / RightField settings.
    private function drawBottomBar(dc as Dc) as Void {
        var actInfo = ActivityMonitor.getInfo();
        var justC   = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;

        var l = _leftField  != FIELD_NONE ? fieldValue(_leftField,  actInfo) : "";
        var r = _rightField != FIELD_NONE ? fieldValue(_rightField, actInfo) : "";
        var text = (l.length() > 0 && r.length() > 0) ? l + " • " + r
                 : (l.length() > 0)                   ? l
                 : r;

        if (text.length() > 0) {
            dc.setColor(_fgColor, Graphics.COLOR_TRANSPARENT);
            dc.drawText(_centerX, 228, Graphics.FONT_SMALL, text, justC);
        }
    }

    // ── Icon helpers ──────────────────────────────────────────────────────────

    // 3-sided box (top + left + bottom, open right) with rounded top-left and
    // bottom-left corners. Bell straddles the top border; count fills the interior.
    private function drawNotifBox(dc as Dc, cx as Number, cy as Number, count as Number) as Void {
        var boxW = 34;
        var boxH = 52;
        var rc   = 5;                 // corner radius
        var x    = cx - boxW / 2;
        var y    = cy - boxH / 2;    // y = top border line

        // Erase minute digits behind the box
        dc.setColor(_bgColor, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(x, y, boxW, boxH);

        // 3-sided border with rounded left corners:
        //   top line → top-left arc → left line → bottom-left arc → bottom line
        dc.setPenWidth(1);
        dc.setColor(_dimColor, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(x + rc, y,            x + boxW, y);               // top
        dc.drawArc( x + rc, y + rc,       rc, Graphics.ARC_COUNTER_CLOCKWISE, 90, 180);  // top-left
        dc.drawLine(x,      y + rc,       x,        y + boxH - rc);   // left
        dc.drawArc( x + rc, y + boxH - rc, rc, Graphics.ARC_COUNTER_CLOCKWISE, 180, 270); // bottom-left
        dc.drawLine(x + rc, y + boxH,    x + boxW, y + boxH);         // bottom

        // Bell centred on the top border — half above, half inside
        drawMiniBell(dc, cx, y);

        // Count centred between bell bottom (y+9) and box bottom
        dc.setColor(_fgColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, (y + 9 + y + boxH) / 2, Graphics.FONT_SMALL, count.toString(),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    // Small bell glyph ~12px tall, for use inside compact UI elements.
    private function drawMiniBell(dc as Dc, cx as Number, cy as Number) as Void {
        dc.setColor(_fgColor, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx, cy - 2, 5);
        dc.setColor(_bgColor, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(cx - 6, cy - 2, 12, 6);
        dc.setColor(_fgColor, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(cx - 5, cy - 2, 10, 5);
        dc.fillRectangle(cx - 6, cy + 3, 12, 2);
        dc.fillCircle(cx, cy + 7, 2);
    }

    // ── Weather icon ──────────────────────────────────────────────────────────

    // Dispatch to the right drawing function based on condition integer.
    private function drawWeatherIcon(dc as Dc, cx as Number, cy as Number, condition as Number) as Void {
        if      (condition == Weather.CONDITION_CLEAR) {
            drawWSun(dc, cx, cy);
        } else if (condition == Weather.CONDITION_PARTLY_CLOUDY) {
            drawWPartlyCloudy(dc, cx, cy);
        } else if (condition == Weather.CONDITION_RAIN       ||
                   condition == Weather.CONDITION_SCATTERED_SHOWERS ||
                   condition == Weather.CONDITION_LIGHT_RAIN ||
                   condition == Weather.CONDITION_UNKNOWN_PRECIPITATION) {
            drawWRain(dc, cx, cy, false);
        } else if (condition == Weather.CONDITION_HEAVY_RAIN) {
            drawWRain(dc, cx, cy, true);
        } else if (condition == Weather.CONDITION_SNOW       ||
                   condition == Weather.CONDITION_LIGHT_SNOW ||
                   condition == Weather.CONDITION_HEAVY_SNOW) {
            drawWSnow(dc, cx, cy);
        } else if (condition == Weather.CONDITION_THUNDERSTORMS         ||
                   condition == Weather.CONDITION_SCATTERED_THUNDERSTORMS) {
            drawWThunder(dc, cx, cy);
        } else if (condition == Weather.CONDITION_FOG   ||
                   condition == Weather.CONDITION_HAZY) {
            drawWFog(dc, cx, cy);
        } else if (condition == Weather.CONDITION_WINDY) {
            drawWWindy(dc, cx, cy);
        } else if (condition == Weather.CONDITION_WINTRY_MIX       ||
                   condition == Weather.CONDITION_LIGHT_RAIN_SNOW  ||
                   condition == Weather.CONDITION_HEAVY_RAIN_SNOW) {
            drawWWintryMix(dc, cx, cy);
        } else if (condition == Weather.CONDITION_HAIL) {
            drawWHail(dc, cx, cy);
        } else {
            drawWCloud(dc, cx, cy);  // mostly cloudy, cloudy, unknown
        }
    }

    // Cloud silhouette: two bumps over a flat rectangular base (~18×10px).
    private function drawWCloud(dc as Dc, cx as Number, cy as Number) as Void {
        dc.setColor(_fgColor, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx - 4, cy - 4, 5);
        dc.fillCircle(cx + 3, cy - 5, 4);
        dc.fillRectangle(cx - 9, cy - 4, 18, 5);
    }

    // Clear: orange filled circle + 4 short cardinal rays.
    private function drawWSun(dc as Dc, cx as Number, cy as Number) as Void {
        dc.setColor(Graphics.COLOR_ORANGE, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx, cy, 6);
        dc.setPenWidth(2);
        dc.drawLine(cx,      cy - 9, cx,     cy - 8);
        dc.drawLine(cx,      cy + 8, cx,     cy + 9);
        dc.drawLine(cx - 9,  cy,     cx - 8, cy);
        dc.drawLine(cx + 8,  cy,     cx + 9, cy);
        dc.setPenWidth(1);
    }

    // Partly cloudy: small sun upper-left, cloud lower-right overlapping it.
    private function drawWPartlyCloudy(dc as Dc, cx as Number, cy as Number) as Void {
        dc.setColor(Graphics.COLOR_ORANGE, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx - 4, cy - 4, 4);
        drawWCloud(dc, cx + 2, cy + 2);
    }

    // Rain: cloud + 3 angled blue lines below. heavy = 2 extra drops.
    private function drawWRain(dc as Dc, cx as Number, cy as Number, heavy as Boolean) as Void {
        drawWCloud(dc, cx, cy - 2);
        dc.setColor(0x4488FF, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        dc.drawLine(cx - 4, cy + 3, cx - 5, cy + 7);
        dc.drawLine(cx,     cy + 3, cx - 1, cy + 7);
        dc.drawLine(cx + 4, cy + 3, cx + 3, cy + 7);
        if (heavy) {
            dc.drawLine(cx - 2, cy + 6, cx - 3, cy + 10);
            dc.drawLine(cx + 2, cy + 6, cx + 1, cy + 10);
        }
        dc.setPenWidth(1);
    }

    // Snow: cloud + 3 small light-blue dots below.
    private function drawWSnow(dc as Dc, cx as Number, cy as Number) as Void {
        drawWCloud(dc, cx, cy - 2);
        dc.setColor(0xAADDFF, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx - 4, cy + 6, 2);
        dc.fillCircle(cx,     cy + 6, 2);
        dc.fillCircle(cx + 4, cy + 6, 2);
    }

    // Thunderstorm: cloud + yellow lightning bolt below.
    private function drawWThunder(dc as Dc, cx as Number, cy as Number) as Void {
        drawWCloud(dc, cx, cy - 2);
        dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon([[cx + 2, cy + 2], [cx - 2, cy + 7],
                        [cx,     cy + 7], [cx - 2, cy + 11],
                        [cx + 3, cy + 6], [cx + 1, cy + 6]]);
    }

    // Fog / haze: three horizontal lines of decreasing length.
    private function drawWFog(dc as Dc, cx as Number, cy as Number) as Void {
        dc.setColor(_dimColor, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        dc.drawLine(cx - 8, cy - 4, cx + 8, cy - 4);
        dc.drawLine(cx - 8, cy,     cx + 8, cy);
        dc.drawLine(cx - 6, cy + 4, cx + 6, cy + 4);
        dc.setPenWidth(1);
    }

    // Windy: three horizontal lines of staggered length.
    private function drawWWindy(dc as Dc, cx as Number, cy as Number) as Void {
        dc.setColor(_fgColor, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        dc.drawLine(cx - 8, cy - 4, cx + 7, cy - 4);
        dc.drawLine(cx - 8, cy,     cx + 9, cy);
        dc.drawLine(cx - 8, cy + 4, cx + 5, cy + 4);
        dc.setPenWidth(1);
    }

    // Wintry mix: cloud + one blue raindrop left + one snow dot right.
    private function drawWWintryMix(dc as Dc, cx as Number, cy as Number) as Void {
        drawWCloud(dc, cx, cy - 2);
        dc.setColor(0x4488FF, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        dc.drawLine(cx - 4, cy + 3, cx - 5, cy + 7);
        dc.setPenWidth(1);
        dc.setColor(0xAADDFF, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx + 3, cy + 6, 2);
    }

    // Hail: cloud + 3 small grey circles below.
    private function drawWHail(dc as Dc, cx as Number, cy as Number) as Void {
        drawWCloud(dc, cx, cy - 2);
        dc.setColor(_dimColor, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx - 4, cy + 6, 2);
        dc.fillCircle(cx,     cy + 6, 2);
        dc.fillCircle(cx + 4, cy + 6, 2);
    }

    function onHide() as Void {
    }

    function onExitSleep() as Void {
        WatchUi.requestUpdate();
    }

    function onEnterSleep() as Void {
        WatchUi.requestUpdate();
    }

}
