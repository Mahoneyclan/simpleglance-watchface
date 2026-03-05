import Toybox.ActivityMonitor;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.WatchUi;

class WatchFaceView extends WatchUi.WatchFace {

    // Screen dimensions (Fenix 6 Pro: 260x260)
    private var _screenWidth  as Number = 260;
    private var _screenHeight as Number = 260;
    private var _centerX      as Number = 130;
    private var _centerY      as Number = 130;

    function initialize() {
        WatchFace.initialize();
    }

    function onLayout(dc as Dc) as Void {
        _screenWidth  = dc.getWidth();
        _screenHeight = dc.getHeight();
        _centerX      = _screenWidth  / 2;
        _centerY      = _screenHeight / 2;
    }

    function onShow() as Void {
    }

    function onUpdate(dc as Dc) as Void {
        // Clear to black
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        drawDate(dc);
        drawTime(dc);
        drawComplications(dc);
    }

    private function drawDate(dc as Dc) as Void {
        var now  = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var days = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"];
        var dateStr = Lang.format("$1$  $2$", [days[now.day_of_week - 1], now.day]);

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            _centerX,
            _centerY - 68,
            Graphics.FONT_SMALL,
            dateStr,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }

    private function drawTime(dc as Dc) as Void {
        var clockTime = System.getClockTime();
        var hours     = clockTime.hour;
        var minutes   = clockTime.min;

        // 12-hour format — swap to hours.format("%02d") for 24hr
        var isPm = hours >= 12;
        hours = hours % 12;
        if (hours == 0) { hours = 12; }

        var timeStr = Lang.format("$1$:$2$", [
            hours.format("%d"),
            minutes.format("%02d")
        ]);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            _centerX,
            _centerY,
            Graphics.FONT_NUMBER_THAI_HOT,
            timeStr,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );

        // AM/PM indicator — small, top-right of time
        var amPmStr = isPm ? "PM" : "AM";
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            _centerX + 70,
            _centerY - 20,
            Graphics.FONT_XTINY,
            amPmStr,
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }

    private function drawComplications(dc as Dc) as Void {
        var complicationsY = _centerY + 68;

        // --- Steps (left) ---
        var stepStr = "--";
        var actInfo = ActivityMonitor.getInfo();
        if (actInfo != null && actInfo.steps != null) {
            var steps = actInfo.steps as Number;
            if (steps >= 1000) {
                stepStr = Lang.format("$1$k", [(steps / 1000.0).format("%.1f")]);
            } else {
                stepStr = steps.toString();
            }
        }

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            _centerX - 50,
            complicationsY,
            Graphics.FONT_XTINY,
            "STEPS",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            _centerX - 50,
            complicationsY + 16,
            Graphics.FONT_SMALL,
            stepStr,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );

        // Divider dot
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(_centerX, complicationsY + 8, 2);

        // --- Battery (right) ---
        var stats      = System.getSystemStats();
        var battPct    = stats.battery.toNumber();
        var battStr    = Lang.format("$1$%", [battPct]);
        var battColor  = battPct <= 15
            ? Graphics.COLOR_RED
            : battPct <= 30
                ? Graphics.COLOR_ORANGE
                : Graphics.COLOR_WHITE;

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            _centerX + 50,
            complicationsY,
            Graphics.FONT_XTINY,
            "BATTERY",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
        dc.setColor(battColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            _centerX + 50,
            complicationsY + 16,
            Graphics.FONT_SMALL,
            battStr,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }

    function onHide() as Void {
    }

    function onExitSleep() as Void {
    }

    function onEnterSleep() as Void {
        // In low-power mode, don't show seconds
        WatchUi.requestUpdate();
    }

}
