import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/uv_data.dart';
import '../theme/app_theme.dart';
import 'skeleton_loader.dart';
import 'pressable.dart';

/// A single routine product with its own label and recommended SPF.
class _RoutineItem {
  final String label;
  final int spf;
  const _RoutineItem(this.label, this.spf);
}

class DailyRoutineCard extends StatefulWidget {
  final bool isDark;
  final UVData? uvData;

  const DailyRoutineCard({
    super.key,
    required this.isDark,
    this.uvData,
  });

  @override
  State<DailyRoutineCard> createState() => _DailyRoutineCardState();
}

class _DailyRoutineCardState extends State<DailyRoutineCard> {
  static const _keyPrefix = 'routine_';
  static const _keyDate = 'routine_date';

  static const List<_RoutineItem> _items = [
    _RoutineItem('Face Sunscreen', 50),
    _RoutineItem('Body Sunscreen', 30),
    _RoutineItem('Lip Balm', 20),
    _RoutineItem('Hand Cream', 30),
  ];

  final List<bool> _checked = [false, false, false, false];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  /// Load checked state from SharedPreferences.
  /// If the saved date is not today, auto-reset all items.
  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayString();
    final savedDate = prefs.getString(_keyDate) ?? '';

    if (savedDate != today) {
      // New day → reset all
      for (var i = 0; i < _items.length; i++) {
        await prefs.setBool('$_keyPrefix$i', false);
      }
      await prefs.setString(_keyDate, today);
    }

    for (var i = 0; i < _items.length; i++) {
      _checked[i] = prefs.getBool('$_keyPrefix$i') ?? false;
    }

    if (mounted) setState(() => _loaded = true);
  }

  Future<void> _toggle(int index) async {
    setState(() => _checked[index] = !_checked[index]);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_keyPrefix$index', _checked[index]);
  }

  Future<void> _resetAll() async {
    setState(() {
      for (var i = 0; i < _checked.length; i++) {
        _checked[i] = false;
      }
    });
    final prefs = await SharedPreferences.getInstance();
    for (var i = 0; i < _items.length; i++) {
      await prefs.setBool('$_keyPrefix$i', false);
    }
  }

  String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  int get _doneCount => _checked.where((c) => c).length;

  /// Adjust recommended SPF based on UV index.
  int _adjustedSpf(int baseSpf) {
    final uv = widget.uvData?.uvIndex ?? 0;
    if (uv >= 8) return (baseSpf < 50) ? 50 : baseSpf;
    if (uv >= 6) return (baseSpf < 30) ? 30 : baseSpf;
    return baseSpf;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          width: double.infinity,
          padding: EdgeInsets.all(sw * 0.044),
          decoration: AppTheme.cardDecoration(isDark),
          child: !_loaded
              ? _buildLoading(sh, isDark)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(children: [
                          Icon(Icons.checklist_rounded,
                              size: sh * 0.015,
                              color: AppTheme.textLabel(isDark)),
                          SizedBox(width: sw * 0.012),
                          Text('DAILY ROUTINE',
                              style: AppTheme.labelSmall(isDark)),
                        ]),
                        Text(
                          '$_doneCount of ${_items.length} done',
                          style: TextStyle(
                            fontSize: sh * 0.012,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.ctaText(isDark),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: sh * 0.014),

                    // ── Checklist items ──
                    ...List.generate(_items.length, (i) {
                      final item = _items[i];
                      final spf = _adjustedSpf(item.spf);
                      final checked = _checked[i];

                      return Padding(
                        padding: EdgeInsets.only(
                            bottom: i < _items.length - 1 ? sh * 0.01 : 0),
                        child: GestureDetector(
                          onTap: () => _toggle(i),
                          behavior: HitTestBehavior.opaque,
                          child: Row(
                            children: [
                              // Animated checkbox
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeOutBack,
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: checked
                                      ? const Color(0xFF1a5c35)
                                      : (isDark
                                          ? Colors.white
                                              .withValues(alpha: 0.08)
                                          : Colors.black
                                              .withValues(alpha: 0.06)),
                                  borderRadius: BorderRadius.circular(7),
                                  border: checked
                                      ? null
                                      : Border.all(
                                          color: isDark
                                              ? Colors.white
                                                  .withValues(alpha: 0.15)
                                              : Colors.black
                                                  .withValues(alpha: 0.1),
                                          width: 1,
                                        ),
                                ),
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  child: checked
                                      ? const Icon(Icons.check_rounded,
                                          key: ValueKey('check'),
                                          size: 14,
                                          color: Colors.white)
                                      : const SizedBox.shrink(
                                          key: ValueKey('empty')),
                                ),
                              ),

                              SizedBox(width: sw * 0.03),

                              // Product label
                              Expanded(
                                child: AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 250),
                                  style: TextStyle(
                                    fontSize: sh * 0.016,
                                    fontWeight: checked
                                        ? FontWeight.w400
                                        : FontWeight.w500,
                                    color: checked
                                        ? AppTheme.textMuted(isDark)
                                        : AppTheme.textPrimary(isDark),
                                    decoration: checked
                                        ? TextDecoration.lineThrough
                                        : TextDecoration.none,
                                    decorationColor:
                                        AppTheme.textMuted(isDark),
                                  ),
                                  child: Text('${item.label} SPF $spf'),
                                ),
                              ),

                              // SPF badge
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: checked
                                      ? const Color(0xFF15803D)
                                          .withValues(alpha: isDark ? 0.15 : 0.08)
                                      : AppTheme.brandBlue(isDark)
                                          .withValues(alpha: isDark ? 0.12 : 0.07),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'SPF $spf',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: checked
                                        ? const Color(0xFF15803D)
                                        : AppTheme.brandBlue(isDark),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),

                    SizedBox(height: sh * 0.016),

                    // ── Bottom row: progress bar + reset ──
                    // Mini progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: _doneCount / _items.length,
                        backgroundColor: AppTheme.progressTrack(isDark),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF15803D)),
                        minHeight: sh * 0.003,
                      ),
                    ),

                    SizedBox(height: sh * 0.012),

                    // Reset All button (centered)
                    if (_doneCount > 0)
                      Center(
                        child: Pressable(
                          onTap: _resetAll,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            padding: EdgeInsets.symmetric(
                              horizontal: sw * 0.05,
                              vertical: sh * 0.007,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDC2626)
                                  .withValues(alpha: isDark ? 0.12 : 0.07),
                              border: Border.all(
                                color: const Color(0xFFDC2626)
                                    .withValues(alpha: 0.15),
                                width: 0.5,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Reset All',
                              style: TextStyle(
                                fontSize: sh * 0.013,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFDC2626),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildLoading(double sh, bool isDark) {
    return SkeletonDailyRoutine(isDark: isDark);
  }
}