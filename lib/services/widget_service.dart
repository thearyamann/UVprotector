import 'dart:io';
import 'package:home_widget/home_widget.dart';
import 'uv_cache_service.dart';
import '../core/logger.dart';

class WidgetService {
  static const String _groupId = 'group.com.thearyamann.uvprotector';
  static const String _iosWidgetName = 'UVProtectorWidget';
  static const String _androidSmallWidgetName = 'UVWidgetProvider';
  static const String _androidMediumWidgetName = 'UVWidgetMediumProvider';

  static Future<void> initializeWidget() async {
    try {
      if (Platform.isIOS) {
        await HomeWidget.setAppGroupId(_groupId);
      }

      await HomeWidget.saveWidgetData<int>('uv_index', 0);
      await HomeWidget.saveWidgetData<String>('uv_status', 'Loading...');
      await HomeWidget.saveWidgetData<String>('burn_time', '--');
      await HomeWidget.saveWidgetData<bool>('timer_running', false);
      await HomeWidget.saveWidgetData<int>('timer_progress_percent', 0);
      await HomeWidget.saveWidgetData<String>('sessions_text', '0/0');
      await HomeWidget.saveWidgetData<String>('protection_status', 'Open app');
      await HomeWidget.saveWidgetData<int>('timer_end_time', 0);

      await HomeWidget.updateWidget(
        iOSName: _iosWidgetName,
        androidName: _androidSmallWidgetName,
      );
      await HomeWidget.updateWidget(androidName: _androidMediumWidgetName);
    } catch (e, st) {
      AppLogger.logServiceError('WidgetService', 'initializeWidget', e, st);
    }
  }

  static Future<void> updateFromCache() async {
    try {
      final uvData = await UVCacheService.loadCachedUVData();
      final session = await UVCacheService.loadSessionData();

      if (uvData == null) return;

      bool timerRunning = false;
      DateTime? timerEndTime;
      String protectionStatus = 'Not Applied';
      int timerProgressPercent = 0;
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
        final isOutdoor = session['isOutdoor'] as bool? ?? true;
        final remainingOutdoorSeconds =
            (session['remainingOutdoorSeconds'] as num?)?.toDouble();

        if (sessionsCompleted > 0 && sessionsCompleted < sessionsTotal) {
          final rate = isOutdoor ? 1.0 : (1.0 / 3.0);
          final totalSeconds = reapplyMins * 60.0 / rate;

          double secondsLeft;
          if (remainingOutdoorSeconds != null) {
            secondsLeft = remainingOutdoorSeconds / rate;
          } else {
            final endMs = lastApplied + (reapplyMins * 60 * 1000);
            final nowMs = DateTime.now().millisecondsSinceEpoch;
            secondsLeft = (endMs - nowMs) / 1000.0;
          }

          secondsLeft = secondsLeft.clamp(0.0, totalSeconds);

          if (secondsLeft > 0 && totalSeconds > 0) {
            timerRunning = true;
            timerEndTime = DateTime.now().add(
              Duration(milliseconds: (secondsLeft * 1000).round()),
            );
            final ratio = (secondsLeft / totalSeconds).clamp(0.0, 1.0);
            timerProgressPercent = (ratio * 100).round();
            protectionStatus = ratio <= 0.2 ? 'Expiring Soon' : 'Protected';
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
        timerProgressPercent = 0;
      }

      final burnTime = _formatBurnTime(uvData.burnTimeMinutes);
      final sessionsText = '$sessionsCompleted/$sessionsTotal';

      await _push(
        uvIndex: uvData.uvIndex.round(),
        uvStatus: uvData.riskLevel,
        burnTime: burnTime,
        timerRunning: timerRunning,
        timerEndTime: timerEndTime,
        timerProgressPercent: timerProgressPercent,
        sessionsText: sessionsText,
        protectionStatus: protectionStatus,
      );
    } catch (e, st) {
      AppLogger.logServiceError('WidgetService', 'updateFromCache', e, st);
    }
  }

  static String _formatBurnTime(double burnTimeMinutes) {
    if (burnTimeMinutes == double.infinity) return 'No burn risk';

    final totalMinutes = burnTimeMinutes.round();
    if (totalMinutes < 60) {
      return '$totalMinutes min';
    }

    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (minutes == 0) {
      return '$hours hr';
    }
    return '$hours hr $minutes min';
  }

  static Future<void> _push({
    required int uvIndex,
    required String uvStatus,
    required String burnTime,
    required bool timerRunning,
    required DateTime? timerEndTime,
    required int timerProgressPercent,
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
      await HomeWidget.saveWidgetData<int>(
        'timer_progress_percent',
        timerProgressPercent,
      );
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
        androidName: _androidSmallWidgetName,
      );
      await HomeWidget.updateWidget(androidName: _androidMediumWidgetName);
    } catch (e, st) {
      AppLogger.logServiceError('WidgetService', '_push', e, st);
    }
  }
}
