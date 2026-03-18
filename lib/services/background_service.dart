import 'package:workmanager/workmanager.dart';
import 'uv_cache_service.dart';
import 'uv_controller.dart';
import 'location_service.dart';
import 'weather_service.dart';
import 'geocoding_service.dart';
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