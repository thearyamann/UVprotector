import 'dart:io';
import 'package:home_widget/home_widget.dart';
import 'uv_cache_service.dart';

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
      String sessionsText = '0/0';
      String protectionStatus = 'Not Applied';
      String burnTime = '${uvData.burnTimeMinutes} mins';

      if (session != null) {
        final completed = session['sessionsCompleted'] as int;
        final total = session['lockedTotalSessions'] as int? ?? session['totalSessions'] as int;
        final lastApplied = session['lastAppliedAt'] as int;
        final reapplyMins = session['lockedReapplyMinutes'] as int? ?? session['reapplyMinutes'] as int;

        timerRunning = completed > 0 && completed < total;
        sessionsText = '$completed/$total';

        if (timerRunning) {
          final endMs = lastApplied + (reapplyMins * 60 * 1000);
          timerEndTime = DateTime.fromMillisecondsSinceEpoch(endMs);
          
          final nowMs = DateTime.now().millisecondsSinceEpoch;
          if (nowMs < endMs) {
            protectionStatus = 'Protected';
          } else {
            protectionStatus = 'Expired';
          }
        } else if (completed >= total) {
          protectionStatus = 'Done for today';
        }
      }

      await updateWidgetData(
        uvIndex: uvData.uvIndex.round(),
        uvStatus: uvData.riskLevel,
        burnTime: burnTime,
        timerRunning: timerRunning,
        timerEndTime: timerEndTime,
        sessionsText: sessionsText,
        protectionStatus: protectionStatus,
      );
    } catch (_) {}
  }

  static Future<void> updateWidgetData({
    required int uvIndex,
    required String uvStatus,
    required String burnTime,
    required bool timerRunning,
    required DateTime? timerEndTime,
    required String sessionsText,
    required String protectionStatus,
  }) async {
    try {
      if (Platform.isIOS) {
        await HomeWidget.setAppGroupId(_groupId);
      }

      await HomeWidget.saveWidgetData('uv_index', uvIndex);
      await HomeWidget.saveWidgetData('uv_status', uvStatus);
      await HomeWidget.saveWidgetData('burn_time', burnTime);
      await HomeWidget.saveWidgetData('timer_running', timerRunning);
      await HomeWidget.saveWidgetData('sessions_text', sessionsText);
      await HomeWidget.saveWidgetData('protection_status', protectionStatus);
      
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
