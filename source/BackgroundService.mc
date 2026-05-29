import Toybox.Application.Storage;
import Toybox.Background;
import Toybox.Communications;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;

// Runs every 30 minutes to fetch current temperature from Open-Meteo.
// Uses coordinates saved by WatchFaceView from Garmin's weather observation
// position. Exits with a Number (°C) or null on failure.
(:background)
class BackgroundService extends System.ServiceDelegate {

    function initialize() {
        System.ServiceDelegate.initialize();
    }

    function onTemporalEvent() as Void {
        var coords = Storage.getValue("wx_coords") as Array?;
        if (coords == null || coords.size() < 2) {
            Background.exit(null);
            return;
        }
        Communications.makeWebRequest(
            "https://api.open-meteo.com/v1/forecast",
            {
                "latitude"  => (coords[0] as Double).format("%.4f"),
                "longitude" => (coords[1] as Double).format("%.4f"),
                "current"   => "temperature_2m",
                "timezone"  => "auto"
            },
            { :method => Communications.HTTP_REQUEST_METHOD_GET },
            method(:onReceive)
        );
    }

    function onReceive(responseCode as Number, data as Dictionary?) as Void {
        if (responseCode == 200 && data != null) {
            var current = data["current"] as Dictionary?;
            if (current != null && current["temperature_2m"] != null) {
                var temp = Math.round(current["temperature_2m"] as Float).toNumber();
                Background.exit(temp);
                return;
            }
        }
        Background.exit(null);
    }

}
