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

    // Block colors: Floors, Active Calories, Steps, Stress, Body Battery
    private var BLOCK_COLORS = [0x1155BB, 0x00AA44, 0xBBAA00, 0xCC5500, 0xBB1133];

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

        drawTopIcons(dc);
        drawDate(dc);
        drawTime(dc);
        drawBlocks(dc);
    }

    // White outline, grey fill — used for time and date
    private function drawOutlinedText(dc as Dc, x as Number, y as Number, font as FontType, text as String, justify as Number, textColor as ColorType) as Void {
        var offsets = [[-1, -1], [0, -1], [1, -1], [-1, 0], [1, 0], [-1, 1], [0, 1], [1, 1]];
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        for (var i = 0; i < offsets.size(); i++) {
            dc.drawText(x + offsets[i][0], y + offsets[i][1], font, text, justify);
        }
        dc.setColor(textColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y, font, text, justify);
    }

    // Top row: Moon/Sun | Bluetooth | Battery graphic
    private function drawTopIcons(dc as Dc) as Void {
        var y        = _centerY - 88; // y = 42
        var settings = System.getDeviceSettings();
        var stats    = System.getSystemStats();
        var hour     = System.getClockTime().hour;

        // Moon (PM) or Sun (AM)
        if (hour >= 12) {
            drawMoonIcon(dc, _centerX - 55, y);
        } else {
            drawSunIcon(dc, _centerX - 55, y);
        }

        // Bluetooth
        drawBtIcon(dc, _centerX, y, settings.phoneConnected);

        // Battery graphic
        drawBatteryGraphic(dc, _centerX + 55, y, stats.battery.toNumber());
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
        drawOutlinedText(dc, _centerX, _centerY - 66, Graphics.FONT_MEDIUM, dateStr,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER,
            Graphics.COLOR_LT_GRAY);
    }

    // Large time, white outline, grey fill
    private function drawTime(dc as Dc) as Void {
        var clockTime = System.getClockTime();
        var hours     = clockTime.hour % 12;
        if (hours == 0) { hours = 12; }
        var timeStr = Lang.format("$1$:$2$", [hours.format("%02d"), clockTime.min.format("%02d")]);
        drawOutlinedText(dc, _centerX, _centerY - 8, Graphics.FONT_NUMBER_THAI_HOT, timeStr,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER,
            Graphics.COLOR_LT_GRAY);
    }

    // 5 colored blocks: Floors | Active Cal | Steps | Stress | Body Battery
    private function drawBlocks(dc as Dc) as Void {
        var actInfo  = ActivityMonitor.getInfo();
        var blockTop = _centerY + 46;
        var bw       = _screenWidth / 5;

        var values = ["--", "--", "--", "--", "--"] as Array<String>;

        if (actInfo != null) {
            // Floors
            if (actInfo.floorsClimbed != null) {
                values[0] = actInfo.floorsClimbed.toString();
            }
            // Active calories
            if (actInfo.activeCalories != null) {
                values[1] = actInfo.activeCalories.toString();
            }
            // Steps
            if (actInfo.steps != null) {
                var steps = actInfo.steps as Number;
                values[2] = steps >= 1000
                    ? Lang.format("$1$k", [(steps / 1000.0).format("%.1f")])
                    : steps.toString();
            }
            // Stress
            if ((actInfo has :stressScore) && actInfo.stressScore != null) {
                values[3] = actInfo.stressScore.toString();
            }
            // Body battery
            if ((actInfo has :bodyBatteryHistory)
                && actInfo.bodyBatteryHistory != null
                && actInfo.bodyBatteryHistory.size() > 0) {
                values[4] = actInfo.bodyBatteryHistory[0].toString() + "%";
            }
        }

        for (var i = 0; i < 5; i++) {
            var bx = i * bw;
            var cx = bx + bw / 2;

            dc.setColor(BLOCK_COLORS[i], BLOCK_COLORS[i]);
            dc.fillRectangle(bx, blockTop, bw, _screenHeight - blockTop);

            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, blockTop + 13, Graphics.FONT_TINY, values[i],
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

            drawBlockIcon(dc, cx, blockTop + 38, i);
        }
    }

    private function drawBlockIcon(dc as Dc, cx as Number, cy as Number, type as Number) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        if (type == 0) {
            drawStairsIcon(dc, cx, cy);        // Floors
        } else if (type == 1) {
            drawLightningIcon(dc, cx, cy);     // Active Calories
        } else if (type == 2) {
            drawFootstepsIcon(dc, cx, cy);     // Steps
        } else if (type == 3) {
            drawFlameIcon(dc, cx, cy);         // Stress
        } else if (type == 4) {
            drawBodyIcon(dc, cx, cy);          // Body Battery
        }
    }

    // ── Top icon helpers ──────────────────────────────────────────────────────

    private function drawMoonIcon(dc as Dc, cx as Number, cy as Number) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx, cy, 8);
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx + 4, cy - 3, 6);
    }

    private function drawSunIcon(dc as Dc, cx as Number, cy as Number) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx, cy, 5);
        // 8 rays (hardcoded directions)
        var ix = [ 0,  4,  6,  4,  0, -4, -6, -4];
        var iy = [-6, -4,  0,  4,  6,  4,  0, -4];
        var ox = [ 0,  7, 10,  7,  0, -7,-10, -7];
        var oy = [-10,-7,  0,  7, 10,  7,  0, -7];
        for (var i = 0; i < 8; i++) {
            dc.drawLine(cx + ix[i], cy + iy[i], cx + ox[i], cy + oy[i]);
        }
    }

    private function drawBtIcon(dc as Dc, cx as Number, cy as Number, connected as Boolean) as Void {
        var color = connected ? Graphics.COLOR_BLUE : Graphics.COLOR_DK_GRAY;
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(cx, cy - 8, cx, cy + 8);         // vertical stem
        dc.drawLine(cx, cy - 8, cx + 5, cy - 4);     // upper-right out
        dc.drawLine(cx + 5, cy - 4, cx, cy);          // upper-right back
        dc.drawLine(cx, cy, cx + 5, cy + 4);          // lower-right out
        dc.drawLine(cx + 5, cy + 4, cx, cy + 8);      // lower-right back
    }

    private function drawBatteryGraphic(dc as Dc, cx as Number, cy as Number, pct as Number) as Void {
        var bw = 22;
        var bh = 10;
        var x  = cx - bw / 2;
        var y  = cy - bh / 2;
        var col = pct <= 15
            ? Graphics.COLOR_RED
            : pct <= 30 ? Graphics.COLOR_ORANGE : Graphics.COLOR_WHITE;
        dc.setColor(col, Graphics.COLOR_TRANSPARENT);
        dc.drawRectangle(x, y, bw, bh);
        dc.fillRectangle(x + bw, y + 3, 3, bh - 6);          // terminal nub
        var fillW = ((bw - 4) * pct / 100).toNumber();
        dc.fillRectangle(x + 2, y + 2, fillW, bh - 4);        // fill level
    }

    // ── Block icon helpers ────────────────────────────────────────────────────

    private function drawStairsIcon(dc as Dc, cx as Number, cy as Number) as Void {
        dc.fillRectangle(cx - 6, cy + 2,  12, 2);
        dc.fillRectangle(cx - 2, cy - 2,   8, 2);
        dc.fillRectangle(cx + 2, cy - 6,   4, 2);
        dc.fillRectangle(cx - 2, cy - 2,   2, 4);
        dc.fillRectangle(cx + 2, cy - 6,   2, 8);
    }

    private function drawLightningIcon(dc as Dc, cx as Number, cy as Number) as Void {
        var pts = [[cx + 2, cy - 9], [cx - 4, cy], [cx, cy],
                   [cx - 2, cy + 9], [cx + 4, cy], [cx, cy]] as Array<Array<Number>>;
        dc.fillPolygon(pts);
    }

    private function drawFootstepsIcon(dc as Dc, cx as Number, cy as Number) as Void {
        dc.fillRectangle(cx - 7, cy - 7, 5, 7);
        dc.fillRectangle(cx + 2, cy,     5, 7);
    }

    private function drawFlameIcon(dc as Dc, cx as Number, cy as Number) as Void {
        var pts = [[cx, cy - 9], [cx + 5, cy - 2], [cx + 5, cy + 5],
                   [cx, cy + 8], [cx - 5, cy + 5], [cx - 5, cy - 2]] as Array<Array<Number>>;
        dc.fillPolygon(pts);
        dc.setColor(0xFFAA00, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx, cy + 2, 3);
    }

    private function drawBodyIcon(dc as Dc, cx as Number, cy as Number) as Void {
        // Head
        dc.fillCircle(cx, cy - 7, 3);
        // Torso
        dc.fillRectangle(cx - 3, cy - 3, 6, 6);
        // Arms
        dc.drawLine(cx - 3, cy - 2, cx - 7, cy + 2);
        dc.drawLine(cx + 3, cy - 2, cx + 7, cy + 2);
        // Legs
        dc.drawLine(cx - 2, cy + 3, cx - 4, cy + 9);
        dc.drawLine(cx + 2, cy + 3, cx + 4, cy + 9);
    }

    function onHide() as Void {
    }

    function onExitSleep() as Void {
    }

    function onEnterSleep() as Void {
        WatchUi.requestUpdate();
    }

}
