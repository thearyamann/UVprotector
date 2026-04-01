import 'dart:io';
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
const String kUVRefreshTaskIOS = 'uv_refresh_task_ios';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    final effectiveTaskName = Platform.isIOS
        ? kUVRefreshTaskIOS
        : kUVRefreshTask;

    if (taskName == effectiveTaskName ||
        taskName == kUVRefreshTask ||
        taskName == kUVRefreshTaskIOS) {
      try {
        await NotificationService.init();

        final prefs = await PreferencesService.loadPreferences();
        final location = await LocationService().getCurrentLocation();
        final city = await GeocodingService.getCityName(
          location.latitude,
          location.longitude,
        );

        final weatherResult = await WeatherService.fetchWeatherAndPeak(
          latitude: location.latitude,
          longitude: location.longitude,
          cityName: city,
        );

        final controller = UVController();
        final data = await controller.getCurrentUVData(
          uvIndex: weatherResult.currentUV,
          latitude: location.latitude,
          longitude: location.longitude,
          skinTypeNumber: prefs.skinTypeNumber,
        );

        final finalData = data.copyWith(
          peakStart: weatherResult.peakStart,
          peakEnd: weatherResult.peakEnd,
        );

        await UVCacheService.saveUVData(finalData);
        await WidgetService.updateFromCache();

        await _sendNotifications(finalData);
      } catch (e) {
        print('[BackgroundService] Error in background task: $e');
      }
    }
    return Future.value(true);
  });
}

Future<void> _sendNotifications(dynamic finalData) async {
  final session = await UVCacheService.loadSessionData();
  final completed = session?['sessionsCompleted'] as int? ?? 0;
  final total =
      session?['lockedTotalSessions'] as int? ??
      session?['totalSessions'] as int? ??
      0;
  final isOutdoor = session?['isOutdoor'] as bool? ?? true;

  if (completed == 0 && finalData.uvIndex >= 3) {
    final todayKey = _todayKey();
    final lastHighUvAlertDate =
        await PreferencesService.loadLastHighUvAlertDate();
    if (lastHighUvAlertDate != todayKey) {
      final isHighUv = finalData.uvIndex >= 6;
      await NotificationService.showNotification(
        id: 2,
        title: isHighUv ? 'High UV Alert! ☀️' : 'UV Alert! ☀️',
        body: isHighUv
            ? 'UV index is now ${finalData.uvIndex.toStringAsFixed(1)}. Apply sunscreen for protection.'
            : 'UV index is now ${finalData.uvIndex.toStringAsFixed(1)}. Sunscreen is recommended before going outside.',
      );
      await PreferencesService.saveLastHighUvAlertDate(todayKey);
    }
  }

  if (session != null) {
    final reapplyMins =
        session['lockedReapplyMinutes'] as int? ??
        session['reapplyMinutes'] as int? ??
        0;
    final remainingOutdoorSeconds =
        (session['remainingOutdoorSeconds'] as num?)?.toDouble() ?? 0.0;
    final rate = isOutdoor ? 1.0 : (1.0 / 3.0);
    final secondsLeft = remainingOutdoorSeconds / rate;

    if (completed > 0 && completed < total && secondsLeft <= 0) {
      final lastReapplyAlertSession =
          await PreferencesService.loadLastReapplyAlertSession();
      if (lastReapplyAlertSession != completed) {
        await NotificationService.showNotification(
          id: 1,
          title: 'Sunscreen Protection Expired',
          body:
              'Time to reapply! You have ${total - completed} sessions left for today.',
        );
        await PreferencesService.saveLastReapplyAlertSession(completed);
      }
    }

    if (completed > 0 && completed < total && isOutdoor) {
      final double lockedUV = (session['lockedUV'] as num?)?.toDouble() ?? 0.0;
      final bool protectionActive = secondsLeft > 0;
      final bool uvRoseSharply = finalData.uvIndex > lockedUV + 2.0;
      if (protectionActive && uvRoseSharply) {
        final signature =
            '${_todayKey()}-$completed-${finalData.uvIndex.floor()}';
        final lastSignature =
            await PreferencesService.loadLastUvRiseAlertSignature();
        if (lastSignature != signature) {
          await NotificationService.showNotification(
            id: 3,
            title: 'UV Levels Rising',
            body:
                'UV has increased significantly. Consider reapplying sooner or finding shade.',
          );
          await PreferencesService.saveLastUvRiseAlertSignature(signature);
        }
      }
    }

    if (reapplyMins > 0) {
      final lastAlert = await PreferencesService.loadLastUvAlert();
      if (lastAlert != 0.0) {
        await PreferencesService.saveLastUvAlert(0.0);
      }
    }
  }
}

String _todayKey() {
  final now = DateTime.now();
  final month = now.month.toString().padLeft(2, '0');
  final day = now.day.toString().padLeft(2, '0');
  return '${now.year}-$month-$day';
}

class BackgroundService {
  static Future<void> init() async {
    await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
  }

  static Future<void> registerPeriodicRefresh() async {
    if (Platform.isIOS) {
      await Workmanager().registerPeriodicTask(
        kUVRefreshTaskIOS,
        kUVRefreshTaskIOS,
        frequency: const Duration(minutes: 30),
        existingWorkPolicy: ExistingWorkPolicy.replace,
        constraints: Constraints(
          networkType: NetworkType.connected,
          requiresBatteryNotLow: false,
        ),
        inputData: {'task': 'uv_refresh'},
      );
    } else {
      await Workmanager().registerPeriodicTask(
        kUVRefreshTask,
        kUVRefreshTask,
        frequency: const Duration(minutes: 30),
        existingWorkPolicy: ExistingWorkPolicy.replace,
        constraints: Constraints(
          networkType: NetworkType.connected,
          requiresBatteryNotLow: false,
        ),
        inputData: {'task': 'uv_refresh'},
      );
    }
  }
}
