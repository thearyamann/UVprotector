import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SplashScreen extends StatefulWidget {
  final Widget nextScreen;

  const SplashScreen({super.key, required this.nextScreen});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _glow;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _backgroundPulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );

    _glow = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 58,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 0.35,
        ).chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 42,
      ),
    ]).animate(_controller);

    _logoScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.9,
          end: 1.03,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 65,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.03,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 35,
      ),
    ]).animate(_controller);

    _logoOpacity = Tween<double>(begin: 0.28, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _backgroundPulse = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeInOut),
      ),
    );

    _playAndContinue();
  }

  Future<void> _playAndContinue() async {
    await _controller.forward();
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (_, _, _) => widget.nextScreen,
        transitionDuration: const Duration(milliseconds: 500),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: child,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final logoWidth = screenWidth * 0.52;

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final glowValue = _glow.value;
          final logoTint = Color.lerp(
            const Color(0xFFA8A8A8),
            Colors.white,
            _logoOpacity.value,
          )!;

          return Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.04),
                    radius: 0.82,
                    colors: [
                      Color.lerp(
                        const Color(0xFF000000),
                        const Color(0xFF050505),
                        _backgroundPulse.value * 0.18,
                      )!,
                      const Color(0xFF000000),
                      const Color(0xFF000000),
                    ],
                    stops: const [0.0, 0.42, 1.0],
                  ),
                ),
              ),
              Center(
                child: Transform.scale(
                  scale: _logoScale.value,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Opacity(
                        opacity: glowValue * 0.45,
                        child: Transform.scale(
                          scale: 1 + (glowValue * 0.03),
                          child: ImageFiltered(
                            imageFilter: ImageFilter.blur(
                              sigmaX: 14 * glowValue,
                              sigmaY: 14 * glowValue,
                            ),
                            child: ColorFiltered(
                              colorFilter: const ColorFilter.mode(
                                Colors.white,
                                BlendMode.srcATop,
                              ),
                              child: SvgPicture.asset(
                                'assets/images/logo.svg',
                                width: logoWidth,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: logoWidth * 0.9,
                        height: logoWidth * 0.34,
                        decoration: BoxDecoration(
                          shape: BoxShape.rectangle,
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withValues(
                                alpha: 0.012 + (glowValue * 0.02),
                              ),
                              blurRadius: 16 * glowValue,
                              spreadRadius: 1.5 * glowValue,
                            ),
                          ],
                        ),
                      ),
                      Opacity(
                        opacity: _logoOpacity.value,
                        child: ColorFiltered(
                          colorFilter: ColorFilter.mode(
                            logoTint,
                            BlendMode.srcATop,
                          ),
                          child: SvgPicture.asset(
                            'assets/images/logo.svg',
                            width: logoWidth,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
