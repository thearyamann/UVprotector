import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Reusable sun/logo icon used in the header.
/// Pass any color — defaults to brand blue.
class SunIcon extends StatelessWidget {
  final Color color;
  final double size;

  const SunIcon({
    super.key,
    this.color = AppTheme.brandBlue,
    this.size = 28,
  });

  @override
  Widget build(BuildContext context) {
    return Icon(Icons.wb_sunny, color: color, size: size);
  }
}