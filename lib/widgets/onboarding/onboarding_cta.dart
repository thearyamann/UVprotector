import 'package:flutter/material.dart';


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
    return Row(
      children: [
        if (isLastStep) ...[
          Expanded(
            child: _GlassButton(
              label: 'Back',
              onTap: onBack ?? () {},
            ),
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          flex: isLastStep ? 2 : 1,
          child: _GreenButton(
            label: isLastStep ? 'Get Started' : 'Continue',
            onTap: onContinue,
          ),
        ),
      ],
    );
  }
}

class _GreenButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _GreenButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xD4A8D971), // semi-transparent green
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0x99A8D971),
            width: 0.5,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2d5a1b),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _GlassButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.55),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.85),
            width: 0.5,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6a7a8a),
            ),
          ),
        ),
      ),
    );
  }
}