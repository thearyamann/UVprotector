import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/uv_data.dart';

class UVCacheService {
  static const String _keyUVData        = 'cached_uv_data';
  static const String _keyLastFetched   = 'last_fetched_ms';
  static const String _keySessionData   = 'sunscreen_session_data';

  static Future<void> saveUVData(UVData data) async {
    final store = await SharedPreferences.getInstance();
    final map = {
      'uvIndex':           data.uvIndex,
      'riskLevel':         data.riskLevel,
      'burnTimeMinutes':   data.burnTimeMinutes == double.infinity ? -1.0 : data.burnTimeMinutes,
      'exposureAdvice':    data.exposureAdvice,
      'spfRecommendation': data.spfRecommendation,
      'reapplyMinutes':    data.reapplyMinutes,
      'timestamp':         data.timestamp.millisecondsSinceEpoch,
      'latitude':          data.latitude,
      'longitude':         data.longitude,
    };
    await store.setString(_keyUVData, jsonEncode(map));
    await store.setInt(_keyLastFetched, DateTime.now().millisecondsSinceEpoch);
  }

  static Future<UVData?> loadCachedUVData() async {
    final store = await SharedPreferences.getInstance();
    final raw = store.getString(_keyUVData);
    if (raw == null) return null;
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return UVData(
      uvIndex:           (map['uvIndex'] as num).toDouble(),
      riskLevel:         map['riskLevel'] as String,
      burnTimeMinutes:   (map['burnTimeMinutes'] as num).toDouble() == -1.0
          ? double.infinity
          : (map['burnTimeMinutes'] as num).toDouble(),
      exposureAdvice:    map['exposureAdvice'] as String,
      spfRecommendation: map['spfRecommendation'] as String,
      reapplyMinutes:    map['reapplyMinutes'] as int,
      timestamp:         DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      latitude:          (map['latitude'] as num?)?.toDouble(),
      longitude:         (map['longitude'] as num?)?.toDouble(),
    );
  }

  static Future<bool> shouldRefresh() async {
    final store = await SharedPreferences.getInstance();
    final last = store.getInt(_keyLastFetched);
    if (last == null) return true;
    return DateTime.now().millisecondsSinceEpoch - last > 30 * 60 * 1000;
  }

  // Session data: tracks today's applications
  // {
  //   'date': 'YYYY-MM-DD',
  //   'sessionsCompleted': 2,
  //   'totalSessions': 3,
  //   'lastAppliedAt': 1234567890,   // ms since epoch
  //   'sessionStartedAt': 12345678,  // ms since epoch — when current countdown started
  //   'reapplyMinutes': 90,
  //   'spf': 30,
  // }

  static Future<void> saveSession({
    required int sessionsCompleted,
    required int totalSessions,
    required int reapplyMinutes,
    required int spf,
  }) async {
    final store = await SharedPreferences.getInstance();
    final now   = DateTime.now();
    final date  = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final map = {
      'date':               date,
      'sessionsCompleted':  sessionsCompleted,
      'totalSessions':      totalSessions,
      'lastAppliedAt':      now.millisecondsSinceEpoch,
      'sessionStartedAt':   now.millisecondsSinceEpoch,
      'reapplyMinutes':     reapplyMinutes,
      'spf':                spf,
    };
    await store.setString(_keySessionData, jsonEncode(map));
  }

  static Future<Map<String, dynamic>?> loadSessionData() async {
    final store = await SharedPreferences.getInstance();
    final raw = store.getString(_keySessionData);
    if (raw == null) return null;
    final map  = jsonDecode(raw) as Map<String, dynamic>;
    final now  = DateTime.now();
    final date = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    if (map['date'] != date) return null;
    return map;
  }

  static Future<void> clearSession() async {
    final store = await SharedPreferences.getInstance();
    await store.remove(_keySessionData);
  }

  // Legacy — kept for compatibility
  static Future<void> saveApplied(int spf) async {}
  static Future<Map<String, dynamic>?> loadAppliedState() async => null;
  static Future<void> clearApplied() async {}
}