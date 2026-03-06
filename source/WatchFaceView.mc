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

    // Top row: Moon/Sun | Bluetooth | Battery — tight to top
    private function drawTopIcons(dc as Dc) as Void {
        var y        = 20;
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
        dc.drawText(_centerX, 40, Graphics.FONT_SMALL, dateStr,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    // System font time rendered to buffer, then drawn with vertical scale (frosted glass)
    private function drawTime(dc as Dc) as Void {
        var clockTime = System.getClockTime();
        var hours     = clockTime.hour % 12;
        if (hours == 0) { hours = 12; }
        var timeStr = Lang.format("$1$:$2$", [hours.format("%02d"), clockTime.min.format("%02d")]);
        var font    = Graphics.FONT_NUMBER_THAI_HOT;
        var justify = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;

        // Off-screen buffer: full width, font height + outline padding
        var fh  = dc.getFontHeight(font);
        var pad = 4;
        var bw  = _screenWidth;
        var bh  = fh + pad * 2;

        var bitmapRef = Graphics.createBufferedBitmap({:width => bw, :height => bh});
        if (bitmapRef == null) { return; }
        var bdc = bitmapRef.get().getDc();

        bdc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        bdc.clear();

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
        var bcx = bw / 2;
        var bcy = bh / 2;
        bdc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        for (var i = 0; i < offsets.size(); i++) {
            bdc.drawText(bcx + offsets[i][0], bcy + offsets[i][1], font, timeStr, justify);
        }
        bdc.setColor(0xAAAAAA, Graphics.COLOR_TRANSPARENT);
        bdc.drawText(bcx, bcy, font, timeStr, justify);

        // Stretch vertically only — destX=0 (full-width buffer, no horizontal overflow)
        var scaleY  = 1.95f;
        var scaledH = (bh.toFloat() * scaleY).toNumber();
        var destY   = (_screenHeight / 2) - scaledH / 2 - 10;
        var transform = new Graphics.AffineTransform();
        transform.scale(1.0f, scaleY);
        dc.drawBitmap2(0, destY, bitmapRef.get(), {:transform => transform});
    }

    // Two bottom fields: Steps (left) | Body Battery (right)
    private function drawBlocks(dc as Dc) as Void {
        var actInfo = ActivityMonitor.getInfo();
        var stepsVal = "--" as String;
        var bodyVal  = "--" as String;

        if (actInfo != null) {
            if (actInfo.steps != null) {
                var v = actInfo.steps as Number;
                stepsVal = v >= 1000
                    ? Lang.format("$1$k", [(v / 1000.0).format("%.1f")])
                    : v.toString();
            }
            if ((actInfo has :bodyBatteryHistory)
                && actInfo.bodyBatteryHistory != null
                && actInfo.bodyBatteryHistory.size() > 0) {
                bodyVal = (actInfo.bodyBatteryHistory[0] as Number).toString() + "%";
            }
        }

        var y     = 205;
        var leftX = _centerX / 2;
        var rightX = _centerX + _centerX / 2;
        var justify = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;

        // Steps
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(leftX, y - 10, Graphics.FONT_XTINY, "STEPS", justify);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(leftX, y + 10, Graphics.FONT_SMALL, stepsVal, justify);

        // Divider
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(_centerX, y - 18, _centerX, y + 18);

        // Body Battery
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(rightX, y - 10, Graphics.FONT_XTINY, "BODY BAT", justify);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(rightX, y + 10, Graphics.FONT_SMALL, bodyVal, justify);
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

    function onHide() as Void {
    }

    function onExitSleep() as Void {
    }

    function onEnterSleep() as Void {
        WatchUi.requestUpdate();
    }

}
