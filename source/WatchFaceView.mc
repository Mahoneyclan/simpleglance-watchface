import Toybox.ActivityMonitor;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.WatchUi;

class WatchFaceView extends WatchUi.WatchFace {

    private var _screenWidth  as Number = 260;
    private var _screenHeight as Number = 260;
    private var _centerX      as Number = 130;
    private var _centerY      as Number = 130;

    // Block colors: Floors, Body Battery, Steps, Calories, Watch Battery
    private var BLOCK_COLORS = [0x1155BB, 0x00AA44, 0xBB9900, 0xCC5500, 0xBB1133];

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
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        drawDate(dc);
        drawStatusBar(dc);
        drawTime(dc);
        drawBlocks(dc);
    }

    private function drawOutlinedText(dc as Dc, x as Number, y as Number, font as FontType, text as String, justify as Number, textColor as ColorType) as Void {
        var offsets = [[-1, -1], [0, -1], [1, -1], [-1, 0], [1, 0], [-1, 1], [0, 1], [1, 1]];
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        for (var i = 0; i < offsets.size(); i++) {
            dc.drawText(x + offsets[i][0], y + offsets[i][1], font, text, justify);
        }
        dc.setColor(textColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y, font, text, justify);
    }

    private function drawDate(dc as Dc) as Void {
        var now    = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var days   = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"];
        var months = ["JAN", "FEB", "MAR", "APR", "MAY", "JUN",
                      "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"];
        var dateStr = Lang.format("$1$  $2$  $3$", [
            days[now.day_of_week - 1],
            months[now.month - 1],
            now.day.format("%02d")
        ]);
        drawOutlinedText(dc, _centerX, _centerY - 80, Graphics.FONT_MEDIUM, dateStr,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER,
            Graphics.COLOR_LT_GRAY);
    }

    // Status bar: Notifications left, BT right
    private function drawStatusBar(dc as Dc) as Void {
        var settings = System.getDeviceSettings();
        var y        = _centerY - 58;

        // Notifications
        var notifCount = settings.notificationCount;
        var notifStr   = notifCount > 0 ? notifCount.toString() : "-";
        var notifColor = notifCount > 0 ? Graphics.COLOR_WHITE : Graphics.COLOR_DK_GRAY;
        drawOutlinedText(dc, _centerX - 30, y, Graphics.FONT_XTINY, notifStr,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER, notifColor);

        // Bluetooth
        var btColor = settings.phoneConnected ? Graphics.COLOR_BLUE : Graphics.COLOR_DK_GRAY;
        drawOutlinedText(dc, _centerX + 30, y, Graphics.FONT_XTINY, "BT",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER, btColor);
    }

    private function drawTime(dc as Dc) as Void {
        var clockTime = System.getClockTime();
        var hours     = clockTime.hour % 12;
        if (hours == 0) { hours = 12; }
        var timeStr = Lang.format("$1$:$2$", [hours.format("%02d"), clockTime.min.format("%02d")]);
        drawOutlinedText(dc, _centerX, _centerY - 5, Graphics.FONT_NUMBER_THAI_HOT, timeStr,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER,
            Graphics.COLOR_WHITE);
    }

    private function drawBlocks(dc as Dc) as Void {
        var actInfo  = ActivityMonitor.getInfo();
        var stats    = System.getSystemStats();
        var blockTop = _centerY + 44;
        var bw       = _screenWidth / 5; // 52px each

        // Gather values
        var values = ["--", "--", "--", "--", "--"] as Array<String>;

        // [0] Floors  [1] Watch Battery  [2] Steps  [3] Calories  [4] Body Battery
        values[1] = stats.battery.toNumber().toString() + "%";

        if (actInfo != null) {
            if (actInfo.floorsClimbed != null) {
                values[0] = actInfo.floorsClimbed.toString();
            }
            if (actInfo.steps != null) {
                var steps = actInfo.steps as Number;
                values[2] = steps >= 1000
                    ? Lang.format("$1$k", [(steps / 1000.0).format("%.1f")])
                    : steps.toString();
            }
            if (actInfo.calories != null) {
                values[3] = actInfo.calories.toString();
            }
            if ((actInfo has :bodyBatteryHistory)
                && actInfo.bodyBatteryHistory != null
                && actInfo.bodyBatteryHistory.size() > 0) {
                values[4] = actInfo.bodyBatteryHistory[0].toString() + "%";
            }
        }

        // Draw each block
        for (var i = 0; i < 5; i++) {
            var bx = i * bw;
            var cx = bx + bw / 2;

            // Colored background (clipped by round screen bezel)
            dc.setColor(BLOCK_COLORS[i], BLOCK_COLORS[i]);
            dc.fillRectangle(bx, blockTop, bw, _screenHeight - blockTop);

            // Value
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, blockTop + 13, Graphics.FONT_TINY, values[i],
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

            // Icon
            drawBlockIcon(dc, cx, blockTop + 36, i);
        }
    }

    private function drawBlockIcon(dc as Dc, cx as Number, cy as Number, type as Number) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        if (type == 0) {
            drawStairsIcon(dc, cx, cy);    // Floors
        } else if (type == 1) {
            drawBatteryIcon(dc, cx, cy);   // Watch Battery
        } else if (type == 2) {
            drawFootstepsIcon(dc, cx, cy); // Steps
        } else if (type == 3) {
            drawFlameIcon(dc, cx, cy);     // Calories
        } else if (type == 4) {
            drawLightningIcon(dc, cx, cy); // Body Battery
        }
    }

    // Staircase: 3 ascending steps
    private function drawStairsIcon(dc as Dc, cx as Number, cy as Number) as Void {
        var s = 4;
        dc.fillRectangle(cx - 6, cy + 2, s * 3, 2);
        dc.fillRectangle(cx - 2, cy - 2, s * 2, 2);
        dc.fillRectangle(cx + 2, cy - 6, s, 2);
        dc.fillRectangle(cx - 2, cy - 2, 2, 4);
        dc.fillRectangle(cx + 2, cy - 6, 2, 8);
    }

    // Lightning bolt
    private function drawLightningIcon(dc as Dc, cx as Number, cy as Number) as Void {
        var pts = [[cx + 2, cy - 9], [cx - 4, cy], [cx, cy], [cx - 2, cy + 9], [cx + 4, cy], [cx, cy]] as Array<Array<Number>>;
        dc.fillPolygon(pts);
    }

    // Two small footprint ovals
    private function drawFootstepsIcon(dc as Dc, cx as Number, cy as Number) as Void {
        dc.fillRectangle(cx - 6, cy - 6, 5, 7);
        dc.fillRectangle(cx + 2, cy, 5, 7);
    }

    // Flame shape
    private function drawFlameIcon(dc as Dc, cx as Number, cy as Number) as Void {
        var pts = [[cx, cy - 9], [cx + 5, cy - 2], [cx + 5, cy + 5],
                   [cx, cy + 8], [cx - 5, cy + 5], [cx - 5, cy - 2]] as Array<Array<Number>>;
        dc.fillPolygon(pts);
        // Inner highlight
        dc.setColor(0xFFAA00, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx, cy + 2, 3);
    }

    // Battery outline + fill
    private function drawBatteryIcon(dc as Dc, cx as Number, cy as Number) as Void {
        dc.drawRectangle(cx - 8, cy - 4, 14, 9);
        dc.fillRectangle(cx + 6, cy - 2, 3, 5);
        dc.fillRectangle(cx - 6, cy - 2, 10, 5);
    }

    function onHide() as Void {
    }

    function onExitSleep() as Void {
    }

    function onEnterSleep() as Void {
        WatchUi.requestUpdate();
    }

}
