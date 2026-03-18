import 'package:flutter/material.dart';
import '../models/skin_type.dart';
import '../models/user_preferences.dart';
import '../services/preferences_service.dart';
import '../widgets/onboarding/step_indicator.dart';
import '../widgets/onboarding/skin_type_grid.dart';
import '../widgets/onboarding/spf_grid.dart';
import '../widgets/onboarding/onboarding_cta.dart';
import '../theme/app_theme.dart';
import '../theme/theme_controller.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentStep = 0;
  SkinType _selectedSkinType = SkinType.type3;
  int _selectedSpf = 30;

  Future<void> _finish() async {
    await PreferencesService.savePreferences(
      UserPreferences(
        skinTypeNumber: _selectedSkinType.type,
        spf: _selectedSpf,
      ),
    );

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => HomeScreen(
          initialSkinType: _selectedSkinType,
          initialSpf: _selectedSpf,
        ),
      ),
    );
  }

  void _next() {
    if (_currentStep == 0) {
      setState(() => _currentStep = 1);
    } else {
      _finish();
    }
  }

  void _back() => setState(() => _currentStep = 0);

  @override
  Widget build(BuildContext context) {
    final bool isDark = ThemeController.of(context).isDark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark ? AppTheme.darkGradient : AppTheme.lightGradient,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                    MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom,
              ),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    _buildHeader(),
                    const SizedBox(height: 24),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      transitionBuilder: (child, animation) =>
                          FadeTransition(opacity: animation, child: child),
                      layoutBuilder: (currentChild, previousChildren) => Stack(
                        alignment: Alignment.topCenter,
                        children: [
                          ...previousChildren,
                          if (currentChild != null) currentChild,
                        ],
                      ),
                      child: _currentStep == 0 ? _buildStep1() : _buildStep2(),
                    ),
                    const Spacer(),
                    const SizedBox(height: 24),
                    StepIndicator(totalSteps: 2, currentStep: _currentStep),
                    const SizedBox(height: 20),
                    OnboardingCta(
                      isLastStep: _currentStep == 1,
                      onContinue: _next,
                      onBack: _back,
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final bool isDark = ThemeController.of(context).isDark;
    final isStep1 = _currentStep == 0;
    
    final accentColor = isStep1 
        ? const Color(0xFF3B7DD8) 
        : const Color(0xFF166534);

    return Column(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.12),
            border: Border.all(
              color: accentColor.withValues(alpha: 0.2),
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(
            isStep1 ? Icons.wb_sunny_outlined : Icons.shield_outlined,
            color: accentColor,
            size: 24,
          ),
        ),
        const SizedBox(height: 14),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: Text(
            isStep1 ? 'Your skin type?' : 'Your sunscreen?',
            key: ValueKey(_currentStep),
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary(isDark),
              letterSpacing: -0.5,
            ),
          ),
        ),
        const SizedBox(height: 6),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: Text(
            isStep1
                ? 'Helps calculate your exact burn time'
                : 'Used to calculate your reapply timer',
            key: ValueKey('sub$_currentStep'),
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary(isDark),
              height: 1.5,
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildStep1() {
    return SkinTypeGrid(
      key: const ValueKey('step1'),
      selectedType: _selectedSkinType,
      onSelected: (type) => setState(() => _selectedSkinType = type),
    );
  }

  Widget _buildStep2() {
    return SpfGrid(
      key: const ValueKey('step2'),
      selectedSpf: _selectedSpf,
      onSelected: (spf) => setState(() => _selectedSpf = spf),
    );
  }
}
