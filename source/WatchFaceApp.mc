import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class WatchFaceApp extends Application.AppBase {

    private var _view as WatchFaceView or Null = null;

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Dictionary?) as Void {
    }

    function onStop(state as Dictionary?) as Void {
    }

    function getInitialView() as [Views] or [Views, InputDelegates] {
        _view = new WatchFaceView();
        return [_view];
    }

    function onSettingsChanged() as Void {
        if (_view != null) {
            (_view as WatchFaceView).onSettingsChanged();
        }
        WatchUi.requestUpdate();
    }

}
