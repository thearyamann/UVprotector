import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';


class StepIndicator extends StatelessWidget {
  final int totalSteps;
  final int currentStep;

  const StepIndicator({
    super.key,
    required this.totalSteps,
    required this.currentStep,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalSteps, (index) {
        final isActive = index == currentStep;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          height: 4,
          width: isActive ? 24 : 8,
          decoration: BoxDecoration(
            color: isActive
                ? AppTheme.brandBlue
                : AppTheme.brandBlue.withOpacity(0.25),
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }
}