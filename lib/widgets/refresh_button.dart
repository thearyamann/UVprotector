import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class RefreshButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onTap;

  const RefreshButton({
    super.key,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isLoading ? AppTheme.ctaGreen.withOpacity(0.5) : AppTheme.ctaGreen,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: AppTheme.ctaGreenText,
                    strokeWidth: 2.5,
                  ),
                )
              : const Text(
                  'Refresh UV Data',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.ctaGreenText,
                  ),
                ),
        ),
      ),
    );
  }
}