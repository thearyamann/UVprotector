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
    final screenHeight = MediaQuery.of(context).size.height;

    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        // Responsive height — taller on bigger screens
        padding: EdgeInsets.symmetric(vertical: screenHeight * 0.019),
        decoration: BoxDecoration(
          color: isLoading
              ? AppTheme.ctaGreen.withOpacity(0.5)
              : AppTheme.ctaGreen,
          borderRadius: BorderRadius.circular(screenHeight * 0.02),
        ),
        child: Center(
          child: isLoading
              ? SizedBox(
                  width: screenHeight * 0.024,
                  height: screenHeight * 0.024,
                  child: const CircularProgressIndicator(
                    color: AppTheme.ctaGreenText,
                    strokeWidth: 2.5,
                  ),
                )
              : Text(
                  'Refresh UV Data',
                  style: TextStyle(
                    fontSize: screenHeight * 0.019,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.ctaGreenText,
                  ),
                ),
        ),
      ),
    );
  }
}
