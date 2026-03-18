import 'package:flutter/material.dart';
import '../../theme/theme_controller.dart';

class OnboardingCta extends StatelessWidget {
  final bool isLastStep;
  final VoidCallback onContinue;
  final VoidCallback? onBack;

  const OnboardingCta({
    super.key,
    required this.isLastStep,
    required this.onContinue,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = ThemeController.of(context).isDark;

    return Row(
      children: [
        if (isLastStep) ...[
          Expanded(
            child: _OnboardingButton(
              label: 'Back',
              onTap: onBack ?? () {},
              isDark: isDark,
              isSecondary: true,
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          flex: isLastStep ? 2 : 1,
          child: _OnboardingButton(
            label: isLastStep ? 'Get Started' : 'Continue',
            onTap: onContinue,
            isDark: isDark,
          ),
        ),
      ],
    );
  }
}

class _OnboardingButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isDark;
  final bool isSecondary;

  const _OnboardingButton({
    required this.label,
    required this.onTap,
    required this.isDark,
    this.isSecondary = false,
  });

  @override
  Widget build(BuildContext context) {
    // Light Mode: Forest Green, Dark Mode: Pure Black (or Glass for secondary)
    final Color green = const Color(0xFF166534);
    
    BoxDecoration decoration;
    Color textColor;

    if (isDark) {
      if (isSecondary) {
        decoration = BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 0.5),
        );
        textColor = Colors.white.withValues(alpha: 0.6);
      } else {
        decoration = BoxDecoration(
          color: Colors.black.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 0.5),
        );
        textColor = Colors.white;
      }
    } else {
      if (isSecondary) {
        decoration = BoxDecoration(
          color: Colors.black.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withValues(alpha: 0.05), width: 0.5),
        );
        textColor = Colors.black.withValues(alpha: 0.5);
      } else {
        decoration = BoxDecoration(
          color: green.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: green.withValues(alpha: 0.3), width: 0.5),
        );
        textColor = green;
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: decoration,
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textColor,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}