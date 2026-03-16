import 'package:workmanager/workmanager.dart';
import 'uv_cache_service.dart';
import 'uv_controller.dart';
import '../services/preferences_service.dart';

const String kUVRefreshTask = 'uv_refresh_task';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    if (taskName == kUVRefreshTask) {
      try {
        final prefs      = await PreferencesService.loadPreferences();
        final controller = UVController();
        final data       = await controller.getCurrentUVData(
          skinTypeNumber: prefs.skinTypeNumber,
        );
        await UVCacheService.saveUVData(data);
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