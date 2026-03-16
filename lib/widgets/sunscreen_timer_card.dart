import 'dart:async';
import 'package:flutter/material.dart';
import '../models/uv_data.dart';
import '../services/uv_cache_service.dart';
import '../theme/app_theme.dart';

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
  bool _isApplied    = false;
  int _secondsLeft   = 0;
  int _totalSeconds  = 0;
  DateTime? _appliedAt;
  int _appliedSpf    = 30;

  @override
  void initState() {
    super.initState();
    _loadAppliedState();
  }

  @override
  void didUpdateWidget(SunscreenTimerCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.uvData != oldWidget.uvData && widget.uvData != null) {
      _recalculateTotalSeconds();
    }
  }

  Future<void> _loadAppliedState() async {
    final state = await UVCacheService.loadAppliedState();
    if (state == null) {
      setState(() => _isApplied = false);
      return;
    }

    final appliedAt  = DateTime.fromMillisecondsSinceEpoch(state['appliedAt'] as int);
    final spf        = state['spf'] as int;
    final reapplyMin = widget.uvData?.reapplyMinutes ?? 180;
    final expiresAt  = appliedAt.add(Duration(minutes: reapplyMin));
    final now        = DateTime.now();

    if (now.isAfter(expiresAt)) {
      setState(() { _isApplied = false; });
      return;
    }

    final secondsLeft = expiresAt.difference(now).inSeconds;

    setState(() {
      _isApplied     = true;
      _appliedAt     = appliedAt;
      _appliedSpf    = spf;
      _totalSeconds  = reapplyMin * 60;
      _secondsLeft   = secondsLeft;
    });

    _startTicker();
  }

  void _recalculateTotalSeconds() {
    if (!_isApplied || _appliedAt == null || widget.uvData == null) return;
    final reapplyMin = widget.uvData!.reapplyMinutes;
    final expiresAt  = _appliedAt!.add(Duration(minutes: reapplyMin));
    final secondsLeft = expiresAt.difference(DateTime.now()).inSeconds;
    setState(() {
      _totalSeconds = reapplyMin * 60;
      _secondsLeft  = secondsLeft.clamp(0, _totalSeconds);
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
    final spf = widget.uvData?.reapplyMinutes ?? 180;
    await UVCacheService.saveApplied(_appliedSpf);
    final reapplyMin = widget.uvData?.reapplyMinutes ?? 180;

    setState(() {
      _isApplied    = true;
      _appliedAt    = DateTime.now();
      _totalSeconds = reapplyMin * 60;
      _secondsLeft  = _totalSeconds;
    });

    _startTicker();
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

  String get _appliedTimeDisplay {
    if (_appliedAt == null) return '';
    final h  = _appliedAt!.hour;
    final m  = _appliedAt!.minute.toString().padLeft(2, '0');
    final am = h < 12 ? 'AM' : 'PM';
    final h12 = h % 12 == 0 ? 12 : h % 12;
    return '$h12:$m $am';
  }

  String get _expiresTimeDisplay {
    if (_appliedAt == null || widget.uvData == null) return '';
    final expires = _appliedAt!.add(Duration(minutes: widget.uvData!.reapplyMinutes));
    final h  = expires.hour;
    final m  = expires.minute.toString().padLeft(2, '0');
    final am = h < 12 ? 'AM' : 'PM';
    final h12 = h % 12 == 0 ? 12 : h % 12;
    return '$h12:$m $am';
  }

  Color get _progressColor {
    if (_progress > 0.5)  return const Color(0xFF16A34A);
    if (_progress > 0.25) return const Color(0xFFD97706);
    return const Color(0xFFEF4444);
  }

  String get _statusLabel {
    if (_progress > 0.5)  return 'Good protection';
    if (_progress > 0.25) return 'Reapply soon';
    return 'Reapply now!';
  }

  BoxDecoration get _buttonDecoration => BoxDecoration(
    color:        const Color(0x338CC850),
    border:       Border.all(color: const Color(0x3264AA32), width: 0.5),
    borderRadius: BorderRadius.circular(14),
  );

  @override
  Widget build(BuildContext context) {
    final screenWidth  = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      width: double.infinity,
      decoration: AppTheme.cardDecoration(widget.isDark),
      padding: EdgeInsets.all(screenWidth * 0.046),
      child: _isApplied ? _buildTimerRunning(screenWidth, screenHeight)
                        : _buildNotApplied(screenWidth, screenHeight),
    );
  }

  Widget _buildNotApplied(double sw, double sh) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.access_time_rounded, size: sh * 0.015, color: AppTheme.textLabel(widget.isDark)),
            SizedBox(width: sw * 0.012),
            Text('SUNSCREEN TIMER', style: AppTheme.labelSmall(widget.isDark)),
          ],
        ),
        SizedBox(height: sh * 0.012),
        Text(
          'Applied today?',
          style: TextStyle(fontSize: sh * 0.022, fontWeight: FontWeight.w600, color: AppTheme.textPrimary(widget.isDark)),
        ),
        SizedBox(height: sh * 0.004),
        Text('Tap when you put on sunscreen', style: AppTheme.bodySecondary(widget.isDark)),
        SizedBox(height: sh * 0.016),
        GestureDetector(
          onTap: _onApplied,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: sh * 0.016),
            decoration: _buttonDecoration,
            child: Center(
              child: Text(
                'I applied sunscreen',
                style: TextStyle(fontSize: sh * 0.018, fontWeight: FontWeight.w600, color: const Color(0xFF3a7818)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimerRunning(double sw, double sh) {
    final isExpired = _secondsLeft <= 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.access_time_rounded, size: sh * 0.015, color: AppTheme.textLabel(widget.isDark)),
                SizedBox(width: sw * 0.012),
                Text('SUNSCREEN TIMER', style: AppTheme.labelSmall(widget.isDark)),
              ],
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: sw * 0.025, vertical: sh * 0.004),
              decoration: BoxDecoration(
                color: _progressColor.withValues(alpha: 0.1),
                border: Border.all(color: _progressColor.withValues(alpha: 0.2), width: 0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _statusLabel,
                style: TextStyle(fontSize: sh * 0.012, fontWeight: FontWeight.w600, color: _progressColor),
              ),
            ),
          ],
        ),
        SizedBox(height: sh * 0.012),
        Text(
          _timeDisplay,
          style: TextStyle(
            fontSize: sh * 0.028,
            fontWeight: FontWeight.w700,
            color: isExpired ? const Color(0xFFEF4444) : AppTheme.textPrimary(widget.isDark),
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: sh * 0.003),
        Text(
          'Applied $_appliedTimeDisplay · SPF $_appliedSpf',
          style: AppTheme.bodySecondary(widget.isDark),
        ),
        SizedBox(height: sh * 0.012),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: _progress,
            backgroundColor: AppTheme.progressTrack(widget.isDark),
            valueColor: AlwaysStoppedAnimation<Color>(_progressColor),
            minHeight: sh * 0.003,
          ),
        ),
        SizedBox(height: sh * 0.004),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_appliedTimeDisplay, style: TextStyle(fontSize: sh * 0.011, color: AppTheme.textMuted(widget.isDark))),
            Text(_expiresTimeDisplay, style: TextStyle(fontSize: sh * 0.011, color: AppTheme.textMuted(widget.isDark))),
          ],
        ),
        SizedBox(height: sh * 0.016),
        GestureDetector(
          onTap: _onApplied,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: sh * 0.016),
            decoration: isExpired
                ? BoxDecoration(color: const Color(0xFFEF4444), borderRadius: BorderRadius.circular(14))
                : _buttonDecoration,
            child: Center(
              child: Text(
                isExpired ? 'Reapply now!' : 'Mark as reapplied',
                style: TextStyle(
                  fontSize: sh * 0.018,
                  fontWeight: FontWeight.w600,
                  color: isExpired ? Colors.white : const Color(0xFF3a7818),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}