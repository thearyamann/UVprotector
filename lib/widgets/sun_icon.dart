import 'package:flutter/material.dart';
import '../theme/theme_controller.dart';
import '../theme/app_theme.dart';

class SunIcon extends StatefulWidget {
  const SunIcon({super.key});

  @override
  State<SunIcon> createState() => _SunIconState();
}

class _SunIconState extends State<SunIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _scale   = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeIn),
    );
    _opacity = Tween<double>(begin: 1.0, end: 0.7).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _handleTap(ThemeController controller) {
    _ctrl.forward().then((_) {
      _ctrl.reverse();
      controller.toggle();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = ThemeController.of(context);
    final isDark     = controller.isDark;

    return GestureDetector(
      onTap: () => _handleTap(controller),
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, child) => Transform.scale(
          scale: _scale.value,
          child: Opacity(opacity: _opacity.value, child: child),
        ),
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
            size: 26,
          ),
        ),
      ),
    );
  }
}