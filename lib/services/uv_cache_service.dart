import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/uv_data.dart';

class UVCacheService {
  static const String _keyUVData = 'cached_uv_data';
  static const String _keyLastFetched = 'last_fetched_ms';
  static const String _keyLastAppliedAt = 'last_applied_at_ms';
  static const String _keyAppliedSpf = 'applied_spf';

  static Future<void> saveUVData(UVData data) async {
    final store = await SharedPreferences.getInstance();
    final map = {
      'uvIndex': data.uvIndex,
      'riskLevel': data.riskLevel,
      'burnTimeMinutes': data.burnTimeMinutes == double.infinity
          ? -1.0
          : data.burnTimeMinutes,
      'exposureAdvice': data.exposureAdvice,
      'spfRecommendation': data.spfRecommendation,
      'reapplyMinutes': data.reapplyMinutes,
      'timestamp': data.timestamp.millisecondsSinceEpoch,
      'latitude': data.latitude,
      'longitude': data.longitude,
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
      uvIndex: (map['uvIndex'] as num).toDouble(),
      riskLevel: map['riskLevel'] as String,
      burnTimeMinutes: (map['burnTimeMinutes'] as num).toDouble() == -1.0
          ? double.infinity
          : (map['burnTimeMinutes'] as num).toDouble(),
      exposureAdvice: map['exposureAdvice'] as String,
      spfRecommendation: map['spfRecommendation'] as String,
      reapplyMinutes: map['reapplyMinutes'] as int,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
    );
  }

  static Future<bool> shouldRefresh() async {
    final store = await SharedPreferences.getInstance();
    final last = store.getInt(_keyLastFetched);
    if (last == null) return true;
    final diff = DateTime.now().millisecondsSinceEpoch - last;
    return diff > 30 * 60 * 1000;
  }

  static Future<void> saveApplied(int spf) async {
    final store = await SharedPreferences.getInstance();
    await store.setInt(
      _keyLastAppliedAt,
      DateTime.now().millisecondsSinceEpoch,
    );
    await store.setInt(_keyAppliedSpf, spf);
  }

  static Future<Map<String, dynamic>?> loadAppliedState() async {
    final store = await SharedPreferences.getInstance();
    final appliedAt = store.getInt(_keyLastAppliedAt);
    final spf = store.getInt(_keyAppliedSpf);
    if (appliedAt == null) return null;
    final appliedDate = DateTime.fromMillisecondsSinceEpoch(appliedAt);
    final now = DateTime.now();
    final isToday =
        appliedDate.year == now.year &&
        appliedDate.month == now.month &&
        appliedDate.day == now.day;
    if (!isToday) return null;
    return {'appliedAt': appliedAt, 'spf': spf ?? 30};
  }

  static Future<void> clearApplied() async {
    final store = await SharedPreferences.getInstance();
    await store.remove(_keyLastAppliedAt);
    await store.remove(_keyAppliedSpf);
  }
}
