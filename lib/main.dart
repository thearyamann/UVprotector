import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/preferences_service.dart';
import 'models/user_preferences.dart';
import 'models/skin_type.dart';
import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  // Required before any async work in main
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  // Check if user has completed onboarding
  final onboardingDone = await PreferencesService.isOnboardingDone();
  final prefs = await PreferencesService.loadPreferences();

  runApp(UVProtectorApp(
    showOnboarding: !onboardingDone,
    savedPreferences: prefs,
  ));
}

class UVProtectorApp extends StatelessWidget {
  final bool showOnboarding;
  final UserPreferences savedPreferences;

  const UVProtectorApp({
    super.key,
    required this.showOnboarding,
    required this.savedPreferences,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UV Protector',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3B7DD8)),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFE8F0F7),
      ),
      home: showOnboarding
          ? const OnboardingScreen()
          : HomeScreen(
              initialSkinType: SkinType.fromType(savedPreferences.skinTypeNumber),
              initialSpf: savedPreferences.spf,
            ),
    );
  }
}