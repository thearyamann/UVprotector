import 'dart:async';
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

  int  _sessionsCompleted = 0;
  int  _totalSessions     = 0;
  int  _secondsLeft       = 0;
  int  _totalSeconds      = 0;
  int  _reapplyMinutes    = 90;
  int  _spf               = 30;
  int  _skinType          = 3;
  double _lockedUV        = 0;
  DateTime? _sessionStartedAt;

  // Two-Speed Tracking
  bool _isOutdoor = true;
  double _remainingOutdoorSeconds = 0.0;

  bool _loaded = false;
  bool _showEscalation = false;
  Color? _escalationColor = const Color(0xFFEF4444); // Medium Red
  bool _isApplying = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  int get _calculatedTotalSessions {
    final uv = widget.uvData?.uvIndex ?? 0;
    final baseTotal = SunscreenEngine.getTotalApplications(_skinType, uv);
    if (baseTotal == 0) return 0;
    if (_isOutdoor) return baseTotal;
    
    // Indoors, sunscreen lasts 3x longer so divide requirement
    // E.g., if base is 3, indoor needs 1. If base is 4, indoor needs 2.
    return (baseTotal / 3.0).ceil();
  }

  @override
  void didUpdateWidget(SunscreenTimerCard old) {
    super.didUpdateWidget(old);
    if (widget.uvData != old.uvData && widget.uvData != null) {
      final newTotal = _calculatedTotalSessions;
      if (newTotal != _totalSessions) {
        setState(() => _totalSessions = newTotal);
      }
      _checkEscalation();
    }
  }

  Future<void> _init() async {
    final prefs = await PreferencesService.loadPreferences();
    _skinType = prefs.skinTypeNumber;
    _spf      = prefs.spf;
    await _loadSession();
    if (mounted) setState(() => _loaded = true);
  }

  Future<void> _loadSession() async {
    final session = await UVCacheService.loadSessionData();
    final uv      = widget.uvData?.uvIndex ?? 0;

    if (session == null) {
      final total   = _calculatedTotalSessions;
      final reapply = SunscreenEngine.getReapplyMinutes(uv);
      _sessionsCompleted = 0;
      _totalSessions     = total;
      _reapplyMinutes    = reapply;
      _totalSeconds      = 0;
      _secondsLeft       = 0;
      _lockedUV          = 0;
      _sessionStartedAt  = null;
      _isOutdoor         = true;
      _remainingOutdoorSeconds = 0;
      return;
    }

    _sessionsCompleted = session['sessionsCompleted'] as int;
    _isOutdoor         = session['isOutdoor'] as bool? ?? true;
    _totalSessions     = _calculatedTotalSessions;
    _reapplyMinutes    = session['lockedReapplyMinutes'] as int? ?? session['reapplyMinutes'] as int;
    _spf               = session['spf'] as int;
    _lockedUV          = (session['lockedUV'] as num?)?.toDouble() ?? uv;

    // Calculate how much real time elapsed since last saved (cache update)
    final lastUpdatedAt = session['lastUpdatedAt'] as int? ?? session['sessionStartedAt'] as int;
    final elapsedSec = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(lastUpdatedAt)).inSeconds.toDouble();
    
    // Calculate new remaining capacity
    final rate = _isOutdoor ? 1.0 : (1.0 / 3.0);
    double remaining = (session['remainingOutdoorSeconds'] as num?)?.toDouble() ?? (_reapplyMinutes * 60.0);
    remaining -= (elapsedSec * rate);
    if (remaining < 0) remaining = 0;

    _remainingOutdoorSeconds = remaining;
    _secondsLeft = (_remainingOutdoorSeconds / rate).toInt();
    _totalSeconds = (_reapplyMinutes * 60.0 / rate).toInt();

    final startedAt = DateTime.fromMillisecondsSinceEpoch(session['sessionStartedAt'] as int);
    _sessionStartedAt = startedAt;

    if (_sessionsCompleted >= _totalSessions && _sessionsCompleted > 0) {
      // Keep it as 0 if they're actually fully done and the required total dropped.
      // But we handled isRunning prioritizing above allDone in build() so no worries.
    }

    if (_remainingOutdoorSeconds > 0) {
      _startTicker();
    } else {
      _secondsLeft = 0;
    }

    // Auto-check escalation on load
    _checkEscalation();
  }

  void _checkEscalation() {
    if (!mounted) return;
    
    final bool isRunning = _remainingOutdoorSeconds > 0;
    if (!isRunning || widget.uvData == null || _lockedUV == null) {
      if (_showEscalation) setState(() => _showEscalation = false);
      return;
    }

    final double currentUV = widget.uvData!.uvIndex;
    
    // User requirement:
    // Only show if UV is High (>= 6) AND timer has less than 10 min left (< 600 sec)
    // AND UV has actually increased since initial application.
    final bool isHigh = currentUV >= 6.0;
    final bool isLowTimer = _secondsLeft <= 600;
    final bool hasIncreased = currentUV > (_lockedUV + 0.5);

    final bool shouldShow = isHigh && isLowTimer && hasIncreased;

    if (_showEscalation != shouldShow) {
      setState(() => _showEscalation = shouldShow);
    }
  }
  
  void _dismissEscalation() {
    setState(() => _showEscalation = false);
  }
  
  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_remainingOutdoorSeconds <= 0) {
        _ticker?.cancel();
        setState(() {
          _remainingOutdoorSeconds = 0;
          _secondsLeft = 0;
        });
        return;
      }
      
      final rate = _isOutdoor ? 1.0 : (1.0 / 3.0);
      setState(() {
        _remainingOutdoorSeconds -= rate;
        _secondsLeft = (_remainingOutdoorSeconds / rate).toInt();
      });
      _checkEscalation();
    });
  }

  Future<void> _toggleMode(bool toOutdoor) async {
    if (_isOutdoor == toOutdoor) return;
    
    setState(() {
      _isOutdoor = toOutdoor;
      final rate = _isOutdoor ? 1.0 : (1.0 / 3.0);
      _secondsLeft = (_remainingOutdoorSeconds / rate).toInt();
      _totalSeconds = (_reapplyMinutes * 60.0 / rate).toInt();
      _totalSessions = _calculatedTotalSessions;
    });

    await UVCacheService.updateSessionMode(
      isOutdoor: _isOutdoor,
      remainingOutdoorSeconds: _remainingOutdoorSeconds,
    );
  }

  Future<void> _onApplied() async {
    if (_isApplying) return;
    setState(() => _isApplying = true);
    
    // Brief haptic delay for the loading animation
    await Future.delayed(const Duration(milliseconds: 600));
    
    final uv = widget.uvData?.uvIndex ?? 0;

    // Reset speed to outdoor upon application mostly as a safe default.
    _isOutdoor = true;

    final total   = _calculatedTotalSessions;
    final reapply = SunscreenEngine.getReapplyMinutes(uv);
    final newCompleted = _sessionsCompleted + 1;

    _remainingOutdoorSeconds = reapply * 60.0;

    await UVCacheService.saveSession(
      sessionsCompleted: newCompleted,
      totalSessions:     total,
      reapplyMinutes:    reapply,
      spf:               _spf,
      lockedUV:          uv,
      isOutdoor:         _isOutdoor,
      remainingOutdoorSeconds: _remainingOutdoorSeconds,
    );

    setState(() {
      _sessionsCompleted = newCompleted;
      _totalSessions     = total;
      _reapplyMinutes    = reapply;
      final rate = _isOutdoor ? 1.0 : (1.0 / 3.0);
      _secondsLeft       = (_remainingOutdoorSeconds / rate).toInt();
      _totalSeconds      = (_reapplyMinutes * 60.0 / rate).toInt();
      _lockedUV          = uv;
      _sessionStartedAt  = DateTime.now();
      _showEscalation = false;
      _isApplying = false;
    });

    if (newCompleted < total) _startTicker();
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
    final h  = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m  = dt.minute.toString().padLeft(2, '0');
    final ap = dt.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $ap';
  }

  String get _appliedDisplay =>
      _sessionStartedAt != null ? _fmt(_sessionStartedAt!) : '';

  String get _expiresDisplay {
    if (_sessionStartedAt == null) return '';
    return _fmt(DateTime.now().add(Duration(seconds: _secondsLeft))); // dynamic expires
  }

  Color get _progressColor {
    if (_progress > 0.5)  return const Color(0xFF15803D);
    if (_progress > 0.25) return const Color(0xFFD97706);
    return const Color(0xFFEF4444);
  }

  BoxDecoration get _btnDecoration {
    final bool isDark = widget.isDark;
    if (isDark) {
      return BoxDecoration(
        color: Colors.black.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 0.5,
        ),
      );
    } else {
      const green = Color(0xFF166534); // Forest Green
      return BoxDecoration(
        color: green.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: green.withValues(alpha: 0.3),
          width: 0.5,
        ),
      );
    }
  }

  Color get _btnTextColor {
    final bool isDark = widget.isDark;
    return isDark 
        ? AppTheme.textPrimary(isDark) 
        : const Color(0xFF166534);
  }

  @override
  Widget build(BuildContext context) {
    final sw  = MediaQuery.of(context).size.width;
    final sh  = MediaQuery.of(context).size.height;
    final uv  = widget.uvData?.uvIndex ?? -1;
    final isLowUV = uv >= 0 && uv <= 2;
    final allDone = _sessionsCompleted >= _totalSessions && _totalSessions > 0;
    final isExpired   = _remainingOutdoorSeconds <= 0 && _sessionsCompleted < _totalSessions && _sessionsCompleted > 0;
    final isRunning   = _remainingOutdoorSeconds > 0;
    // Strictly not started if no applications and timer not running
    final isNotStarted = _sessionsCompleted == 0 && !isRunning;
    final firstApply  = isNotStarted && !isLowUV && _totalSessions > 0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      width: double.infinity,
      decoration: AppTheme.cardDecoration(widget.isDark),
      padding: EdgeInsets.all(sw * 0.044),
      child: !_loaded
          ? _buildLoading(sh)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isLowUV)
                  _buildLowUV(sw, sh)
                else if (isRunning)
                  _buildRunning(sw, sh)
                else if (allDone)
                  _buildAllDone(sw, sh)
                else if (isExpired)
                  _buildExpired(sw, sh)
                else if (firstApply)
                  _buildNotApplied(sw, sh)
                else
                  _buildNotApplied(sw, sh),

                // ── Escalation alert ──
                if (_showEscalation) ...[
                  SizedBox(height: sh * 0.01),
                  _buildEscalationAlert(sw, sh),
                ],
              ],
            ),
    );
  }



  Widget _buildEscalationAlert(double sw, double sh) {
    // ... [Original code] ...
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: sw * 0.03,
        vertical: sh * 0.008,
      ),
      decoration: BoxDecoration(
        color: _escalationColor!.withValues(alpha: widget.isDark ? 0.15 : 0.08),
        border: Border.all(
          color: _escalationColor!.withValues(alpha: 0.2),
          width: 0.5,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded,
              size: sh * 0.018,
              color: _escalationColor),
          SizedBox(width: sw * 0.02),
          Expanded(
            child: Text(
              'UV has increased — consider reapplying sooner',
              style: TextStyle(
                fontSize: sh * 0.012,
                fontWeight: FontWeight.w500,
                color: _escalationColor,
              ),
            ),
          ),
          GestureDetector(
            onTap: _dismissEscalation,
            child: Icon(Icons.close_rounded,
                size: sh * 0.016,
                color: _escalationColor),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading(double sh) {
    return Row(
      children: [
        SizedBox(
          width: sh * 0.02,
          height: sh * 0.02,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            color: AppTheme.textMuted(widget.isDark),
          ),
        ),
        const SizedBox(width: 10),
        Text('Loading...', style: AppTheme.bodySecondary(widget.isDark)),
      ],
    );
  }

  Widget _buildHeader(double sw, double sh, {Widget? trailing}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(Icons.access_time_rounded,
                size: sh * 0.015,
                color: AppTheme.textLabel(widget.isDark)),
            SizedBox(width: sw * 0.012),
            Text('SUNSCREEN TIMER',
                style: AppTheme.labelSmall(widget.isDark)),
          ],
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _buildLowUV(double sw, double sh) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(sw, sh),
        SizedBox(height: sh * 0.012),
        Text(
          'UV is low right now',
          style: TextStyle(
            fontSize: sh * 0.019,
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary(widget.isDark),
          ),
        ),
        SizedBox(height: sh * 0.004),
        Text('No cream needed at the moment',
            style: AppTheme.bodySecondary(widget.isDark)),
        SizedBox(height: sh * 0.003),
        Text(
          'Check again when you head outside',
          style: TextStyle(
            fontSize: sh * 0.013,
            color: AppTheme.textMuted(widget.isDark),
          ),
        ),
      ],
    );
  }

  Widget _buildNotApplied(double sw, double sh) {
    final uv = widget.uvData?.uvIndex ?? 0;
    final isHigh = uv >= 6; // High, Very High, or Extreme

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(sw, sh),
        SizedBox(height: sh * 0.022),
        Text(
          isHigh ? 'High UV — Apply Sunscreen!' : 'Ready for the sun?',
          style: TextStyle(
            fontSize: sh * 0.019,
            fontWeight: FontWeight.w600,
            color: isHigh ? const Color(0xFFEF4444) : AppTheme.textPrimary(widget.isDark),
          ),
        ),
        SizedBox(height: sh * 0.003),
        Text(
          isHigh 
              ? 'UV is high right now. Protect your skin before heading out.'
              : 'SPF $_spf · $_totalSessions application${_totalSessions > 1 ? 's' : ''} recommended',
          style: TextStyle(
            fontSize: sh * 0.014,
            fontWeight: isHigh ? FontWeight.w500 : FontWeight.w400,
            color: isHigh ? const Color(0xFFEF4444).withValues(alpha: 0.8) : AppTheme.bodySecondary(widget.isDark).color,
          ),
        ),
        SizedBox(height: sh * 0.006),
        Text(
          'Based on your skin type and current UV index',
          style: TextStyle(
            fontSize: sh * 0.013,
            color: AppTheme.textMuted(widget.isDark),
          ),
        ),
        SizedBox(height: sh * 0.016),
        _buildPillButton(
          sw: sw,
          sh: sh,
          label: 'Applied?',
          onPressed: _onApplied,
        ),
      ],
    );
  }

  Widget _buildPillButton({
    required double sw,
    required double sh,
    required String label,
    required VoidCallback onPressed,
  }) {
    final accent = _btnTextColor;
    return Pressable(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: sw * 0.05,
          vertical: sh * 0.016,
        ),
        decoration: _btnDecoration,
        child: Center(
          child: _isApplying
              ? SizedBox(
                width: sh * 0.022,
                height: sh * 0.022,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: accent,
                ),
              )
              : Text(
                label,
                style: TextStyle(
                  color: accent,
                  fontSize: sh * 0.017,
                  fontWeight: FontWeight.w600,
                ),
              ),
        ),
      ),
    );
  }

  Widget _buildRunning(double sw, double sh) {
    final pill = Container(
      padding: EdgeInsets.symmetric(
          horizontal: sw * 0.025, vertical: sh * 0.004),
      decoration: BoxDecoration(
        color: const Color(0xFF15803D).withValues(alpha: 0.12),
        border: Border.all(
            color: const Color(0xFF15803D).withValues(alpha: 0.25),
            width: 0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$_sessionsCompleted of $_totalSessions done',
        style: TextStyle(
          fontSize: sh * 0.012,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF15803D),
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(sw, sh, trailing: pill),
        SizedBox(height: sh * 0.011),
        Text(
          _timeDisplay,
          style: TextStyle(
            fontSize: sh * 0.027,
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
        SizedBox(height: sh * 0.011),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: _progress,
            backgroundColor: AppTheme.progressTrack(widget.isDark),
            valueColor:
                AlwaysStoppedAnimation<Color>(_progressColor),
            minHeight: sh * 0.003,
          ),
        ),
        SizedBox(height: sh * 0.004),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_appliedDisplay,
                style: TextStyle(
                    fontSize: sh * 0.011,
                    color: AppTheme.textMuted(widget.isDark))),
            Text(_expiresDisplay,
                style: TextStyle(
                    fontSize: sh * 0.011,
                    color: AppTheme.textMuted(widget.isDark))),
          ],
        ),
        SizedBox(height: sh * 0.014),

        // ── Indoor / Outdoor Toggle ──
        Container(
          width: double.infinity,
          height: sh * 0.046,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: widget.isDark ? AppTheme.progressTrack(widget.isDark) : const Color(0xFFF1F4F9),
            borderRadius: BorderRadius.circular(10),
            border: widget.isDark ? null : Border.all(
              color: AppTheme.cardBorder(widget.isDark).withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _toggleMode(false),
                  child: Container(
                    decoration: BoxDecoration(
                      color: !_isOutdoor ? AppTheme.cardBg(widget.isDark) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.home_rounded,
                          size: sh * 0.022,
                          color: !_isOutdoor ? AppTheme.ctaText(widget.isDark) : AppTheme.textMuted(widget.isDark),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Indoor',
                          style: TextStyle(
                            fontSize: sh * 0.014,
                            fontWeight: !_isOutdoor ? FontWeight.w600 : FontWeight.w500,
                            color: !_isOutdoor ? AppTheme.ctaText(widget.isDark) : AppTheme.textMuted(widget.isDark),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => _toggleMode(true),
                  child: Container(
                    decoration: BoxDecoration(
                      color: _isOutdoor ? AppTheme.cardBg(widget.isDark) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.wb_sunny_rounded,
                          size: sh * 0.021,
                          color: _isOutdoor ? const Color(0xFFF59E0B) : AppTheme.textMuted(widget.isDark),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Outdoor',
                          style: TextStyle(
                            fontSize: sh * 0.014,
                            fontWeight: _isOutdoor ? FontWeight.w600 : FontWeight.w500,
                            color: _isOutdoor ? const Color(0xFFF59E0B) : AppTheme.textMuted(widget.isDark),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExpired(double sw, double sh) {
    final pill = Container(
      padding: EdgeInsets.symmetric(
          horizontal: sw * 0.025, vertical: sh * 0.004),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withValues(alpha: 0.1),
        border: Border.all(
            color: const Color(0xFFEF4444).withValues(alpha: 0.2),
            width: 0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'Reapply now',
        style: TextStyle(
          fontSize: sh * 0.012,
          fontWeight: FontWeight.w600,
          color: const Color(0xFFDC2626),
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(sw, sh, trailing: pill),
        SizedBox(height: sh * 0.011),
        Text(
          'Time to reapply!',
          style: TextStyle(
            fontSize: sh * 0.027,
            fontWeight: FontWeight.w700,
            color: const Color(0xFFDC2626),
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: sh * 0.003),
        Text(
          'Application $_sessionsCompleted of $_totalSessions complete',
          style: AppTheme.bodySecondary(widget.isDark),
        ),
        SizedBox(height: sh * 0.011),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: 0,
            backgroundColor: const Color(0xFFDC2626).withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation<Color>(
                const Color(0xFFDC2626).withValues(alpha: 0.5)),
            minHeight: sh * 0.003,
          ),
        ),
        SizedBox(height: sh * 0.016),
        _buildPillButton(
          sw: sw,
          sh: sh,
          label: 'Reapplied',
          onPressed: _onApplied,
        ),
      ],
    );
  }

  Widget _buildAllDone(double sw, double sh) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(sw, sh),
        SizedBox(height: sh * 0.012),
        Row(
          children: [
            Container(
              width: sh * 0.038,
              height: sh * 0.038,
              decoration: BoxDecoration(
                color: const Color(0xFF15803D).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.check_rounded,
                  color: Color(0xFF15803D), size: 16),
            ),
            SizedBox(width: sw * 0.025),
            Text(
              'Protected for today',
              style: TextStyle(
                fontSize: sh * 0.019,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary(widget.isDark),
              ),
            ),
          ],
        ),
        SizedBox(height: sh * 0.006),
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
            color: const Color(0xFF15803D),
          ),
        ),
        SizedBox(height: sh * 0.013),
        Row(
          children: List.generate(_totalSessions, (i) => Expanded(
            child: Container(
              margin: EdgeInsets.only(right: i < _totalSessions - 1 ? 4 : 0),
              height: 3,
              decoration: BoxDecoration(
                color: const Color(0xFF15803D),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          )),
        ),
        SizedBox(height: sh * 0.004),
        Center(
          child: Text(
            '$_totalSessions of $_totalSessions complete',
            style: TextStyle(
              fontSize: sh * 0.011,
              color: AppTheme.textMuted(widget.isDark),
            ),
          ),
        ),
      ],
    );
  }
}