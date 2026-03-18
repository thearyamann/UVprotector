import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SkeletonBox extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return _ShimmerBox(
      width: width,
      height: height,
      radius: radius,
      isDark: isDark,
    );
  }
}

class _ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final double radius;
  final bool isDark;

  const _ShimmerBox({
    required this.width,
    required this.height,
    required this.isDark,
    this.radius = 8,
  });

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
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
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) => Container(
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
        _ShimmerBox(width: w, height: h, radius: r, isDark: isDark);

    Widget card({Widget? child, double? h}) => Container(
      height: h,
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.cardDecoration(isDark),
      child: child,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: gap * 1.3),

        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      sb(56, 10),
                      const SizedBox(height: 10),
                      sb(36, 36, r: 6),
                      const SizedBox(height: 8),
                      sb(42, 12, r: 4),
                      const SizedBox(height: 12),
                      sb(cardW - 28, 4, r: 2),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [sb(28, 9, r: 3), sb(56, 9, r: 3)],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: sw * 0.026),
              Expanded(
                child: card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      sb(60, 10),
                      const SizedBox(height: 10),
                      sb(40, 32, r: 6),
                      const SizedBox(height: 6),
                      sb(70, 11, r: 4),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [sb(28, 9, r: 3), sb(28, 9, r: 3)],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: gap),

        card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              sb(110, 10),
              const SizedBox(height: 12),
              sb(140, 16, r: 5),
              const SizedBox(height: 6),
              sb(190, 11, r: 4),
              const SizedBox(height: 16),
              sb(sw - pad * 2 - 28, 44, r: 13),
            ],
          ),
        ),

        SizedBox(height: gap),

        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      sb(60, 10),
                      const SizedBox(height: 10),
                      sb(44, 26, r: 6),
                      const SizedBox(height: 8),
                      sb(52, 11, r: 4),
                    ],
                  ),
                ),
              ),
              SizedBox(width: sw * 0.026),
              Expanded(
                child: card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      sb(66, 10),
                      const SizedBox(height: 10),
                      sb(52, 20, r: 6),
                      const SizedBox(height: 8),
                      sb(80, 11, r: 4),
                      const SizedBox(height: 6),
                      sb(70, 9, r: 3),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: gap),

        SkeletonDailyRoutine(isDark: isDark),

        SizedBox(height: gap),

        card(
          child: Row(
            children: [
              _ShimmerBox(width: 36, height: 36, radius: 10, isDark: isDark),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    sb(sw * 0.42, 13, r: 4),
                    const SizedBox(height: 6),
                    sb(sw * 0.28, 10, r: 4),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class SkeletonDailyRoutine extends StatelessWidget {
  final bool isDark;

  const SkeletonDailyRoutine({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final pad = sw * 0.044;

    Widget sb(double w, double h, {double r = 8}) =>
        SkeletonBox(width: w, height: h, radius: r, isDark: isDark);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(pad),
      decoration: AppTheme.cardDecoration(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                sb(14, 14, r: 4),
                const SizedBox(width: 6),
                sb(80, 10),
              ]),
              sb(60, 10),
            ],
          ),
          const SizedBox(height: 14),
          ...List.generate(4, (i) {
            final widths = [0.45, 0.35, 0.5, 0.4];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  sb(22, 22, r: 7),
                  const SizedBox(width: 12),
                  sb(sw * widths[i], 14, r: 4),
                  const Spacer(),
                  sb(44, 16, r: 8),
                ],
              ),
            );
          }),
          const SizedBox(height: 10),
          sb(double.infinity, 3, r: 2),
        ],
      ),
    );
  }
}