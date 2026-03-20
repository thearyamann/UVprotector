import 'dart:io';
import 'package:home_widget/home_widget.dart';
import 'uv_cache_service.dart';
import '../core/logger.dart';

class WidgetService {
  static const String _groupId = 'group.com.thearyamann.uvprotector';
  static const String _iosWidgetName = 'UVProtectorWidget';
  static const String _androidWidgetName = 'UVWidgetProvider';

  static Future<void> updateFromCache() async {
    try {
      final uvData = await UVCacheService.loadCachedUVData();
      final session = await UVCacheService.loadSessionData();

      if (uvData == null) return;

      bool timerRunning = false;
      DateTime? timerEndTime;
      String protectionStatus = 'Not Applied';
      int sessionsCompleted = 0;
      int sessionsTotal = 0;

      if (session != null) {
        sessionsCompleted = session['sessionsCompleted'] as int? ?? 0;
        sessionsTotal =
            session['lockedTotalSessions'] as int? ??
            session['totalSessions'] as int? ??
            0;
        final lastApplied = session['lastAppliedAt'] as int? ?? 0;
        final reapplyMins =
            session['lockedReapplyMinutes'] as int? ??
            session['reapplyMinutes'] as int? ??
            0;

        if (sessionsCompleted > 0 && sessionsCompleted < sessionsTotal) {
          timerRunning = true;
          final endMs = lastApplied + (reapplyMins * 60 * 1000);
          timerEndTime = DateTime.fromMillisecondsSinceEpoch(endMs);

          final nowMs = DateTime.now().millisecondsSinceEpoch;
          final minsLeft = (endMs - nowMs) / (1000 * 60);

          if (minsLeft > 15) {
            protectionStatus = 'Protected';
          } else if (minsLeft > 0) {
            protectionStatus = 'Expiring Soon';
          } else {
            protectionStatus = 'Not Applied';
          }
        } else if (sessionsCompleted >= sessionsTotal && sessionsTotal > 0) {
          protectionStatus = 'Done for today';
        } else {
          protectionStatus = 'Not Applied';
        }
      }

      final isLowUV = uvData.uvIndex <= 2;

      if (isLowUV) {
        protectionStatus = 'UV is low';
        timerRunning = false;
        timerEndTime = null;
      }

      final burnTime = '${uvData.burnTimeMinutes} mins';
      final sessionsText = '$sessionsCompleted/$sessionsTotal';

      await _push(
        uvIndex: uvData.uvIndex.round(),
        uvStatus: uvData.riskLevel,
        burnTime: burnTime,
        timerRunning: timerRunning,
        timerEndTime: timerEndTime,
        sessionsText: sessionsText,
        protectionStatus: protectionStatus,
      );
    } catch (e, st) {
      AppLogger.logServiceError('WidgetService', 'updateFromCache', e, st);
    }
  }

  static Future<void> _push({
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

      await HomeWidget.saveWidgetData<int>('uv_index', uvIndex);
      await HomeWidget.saveWidgetData<String>('uv_status', uvStatus);
      await HomeWidget.saveWidgetData<String>('burn_time', burnTime);
      await HomeWidget.saveWidgetData<bool>('timer_running', timerRunning);
      await HomeWidget.saveWidgetData<String>('sessions_text', sessionsText);
      await HomeWidget.saveWidgetData<String>(
        'protection_status',
        protectionStatus,
      );

      if (timerEndTime != null) {
        await HomeWidget.saveWidgetData<int>(
          'timer_end_time',
          timerEndTime.millisecondsSinceEpoch,
        );
      } else {
        await HomeWidget.saveWidgetData<int?>('timer_end_time', null);
      }

      await HomeWidget.updateWidget(
        iOSName: _iosWidgetName,
        androidName: _androidWidgetName,
      );
    } catch (e, st) {
      AppLogger.logServiceError('WidgetService', '_push', e, st);
    }
  }
}
