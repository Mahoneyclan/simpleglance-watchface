// WatchFaceApp.mc
// Entry point for the Garmin watch face application.
// Owns the background weather schedule and routes background results
// into persistent Storage for WatchFaceView to read on each screen draw.
//
// The three annotations below tell the compiler to include this class in all
// three compilation targets:
//   (no annotation) = foreground watch face — getInitialView() is called
//   :glance         = glance mode preview   — getGlanceView() is called
//   :background     = background timer      — getServiceDelegate() / onBackgroundData() are called

import Toybox.Application;
import Toybox.Application.Storage;
import Toybox.Background;
import Toybox.Lang;
import Toybox.Time;
import Toybox.WatchUi;

(:background, :glance)
class WatchFaceApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    // Called when the watch face becomes active (screen on, face selected).
    // Schedule the first background weather fetch so data starts flowing
    // without waiting for the user to open a widget.
    function onStart(state as Dictionary?) as Void {
        scheduleBackground();
    }

    function onStop(state as Dictionary?) as Void {
    }

    // Return the main watch face view shown when the face is active.
    function getInitialView() as [Views] or [Views, InputDelegates] {
        return [new WatchFaceView()];
    }

    // Return the compact glance view shown when the user browses faces or
    // the watch is in ambient/glance mode.
    function getGlanceView() as [WatchUi.GlanceView] or [WatchUi.GlanceView, WatchUi.GlanceViewDelegate] or Null {
        return [new WatchFaceGlanceView()];
    }

    // Tell the Garmin OS which class handles background timer events.
    // The OS instantiates WatchFaceBackground and calls onTemporalEvent()
    // on the schedule registered below.
    function getServiceDelegate() as [Toybox.System.ServiceDelegate] {
        return [new WatchFaceBackground()];
    }

    // Receives the array returned by Background.exit() in WatchFaceBackground.
    // Layout: [ gpsWeather, homeWeather ]  (each slot is a 7-element array or null)
    //
    // Null slots mean the HTTP request failed — we keep the last known value in
    // Storage rather than overwriting with null, so the watch face always shows
    // SOMETHING rather than dashes after a transient network error.
    function onBackgroundData(data as Application.PersistableType) as Void {
        var result = data as Array;
        if (result == null || result.size() < 2) {
            return;
        }
        var gps  = result[0] as Array?;
        var home = result[1] as Array?;
        if (gps  != null) { Storage.setValue("gps_weather",  gps);  }
        if (home != null) { Storage.setValue("home_weather", home); }
        WatchUi.requestUpdate();  // redraw the face with the fresh temperature
    }

    // Called when the user changes a setting in the Garmin Connect mobile app
    // (e.g. home location name/coordinates or refresh interval).
    // Re-schedule the background timer so the new interval takes effect now,
    // and redraw the face in case the home name label changed.
    function onSettingsChanged() as Void {
        scheduleBackground();
        WatchUi.requestUpdate();
    }

    // ── Background scheduling ────────────────────────────────────────────────
    // Register a recurring background fetch at the interval set in Settings.
    // deleteTemporalEvent() MUST be called first — registering a second event
    // without deleting the first is a runtime error on the device.

    private function scheduleBackground() as Void {
        Background.deleteTemporalEvent();
        var rate = Properties.getValue("refresh_rate") as Number?;
        if (rate == null) { rate = 30; }  // default: 30 minutes
        Background.registerForTemporalEvent(new Time.Duration(rate * 60));
    }
}
