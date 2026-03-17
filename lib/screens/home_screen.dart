import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../widgets/alert_banner.dart';
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
  bool         _isAppliedToday = false;
  SkinType     _selectedSkinType = SkinType.type3;
  late ThemeController _themeController;

  bool get _showAlert =>
      _uvData != null &&
      _uvData!.uvIndex >= 6 &&
      !_isAppliedToday;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    if (widget.initialSkinType != null) _selectedSkinType = widget.initialSkinType!;
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _themeController = ThemeController.of(context);
    _themeController.addListener(_onThemeChanged);
  }

  void _onThemeChanged() { if (mounted) setState(() {}); }

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
    await _refreshAppliedState();
  }

  Future<void> _refreshAppliedState() async {
    final applied = await UVCacheService.isAppliedToday();
    if (mounted) setState(() => _isAppliedToday = applied);
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      final cached = await UVCacheService.loadCachedUVData();
      if (cached != null && !await UVCacheService.shouldRefresh()) {
        if (mounted) setState(() { _uvData = cached; _isLoading = false; });
        _fetchWeather(cached.latitude, cached.longitude);
        await _refreshAppliedState();
        return;
      }

      final uvData = await _uvController.getCurrentUVData(
          skinTypeNumber: _selectedSkinType.type);
      await UVCacheService.saveUVData(uvData);
      if (mounted) setState(() => _uvData = uvData);
      _fetchWeather(uvData.latitude, uvData.longitude);
      await _refreshAppliedState();

    } on LocationException catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
      if (e.type == LocationErrorType.permissionPermanentlyDenied) _showSettingsDialog();
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

  Future<void> _fetchWeather(double? lat, double? lng) async {
    if (lat == null || lng == null) return;
    try {
      final city    = await GeocodingService.getCityName(lat, lng);
      final weather = await WeatherService.fetchWeather(
          latitude: lat, longitude: lng, cityName: city);
      if (mounted) setState(() => _weatherData = weather);
    } catch (_) {}
  }

  void _showSettingsDialog() {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Location Permission',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
      content: const Text(
        'Location access is permanently denied.\n\nGo to Settings → UV Protector → Location → Allow.',
        style: TextStyle(fontSize: 14, color: Color(0xFF555555), height: 1.5),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF888888)))),
        TextButton(onPressed: () async { Navigator.pop(ctx); await Geolocator.openAppSettings(); },
            child: const Text('Open Settings',
                style: TextStyle(color: Color(0xFF1a5c35), fontWeight: FontWeight.w600))),
      ],
    ));
  }

  void _onAlertApplyTap() async {
    // Scroll to timer card and mark as applied
    setState(() => _isAppliedToday = true);
  }

  @override
  Widget build(BuildContext context) {
    final isDark      = _themeController.isDark;
    final sw          = MediaQuery.of(context).size.width;
    final sh          = MediaQuery.of(context).size.height;
    final gap         = sh * 0.011;
    final bottomPad   = sh * 0.04;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
        body: RefreshIndicator(
          onRefresh: _loadData,
          color: const Color(0xFF1a5c35),
          backgroundColor: isDark ? const Color(0xFF1a2e1e) : Colors.white,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Green header ──────────────────────────────
                _buildGreenHeader(isDark, sw, sh),

                // ── White/dark body ───────────────────────────
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkBg : AppTheme.lightBg,
                  ),
                  padding: EdgeInsets.only(
                    left: sw * 0.044, right: sw * 0.044, bottom: bottomPad),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: gap * 1.2),

                      if (_showAlert)
                        UVAlertBanner(
                          uvIndex: _uvData!.uvIndex,
                          isDark: isDark,
                          onApplyTap: _onAlertApplyTap,
                        ),

                      if (_isLoading && _uvData == null)
                        SkeletonHomeScreen(isDark: isDark)
                      else ...[
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(child: UVIndexCard(uvData: _uvData, isDark: isDark)),
                              SizedBox(width: sw * 0.026),
                              Expanded(child: WeatherCard(weatherData: _weatherData, isDark: isDark)),
                            ],
                          ),
                        ),
                        SizedBox(height: gap),

                        SunscreenTimerCard(uvData: _uvData, isDark: isDark),
                        SizedBox(height: gap),

                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(child: BurnTimeCard(uvData: _uvData, isDark: isDark)),
                              SizedBox(width: sw * 0.026),
                              Expanded(child: ProtectionCard(uvData: _uvData, isDark: isDark)),
                            ],
                          ),
                        ),
                        SizedBox(height: gap),

                        AdviceCard(uvData: _uvData, isDark: isDark),
                        SizedBox(height: gap),

                        DailyRoutineCard(isDark: isDark),

                        if (_errorMessage != null)
                          Padding(
                            padding: EdgeInsets.only(top: gap),
                            child: Text(_errorMessage!,
                                style: const TextStyle(color: Colors.red, fontSize: 11)),
                          ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGreenHeader(bool isDark, double sw, double sh) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppTheme.greenGradient,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(sw * 0.044, sh * 0.014, sw * 0.044, sh * 0.03),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row — sun toggle + bell
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const SunIcon(),
                Pressable(
                  scaleDown: 0.88,
                  child: Stack(
                    children: [
                      Container(
                        width: sh * 0.042, height: sh * 0.042,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2), width: 0.5),
                        ),
                        child: Icon(Icons.notifications_outlined,
                            size: sh * 0.021, color: Colors.white),
                      ),
                      if (_showAlert)
                        Positioned(
                          top: 0, right: 0,
                          child: Container(
                            width: 9, height: 9,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444),
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFF1a5c35), width: 1.5),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ]),
              SizedBox(height: sh * 0.016),
              Text('Hi Aryamann',
                  style: TextStyle(
                    fontSize: sh * 0.026, fontWeight: FontWeight.w700,
                    color: Colors.white, letterSpacing: -0.3,
                  )),
              SizedBox(height: sh * 0.003),
              Text('Ready for today?',
                  style: TextStyle(
                    fontSize: sh * 0.017,
                    color: Colors.white.withValues(alpha: 0.58),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}