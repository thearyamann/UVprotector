import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_preferences.dart';

class PreferencesService {
  static const String _keyName = 'user_name';
  static const String _keySkinType = 'skin_type';
  static const String _keySpf = 'spf';
  static const String _keyOnboardingDone = 'onboarding_done';
  static const String _keyDarkMode = 'dark_mode';

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
    return store.getBool(_keyDarkMode) ?? false;
  }
}
