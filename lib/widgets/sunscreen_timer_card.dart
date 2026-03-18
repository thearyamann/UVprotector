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

  bool _loaded = false;
  bool _showEscalationAlert = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void didUpdateWidget(SunscreenTimerCard old) {
    super.didUpdateWidget(old);
    if (widget.uvData != old.uvData && widget.uvData != null) {
      // ── LOCK-AT-FIRST-APPLY: do NOT recalculate timer ──
      // Only check for escalation alert if session is active
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
      // No session today — show pre-apply state with LIVE UV values
      final total   = SunscreenEngine.getTotalApplications(_skinType, uv);
      final reapply = SunscreenEngine.getReapplyMinutes(uv);
      _sessionsCompleted = 0;
      _totalSessions     = total;
      _reapplyMinutes    = reapply;
      _totalSeconds      = 0;
      _secondsLeft       = 0;
      _lockedUV          = 0;
      _sessionStartedAt  = null;
      return;
    }

    // Session exists — use LOCKED values (never recalculate from live UV)
    _sessionsCompleted = session['sessionsCompleted'] as int;
    _totalSessions     = session['lockedTotalSessions'] as int? ?? session['totalSessions'] as int;
    _reapplyMinutes    = session['lockedReapplyMinutes'] as int? ?? session['reapplyMinutes'] as int;
    _spf               = session['spf'] as int;
    _lockedUV          = (session['lockedUV'] as num?)?.toDouble() ?? uv;

    final startedAt = DateTime.fromMillisecondsSinceEpoch(
        session['sessionStartedAt'] as int);
    final expiresAt = startedAt.add(Duration(minutes: _reapplyMinutes));
    final now       = DateTime.now();

    _sessionStartedAt = startedAt;
    _totalSeconds     = _reapplyMinutes * 60;

    if (_sessionsCompleted >= _totalSessions) {
      _secondsLeft = 0;
      return;
    }

    if (now.isBefore(expiresAt)) {
      _secondsLeft = expiresAt.difference(now).inSeconds;
      _startTicker();
    } else {
      _secondsLeft = 0;
    }
  }

  /// Check if live UV has risen significantly above locked UV.
  /// If so, show a one-time escalation alert — but do NOT change timer.
  void _checkEscalation() {
    if (_lockedUV <= 0 || _sessionsCompleted == 0) return;
    final liveUV = widget.uvData?.uvIndex ?? 0;
    if (liveUV >= _lockedUV + 2 && !_showEscalationAlert) {
      if (mounted) setState(() => _showEscalationAlert = true);
    }
  }

  void _dismissEscalation() {
    setState(() => _showEscalationAlert = false);
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_secondsLeft <= 0) {
        _ticker?.cancel();
        setState(() => _secondsLeft = 0);
        return;
      }
      setState(() => _secondsLeft--);
    });
  }

  Future<void> _onApplied() async {
    final uv = widget.uvData?.uvIndex ?? 0;

    // Calculate from current UV — these get LOCKED for the rest of the day
    final total   = SunscreenEngine.getTotalApplications(_skinType, uv);
    final reapply = SunscreenEngine.getReapplyMinutes(uv);
    final newCompleted = _sessionsCompleted + 1;

    await UVCacheService.saveSession(
      sessionsCompleted: newCompleted,
      totalSessions:     total,
      reapplyMinutes:    reapply,
      spf:               _spf,
      lockedUV:          uv,
    );

    setState(() {
      _sessionsCompleted = newCompleted;
      _totalSessions     = total;
      _reapplyMinutes    = reapply;
      _totalSeconds      = reapply * 60;
      _secondsLeft       = reapply * 60;
      _lockedUV          = uv;
      _sessionStartedAt  = DateTime.now();
      _showEscalationAlert = false;
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
    return _fmt(_sessionStartedAt!.add(Duration(minutes: _reapplyMinutes)));
  }

  Color get _progressColor {
    if (_progress > 0.5)  return const Color(0xFF15803D);
    if (_progress > 0.25) return const Color(0xFFD97706);
    return const Color(0xFFDC2626);
  }

  BoxDecoration get _greenBtn => BoxDecoration(
    color: AppTheme.ctaBg(widget.isDark),
    border: Border.all(color: AppTheme.ctaBorder(widget.isDark), width: 0.5),
    borderRadius: BorderRadius.circular(13),
  );

  @override
  Widget build(BuildContext context) {
    final sw  = MediaQuery.of(context).size.width;
    final sh  = MediaQuery.of(context).size.height;
    final uv  = widget.uvData?.uvIndex ?? -1;
    final isLowUV = uv >= 0 && uv <= 2;
    final allDone = _sessionsCompleted >= _totalSessions && _totalSessions > 0;
    final notStarted  = _sessionsCompleted == 0 && _secondsLeft == 0;
    final isExpired   = _secondsLeft <= 0 && _sessionsCompleted < _totalSessions && _sessionsCompleted > 0;
    final isRunning   = _secondsLeft > 0 && _sessionsCompleted < _totalSessions;
    final firstApply  = notStarted && !isLowUV && _totalSessions > 0;

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
                else if (allDone)
                  _buildAllDone(sw, sh)
                else if (isRunning)
                  _buildRunning(sw, sh)
                else if (isExpired)
                  _buildExpired(sw, sh)
                else if (firstApply)
                  _buildNotApplied(sw, sh)
                else
                  _buildNotApplied(sw, sh),

                // ── Escalation alert ──
                if (_showEscalationAlert) ...[
                  SizedBox(height: sh * 0.01),
                  _buildEscalationAlert(sw, sh),
                ],
              ],
            ),
    );
  }

  Widget _buildEscalationAlert(double sw, double sh) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: sw * 0.03,
        vertical: sh * 0.008,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFD97706).withValues(alpha: widget.isDark ? 0.15 : 0.08),
        border: Border.all(
          color: const Color(0xFFD97706).withValues(alpha: 0.2),
          width: 0.5,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded,
              size: sh * 0.018,
              color: const Color(0xFFD97706)),
          SizedBox(width: sw * 0.02),
          Expanded(
            child: Text(
              'UV has increased — consider reapplying sooner',
              style: TextStyle(
                fontSize: sh * 0.012,
                fontWeight: FontWeight.w500,
                color: const Color(0xFFD97706),
              ),
            ),
          ),
          GestureDetector(
            onTap: _dismissEscalation,
            child: Icon(Icons.close_rounded,
                size: sh * 0.016,
                color: const Color(0xFFD97706)),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(sw, sh),
        SizedBox(height: sh * 0.012),
        Text(
          'Applied today?',
          style: TextStyle(
            fontSize: sh * 0.019,
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary(widget.isDark),
          ),
        ),
        SizedBox(height: sh * 0.003),
        Text(
          'SPF $_spf · $_totalSessions application${_totalSessions > 1 ? 's' : ''} needed today',
          style: AppTheme.bodySecondary(widget.isDark),
        ),
        SizedBox(height: sh * 0.003),
        Text(
          'Based on your skin type and UV index',
          style: TextStyle(
            fontSize: sh * 0.013,
            color: AppTheme.textMuted(widget.isDark),
          ),
        ),
        SizedBox(height: sh * 0.016),
        Pressable(
          onTap: _onApplied,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: sh * 0.016),
            decoration: _greenBtn,
            child: Center(
              child: Text(
                'I applied sunscreen',
                style: TextStyle(
                  fontSize: sh * 0.018,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.ctaText(widget.isDark),
                ),
              ),
            ),
          ),
        ),
      ],
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
      ],
    );
  }

  Widget _buildExpired(double sw, double sh) {
    final pill = Container(
      padding: EdgeInsets.symmetric(
          horizontal: sw * 0.025, vertical: sh * 0.004),
      decoration: BoxDecoration(
        color: const Color(0xFFDC2626).withValues(alpha: 0.1),
        border: Border.all(
            color: const Color(0xFFDC2626).withValues(alpha: 0.2),
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
        Pressable(
          onTap: _onApplied,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: sh * 0.016),
            decoration: BoxDecoration(
              color: const Color(0xFFDC2626),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Center(
              child: Text(
                'I reapplied',
                style: TextStyle(
                  fontSize: sh * 0.018,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
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