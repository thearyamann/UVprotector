import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class RefreshButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onTap;
  final bool isDark;

  const RefreshButton({
    super.key,
    required this.isLoading,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: screenHeight * 0.019),
        decoration: BoxDecoration(
          color: isLoading
              ? AppTheme.ctaBg(isDark).withOpacity(0.5)
              : AppTheme.ctaBg(isDark),
          border: Border.all(color: AppTheme.ctaBorder(isDark), width: 0.5),
          borderRadius: BorderRadius.circular(screenHeight * 0.02),
        ),
        child: Center(
          child: isLoading
              ? SizedBox(
                  width: screenHeight * 0.024,
                  height: screenHeight * 0.024,
                  child: CircularProgressIndicator(
                    color: AppTheme.ctaText(isDark),
                    strokeWidth: 2.5,
                  ),
                )
              : Text(
                  'Refresh UV Data',
                  style: TextStyle(
                    fontSize: screenHeight * 0.019,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.ctaText(isDark),
                  ),
                ),
        ),
      ),
    );
  }
}
