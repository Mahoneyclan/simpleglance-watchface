import Toybox.Application;
import Toybox.Application.Storage;
import Toybox.Background;
import Toybox.Communications;
import Toybox.Lang;
import Toybox.Math;
import Toybox.Position;
import Toybox.System;
import Toybox.Time;
import Toybox.WatchUi;

class WatchFaceApp extends Application.AppBase {

    private var _view as WatchFaceView or Null = null;

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Dictionary?) as Void {
        scheduleBackground();
    }

    function onStop(state as Dictionary?) as Void {
    }

    function getInitialView() as [Views] or [Views, InputDelegates] {
        _view = new WatchFaceView();
        return [_view];
    }

    // Registers BackgroundService as the service delegate for temporal events.
    function getServiceDelegate() as [System.ServiceDelegate] {
        return [new BackgroundService()];
    }

    function onSettingsChanged() as Void {
        scheduleBackground();
        if (_view != null) {
            (_view as WatchFaceView).onSettingsChanged();
        }
        WatchUi.requestUpdate();
    }

    // Called when BackgroundService exits with a temperature Number.
    function onBackgroundData(data as Application.PersistableType) as Void {
        if (data != null) {
            Storage.setValue("wx_temp", data);
        }
        WatchUi.requestUpdate();
    }

    // Immediate foreground fetch — called from WatchFaceView.onShow() when
    // no temperature is stored yet so the display isn't blank on first install.
    function fetchTemperatureNow() as Void {
        var posInfo = Position.getInfo();
        if (posInfo == null || posInfo.position == null) { return; }
        var coords = posInfo.position.toDegrees();
        Storage.setValue("wx_coords", coords);
        Communications.makeWebRequest(
            "https://api.open-meteo.com/v1/forecast",
            {
                "latitude"  => (coords[0] as Double).format("%.4f"),
                "longitude" => (coords[1] as Double).format("%.4f"),
                "current"   => "temperature_2m",
                "timezone"  => "auto"
            },
            { :method => Communications.HTTP_REQUEST_METHOD_GET },
            method(:onTempResponse)
        );
    }

    function onTempResponse(responseCode as Number, data as Dictionary?) as Void {
        if (responseCode == 200 && data != null) {
            var current = data["current"] as Dictionary?;
            if (current != null && current["temperature_2m"] != null) {
                Storage.setValue("wx_temp",
                    Math.round(current["temperature_2m"] as Float).toNumber());
                WatchUi.requestUpdate();
            }
        }
    }

    // Reads RefreshRate setting (minutes) and re-registers the temporal event.
    private function scheduleBackground() as Void {
        var rate = Application.Properties.getValue("RefreshRate") as Number?;
        if (rate == null || rate < 15) { rate = 30; }
        Background.deleteTemporalEvent();
        Background.registerForTemporalEvent(new Time.Duration(rate * 60));
    }

}
