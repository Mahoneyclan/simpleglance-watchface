import Toybox.ActivityMonitor;
import Toybox.Graphics;
import Toybox.Lang;
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

    // Cached once — outline offsets for the frosted-glass effect
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

    function onLayout(dc as Dc) as Void {
        _screenWidth = dc.getWidth();
        _centerX     = _screenWidth / 2;
        // Load font once here instead of every second in drawTime
        var fontRez = DARK_MODE ? Rez.Fonts.TimeFont : Rez.Fonts.TimeFontLight;
        _font = WatchUi.loadResource(fontRez) as Graphics.FontReference;
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

    // Top row: Bluetooth | Battery (centred, now moon/sun has moved below time)
    private function drawTopIcons(dc as Dc) as Void {
        var y        = 20;
        var settings = System.getDeviceSettings();
        var stats    = System.getSystemStats();

        drawBtIcon(dc, _centerX - 20, y, settings.phoneConnected);
        drawBatteryGraphic(dc, _centerX + 20, y, stats.battery.toNumber());

        // Days of charge remaining — drawn to the right of the battery graphic
        if (stats.batteryInDays != null) {
            var days = (stats.batteryInDays as Float).toNumber();
            var label = days.toString() + "d";
            var fg = DARK_MODE ? Graphics.COLOR_DK_GRAY : Graphics.COLOR_LT_GRAY;
            dc.setColor(fg, Graphics.COLOR_TRANSPARENT);
            dc.drawText(_centerX + 34, y, Graphics.FONT_XTINY, label,
                Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }

    // Moon or Sun icon centred above the colon, within the time section
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

    // Custom font time — frosted glass effect (outline + fill).
    // Colon is drawn manually as two small dots so it doesn't dominate.
    private function drawTime(dc as Dc) as Void {
        var clockTime = System.getClockTime();
        var hours     = clockTime.hour % 12;
        if (hours == 0) { hours = 12; }
        var hrStr  = hours.format("%02d");
        var minStr = clockTime.min.format("%02d");
        var font  = _font;
        var justL = Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER;
        var y     = 118;
        var cx    = _centerX;

        // Measure both strings so we can centre the whole group precisely
        var hrDims  = dc.getTextDimensions(hrStr,  font);
        var minDims = dc.getTextDimensions(minStr, font);
        var hrW  = hrDims[0];
        var minW = minDims[0];
        var colonW = 20; // total pixel width reserved for the dot colon
        var totalW = hrW + colonW + minW;
        var startX = cx - totalW / 2;
        var hrX    = startX;               // left edge of hour digits
        var minX   = startX + hrW + colonW; // left edge of minute digits

        // Fill colour interpolates from grey → white (dark) or dark-grey → black (light)
        // based on steps progress toward daily goal.
        var stepPct = 0.0f;
        var actInfo = ActivityMonitor.getInfo();
        if (actInfo != null && actInfo.steps != null && actInfo.stepGoal != null) {
            var pct = (actInfo.steps as Number).toFloat() / (actInfo.stepGoal as Number).toFloat();
            stepPct = pct < 0.0f ? 0.0f : (pct > 1.0f ? 1.0f : pct);
        }

        // Dark:  0xAAAAAA (170) → 0xFFFFFF (255)  channel = 170 + 85*p
        // Light: 0x555555 (85)  → 0x000000 (0)    channel = 85  - 85*p
        var outlineCol = DARK_MODE ? Graphics.COLOR_WHITE : Graphics.COLOR_BLACK;
        var ch = DARK_MODE
            ? (170 + (85.0f * stepPct).toNumber())
            : (85  - (85.0f * stepPct).toNumber());
        var fillCol = (ch * 65536) + (ch * 256) + ch;

        // Outline pass — uses cached _offsets array
        dc.setColor(outlineCol, Graphics.COLOR_TRANSPARENT);
        for (var i = 0; i < _offsets.size(); i++) {
            var dx = _offsets[i][0];
            var dy = _offsets[i][1];
            dc.drawText(hrX  + dx, y + dy, font, hrStr,  justL);
            dc.drawText(minX + dx, y + dy, font, minStr, justL);
        }

        // Fill pass
        dc.setColor(fillCol, Graphics.COLOR_TRANSPARENT);
        dc.drawText(hrX,  y, font, hrStr,  justL);
        dc.drawText(minX, y, font, minStr, justL);

        // Small colon: two dots centred between the two groups
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

    // Two bottom fields: Steps (left) | Floors (right)
    private function drawBlocks(dc as Dc) as Void {
        var actInfo   = ActivityMonitor.getInfo();
        var stepsVal  = "--" as String;
        var floorsVal = "--" as String;

        if (actInfo != null) {
            if (actInfo.steps != null) {
                var v = actInfo.steps as Number;
                stepsVal = v >= 1000
                    ? Lang.format("$1$k", [(v / 1000.0).format("%.1f")])
                    : v.toString();
            }
            if (actInfo.floorsClimbed != null) {
                floorsVal = (actInfo.floorsClimbed as Number).toString();
            }
        }

        var y       = 205;
        var leftX   = _centerX / 2;
        var rightX  = _centerX + _centerX / 2;
        var justify = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;
        var fg      = DARK_MODE ? Graphics.COLOR_WHITE   : Graphics.COLOR_BLACK;
        var labelFg = DARK_MODE ? Graphics.COLOR_DK_GRAY : Graphics.COLOR_LT_GRAY;

        // Steps
        dc.setColor(labelFg, Graphics.COLOR_TRANSPARENT);
        dc.drawText(leftX, y - 10, Graphics.FONT_XTINY, "STEPS", justify);
        dc.setColor(fg, Graphics.COLOR_TRANSPARENT);
        dc.drawText(leftX, y + 10, Graphics.FONT_SMALL, stepsVal, justify);

        // Divider
        dc.setColor(labelFg, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(_centerX, y - 18, _centerX, y + 18);

        // Floors
        dc.setColor(labelFg, Graphics.COLOR_TRANSPARENT);
        dc.drawText(rightX, y - 10, Graphics.FONT_XTINY, "FLOORS", justify);
        dc.setColor(fg, Graphics.COLOR_TRANSPARENT);
        dc.drawText(rightX, y + 10, Graphics.FONT_SMALL, floorsVal, justify);
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
