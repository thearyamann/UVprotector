import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_controller.dart';
import '../../config/app_config.dart';

class NameInputStep extends StatefulWidget {
  final String currentValue;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmitted;

  const NameInputStep({
    super.key,
    required this.currentValue,
    required this.onChanged,
    required this.onSubmitted,
  });

  @override
  State<NameInputStep> createState() => _NameInputStepState();
}

class _NameInputStepState extends State<NameInputStep> {
  String? _errorText;

  void _validateAndSubmit(String value) {
    final trimmed = value.trim();
    if (trimmed.length > AppConfig.nameMaxLength) {
      setState(() {
        _errorText =
            'Name must be ${AppConfig.nameMaxLength} characters or less';
      });
      return;
    }
    setState(() {
      _errorText = null;
    });
    widget.onSubmitted();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = ThemeController.of(context).isDark;

    return Column(
      children: [
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.cardBg(isDark),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _errorText != null
                  ? const Color(0xFFDC2626).withValues(alpha: 0.5)
                  : AppTheme.cardBorder(isDark),
              width: 0.8,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'FIRST NAME',
                style: AppTheme.labelSmall(isDark).copyWith(
                  color: AppTheme.brandBlue(isDark).withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                autofocus: true,
                maxLength: AppConfig.nameMaxLength,
                onChanged: (value) {
                  widget.onChanged(value.trim());
                  if (_errorText != null &&
                      value.length <= AppConfig.nameMaxLength) {
                    setState(() => _errorText = null);
                  }
                },
                onSubmitted: _validateAndSubmit,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary(isDark),
                  letterSpacing: -0.5,
                ),
                decoration: InputDecoration(
                  hintText: 'e.g. Alex',
                  hintStyle: TextStyle(
                    color: AppTheme.textMuted(isDark),
                    fontSize: 22,
                    fontWeight: FontWeight.w400,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  counterText: '',
                  errorText: _errorText,
                  errorStyle: TextStyle(
                    color: const Color(0xFFDC2626),
                    fontSize: 12,
                  ),
                ),
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                autocorrect: false,
                enableSuggestions: false,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'We Use this only to personalize your experience.',
            style: AppTheme.bodySecondary(isDark),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
