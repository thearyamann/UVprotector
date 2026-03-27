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
import '../services/widget_service.dart';
import '../services/notification_history_service.dart';

class HomeScreen extends StatefulWidget {
  final SkinType? initialSkinType;
  final int? initialSpf;

  const HomeScreen({super.key, this.initialSkinType, this.initialSpf});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final UVController _uvController = UVController();

  UVData? _uvData;
  WeatherData? _weatherData;
  bool _isLoading = false;
  String? _errorMessage;
  String _userName = 'Friend';
  SkinType _selectedSkinType = SkinType.type3;
  ThemeController? _themeController;
  int _unreadNotifications = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.initialSkinType != null) {
      _selectedSkinType = widget.initialSkinType!;
    }
    _loadNotificationState();
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nextController = ThemeController.of(context);
    if (!identical(_themeController, nextController)) {
      _themeController?.removeListener(_onThemeChanged);
      _themeController = nextController;
      _themeController?.addListener(_onThemeChanged);
    }
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _themeController?.removeListener(_onThemeChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadNotificationState();
      _loadDataIfStale();
    }
  }

  Future<void> _loadNotificationState() async {
    final unread = await NotificationHistoryService.loadUnreadCount();
    if (!mounted) return;
    setState(() => _unreadNotifications = unread);
  }

  Future<void> _openNotificationInbox(bool isDark) async {
    final notifications =
        await NotificationHistoryService.loadTodayNotifications();
    await NotificationHistoryService.markAllAsRead();
    if (mounted) {
      setState(() => _unreadNotifications = 0);
    }
    if (!mounted) return;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _NotificationInboxSheet(
          isDark: isDark,
          notifications: notifications,
        );
      },
    );
  }

  Future<void> _loadDataIfStale() async {
    if (await UVCacheService.shouldRefresh()) _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await PreferencesService.loadPreferences();
      if (mounted) setState(() => _userName = prefs.name);

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
      final city = await GeocodingService.getCityName(lat, lng);
      final result = await WeatherService.fetchWeatherAndPeak(
        latitude: lat,
        longitude: lng,
        cityName: city,
      );

      final uvData = await _uvController.getCurrentUVData(
        uvIndex: result.currentUV,
        latitude: lat,
        longitude: lng,
        skinTypeNumber: _selectedSkinType.type,
      );

      await UVCacheService.saveUVData(uvData);
      await WidgetService.updateFromCache(); // Instantly push live data to widgets

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

  @override
  Widget build(BuildContext context) {
    final isDark = _themeController?.isDark ?? ThemeController.of(context).isDark;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final verticalGap = screenHeight * 0.012;
    final bottomPad = screenHeight * 0.04;

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
          backgroundColor: isDark ? const Color(0xFF1a2332) : Colors.white,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.only(
              left: screenWidth * 0.044,
              right: screenWidth * 0.044,
              top: MediaQuery.of(context).padding.top + 8,
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
                        Expanded(
                          child: UVIndexCard(uvData: _uvData, isDark: isDark),
                        ),
                        SizedBox(width: screenWidth * 0.026),
                        Expanded(
                          child: WeatherCard(
                            weatherData: _weatherData,
                            isDark: isDark,
                          ),
                        ),
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
                        Expanded(
                          child: BurnTimeCard(uvData: _uvData, isDark: isDark),
                        ),
                        SizedBox(width: screenWidth * 0.026),
                        Expanded(
                          child: ProtectionCard(
                            uvData: _uvData,
                            isDark: isDark,
                          ),
                        ),
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
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),

                  SizedBox(height: verticalGap * 1.6),
                  _buildFooterNote(screenWidth, screenHeight, isDark),
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
          const Spacer(),
          Pressable(
            onTap: () => _openNotificationInbox(isDark),
            scaleDown: 0.88,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
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
                if (_unreadNotifications > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF111111)
                              : Colors.white,
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _unreadNotifications > 9
                              ? '9+'
                              : _unreadNotifications.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
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
              text: 'Hi $_userName\n',
              style: TextStyle(
                fontSize: screenHeight * 0.027,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary(isDark),
                height: 1.3,
              ),
            ),
            TextSpan(
              text: 'Ready for today?',
              style: TextStyle(
                fontSize: screenHeight * 0.021,
                fontWeight: FontWeight.w400,
                color: AppTheme.textSecondary(isDark),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterNote(double screenWidth, double screenHeight, bool isDark) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Made with ',
            style: TextStyle(
              fontSize: screenHeight * 0.014,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.82)
                  : const Color(0xFF35524A),
            ),
          ),
          Text(
            'love',
            style: TextStyle(
              fontSize: screenHeight * 0.014,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.92)
                  : const Color(0xFF24423B),
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.favorite_rounded, color: Color(0xFFEF4444), size: 16),
          const SizedBox(width: 4),
          Text(
            'for your skin',
            style: TextStyle(
              fontSize: screenHeight * 0.014,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.82)
                  : const Color(0xFF35524A),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationInboxSheet extends StatelessWidget {
  final bool isDark;
  final List<Map<String, dynamic>> notifications;

  const _NotificationInboxSheet({
    required this.isDark,
    required this.notifications,
  });

  String _formatTime(int timestamp) {
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF121212) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : const Color(0x14000000),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.18)
                      : Colors.black.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Today\'s notifications',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary(isDark),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'This list resets automatically tomorrow.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.textMuted(isDark),
              ),
            ),
            const SizedBox(height: 14),
            if (notifications.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Center(
                  child: Text(
                    'No notifications yet today',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary(isDark),
                    ),
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: notifications.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = notifications[index];
                    final timestamp = item['createdAt'] as int? ?? 0;
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.04)
                            : const Color(0xFFF6F7F9),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item['title'] as String? ?? 'Notification',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textPrimary(isDark),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _formatTime(timestamp),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppTheme.textMuted(isDark),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item['body'] as String? ?? '',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary(isDark),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
