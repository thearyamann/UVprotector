import 'package:flutter/material.dart';
import '../theme/theme_controller.dart';
import '../theme/app_theme.dart';

class SunIcon extends StatelessWidget {
  const SunIcon({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ThemeController.of(context);
    final isDark = controller.isDark;

    return GestureDetector(
      onTap: () => controller.toggle(),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        transitionBuilder: (child, animation) => ScaleTransition(
          scale: animation,
          child: FadeTransition(opacity: animation, child: child),
        ),
        child: Icon(
          isDark ? Icons.wb_sunny : Icons.wb_sunny_outlined,
          key: ValueKey(isDark),
          color: AppTheme.brandBlue(isDark),
          size: 28,
        ),
      ),
    );
  }
}
