import 'package:flutter/material.dart';
import '../theme/theme_controller.dart';

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
    _scale   = Tween<double>(begin: 1.0, end: 0.85)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
    _opacity = Tween<double>(begin: 1.0, end: 0.7)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              transitionBuilder: (child, anim) => ScaleTransition(
                scale: anim,
                child: FadeTransition(opacity: anim, child: child),
              ),
              child: Icon(
                isDark ? Icons.nightlight_round : Icons.wb_sunny_outlined,
                key: ValueKey(isDark),
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 7),
            // Toggle track
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 36,
              height: 20,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: isDark
                    ? Colors.white.withValues(alpha: 0.9)
                    : Colors.white.withValues(alpha: 0.25),
                border: Border.all(
                  color: Colors.white.withValues(alpha: isDark ? 0 : 0.3),
                  width: 0.5,
                ),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                alignment: isDark ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 16,
                  height: 16,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? const Color(0xFF1a5c35) : Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}