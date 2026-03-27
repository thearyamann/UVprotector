import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_preferences.dart';

class PreferencesService {
  static const String _keyName = 'user_name';
  static const String _keySkinType = 'skin_type';
  static const String _keySpf = 'spf';
  static const String _keyOnboardingDone = 'onboarding_done';
  static const String _keyDarkMode = 'dark_mode';
  static const String _keyTimerExpiry = 'timer_expiry';
  static const String _keyIsTimerRunning = 'timer_running';
  static const String _keyTotalSessions = 'total_sessions';
  static const String _keyCurrentSession = 'current_session';
  static const String _keyLastUvAlert = 'last_uv_alert';
  static const String _keyLastReapplyAlertSession = 'last_reapply_alert_session';
  static const String _keyLastHighUvAlertDate = 'last_high_uv_alert_date';
  static const String _keyLastUvRiseAlertSignature =
      'last_uv_rise_alert_signature';

  static Future<void> savePreferences(UserPreferences prefs) async {
    final store = await SharedPreferences.getInstance();
    await store.setString(_keyName, prefs.name);
    await store.setInt(_keySkinType, prefs.skinTypeNumber);
    await store.setInt(_keySpf, prefs.spf);
    await store.setBool(_keyOnboardingDone, true);
  }

  static Future<UserPreferences> loadPreferences() async {
    final store = await SharedPreferences.getInstance();
    return UserPreferences(
      name: store.getString(_keyName) ?? 'Friend',
      skinTypeNumber: store.getInt(_keySkinType) ?? 3,
      spf: store.getInt(_keySpf) ?? 30,
    );
  }

  static Future<bool> isOnboardingDone() async {
    final store = await SharedPreferences.getInstance();
    return store.getBool(_keyOnboardingDone) ?? false;
  }

  static Future<void> resetOnboarding() async {
    final store = await SharedPreferences.getInstance();
    await store.setBool(_keyOnboardingDone, false);
  }

  static Future<void> saveTheme(bool isDark) async {
    final store = await SharedPreferences.getInstance();
    await store.setBool(_keyDarkMode, isDark);
  }

  static Future<bool> loadIsDarkMode() async {
    final store = await SharedPreferences.getInstance();
    return store.getBool(_keyDarkMode) ?? true;
  }

  // --- Timer State ---
  static Future<void> saveTimerState({
    required DateTime? expiry,
    required bool running,
    required int total,
    required int current,
  }) async {
    final store = await SharedPreferences.getInstance();
    if (expiry != null) {
      await store.setString(_keyTimerExpiry, expiry.toIso8601String());
    } else {
      await store.remove(_keyTimerExpiry);
    }
    await store.setBool(_keyIsTimerRunning, running);
    await store.setInt(_keyTotalSessions, total);
    await store.setInt(_keyCurrentSession, current);
  }

  static Future<Map<String, dynamic>> loadTimerState() async {
    final store = await SharedPreferences.getInstance();
    final expiryStr = store.getString(_keyTimerExpiry);
    return {
      'expiry': expiryStr != null ? DateTime.parse(expiryStr) : null,
      'running': store.getBool(_keyIsTimerRunning) ?? false,
      'total': store.getInt(_keyTotalSessions) ?? 0,
      'current': store.getInt(_keyCurrentSession) ?? 0,
    };
  }

  static Future<void> saveLastUvAlert(double uv) async {
    final store = await SharedPreferences.getInstance();
    await store.setDouble(_keyLastUvAlert, uv);
  }

  static Future<double> loadLastUvAlert() async {
    final store = await SharedPreferences.getInstance();
    return store.getDouble(_keyLastUvAlert) ?? 0.0;
  }

  static Future<void> saveLastReapplyAlertSession(int sessionNumber) async {
    final store = await SharedPreferences.getInstance();
    await store.setInt(_keyLastReapplyAlertSession, sessionNumber);
  }

  static Future<int?> loadLastReapplyAlertSession() async {
    final store = await SharedPreferences.getInstance();
    return store.getInt(_keyLastReapplyAlertSession);
  }

  static Future<void> saveLastHighUvAlertDate(String dateKey) async {
    final store = await SharedPreferences.getInstance();
    await store.setString(_keyLastHighUvAlertDate, dateKey);
  }

  static Future<String?> loadLastHighUvAlertDate() async {
    final store = await SharedPreferences.getInstance();
    return store.getString(_keyLastHighUvAlertDate);
  }

  static Future<void> saveLastUvRiseAlertSignature(String signature) async {
    final store = await SharedPreferences.getInstance();
    await store.setString(_keyLastUvRiseAlertSignature, signature);
  }

  static Future<String?> loadLastUvRiseAlertSignature() async {
    final store = await SharedPreferences.getInstance();
    return store.getString(_keyLastUvRiseAlertSignature);
  }
}
