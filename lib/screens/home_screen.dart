import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/uv_controller.dart';
import '../services/weather_service.dart';
import '../services/geocoding_service.dart';
import '../services/uv_cache_service.dart';
import '../models/uv_data.dart';
import '../models/weather_data.dart';
import '../models/skin_type.dart';
import '../theme/app_theme.dart';
import '../theme/theme_controller.dart';
import '../widgets/sun_icon.dart';
import '../widgets/uv_index_card.dart';
import '../widgets/weather_card.dart';
import '../widgets/sunscreen_timer_card.dart';
import '../widgets/burn_time_card.dart';
import '../widgets/protection_card.dart';
import '../widgets/advice_card.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/daily_routine_card.dart';
import '../widgets/pressable.dart';
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

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final UVController _uvController = UVController();

  UVData?      _uvData;
  WeatherData? _weatherData;
  bool         _isLoading    = false;
  String?      _errorMessage;
  SkinType     _selectedSkinType = SkinType.type3;
  late ThemeController _themeController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.initialSkinType != null) {
      _selectedSkinType = widget.initialSkinType!;
    }
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _themeController = ThemeController.of(context);
    _themeController.addListener(_onThemeChanged);
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _themeController.removeListener(_onThemeChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _loadDataIfStale();
  }

  Future<void> _loadDataIfStale() async {
    if (await UVCacheService.shouldRefresh()) _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      final pos = await LocationService().getCurrentLocation();
      await _fetchConsolidatedData(pos.latitude, pos.longitude);
    } on LocationException catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
      if (e.type == LocationErrorType.permissionPermanentlyDenied) {
        _showSettingsDialog();
      }
      final cached = await UVCacheService.loadCachedUVData();
      if (cached != null && mounted) setState(() => _uvData = cached);
    } catch (e) {
      if (mounted) setState(() => _errorMessage = e.toString());
      final cached = await UVCacheService.loadCachedUVData();
      if (cached != null && mounted) setState(() => _uvData = cached);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchConsolidatedData(double lat, double lng) async {
    try {
      final city   = await GeocodingService.getCityName(lat, lng);
      final result = await WeatherService.fetchWeatherAndPeak(
        latitude: lat, longitude: lng, cityName: city,
      );
      
      final uvData = await _uvController.getCurrentUVData(
        uvIndex: result.currentUV,
        latitude: lat,
        longitude: lng,
        skinTypeNumber: _selectedSkinType.type,
      );

      await UVCacheService.saveUVData(uvData);

      if (mounted) {
        setState(() {
          _weatherData = result.weather;
          _uvData = UVData(
            uvIndex: uvData.uvIndex,
            riskLevel: uvData.riskLevel,
            burnTimeMinutes: uvData.burnTimeMinutes,
            exposureAdvice: uvData.exposureAdvice,
            spfRecommendation: uvData.spfRecommendation,
            reapplyMinutes: uvData.reapplyMinutes,
            timestamp: uvData.timestamp,
            latitude: uvData.latitude,
            longitude: uvData.longitude,
            peakStart: result.peakStart,
            peakEnd: result.peakEnd,
          );
        });
      }
    } catch (_) {
      // Data fetch errored - usually handled by showing previously cached data 
    }
  }

  // Removed _fetchWeather in favor of _fetchConsolidatedData

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Location Permission',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        content: const Text(
          'Location access is permanently denied.\n\nGo to Settings → UV Protector → Location → Allow.',
          style: TextStyle(fontSize: 14, color: Color(0xFF555555), height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF888888))),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await Geolocator.openAppSettings();
            },
            child: const Text('Open Settings',
                style: TextStyle(
                    color: Color(0xFF3B7DD8),
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark       = _themeController.isDark;
    final screenWidth  = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final verticalGap  = screenHeight * 0.012;
    final bottomPad    = screenHeight * 0.04;

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
        body: RefreshIndicator(
          onRefresh: _loadData,
          color: AppTheme.brandBlue(isDark),
          backgroundColor:
              isDark ? const Color(0xFF1a2332) : Colors.white,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.only(
              left:   screenWidth * 0.044,
              right:  screenWidth * 0.044,
              top:    MediaQuery.of(context).padding.top + 8,
              bottom: bottomPad + MediaQuery.of(context).padding.bottom + 10,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  _buildHeader(screenHeight, isDark),
                  _buildGreeting(screenHeight, isDark),

                  if (_isLoading && _uvData == null)
                    SkeletonHomeScreen(isDark: isDark)
                  else ...[
                    SizedBox(height: verticalGap * 1.3),

                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: UVIndexCard(uvData: _uvData, isDark: isDark)),
                          SizedBox(width: screenWidth * 0.026),
                          Expanded(child: WeatherCard(weatherData: _weatherData, isDark: isDark)),
                        ],
                      ),
                    ),
                    SizedBox(height: verticalGap),

                    SunscreenTimerCard(uvData: _uvData, isDark: isDark),
                    SizedBox(height: verticalGap),

                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: BurnTimeCard(uvData: _uvData, isDark: isDark)),
                          SizedBox(width: screenWidth * 0.026),
                          Expanded(child: ProtectionCard(uvData: _uvData, isDark: isDark)),
                        ],
                      ),
                    ),
                    SizedBox(height: verticalGap),

                    DailyRoutineCard(isDark: isDark, uvData: _uvData),
                    SizedBox(height: verticalGap),

                    AdviceCard(uvData: _uvData, isDark: isDark),

                    if (_errorMessage != null)
                      Padding(
                        padding: EdgeInsets.only(top: verticalGap),
                        child: Text(_errorMessage!,
                            style: const TextStyle(
                                color: Colors.red, fontSize: 12)),
                      ),
              ],
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
          const SunIcon(),
          Pressable(
              onTap: () async {
                await UVCacheService.clearSession(); // Clear session
                await PreferencesService.resetOnboarding();
                if (!mounted) return;
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                );
              },
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: screenHeight * 0.014,
                vertical:   screenHeight * 0.007,
              ),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text('Reset',
                  style: TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ),
          ),
          Pressable(
            scaleDown: 0.88,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              width:  screenHeight * 0.043,
              height: screenHeight * 0.043,
              decoration: BoxDecoration(
                color:  AppTheme.cardBg(isDark),
                border: Border.all(
                    color: AppTheme.cardBorder(isDark), width: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.notifications_outlined,
                  size: screenHeight * 0.022,
                  color: AppTheme.textSecondary(isDark)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGreeting(double screenHeight, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 4),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: 'Hi Aryamann\n',
              style: TextStyle(
                fontSize:   screenHeight * 0.027,
                fontWeight: FontWeight.w600,
                color:      AppTheme.textPrimary(isDark),
                height:     1.3,
              ),
            ),
            TextSpan(
              text: 'Ready for today?',
              style: TextStyle(
                fontSize:   screenHeight * 0.021,
                fontWeight: FontWeight.w400,
                color:      AppTheme.textSecondary(isDark),
              ),
            ),
          ],
        ),
      ),
    );
  }
}