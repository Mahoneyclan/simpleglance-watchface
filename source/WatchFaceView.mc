import Toybox.ActivityMonitor;
import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
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
// ─────────────────────────────────────────────────────────────────────────────

class WatchFaceView extends WatchUi.WatchFace {

    private var _screenWidth as Number = 260;
    private var _centerX     as Number = 130;
    private var _font        as Graphics.FontReference or Null = null;

    // Populated from Application.Properties on every onUpdate call.
    private var _bgColor    as Number = 0x000000;
    private var _hourColor  as Number = 0xFFFFFF;
    private var _minColor   as Number = 0xFF8000;
    private var _leftField  as Number = FIELD_STEPS;
    private var _rightField as Number = FIELD_FLOORS;

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
    }

    function onUpdate(dc as Dc) as Void {
        loadSettings();
        dc.setColor(_bgColor, _bgColor);
        dc.clear();
        drawDate(dc);
        drawTime(dc);
        drawBottomBar(dc);
    }

    // Read all user-configurable values from Application.Properties.
    private function loadSettings() as Void {
        _bgColor    = Application.Properties.getValue("BgColor")    as Number;
        _hourColor  = Application.Properties.getValue("HourColor")  as Number;
        _minColor   = Application.Properties.getValue("MinColor")   as Number;
        _leftField  = Application.Properties.getValue("LeftField")  as Number;
        _rightField = Application.Properties.getValue("RightField") as Number;
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
            return (actInfo.calories as Number).toString() + "cal";
        }
        if (field == FIELD_DISTANCE) {
            if (actInfo.distance == null) { return "--"; }
            var km = (actInfo.distance as Long).toFloat() / 100000.0;
            return km.format("%.1f") + "km";
        }
        if (field == FIELD_FLOORS) {
            if (actInfo.floorsClimbed == null) { return "--"; }
            return (actInfo.floorsClimbed as Number).toString() + " fl";
        }
        if (field == FIELD_ACTIVE_MIN) {
            if (actInfo.activeMinutesDay == null) { return "--"; }
            return (actInfo.activeMinutesDay as ActivityMonitor.ActiveMinutes).total.toString() + "min";
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
        var fg = isDark(_bgColor) ? Graphics.COLOR_WHITE : Graphics.COLOR_BLACK;
        dc.setColor(fg, Graphics.COLOR_TRANSPARENT);
        dc.drawText(_centerX, 35, Graphics.FONT_MEDIUM, dateStr,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    // Large two-tone time centred on screen.
    // Hours (_hourColor) left of colon; minutes (_minColor) right of colon.
    private function drawTime(dc as Dc) as Void {
        var clockTime = System.getClockTime();
        var hours     = clockTime.hour % 12;
        if (hours == 0) { hours = 12; }
        var hrStr  = hours.format("%02d");
        var minStr = clockTime.min.format("%02d");
        var font   = _font;
        var y      = 130;
        var cx     = _centerX;
        var justL  = Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER;

        var hrW      = dc.getTextDimensions(hrStr, font)[0];
        var minW     = dc.getTextDimensions(minStr, font)[0];
        var colonGap = 12;
        var totalW   = hrW + colonGap + minW;
        var hrX      = cx - totalW / 2;
        var minX     = hrX + hrW + colonGap;
        var colonX   = hrX + hrW + colonGap / 2;

        var fg     = isDark(_bgColor) ? Graphics.COLOR_WHITE   : Graphics.COLOR_BLACK;
        var dimCol = isDark(_bgColor) ? Graphics.COLOR_DK_GRAY : Graphics.COLOR_LT_GRAY;

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

        // ── Left side: notification (top) | divider | BT (bottom) ────────────
        var settings   = System.getDeviceSettings();
        var leftX      = 22;
        var notifCount = (settings.notificationCount != null)
            ? (settings.notificationCount as Number) : 0;

        drawBellIcon(dc, leftX, y - 26);
        dc.setColor(fg, Graphics.COLOR_TRANSPARENT);
        dc.drawText(leftX, y - 11, Graphics.FONT_XTINY, notifCount.toString(),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(dimCol, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(leftX - 7, y + 2, leftX + 7, y + 2);

        drawBtIcon(dc, leftX, y + 17, settings.phoneConnected);

        // ── Right side: battery icon + percentage ─────────────────────────────
        var rightX  = _screenWidth - 22;
        var stats   = System.getSystemStats();
        var battPct = stats.battery.toNumber();
        var battCol = battPct < 10
            ? Graphics.COLOR_RED
            : (battPct <= 50 ? Graphics.COLOR_ORANGE : Graphics.COLOR_GREEN);
        drawBatteryIcon(dc, rightX, y - 12, battPct, battCol);
        dc.setColor(fg, Graphics.COLOR_TRANSPARENT);
        dc.drawText(rightX, y + 8, Graphics.FONT_XTINY, battPct.toString() + "%",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    // Single data row below the time digits, driven by LeftField / RightField settings.
    private function drawBottomBar(dc as Dc) as Void {
        var actInfo = ActivityMonitor.getInfo();
        var fg    = isDark(_bgColor) ? Graphics.COLOR_WHITE : Graphics.COLOR_BLACK;
        var justC = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;

        var l = _leftField  != FIELD_NONE ? fieldValue(_leftField,  actInfo) : "";
        var r = _rightField != FIELD_NONE ? fieldValue(_rightField, actInfo) : "";
        var text = (l.length() > 0 && r.length() > 0) ? l + " • " + r
                 : (l.length() > 0)                   ? l
                 : r;

        if (text.length() > 0) {
            dc.setColor(fg, Graphics.COLOR_TRANSPARENT);
            dc.drawText(_centerX, 223, Graphics.FONT_SMALL, text, justC);
        }
    }

    // ── Icon helpers ──────────────────────────────────────────────────────────

    // Bell: dome arc + body + wide rim + clapper dot
    private function drawBellIcon(dc as Dc, cx as Number, cy as Number) as Void {
        var fg = isDark(_bgColor) ? Graphics.COLOR_WHITE : Graphics.COLOR_BLACK;
        dc.setColor(fg, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx, cy - 2, 5);
        dc.setColor(_bgColor, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(cx - 6, cy - 2, 12, 6);
        dc.setColor(fg, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(cx - 4, cy - 2, 8, 5);
        dc.fillRectangle(cx - 6, cy + 3, 12, 2);
        dc.fillCircle(cx, cy + 7, 2);
    }

    // Bluetooth symbol — blue when connected, dim when not
    private function drawBtIcon(dc as Dc, cx as Number, cy as Number, connected as Boolean) as Void {
        var disconnectedCol = isDark(_bgColor) ? Graphics.COLOR_DK_GRAY : Graphics.COLOR_LT_GRAY;
        var color = connected ? Graphics.COLOR_BLUE : disconnectedCol;
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(cx, cy - 6, cx, cy + 6);
        dc.drawLine(cx, cy - 6, cx + 4, cy - 3);
        dc.drawLine(cx + 4, cy - 3, cx, cy);
        dc.drawLine(cx, cy, cx + 4, cy + 3);
        dc.drawLine(cx + 4, cy + 3, cx, cy + 6);
    }

    // Small battery outline + proportional fill + terminal nub, colour-coded.
    private function drawBatteryIcon(dc as Dc, cx as Number, cy as Number, pct as Number, color as Number) as Void {
        var w  = 14;
        var h  = 8;
        var nw = 3;
        var nh = 4;
        var x  = cx - w / 2;
        var y  = cy - h / 2;
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawRectangle(x, y, w, h);
        dc.fillRectangle(x + w, y + (h - nh) / 2, nw, nh);
        var fillW = (w - 2) * pct / 100;
        if (fillW < 1) { fillW = 1; }
        dc.fillRectangle(x + 1, y + 1, fillW, h - 2);
    }

    function onHide() as Void {
    }

    function onExitSleep() as Void {
    }

    function onEnterSleep() as Void {
        WatchUi.requestUpdate();
    }

}
