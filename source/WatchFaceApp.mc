import Toybox.Application;
import Toybox.Application.Storage;
import Toybox.Background;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.WatchUi;

class WatchFaceApp extends Application.AppBase {

    private var _view as WatchFaceView or Null = null;

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Dictionary?) as Void {
        Background.deleteTemporalEvent();
        Background.registerForTemporalEvent(new Time.Duration(30 * 60));
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

}
