import 'dart:io';
import 'package:home_widget/home_widget.dart';
import 'uv_cache_service.dart';
import 'preferences_service.dart';

class WidgetService {
  static const String _groupId = 'group.com.thearyamann.uvprotector';
  static const String _iosWidgetName = 'UVWidget';
  static const String _androidWidgetName = 'UVWidgetProvider';

  static Future<void> updateFromCache() async {
    try {
      final uvData = await UVCacheService.loadCachedUVData();
      final session = await UVCacheService.loadSessionData();

      if (uvData == null) return;

      bool timerRunning = false;
      DateTime? timerEndTime;
      String burnTimeMins = uvData.burnTimeMinutes.round().toString();
      bool isLowUV = uvData.uvIndex < 3;

      final prefs = await PreferencesService.loadPreferences();

      String protectionStatus = 'Unprotected';
      int sessionsCompleted = 0;
      int sessionsTotal = 0; // Default to 0

      if (session != null) {
        sessionsCompleted = session['sessionsCompleted'] as int? ?? 0;
        sessionsTotal = session['lockedTotalSessions'] as int? ?? session['totalSessions'] as int? ?? 0;
        final lastApplied = session['lastAppliedAt'] as int? ?? 0;
        final reapplyMins = session['lockedReapplyMinutes'] as int? ?? session['reapplyMinutes'] as int? ?? 0;

        timerRunning = sessionsCompleted > 0 && sessionsCompleted < sessionsTotal;

        if (timerRunning) {
          final endMs = lastApplied + (reapplyMins * 60 * 1000);
          timerEndTime = DateTime.fromMillisecondsSinceEpoch(endMs);
          
          final nowMs = DateTime.now().millisecondsSinceEpoch;
          final minsLeft = (endMs - nowMs) / (1000 * 60);

          if (minsLeft > 15) {
            protectionStatus = 'Protected';
          } else if (minsLeft > 0) {
            protectionStatus = 'Expiring Soon';
          } else {
            protectionStatus = 'Unprotected';
          }
        } else if (sessionsCompleted >= sessionsTotal && sessionsTotal > 0) {
          protectionStatus = 'Done for today';
        }
      }

      if (isLowUV) {
        protectionStatus = 'UV is low';
      }

      await updateWidgetData(
        uvIndex: uvData.uvIndex.round(),
        uvStatus: uvData.riskLevel,
        burnTime: burnTimeMins,
        timerRunning: timerRunning,
        timerEndTime: timerEndTime,
        sessionsCompleted: sessionsCompleted,
        sessionsTotal: sessionsTotal,
        protectionStatus: protectionStatus,
        isLowUV: isLowUV,
      );
    } catch (_) {}
  }

  static Future<void> updateWidgetData({
    required int uvIndex,
    required String uvStatus,
    required String burnTime,
    required bool timerRunning,
    required DateTime? timerEndTime,
    required int sessionsCompleted,
    required int sessionsTotal,
    required String protectionStatus,
    required bool isLowUV,
  }) async {
    try {
      if (Platform.isIOS) {
        await HomeWidget.setAppGroupId(_groupId);
      }

      await HomeWidget.saveWidgetData('uv_index', uvIndex);
      await HomeWidget.saveWidgetData('uv_status', uvStatus);
      await HomeWidget.saveWidgetData('burn_time', burnTime);
      await HomeWidget.saveWidgetData('timer_running', timerRunning);
      await HomeWidget.saveWidgetData('sessions_completed', sessionsCompleted);
      await HomeWidget.saveWidgetData('sessions_total', sessionsTotal);
      await HomeWidget.saveWidgetData('protection_status', protectionStatus);
      await HomeWidget.saveWidgetData('is_low_uv', isLowUV);
      
      if (timerEndTime != null) {
        await HomeWidget.saveWidgetData(
          'timer_end_time', 
          timerEndTime.millisecondsSinceEpoch
        );
      } else {
        await HomeWidget.saveWidgetData('timer_end_time', null);
      }

      await HomeWidget.updateWidget(
        iOSName: _iosWidgetName,
        androidName: _androidWidgetName,
      );
    } catch (_) {}
  }
}
