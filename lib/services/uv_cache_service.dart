import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/uv_data.dart';

class UVCacheService {
  static const String _keyUVData      = 'cached_uv_data';
  static const String _keyLastFetched = 'last_fetched_ms';
  static const String _keySessionData = 'sunscreen_session_data';

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
          ? double.infinity : (map['burnTimeMinutes'] as num).toDouble(),
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

  static Future<void> saveSession({
    required int sessionsCompleted,
    required int totalSessions,
    required int reapplyMinutes,
    required int spf,
    required double lockedUV,
    required bool isOutdoor,
    required double remainingOutdoorSeconds,
  }) async {
    final store = await SharedPreferences.getInstance();
    final now   = DateTime.now();
    final date  = '${now.year}-${now.month.toString().padLeft(2,'0')}-${now.day.toString().padLeft(2,'0')}';

    // Preserve existing locked values if session already exists today
    final existing = await loadSessionData();
    final effectiveLockedUV = existing?['lockedUV'] as double? ?? lockedUV;
    final effectiveReapply  = existing?['lockedReapplyMinutes'] as int? ?? reapplyMinutes;
    final effectiveTotal    = existing?['lockedTotalSessions'] as int? ?? totalSessions;

    await store.setString(_keySessionData, jsonEncode({
      'date':                date,
      'sessionsCompleted':   sessionsCompleted,
      'totalSessions':       totalSessions,
      'lastAppliedAt':       now.millisecondsSinceEpoch,
      'sessionStartedAt':    now.millisecondsSinceEpoch,
      'reapplyMinutes':      reapplyMinutes,
      'spf':                 spf,
      'lockedUV':            effectiveLockedUV,
      'lockedReapplyMinutes': effectiveReapply,
      'lockedTotalSessions':  effectiveTotal,
      'isOutdoor':           isOutdoor,
      'remainingOutdoorSeconds': remainingOutdoorSeconds,
      'lastUpdatedAt':       now.millisecondsSinceEpoch,
    }));
  }

  /// Update just the timer mode fields (used when toggling Indoor/Outdoor)
  static Future<void> updateSessionMode({
    required bool isOutdoor,
    required double remainingOutdoorSeconds,
  }) async {
    final store = await SharedPreferences.getInstance();
    final raw = store.getString(_keySessionData);
    if (raw == null) return;
    
    final map = jsonDecode(raw) as Map<String, dynamic>;
    map['isOutdoor'] = isOutdoor;
    map['remainingOutdoorSeconds'] = remainingOutdoorSeconds;
    map['lastUpdatedAt'] = DateTime.now().millisecondsSinceEpoch;
    
    await store.setString(_keySessionData, jsonEncode(map));
  }

  static Future<Map<String, dynamic>?> loadSessionData() async {
    final store = await SharedPreferences.getInstance();
    final raw = store.getString(_keySessionData);
    if (raw == null) return null;
    final map  = jsonDecode(raw) as Map<String, dynamic>;
    final now  = DateTime.now();
    final date = '${now.year}-${now.month.toString().padLeft(2,'0')}-${now.day.toString().padLeft(2,'0')}';
    if (map['date'] != date) return null;
    return map;
  }

  static Future<bool> isAppliedToday() async {
    final session = await loadSessionData();
    return session != null && (session['sessionsCompleted'] as int) > 0;
  }

  static Future<void> clearSession() async {
    final store = await SharedPreferences.getInstance();
    await store.remove(_keySessionData);
  }

  // Legacy stubs — kept so uv_controller compiles
  static Future<void> saveApplied(int spf) async {}
  static Future<Map<String, dynamic>?> loadAppliedState() async => null;
  static Future<void> clearApplied() async {}
}