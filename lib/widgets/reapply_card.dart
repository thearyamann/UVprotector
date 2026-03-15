import 'dart:async';
import 'package:flutter/material.dart';
import '../models/uv_data.dart';
import '../theme/app_theme.dart';

class ReapplyCard extends StatefulWidget {
  final UVData? uvData;
  final VoidCallback? onReapplied;

  const ReapplyCard({super.key, required this.uvData, this.onReapplied});

  @override
  State<ReapplyCard> createState() => _ReapplyCardState();
}

class _ReapplyCardState extends State<ReapplyCard> {
  Timer? _timer;
  int _secondsRemaining = 0;
  late int _totalSeconds;

  @override
  void initState() {
    super.initState();
    _initTimer();
  }

  @override
  void didUpdateWidget(ReapplyCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.uvData != oldWidget.uvData) {
      _timer?.cancel();
      _initTimer();
    }
  }

  void _initTimer() {
    if (widget.uvData == null) return;
    _totalSeconds = widget.uvData!.reapplyMinutes * 60;
    _secondsRemaining = _totalSeconds;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsRemaining <= 0) {
        timer.cancel();
        return;
      }
      setState(() => _secondsRemaining--);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  double get _progress {
    if (_totalSeconds == 0) return 0;
    return _secondsRemaining / _totalSeconds;
  }

  String get _timeDisplay {
    if (_secondsRemaining <= 0) return 'Time to reapply!';
    final hours = _secondsRemaining ~/ 3600;
    final minutes = (_secondsRemaining % 3600) ~/ 60;
    final seconds = _secondsRemaining % 60;

    if (hours > 0) {
      return '${hours}h ${minutes.toString().padLeft(2, '0')}m left';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds.toString().padLeft(2, '0')}s left';
    } else {
      return '${seconds}s left';
    }
  }

  Color get _progressColor {
    if (_progress > 0.5) return const Color(0xFF6AAF2E);
    if (_progress > 0.25) return const Color(0xFFFFC107);
    return const Color(0xFFE53935);
  }

  String get _progressLabel {
    if (_progress > 0.5) return 'Good protection';
    if (_progress > 0.25) return 'Reapply soon';
    return 'Reapply now!';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final spf = widget.uvData?.spfRecommendation ?? '—';
    final isExpired = _secondsRemaining <= 0 && widget.uvData != null;

    return Container(
      width: double.infinity,
      decoration: AppTheme.cardDecoration,
      padding: EdgeInsets.all(screenWidth * 0.05),
      child: Column(
        // ← main Column
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Row 1: Header + Status pill ──────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: screenHeight * 0.016,
                    color: const Color(0xFF888888),
                  ),
                  SizedBox(width: screenWidth * 0.012),
                  Text('REAPPLY TIMER', style: AppTheme.labelSmall),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.03,
                  vertical: screenHeight * 0.004,
                ),
                decoration: BoxDecoration(
                  color: _progressColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _progressLabel,
                  style: TextStyle(
                    fontSize: screenHeight * 0.013,
                    fontWeight: FontWeight.w600,
                    color: _progressColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.014),

          // ── Row 2: Countdown + SPF ───────────────────────────
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.uvData != null ? _timeDisplay : '— left',
                style: TextStyle(
                  fontSize: screenHeight * 0.034,
                  fontWeight: FontWeight.w700,
                  color: isExpired
                      ? const Color(0xFFE53935)
                      : const Color(0xFF1a2332),
                  height: 1.1,
                ),
              ),
              SizedBox(height: screenHeight * 0.004),
              Text(spf, style: AppTheme.bodySecondary),
            ],
          ),
          SizedBox(height: screenHeight * 0.014),

          // ── Progress bar ─────────────────────────────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: widget.uvData != null ? _progress : 0,
              backgroundColor: const Color(0xFFF0F0F0),
              valueColor: AlwaysStoppedAnimation<Color>(_progressColor),
              minHeight: screenHeight * 0.007,
            ),
          ),
          SizedBox(height: screenHeight * 0.006),

          // ── Time labels under bar ────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Now',
                style: TextStyle(
                  fontSize: screenHeight * 0.012,
                  color: const Color(0xFFAAAAAA),
                ),
              ),
              Text(
                widget.uvData != null
                    ? '${widget.uvData!.reapplyMinutes >= 60 ? '${widget.uvData!.reapplyMinutes ~/ 60}h' : '${widget.uvData!.reapplyMinutes}m'} total'
                    : '',
                style: TextStyle(
                  fontSize: screenHeight * 0.012,
                  color: const Color(0xFFAAAAAA),
                ),
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.018),

          // ── Full width button ────────────────────────────────
          GestureDetector(
            onTap: () {
              setState(() => _secondsRemaining = _totalSeconds);
              widget.onReapplied?.call();
            },
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: screenHeight * 0.016),
              decoration: BoxDecoration(
                color: isExpired ? const Color(0xFFE53935) : AppTheme.ctaGreen,
                borderRadius: BorderRadius.circular(screenHeight * 0.016),
              ),
              child: Center(
                child: Text(
                  isExpired ? 'Reapply now!' : 'Mark as reapplied',
                  style: TextStyle(
                    fontSize: screenHeight * 0.018,
                    fontWeight: FontWeight.w600,
                    color: isExpired ? Colors.white : AppTheme.ctaGreenText,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
