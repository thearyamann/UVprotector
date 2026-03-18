import 'package:flutter/material.dart';
import '../services/preferences_service.dart';

class ThemeController extends ChangeNotifier {
  bool _isDark;

  ThemeController({required bool isDark}) : _isDark = isDark;

  bool get isDark => _isDark;

  Future<void> toggle() async {
    _isDark = !_isDark;
    notifyListeners();
    await PreferencesService.saveTheme(_isDark);
  }

  static ThemeController of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_ThemeControllerScope>()!
        .controller;
  }
}

class _ThemeControllerScope extends InheritedWidget {
  final ThemeController controller;
  final bool isDark;

  const _ThemeControllerScope({
    required this.controller,
    required this.isDark,
    required super.child,
  });

  @override
  bool updateShouldNotify(_ThemeControllerScope old) => isDark != old.isDark;
}

class ThemeControllerProvider extends StatefulWidget {
  final ThemeController controller;
  final Widget child;

  const ThemeControllerProvider({
    super.key,
    required this.controller,
    required this.child,
  });

  @override
  State<ThemeControllerProvider> createState() =>
      _ThemeControllerProviderState();
}

class _ThemeControllerProviderState extends State<ThemeControllerProvider> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return _ThemeControllerScope(
      controller: widget.controller,
      isDark: widget.controller.isDark,
      child: widget.child,
    );
  }
}
