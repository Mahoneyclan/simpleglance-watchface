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
    // Darkened versions for unfilled background (≈25% brightness)
    private var BLOCK_DARK   = [0x071533, 0x003311, 0x332900, 0x331400, 0x330008];

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

    // 3px white outline — frosted glass effect for time
    private function drawGlassText(dc as Dc, x as Number, y as Number, font as FontType, text as String, justify as Number) as Void {
        var offsets = [
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
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        for (var i = 0; i < offsets.size(); i++) {
            dc.drawText(x + offsets[i][0], y + offsets[i][1], font, text, justify);
        }
        dc.setColor(0xAAAAAA, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y, font, text, justify);
    }

    // Top row: Moon/Sun | Bluetooth | Battery graphic
    private function drawTopIcons(dc as Dc) as Void {
        var y        = _centerY - 88;
        var settings = System.getDeviceSettings();
        var stats    = System.getSystemStats();
        var hour     = System.getClockTime().hour;

        if (hour >= 12) {
            drawMoonIcon(dc, _centerX - 38, y);
        } else {
            drawSunIcon(dc, _centerX - 38, y);
        }

        drawBtIcon(dc, _centerX, y, settings.phoneConnected);
        drawBatteryGraphic(dc, _centerX + 38, y, stats.battery.toNumber());
    }

    private function drawDate(dc as Dc) as Void {
        var now    = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var days   = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
        var months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun",
                      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
        var dateStr = Lang.format("$1$  $2$  $3$", [
            days[now.day_of_week - 1],
            months[now.month - 1],
            now.day.format("%02d")
        ]);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(_centerX, _centerY - 66, Graphics.FONT_MEDIUM, dateStr,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    private function drawTime(dc as Dc) as Void {
        var clockTime = System.getClockTime();
        var hours     = clockTime.hour % 12;
        if (hours == 0) { hours = 12; }
        var timeStr = Lang.format("$1$:$2$", [hours.format("%02d"), clockTime.min.format("%02d")]);
        drawGlassText(dc, _centerX, _centerY - 8, Graphics.FONT_NUMBER_THAI_HOT, timeStr,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    // 5 colored blocks: Floors | Active Cal | Steps | Stress | Body Battery
    // Goals: floors=10, calories=500, steps=10000, stress=lower is better, body=0-100
    private var BLOCK_GOALS = [10.0f, 500.0f, 10000.0f, 100.0f, 100.0f];

    private function drawBlocks(dc as Dc) as Void {
        var actInfo     = ActivityMonitor.getInfo();
        var blockTop    = _centerY + 46;
        var bw          = _screenWidth / 5;
        var blockHeight = _screenHeight - blockTop;

        var values     = ["--", "--", "--", "--", "--"] as Array<String>;
        var fillRatios = [0.0f, 0.0f, 0.0f, 0.0f, 0.0f] as Array<Float>;

        if (actInfo != null) {
            // Floors — goal: 10
            if (actInfo.floorsClimbed != null) {
                var v = actInfo.floorsClimbed as Number;
                values[0] = v.toString();
                fillRatios[0] = v.toFloat() / BLOCK_GOALS[0];
            }
            // Calories — goal: 500
            if (actInfo.calories != null) {
                var v = actInfo.calories as Number;
                values[1] = v.toString();
                fillRatios[1] = v.toFloat() / BLOCK_GOALS[1];
            }
            // Steps — goal: 10,000
            if (actInfo.steps != null) {
                var v = actInfo.steps as Number;
                values[2] = v >= 1000
                    ? Lang.format("$1$k", [(v / 1000.0).format("%.1f")])
                    : v.toString();
                fillRatios[2] = v.toFloat() / BLOCK_GOALS[2];
            }
            // Stress — lower is better: fill = (100 - stress) / 100
            if ((actInfo has :stressScore) && actInfo.stressScore != null) {
                var v = actInfo.stressScore as Number;
                values[3] = v.toString();
                fillRatios[3] = (100.0f - v.toFloat()) / 100.0f;
            }
            // Body battery — 0-100
            if ((actInfo has :bodyBatteryHistory)
                && actInfo.bodyBatteryHistory != null
                && actInfo.bodyBatteryHistory.size() > 0) {
                var v = actInfo.bodyBatteryHistory[0] as Number;
                values[4] = v.toString() + "%";
                fillRatios[4] = v.toFloat() / 100.0f;
            }
        }

        // Clamp ratios and track sparkline y positions
        var sparkY = [0, 0, 0, 0, 0] as Array<Number>;

        for (var i = 0; i < 5; i++) {
            if (fillRatios[i] > 1.0f) { fillRatios[i] = 1.0f; }
            if (fillRatios[i] < 0.0f) { fillRatios[i] = 0.0f; }

            var bx    = i * bw;
            var cx    = bx + bw / 2;
            var fillH = (blockHeight.toFloat() * fillRatios[i]).toNumber();
            var fillY = blockTop + blockHeight - fillH;

            // Dark unfilled background
            dc.setColor(BLOCK_DARK[i], BLOCK_DARK[i]);
            dc.fillRectangle(bx, blockTop, bw, blockHeight);

            // Bright fill rising from bottom
            dc.setColor(BLOCK_COLORS[i], BLOCK_COLORS[i]);
            dc.fillRectangle(bx, fillY, bw, fillH);

            sparkY[i] = fillY;

            // Value text — always on top
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, blockTop + 13, Graphics.FONT_TINY, values[i],
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

            // Icon below value
            drawBlockIcon(dc, cx, blockTop + 36, i);
        }

        // Sparkline connecting fill levels across blocks
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        for (var i = 0; i < 4; i++) {
            dc.drawLine(i * bw + bw / 2, sparkY[i], (i + 1) * bw + bw / 2, sparkY[i + 1]);
        }
        dc.setPenWidth(1);
    }

    private function drawBlockIcon(dc as Dc, cx as Number, cy as Number, type as Number) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        if (type == 0) {
            drawStairsIcon(dc, cx, cy);
        } else if (type == 1) {
            drawLightningIcon(dc, cx, cy);
        } else if (type == 2) {
            drawFootstepsIcon(dc, cx, cy);
        } else if (type == 3) {
            drawFlameIcon(dc, cx, cy);
        } else if (type == 4) {
            drawBodyIcon(dc, cx, cy);
        }
    }

    // ── Top icon helpers ──────────────────────────────────────────────────────

    private function drawMoonIcon(dc as Dc, cx as Number, cy as Number) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx, cy, 6);
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx + 3, cy - 2, 5);
    }

    private function drawSunIcon(dc as Dc, cx as Number, cy as Number) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
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
        var color = connected ? Graphics.COLOR_BLUE : Graphics.COLOR_DK_GRAY;
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
        var col = pct <= 15
            ? Graphics.COLOR_RED
            : pct <= 30 ? Graphics.COLOR_ORANGE : Graphics.COLOR_WHITE;
        dc.setColor(col, Graphics.COLOR_TRANSPARENT);
        dc.drawRectangle(x, y, bw, bh);
        dc.fillRectangle(x + bw, y + 2, 2, bh - 4);
        var fillW = ((bw - 4) * pct / 100).toNumber();
        dc.fillRectangle(x + 2, y + 2, fillW, bh - 4);
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
                   [cx - 2, cy + 9], [cx + 4, cy], [cx, cy]] as Array<[Number, Number]>;
        dc.fillPolygon(pts);
    }

    private function drawFootstepsIcon(dc as Dc, cx as Number, cy as Number) as Void {
        dc.fillRectangle(cx - 7, cy - 7, 5, 7);
        dc.fillRectangle(cx + 2, cy,     5, 7);
    }

    private function drawFlameIcon(dc as Dc, cx as Number, cy as Number) as Void {
        var pts = [[cx, cy - 9], [cx + 5, cy - 2], [cx + 5, cy + 5],
                   [cx, cy + 8], [cx - 5, cy + 5], [cx - 5, cy - 2]] as Array<[Number, Number]>;
        dc.fillPolygon(pts);
        dc.setColor(0xFFAA00, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx, cy + 2, 3);
    }

    private function drawBodyIcon(dc as Dc, cx as Number, cy as Number) as Void {
        dc.fillCircle(cx, cy - 7, 3);
        dc.fillRectangle(cx - 3, cy - 3, 6, 6);
        dc.drawLine(cx - 3, cy - 2, cx - 7, cy + 2);
        dc.drawLine(cx + 3, cy - 2, cx + 7, cy + 2);
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
