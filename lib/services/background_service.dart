import 'package:workmanager/workmanager.dart';
import 'uv_cache_service.dart';
import 'uv_controller.dart';
import 'location_service.dart';
import 'weather_service.dart';
import 'geocoding_service.dart';
import 'notification_service.dart';
import 'widget_service.dart';
import '../services/preferences_service.dart';

const String kUVRefreshTask = 'uv_refresh_task';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    if (taskName == kUVRefreshTask) {
      try {
        final prefs      = await PreferencesService.loadPreferences();
        final location   = await LocationService().getCurrentLocation();
        final city       = await GeocodingService.getCityName(location.latitude, location.longitude);
        
        final weatherResult = await WeatherService.fetchWeatherAndPeak(
          latitude:  location.latitude,
          longitude: location.longitude,
          cityName:  city,
        );

        final controller = UVController();
        final data       = await controller.getCurrentUVData(
          uvIndex:   weatherResult.currentUV,
          latitude:  location.latitude,
          longitude: location.longitude,
          skinTypeNumber: prefs.skinTypeNumber,
        );
        
        // Preserve peak hours from the weather result
        final finalData = data.copyWith(
          peakStart: weatherResult.peakStart,
          peakEnd:   weatherResult.peakEnd,
        );

        await UVCacheService.saveUVData(finalData);
        await WidgetService.updateFromCache();

        // --- Notification Logic ---
        final session = await UVCacheService.loadSessionData();
        if (session != null) {
          final int completed = session['sessionsCompleted'] as int;
          final int total     = session['lockedTotalSessions'] as int? ?? session['totalSessions'] as int;
          final int reapplyMins = session['lockedReapplyMinutes'] as int? ?? session['reapplyMinutes'] as int;
          final int lastApplied = session['lastAppliedAt'] as int;
          
          final nowMs = DateTime.now().millisecondsSinceEpoch;
          final elapsedMins = (nowMs - lastApplied) / (1000 * 60);

          // 1. Reapply Alert
          if (completed < total && completed > 0) {
            if (elapsedMins >= reapplyMins) {
              final lastAlert = await PreferencesService.loadLastUvAlert();
              if (lastAlert != completed.toDouble()) {
                await NotificationService.showNotification(
                  id: 1,
                  title: 'Sunscreen Protection Expired 🧴',
                  body: 'Time to reapply! You have ${total - completed} sessions left for today.',
                );
                await PreferencesService.saveLastUvAlert(completed.toDouble());
              }
            }
          }

          // 2. High UV Alert (Prompt first application)
          if (completed == 0 && finalData.uvIndex >= 6) {
            final lastAlert = await PreferencesService.loadLastUvAlert();
            if (lastAlert != 99.0) {
              await NotificationService.showNotification(
                id: 2,
                title: 'High UV Alert! ☀️',
                body: 'UV index is now ${finalData.uvIndex.toStringAsFixed(1)}. Apply sunscreen for protection.',
              );
              await PreferencesService.saveLastUvAlert(99.0);
            }
          }

          // 3. UV Increase Alert (Already protected but UV jumped)
          if (completed > 0 && session['isOutdoor'] == true) {
            final double lockedUV = session['lockedUV'] as double? ?? 0.0;
            if (finalData.uvIndex > lockedUV + 2.0) {
              await NotificationService.showNotification(
                id: 3,
                title: 'UV Levels Rising 📈',
                body: 'UV has increased significantly. Consider reapplying sooner or finding shade.',
              );
            }
          }
        }
      } catch (_) {}
    }
    return Future.value(true);
  });
}

class BackgroundService {
  static Future<void> init() async {
    await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
  }

  static Future<void> registerPeriodicRefresh() async {
    await Workmanager().registerPeriodicTask(
      kUVRefreshTask,
      kUVRefreshTask,
      frequency: const Duration(minutes: 30),
      existingWorkPolicy: ExistingWorkPolicy.replace,
      constraints: Constraints(networkType: NetworkType.connected),
    );
  }
}