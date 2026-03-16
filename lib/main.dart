import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/preferences_service.dart';
import 'models/user_preferences.dart';
import 'models/skin_type.dart';
import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart';
import 'theme/theme_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  final onboardingDone = await PreferencesService.isOnboardingDone();
  final prefs = await PreferencesService.loadPreferences();
  final isDark = await PreferencesService.loadIsDarkMode();

  final themeController = ThemeController(isDark: isDark);

  runApp(
    ThemeControllerProvider(
      controller: themeController,
      child: UVProtectorApp(
        showOnboarding: !onboardingDone,
        savedPreferences: prefs,
      ),
    ),
  );
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
    final isDark = ThemeController.of(context).isDark;

    return MaterialApp(
      title: 'UV Protector',
      debugShowCheckedModeBanner: false,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData.light(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
      home: showOnboarding
          ? const OnboardingScreen()
          : HomeScreen(
              initialSkinType: SkinType.fromType(
                savedPreferences.skinTypeNumber,
              ),
              initialSpf: savedPreferences.spf,
            ),
    );
  }
}
