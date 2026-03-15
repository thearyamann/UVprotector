import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/uv_controller.dart';
import '../models/uv_data.dart';
import '../models/skin_type.dart';
import '../theme/app_theme.dart';
import '../theme/theme_controller.dart';
import '../widgets/sun_icon.dart';
import '../widgets/uv_index_card.dart';
import '../widgets/skin_type_card.dart';
import '../widgets/reapply_card.dart';
import '../widgets/burn_time_card.dart';
import '../widgets/protection_card.dart';
import '../widgets/advice_card.dart';
import '../widgets/refresh_button.dart';
import '../services/location_service.dart';
import '../services/preferences_service.dart';
import 'onboarding_screen.dart';

class HomeScreen extends StatefulWidget {
  final SkinType? initialSkinType;
  final int? initialSpf;

  const HomeScreen({super.key, this.initialSkinType, this.initialSpf});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final UVController _controller = UVController();

  UVData? _uvData;
  bool _isLoading = false;
  String? _errorMessage;
  SkinType _selectedSkinType = SkinType.type3;

  @override
  void initState() {
    super.initState();
    if (widget.initialSkinType != null) {
      _selectedSkinType = widget.initialSkinType!;
    }
    _loadUVData();
  }

  Future<void> _loadUVData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final data = await _controller.getCurrentUVData(
        skinTypeNumber: _selectedSkinType.type,
      );
      setState(() => _uvData = data);
    } on LocationException catch (e) {
      setState(() => _errorMessage = e.message);
      if (e.type == LocationErrorType.permissionPermanentlyDenied) {
        _showOpenSettingsDialog();
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showOpenSettingsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Location Permission',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        content: const Text(
          'Location access is permanently denied.\n\nGo to Settings → UV Protector → Location → Allow.',
          style: TextStyle(fontSize: 14, color: Color(0xFF555555), height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF888888)),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await Geolocator.openAppSettings();
            },
            child: const Text(
              'Open Settings',
              style: TextStyle(
                color: Color(0xFF3B7DD8),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _cycleSkinType() {
    final idx = SkinType.all.indexOf(_selectedSkinType);
    final next = (idx + 1) % SkinType.all.length;
    setState(() => _selectedSkinType = SkinType.all[next]);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeController.of(context).isDark;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final verticalGap = screenHeight * 0.012;
    final bottomPad = screenHeight * 0.025;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark ? AppTheme.darkGradient : AppTheme.lightGradient,
          stops: const [0.0, 0.35, 0.65, 1.0],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: EdgeInsets.only(
              left: screenWidth * 0.044,
              right: screenWidth * 0.044,
              bottom: bottomPad,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(screenHeight, isDark),
                _buildGreeting(screenHeight, isDark),
                SizedBox(height: verticalGap * 1.3),

                // UV Index + Skin Type
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: UVIndexCard(uvData: _uvData, isDark: isDark),
                      ),
                      SizedBox(width: screenWidth * 0.026),
                      Expanded(
                        child: SkinTypeCard(
                          selectedSkinType: _selectedSkinType,
                          onTap: _cycleSkinType,
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: verticalGap),

                // Reapply timer
                ReapplyCard(
                  uvData: _uvData,
                  onReapplied: () {},
                  isDark: isDark,
                ),
                SizedBox(height: verticalGap),

                // Burn time + Protection
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: BurnTimeCard(uvData: _uvData, isDark: isDark),
                      ),
                      SizedBox(width: screenWidth * 0.026),
                      Expanded(
                        child: ProtectionCard(uvData: _uvData, isDark: isDark),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: verticalGap),

                // Advice
                AdviceCard(uvData: _uvData, isDark: isDark),
                SizedBox(height: verticalGap),

                // Error
                if (_errorMessage != null)
                  Padding(
                    padding: EdgeInsets.only(bottom: screenHeight * 0.01),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ),

                // Refresh
                RefreshButton(
                  isLoading: _isLoading,
                  onTap: _loadUVData,
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(double screenHeight, bool isDark) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: screenHeight * 0.014),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Sun icon — tapping toggles dark/light mode
          const SunIcon(),

          // Temporary reset button — remove before release
          GestureDetector(
            onTap: () async {
              await PreferencesService.resetOnboarding();
              if (!mounted) return;
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const OnboardingScreen()),
              );
            },
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: screenHeight * 0.014,
                vertical: screenHeight * 0.007,
              ),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Reset',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          // Notification bell
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            width: screenHeight * 0.043,
            height: screenHeight * 0.043,
            decoration: BoxDecoration(
              color: AppTheme.cardBg(isDark),
              border: Border.all(
                color: AppTheme.cardBorder(isDark),
                width: 0.5,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_outlined,
              size: screenHeight * 0.022,
              color: AppTheme.textSecondary(isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGreeting(double screenHeight, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'Hi Aryamann\n',
                  style: TextStyle(
                    fontSize: screenHeight * 0.031,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary(isDark),
                    height: 1.3,
                  ),
                ),
                TextSpan(
                  text: 'Ready for today?',
                  style: TextStyle(
                    fontSize: screenHeight * 0.026,
                    fontWeight: FontWeight.w400,
                    color: AppTheme.textSecondary(isDark),
                  ),
                ),
              ],
            ),
          ),
          if (_uvData?.latitude != null) ...[
            SizedBox(height: screenHeight * 0.007),
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: screenHeight * 0.016,
                  color: AppTheme.textMuted(isDark),
                ),
                const SizedBox(width: 4),
                Text(
                  '${_uvData!.latitude!.toStringAsFixed(4)}, '
                  '${_uvData!.longitude!.toStringAsFixed(4)}',
                  style: TextStyle(
                    fontSize: screenHeight * 0.014,
                    color: AppTheme.textMuted(isDark),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
