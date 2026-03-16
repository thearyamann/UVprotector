import 'package:flutter/material.dart';

class StepIndicator extends StatelessWidget {
  final int totalSteps;
  final int currentStep;

  const StepIndicator({
    super.key,
    required this.totalSteps,
    required this.currentStep,
  });

  static const Color _activeColor = Color(0xFF3B7DD8);
  static const Color _inactiveColor = Color(0x403B7DD8);

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
            color: isActive ? _activeColor : _inactiveColor,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }
}
