import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/preferences_service.dart';
import 'services/background_service.dart';
import 'models/user_preferences.dart';
import 'models/skin_type.dart';
import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart';
import 'theme/theme_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor:          Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  try {
    await BackgroundService.init();
    await BackgroundService.registerPeriodicRefresh();
  } catch (_) {}

  final onboardingDone = await PreferencesService.isOnboardingDone();
  final prefs          = await PreferencesService.loadPreferences();
  final isDark         = await PreferencesService.loadIsDarkMode();

  final themeController = ThemeController(isDark: isDark);

  runApp(
    ThemeControllerProvider(
      controller: themeController,
      child: UVProtectorApp(
        showOnboarding:   !onboardingDone,
        savedPreferences: prefs,
      ),
    ),
  );
}

class UVProtectorApp extends StatefulWidget {
  final bool showOnboarding;
  final UserPreferences savedPreferences;

  const UVProtectorApp({
    super.key,
    required this.showOnboarding,
    required this.savedPreferences,
  });

  @override
  State<UVProtectorApp> createState() => _UVProtectorAppState();
}

class _UVProtectorAppState extends State<UVProtectorApp> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    ThemeController.of(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeController.of(context).isDark;

    return AnimatedTheme(
      duration: const Duration(milliseconds: 400),
      data: isDark
          ? ThemeData.dark(useMaterial3: true)
          : ThemeData.light(useMaterial3: true),
      child: MaterialApp(
        title:                      'UV Protector',
        debugShowCheckedModeBanner: false,
        themeMode:                  isDark ? ThemeMode.dark : ThemeMode.light,
        theme:                      ThemeData.light(useMaterial3: true),
        darkTheme:                  ThemeData.dark(useMaterial3: true),
        home: widget.showOnboarding
            ? const OnboardingScreen()
            : HomeScreen(
                initialSkinType: SkinType.fromType(widget.savedPreferences.skinTypeNumber),
                initialSpf:      widget.savedPreferences.spf,
              ),
      ),
    );
  }
}