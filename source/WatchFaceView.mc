import Toybox.ActivityMonitor;
import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.SensorHistory;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.WatchUi;

// ── Field identifiers — match listEntry values in settings.xml ────────────────
const FIELD_NONE       = 0 as Number;
const FIELD_STEPS      = 1 as Number;
const FIELD_CALORIES   = 2 as Number;
const FIELD_DISTANCE   = 3 as Number;
const FIELD_FLOORS     = 4 as Number;
const FIELD_ACTIVE_MIN = 5 as Number;
const FIELD_ELEVATION  = 7 as Number;
// ─────────────────────────────────────────────────────────────────────────────

class WatchFaceView extends WatchUi.WatchFace {

    private var _screenWidth as Number = 260;
    private var _centerX     as Number = 130;
    private var _font        as Graphics.FontReference or Null = null;

    // Cached settings — updated in onShow() and onSettingsChanged() only.
    private var _bgColor    as Number  = 0x000000;
    private var _hourColor  as Number  = 0xFFFFFF;
    private var _minColor   as Number  = 0xFF8000;
    private var _fgColor    as Number  = Graphics.COLOR_WHITE;
    private var _dimColor   as Number  = Graphics.COLOR_DK_GRAY;
    private var _leftField  as Number  = FIELD_STEPS;
    private var _rightField as Number  = FIELD_FLOORS;
    private var _use24h     as Boolean = false;
    private var _sleeping   as Boolean = false;

    function initialize() {
        WatchFace.initialize();
    }

    function onLayout(dc as Dc) as Void {
        _screenWidth = dc.getWidth();
        _centerX     = _screenWidth / 2;
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
        if (_sleeping) {
            drawDate(dc);
            drawTime(dc);
        } else {
            drawBatteryArc(dc);
            drawDate(dc);
            drawTime(dc);
            drawBottomBar(dc);
        }
    }

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

    private function isDark(color as Number) as Boolean {
        var r = (color >> 16) & 0xFF;
        var g = (color >>  8) & 0xFF;
        var b =  color        & 0xFF;
        return (r * 299 + g * 587 + b * 114) < 128000;
    }

    // Returns a formatted string for the given FIELD_* constant (bottom bar).
    private function fieldValue(field as Number, actInfo as ActivityMonitor.Info or Null) as String {
        if (field == FIELD_ELEVATION) {
            if (!(Toybox has :SensorHistory) || !(SensorHistory has :getElevationHistory)) { return "--"; }
            var iter = SensorHistory.getElevationHistory({:order => SensorHistory.ORDER_NEWEST_FIRST});
            var sample = iter.next();
            if (sample == null || sample.data == null) { return "--"; }
            return ((sample.data as Float).toNumber()).toString() + " m";
        }
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

    // "SAT 20 MAY"
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
    private function drawBatteryArc(dc as Dc) as Void {
        var stats   = System.getSystemStats();
        var battPct = stats.battery.toNumber();
        var cx      = _centerX;
        var cy      = _centerX;
        var r       = (_screenWidth / 2) - 7;

        dc.setPenWidth(8);
        dc.setColor(_dimColor, Graphics.COLOR_TRANSPARENT);
        dc.drawArc(cx, cy, r, Graphics.ARC_COUNTER_CLOCKWISE, 30, 150);

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

    // Large two-tone time, with HR panel left and notifications panel right.
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

        dc.setColor(_hourColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(hrX, y, font, hrStr, justL);

        dc.setColor(_minColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(minX, y, font, minStr, justL);

        dc.setColor(_hourColor, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(colonX, y - 20, 7);
        dc.fillCircle(colonX, y + 20, 7);

        drawHRPanel(dc, 30, y);
        drawNotifPanel(dc, _screenWidth - 30, y);
    }

    // Single data row below the time digits.
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

    // ── Side panels ───────────────────────────────────────────────────────────

    // 3-sided box open on the LEFT (top + right + bottom), showing heart icon + HR value.
    private function drawHRPanel(dc as Dc, cx as Number, cy as Number) as Void {
        var boxW = 34;
        var boxH = 52;
        var rc   = 5;
        var x    = cx - boxW / 2;
        var y    = cy - boxH / 2;

        dc.setColor(_bgColor, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(x, y, boxW, boxH);

        dc.setPenWidth(1);
        dc.setColor(_dimColor, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(x,         y,              x + boxW - rc, y);
        dc.drawArc( x + boxW - rc, y + rc,     rc, Graphics.ARC_COUNTER_CLOCKWISE, 0, 90);
        dc.drawLine(x + boxW,  y + rc,         x + boxW,      y + boxH - rc);
        dc.drawArc( x + boxW - rc, y + boxH - rc, rc, Graphics.ARC_COUNTER_CLOCKWISE, 270, 360);
        dc.drawLine(x,         y + boxH,       x + boxW - rc, y + boxH);

        drawMiniHeart(dc, cx, y);

        var hrStr = "--";
        var sample = ActivityMonitor.getHeartRateHistory(null, true).next();
        if (sample != null && sample.heartRate != ActivityMonitor.INVALID_HR_SAMPLE) {
            hrStr = sample.heartRate.toString();
        }
        dc.setColor(_fgColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, (y + 9 + y + boxH) / 2, Graphics.FONT_SMALL, hrStr,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    // 3-sided box open on the RIGHT (top + left + bottom), showing bell icon + notification count.
    private function drawNotifPanel(dc as Dc, cx as Number, cy as Number) as Void {
        var boxW = 34;
        var boxH = 52;
        var rc   = 5;
        var x    = cx - boxW / 2;
        var y    = cy - boxH / 2;

        dc.setColor(_bgColor, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(x, y, boxW, boxH);

        dc.setPenWidth(1);
        dc.setColor(_dimColor, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(x + rc, y,             x + boxW, y);
        dc.drawArc( x + rc, y + rc,        rc, Graphics.ARC_COUNTER_CLOCKWISE, 90, 180);
        dc.drawLine(x,      y + rc,        x,        y + boxH - rc);
        dc.drawArc( x + rc, y + boxH - rc, rc, Graphics.ARC_COUNTER_CLOCKWISE, 180, 270);
        dc.drawLine(x + rc, y + boxH,      x + boxW, y + boxH);

        drawMiniBell(dc, cx, y);

        var settings   = System.getDeviceSettings();
        var count = (settings.notificationCount != null) ? (settings.notificationCount as Number) : 0;
        dc.setColor(_fgColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, (y + 9 + y + boxH) / 2, Graphics.FONT_SMALL, count.toString(),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    // ── Icon helpers ──────────────────────────────────────────────────────────

    // Heart glyph ~16px tall, straddling a border line at cy.
    // Two lobes above cy, V-point below cy.
    private function drawMiniHeart(dc as Dc, cx as Number, cy as Number) as Void {
        dc.setColor(_fgColor, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx - 3, cy - 4, 3);          // left lobe
        dc.fillCircle(cx + 3, cy - 4, 3);          // right lobe
        dc.fillRectangle(cx - 5, cy - 2, 11, 2);   // bridge (connects lobes)
        dc.fillRectangle(cx - 4, cy,      9, 2);
        dc.fillRectangle(cx - 3, cy + 2,  7, 2);
        dc.fillRectangle(cx - 2, cy + 4,  5, 2);
        dc.fillRectangle(cx - 1, cy + 6,  3, 1);
        dc.fillCircle(cx, cy + 7, 1);               // tip
    }

    // Bell glyph ~16px tall, straddling a border line at cy.
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

    function onHide() as Void {
    }

    function onExitSleep() as Void {
        _sleeping = false;
        WatchUi.requestUpdate();
    }

    function onEnterSleep() as Void {
        _sleeping = true;
        WatchUi.requestUpdate();
    }

}
