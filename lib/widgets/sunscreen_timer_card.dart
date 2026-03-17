import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/uv_data.dart';
import '../services/uv_cache_service.dart';
import '../services/preferences_service.dart';
import '../engines/sunscreen_engines.dart';
import '../theme/app_theme.dart';
import 'pressable.dart';

class SunscreenTimerCard extends StatefulWidget {
  final UVData? uvData;
  final bool isDark;
  const SunscreenTimerCard({
    super.key,
    required this.uvData,
    required this.isDark,
  });

  @override
  State<SunscreenTimerCard> createState() => _SunscreenTimerCardState();
}

class _SunscreenTimerCardState extends State<SunscreenTimerCard> {
  Timer? _ticker;

  int _sessionsCompleted = 0;
  int _totalSessions = 0;
  int _secondsLeft = 0;
  int _totalSeconds = 0;
  int _reapplyMinutes = 90;
  int _spf = 30;
  int _skinType = 3;
  DateTime? _sessionStartedAt;
  bool _loaded = false;
  bool _isLoading = false; // button loading state

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void didUpdateWidget(SunscreenTimerCard old) {
    super.didUpdateWidget(old);
    if (widget.uvData != old.uvData && widget.uvData != null) _recalculate();
  }

  Future<void> _init() async {
    final prefs = await PreferencesService.loadPreferences();
    _skinType = prefs.skinTypeNumber;
    _spf = prefs.spf;
    await _loadSession();
    if (mounted) setState(() => _loaded = true);
  }

  Future<void> _loadSession() async {
    final session = await UVCacheService.loadSessionData();
    final uv = widget.uvData?.uvIndex ?? 0;
    final total = SunscreenEngine.getTotalApplications(_skinType, uv);
    final reapply = SunscreenEngine.getReapplyMinutes(uv, _spf);

    if (session == null) {
      _sessionsCompleted = 0;
      _totalSessions = total;
      _reapplyMinutes = reapply;
      _totalSeconds = 0;
      _secondsLeft = 0;
      _sessionStartedAt = null;
      return;
    }

    _sessionsCompleted = session['sessionsCompleted'] as int;
    _totalSessions = session['totalSessions'] as int;
    _reapplyMinutes = session['reapplyMinutes'] as int;
    _spf = session['spf'] as int;

    final startedAt = DateTime.fromMillisecondsSinceEpoch(
      session['sessionStartedAt'] as int,
    );
    final expiresAt = startedAt.add(Duration(minutes: _reapplyMinutes));
    _sessionStartedAt = startedAt;
    _totalSeconds = _reapplyMinutes * 60;

    if (_sessionsCompleted >= _totalSessions) {
      _secondsLeft = 0;
      return;
    }

    if (DateTime.now().isBefore(expiresAt)) {
      _secondsLeft = expiresAt.difference(DateTime.now()).inSeconds;
      _startTicker();
    } else {
      _secondsLeft = 0;
    }
  }

  void _recalculate() {
    final uv = widget.uvData?.uvIndex ?? 0;
    setState(() {
      _totalSessions = SunscreenEngine.getTotalApplications(_skinType, uv);
      _reapplyMinutes = SunscreenEngine.getReapplyMinutes(uv, _spf);
      _totalSeconds = _reapplyMinutes * 60;
    });
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_secondsLeft <= 0) {
        _ticker?.cancel();
        setState(() {});
        return;
      }
      setState(() => _secondsLeft--);
    });
  }

  Future<void> _onApplied() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 600));

    final uv = widget.uvData?.uvIndex ?? 0;
    final total = SunscreenEngine.getTotalApplications(_skinType, uv);
    final reapply = SunscreenEngine.getReapplyMinutes(uv, _spf);
    final newDone = _sessionsCompleted + 1;

    await UVCacheService.saveSession(
      sessionsCompleted: newDone,
      totalSessions: total,
      reapplyMinutes: reapply,
      spf: _spf,
    );

    if (!mounted) return;
    setState(() {
      _sessionsCompleted = newDone;
      _totalSessions = total;
      _reapplyMinutes = reapply;
      _totalSeconds = reapply * 60;
      _secondsLeft = reapply * 60;
      _sessionStartedAt = DateTime.now();
      _isLoading = false;
    });
    if (newDone < total) _startTicker();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  double get _progress {
    if (_totalSeconds == 0) return 0;
    return (_secondsLeft / _totalSeconds).clamp(0.0, 1.0);
  }

  String get _timeDisplay {
    if (_secondsLeft <= 0) return 'Time to reapply!';
    final h = _secondsLeft ~/ 3600;
    final m = (_secondsLeft % 3600) ~/ 60;
    final s = _secondsLeft % 60;
    if (h > 0) return '${h}h ${m.toString().padLeft(2, '0')}m left';
    if (m > 0) return '${m}m ${s.toString().padLeft(2, '0')}s left';
    return '${s}s left';
  }

  String _fmt(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m ${dt.hour < 12 ? "AM" : "PM"}';
  }

  String get _appliedDisplay =>
      _sessionStartedAt != null ? _fmt(_sessionStartedAt!) : '';
  String get _expiresDisplay {
    if (_sessionStartedAt == null) return '';
    return _fmt(_sessionStartedAt!.add(Duration(minutes: _reapplyMinutes)));
  }

  Color get _progressColor {
    if (_progress > 0.5) return const Color(0xFF16A34A);
    if (_progress > 0.25) return const Color(0xFFD97706);
    return const Color(0xFFDC2626);
  }

  Widget _blackBtn({
    required String label,
    required VoidCallback onTap,
    bool isRed = false,
    bool isLoading = false,
  }) {
    return Pressable(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: isRed ? const Color(0xFFDC2626) : const Color(0xD9141414),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: isLoading
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.8,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Applying...',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                )
              : Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;
    final uv = widget.uvData?.uvIndex ?? -1;
    final isLowUV = uv >= 0 && uv <= 2;
    final allDone = _sessionsCompleted >= _totalSessions && _totalSessions > 0;
    final notStarted = _sessionsCompleted == 0 && _secondsLeft == 0;
    final isExpired =
        _secondsLeft <= 0 &&
        _sessionsCompleted < _totalSessions &&
        _sessionsCompleted > 0;
    final isRunning = _secondsLeft > 0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(sw * 0.043),
          decoration: AppTheme.cardDecoration(widget.isDark),
          child: !_loaded
              ? _buildLoading(sh)
              : isLowUV
              ? _buildLowUV(sw, sh)
              : allDone
              ? _buildAllDone(sw, sh)
              : isRunning
              ? _buildRunning(sw, sh)
              : isExpired
              ? _buildExpired(sw, sh)
              : _buildNotApplied(sw, sh),
        ),
      ),
    );
  }

  Widget _buildLoading(double sh) => Row(
    children: [
      SizedBox(
        width: 14,
        height: 14,
        child: CircularProgressIndicator(
          strokeWidth: 1.5,
          color: AppTheme.textMuted(widget.isDark),
        ),
      ),
      const SizedBox(width: 9),
      Text('Loading...', style: AppTheme.bodySecondary(widget.isDark)),
    ],
  );

  Widget _header({Widget? trailing}) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Row(
        children: [
          Icon(
            Icons.access_time_rounded,
            size: 9,
            color: AppTheme.textLabel(widget.isDark),
          ),
          const SizedBox(width: 5),
          Text('SUNSCREEN TIMER', style: AppTheme.labelSmall(widget.isDark)),
        ],
      ),
      if (trailing != null) trailing,
    ],
  );

  Widget _buildLowUV(double sw, double sh) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _header(),
      SizedBox(height: sh * 0.011),
      Text(
        'UV is low right now',
        style: TextStyle(
          fontSize: sh * 0.018,
          fontWeight: FontWeight.w500,
          color: AppTheme.textPrimary(widget.isDark),
        ),
      ),
      SizedBox(height: sh * 0.003),
      Text(
        'No cream needed at the moment',
        style: AppTheme.bodySecondary(widget.isDark),
      ),
      SizedBox(height: sh * 0.002),
      Text(
        'Check again when you head outside',
        style: TextStyle(
          fontSize: sh * 0.013,
          color: AppTheme.textMuted(widget.isDark),
        ),
      ),
    ],
  );

  Widget _buildNotApplied(double sw, double sh) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _header(),
      SizedBox(height: sh * 0.011),
      Text(
        'Applied today?',
        style: TextStyle(
          fontSize: sh * 0.018,
          fontWeight: FontWeight.w500,
          color: AppTheme.textPrimary(widget.isDark),
        ),
      ),
      SizedBox(height: sh * 0.003),
      Text(
        'SPF $_spf · $_totalSessions application${_totalSessions != 1 ? "s" : ""} needed today',
        style: AppTheme.bodySecondary(widget.isDark),
      ),
      SizedBox(height: sh * 0.002),
      Text(
        'Based on your skin type and UV index',
        style: TextStyle(
          fontSize: sh * 0.013,
          color: AppTheme.textMuted(widget.isDark),
        ),
      ),
      SizedBox(height: sh * 0.015),
      _blackBtn(
        label: 'I applied sunscreen',
        onTap: _onApplied,
        isLoading: _isLoading,
      ),
    ],
  );

  Widget _buildRunning(double sw, double sh) {
    final pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF9C3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$_sessionsCompleted of $_totalSessions done',
        style: const TextStyle(
          fontSize: 8.5,
          fontWeight: FontWeight.w600,
          color: Color(0xFF854D0E),
        ),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header(trailing: pill),
        SizedBox(height: sh * 0.01),
        Text(
          _timeDisplay,
          style: TextStyle(
            fontSize: sh * 0.025,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary(widget.isDark),
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: sh * 0.003),
        Text(
          'Applied $_appliedDisplay · SPF $_spf',
          style: AppTheme.bodySecondary(widget.isDark),
        ),
        SizedBox(height: sh * 0.01),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: _progress,
            backgroundColor: AppTheme.progressTrack(widget.isDark),
            valueColor: AlwaysStoppedAnimation<Color>(_progressColor),
            minHeight: sh * 0.003,
          ),
        ),
        SizedBox(height: sh * 0.003),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _appliedDisplay,
              style: TextStyle(
                fontSize: 7.5,
                color: AppTheme.textMuted(widget.isDark),
              ),
            ),
            Text(
              _expiresDisplay,
              style: TextStyle(
                fontSize: 7.5,
                color: AppTheme.textMuted(widget.isDark),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExpired(double sw, double sh) {
    final pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFDC2626).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'Reapply now',
        style: TextStyle(
          fontSize: 8.5,
          fontWeight: FontWeight.w600,
          color: Color(0xFFDC2626),
        ),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header(trailing: pill),
        SizedBox(height: sh * 0.01),
        const Text(
          'Time to reapply!',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFFDC2626),
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: sh * 0.003),
        Text(
          'Application $_sessionsCompleted of $_totalSessions complete',
          style: AppTheme.bodySecondary(widget.isDark),
        ),
        SizedBox(height: sh * 0.012),
        _blackBtn(
          label: 'I reapplied',
          onTap: _onApplied,
          isRed: true,
          isLoading: _isLoading,
        ),
      ],
    );
  }

  Widget _buildAllDone(double sw, double sh) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _header(),
      SizedBox(height: sh * 0.011),
      Row(
        children: [
          Container(
            width: sh * 0.036,
            height: sh * 0.036,
            decoration: BoxDecoration(
              color: const Color(0xFF1a5c35).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Color(0xFF1a5c35),
              size: 14,
            ),
          ),
          SizedBox(width: sw * 0.022),
          Text(
            'Protected for today',
            style: TextStyle(
              fontSize: sh * 0.018,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary(widget.isDark),
            ),
          ),
        ],
      ),
      SizedBox(height: sh * 0.005),
      Text(
        'All $_totalSessions applications done',
        style: AppTheme.bodySecondary(widget.isDark),
      ),
      SizedBox(height: sh * 0.003),
      Text(
        'Great job staying safe!',
        style: TextStyle(
          fontSize: sh * 0.013,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF1a5c35),
        ),
      ),
      SizedBox(height: sh * 0.012),
      Row(
        children: List.generate(
          _totalSessions,
          (i) => Expanded(
            child: Container(
              margin: EdgeInsets.only(right: i < _totalSessions - 1 ? 4 : 0),
              height: 3,
              decoration: BoxDecoration(
                color: const Color(0xFF1a5c35),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ),
      SizedBox(height: sh * 0.004),
      Center(
        child: Text(
          '$_totalSessions of $_totalSessions complete',
          style: TextStyle(
            fontSize: 8,
            color: AppTheme.textMuted(widget.isDark),
          ),
        ),
      ),
    ],
  );
}
