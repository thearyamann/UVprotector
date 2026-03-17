import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SkeletonBox extends StatefulWidget {
  final double width;
  final double height;
  final double radius;
  final bool isDark;

  const SkeletonBox({
    super.key,
    required this.width,
    required this.height,
    required this.isDark,
    this.radius = 8,
  });

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.radius),
          color: Color.lerp(
            AppTheme.skeletonBase(widget.isDark),
            AppTheme.skeletonShimmer(widget.isDark),
            _anim.value,
          ),
        ),
      ),
    );
  }
}

class SkeletonHomeScreen extends StatelessWidget {
  final bool isDark;
  const SkeletonHomeScreen({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final sw  = MediaQuery.of(context).size.width;
    final sh  = MediaQuery.of(context).size.height;
    final gap = sh * 0.012;
    final pad = sw * 0.044;
    final cardW = (sw - pad * 2 - sw * 0.026) / 2;

    Widget sb(double w, double h, {double r = 8}) =>
        SkeletonBox(width: w, height: h, radius: r, isDark: isDark);

    Widget card({Widget? child}) => ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(13),
        decoration: AppTheme.cardDecoration(isDark),
        child: child,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: gap * 1.3),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: card(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  sb(56, 9), const SizedBox(height: 9),
                  sb(34, 34, r: 6), const SizedBox(height: 7),
                  sb(42, 11, r: 4), const SizedBox(height: 10),
                  sb(cardW - 26, 3, r: 2), const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [sb(26, 8, r: 3), sb(52, 8, r: 3)]),
                ],
              ))),
              SizedBox(width: sw * 0.026),
              Expanded(child: card(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  sb(60, 9), const SizedBox(height: 9),
                  sb(38, 30, r: 6), const SizedBox(height: 6),
                  sb(66, 10, r: 4), const Spacer(),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [sb(26, 8, r: 3), sb(26, 8, r: 3)]),
                ],
              ))),
            ],
          ),
        ),
        SizedBox(height: gap),
        card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          sb(110, 9), const SizedBox(height: 11),
          sb(150, 14, r: 5), const SizedBox(height: 5),
          sb(180, 10, r: 4), const SizedBox(height: 14),
          sb(sw - pad * 2 - 26, 40, r: 12),
        ])),
        SizedBox(height: gap),
        IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Expanded(child: card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              sb(60, 9), const SizedBox(height: 9),
              sb(42, 24, r: 6), const SizedBox(height: 7),
              sb(50, 10, r: 4),
            ]))),
            SizedBox(width: sw * 0.026),
            Expanded(child: card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              sb(64, 9), const SizedBox(height: 9),
              sb(50, 18, r: 5), const SizedBox(height: 7),
              sb(76, 10, r: 4), const SizedBox(height: 5),
              sb(68, 8, r: 3),
            ]))),
          ]),
        ),
        SizedBox(height: gap),
        card(child: Row(children: [
          SkeletonBox(width: 34, height: 34, radius: 9, isDark: isDark),
          const SizedBox(width: 11),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            sb(sw * 0.40, 12, r: 4), const SizedBox(height: 5),
            sb(sw * 0.26, 9, r: 4),
          ])),
        ])),
        SizedBox(height: gap),
        card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          sb(90, 9), const SizedBox(height: 10),
          ...List.generate(4, (i) => Padding(
            padding: EdgeInsets.only(bottom: i < 3 ? 8.0 : 0),
            child: Row(children: [
              SkeletonBox(width: 18, height: 18, radius: 5, isDark: isDark),
              const SizedBox(width: 9),
              sb(sw * 0.35, 10, r: 4),
            ]),
          )),
        ])),
      ],
    );
  }
}