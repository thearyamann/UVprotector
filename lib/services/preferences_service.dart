import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_preferences.dart';


class PreferencesService {

  static const String _keySkinType       = 'skin_type';
  static const String _keySpf            = 'spf';
  static const String _keyOnboardingDone = 'onboarding_done';


  static Future<void> savePreferences(UserPreferences prefs) async {
    final store = await SharedPreferences.getInstance();
    await store.setInt(_keySkinType, prefs.skinTypeNumber);
    await store.setInt(_keySpf, prefs.spf);
    await store.setBool(_keyOnboardingDone, true);
  }

  
  static Future<UserPreferences> loadPreferences() async {
    final store = await SharedPreferences.getInstance();
    return UserPreferences(
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
}