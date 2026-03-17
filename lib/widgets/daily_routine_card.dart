import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/preferences_service.dart';

class DailyRoutineCard extends StatefulWidget {
  final bool isDark;
  const DailyRoutineCard({super.key, required this.isDark});

  @override
  State<DailyRoutineCard> createState() => _DailyRoutineCardState();
}

class _DailyRoutineCardState extends State<DailyRoutineCard> {
  int _spf = 30;

  final List<bool> _checked = [false, false, false, false];

  static const List<String> _labels = [
    'Face Sunscreen',
    'Body Sunscreen',
    'Lip Balm SPF',
    'Hand Cream SPF',
  ];

  @override
  void initState() {
    super.initState();
    _loadSpf();
  }

  Future<void> _loadSpf() async {
    final prefs = await PreferencesService.loadPreferences();
    if (mounted) setState(() => _spf = prefs.spf);
  }

  int get _doneCount => _checked.where((c) => c).length;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: AppTheme.cardDecoration(widget.isDark),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('DAILY ROUTINE', style: AppTheme.labelSmall(widget.isDark)),
              Text('$_doneCount of 4 done', style: TextStyle(
                  fontSize: 9, color: AppTheme.brandGreen(widget.isDark),
                  fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 11),
            ...List.generate(4, (i) => Padding(
              padding: EdgeInsets.only(bottom: i < 3 ? 8.0 : 0),
              child: GestureDetector(
                onTap: () => setState(() => _checked[i] = !_checked[i]),
                child: Row(children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 19, height: 19,
                    decoration: BoxDecoration(
                      color: _checked[i]
                          ? const Color(0xFF1a5c35)
                          : (widget.isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.07)),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: _checked[i]
                        ? const Icon(Icons.check_rounded, size: 12, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 9),
                  Text(
                    '${_labels[i]} SPF $_spf',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: _checked[i] ? FontWeight.w400 : FontWeight.w500,
                      color: _checked[i]
                          ? AppTheme.textMuted(widget.isDark)
                          : AppTheme.textPrimary(widget.isDark),
                      decoration: _checked[i] ? TextDecoration.lineThrough : null,
                      decorationColor: AppTheme.textMuted(widget.isDark),
                    ),
                  ),
                ]),
              ),
            )),
          ]),
        ),
      ),
    );
  }
}