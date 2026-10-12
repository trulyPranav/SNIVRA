import 'dart:math' show pi, sin;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_event.dart';
import '../bloc/splash_bloc.dart';
import '../bloc/splash_event.dart';
import '../bloc/splash_state.dart';

const _kBrandLetters = ['S', 'N', 'I', 'V', 'R', 'A'];

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with TickerProviderStateMixin {
  late final AnimationController _main;
  late final AnimationController _shimmer;
  late final AnimationController _breathe;

  // Phase animations driven by _main (0 → 1 over 2400ms)
  late final Animation<double> _bgFade;
  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _ringExpand;
  late final Animation<double> _tagFade;
  late final Animation<Offset> _tagSlide;
  late final Animation<double> _dotsFade;

  // Per-letter stagger (6 letters)
  late final List<Animation<double>> _letterFade;
  late final List<Animation<double>> _letterSlide;

  // Shimmer line across brand name
  late final Animation<double> _shimmerPos;

  // Breathing pulse on logo ring
  late final Animation<double> _breatheScale;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    _main = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _breathe = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    // ── Phase curves ──

    _bgFade = _curved(0.0, 0.20, Curves.easeOut);

    _logoFade = _curved(0.08, 0.30, Curves.easeOut);
    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _main,
        curve: const Interval(0.08, 0.35, curve: Curves.easeOutBack),
      ),
    );

    _ringExpand = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _main,
        curve: const Interval(0.20, 0.50, curve: Curves.easeOutCubic),
      ),
    );

    // Letter stagger: each letter fades/slides in across 0.35 → 0.72
    const letterStart = 0.35;
    const letterEnd = 0.72;
    const letterSpan = letterEnd - letterStart;
    _letterFade = List.generate(6, (i) {
      final s = letterStart + (i / 6) * letterSpan;
      final e = s + letterSpan * 0.45;
      return _curved(s, e.clamp(0.0, 1.0), Curves.easeOut);
    });
    _letterSlide = List.generate(6, (i) {
      final s = letterStart + (i / 6) * letterSpan;
      final e = s + letterSpan * 0.5;
      return Tween<double>(begin: 18, end: 0).animate(
        CurvedAnimation(
          parent: _main,
          curve: Interval(s, e.clamp(0.0, 1.0), curve: Curves.easeOutCubic),
        ),
      );
    });

    _tagFade = _curved(0.68, 0.85, Curves.easeOut);
    _tagSlide = Tween<Offset>(
      begin: const Offset(0, 0.35),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _main,
        curve: const Interval(0.68, 0.88, curve: Curves.easeOutCubic),
      ),
    );

    _dotsFade = _curved(0.82, 1.0, Curves.easeOut);

    // Shimmer sweep position -1 → 2
    _shimmerPos = Tween<double>(begin: -1.0, end: 2.0).animate(_shimmer);

    // Breathe scale 1.0 → 1.08
    _breatheScale = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _breathe, curve: Curves.easeInOut),
    );

    _main.forward();
    context.read<SplashBloc>().add(const SplashStarted());
  }

  Animation<double> _curved(double start, double end, Curve curve) {
    return Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _main,
        curve: Interval(start, end, curve: curve),
      ),
    );
  }

  @override
  void dispose() {
    _main.dispose();
    _shimmer.dispose();
    _breathe.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final w = mq.size.width;
    final h = mq.size.height;

    return BlocListener<SplashBloc, SplashState>(
      listener: (context, state) {
        if (state is SplashAuthenticated) {
          context.read<AuthBloc>().add(AuthSessionRestored(
                user: state.user,
                accessToken: state.accessToken,
              ));
          final route =
              state.user.isOwnerOrBarber ? '/home' : '/saloon-setup';
          Navigator.of(context).pushReplacementNamed(route);
        } else if (state is SplashUnauthenticated) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
      },
      child: AnimatedBuilder(
        animation: Listenable.merge([_main, _shimmer, _breathe]),
        builder: (context, _) {
          return Scaffold(
            body: Opacity(
              opacity: _bgFade.value,
              child: Container(
                width: double.infinity,
                height: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF060E1A),
                      Color(0xFF0A1628),
                      Color(0xFF0F2847),
                      Color(0xFF1352A5),
                    ],
                    stops: [0.0, 0.35, 0.7, 1.0],
                  ),
                ),
                child: Stack(
                  children: [
                    // Ambient orb — top right
                    Positioned(
                      top: -w * 0.35,
                      right: -w * 0.25,
                      child: Container(
                        width: w * 0.8,
                        height: w * 0.8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              const Color(0xFF1565C0).withAlpha(18),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Ambient orb — bottom left
                    Positioned(
                      bottom: -h * 0.08,
                      left: -w * 0.3,
                      child: Container(
                        width: w * 0.7,
                        height: w * 0.7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.white.withAlpha(6),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),

                    // ── Centered content ──
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Logo with breathing ring
                          _buildLogo(),
                          const SizedBox(height: 48),

                          // Brand letters with shimmer
                          _buildBrandName(),
                          const SizedBox(height: 16),

                          // Tagline
                          SlideTransition(
                            position: _tagSlide,
                            child: Opacity(
                              opacity: _tagFade.value,
                              child: const Text(
                                'Salon Management',
                                style: TextStyle(
                                  color: Color(0x99FFFFFF),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w300,
                                  letterSpacing: 4,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Loading indicator at bottom
                    Positioned(
                      bottom: mq.padding.bottom + 48,
                      left: 0,
                      right: 0,
                      child: Opacity(
                        opacity: _dotsFade.value,
                        child: const _WaveLoader(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLogo() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer breathing ring
        Transform.scale(
          scale: _breatheScale.value,
          child: Opacity(
            opacity: (_ringExpand.value * 0.5).clamp(0.0, 0.5),
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withAlpha(
                    (_ringExpand.value * 40).round().clamp(0, 255),
                  ),
                  width: 1,
                ),
              ),
            ),
          ),
        ),
        // Soft glow behind logo
        Opacity(
          opacity: _logoFade.value,
          child: Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1565C0)
                      .withAlpha((_logoFade.value * 80).round()),
                  blurRadius: 40,
                  spreadRadius: 8,
                ),
              ],
            ),
          ),
        ),
        // Logo image
        Opacity(
          opacity: _logoFade.value,
          child: Transform.scale(
            scale: _logoScale.value,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withAlpha(30),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(40),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset('assets/snivra.png', fit: BoxFit.cover),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBrandName() {
    return SizedBox(
      height: 42,
      child: ShaderMask(
        shaderCallback: (bounds) {
          return LinearGradient(
            begin: Alignment(-1.0 + _shimmerPos.value, 0),
            end: Alignment(-0.5 + _shimmerPos.value, 0),
            colors: const [
              Colors.white,
              Color(0xFFB0D4FF),
              Colors.white,
            ],
            stops: const [0.0, 0.5, 1.0],
          ).createShader(bounds);
        },
        blendMode: BlendMode.srcIn,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(6, (i) {
            return Transform.translate(
              offset: Offset(0, _letterSlide[i].value),
              child: Opacity(
                opacity: _letterFade[i].value,
                child: Text(
                  _kBrandLetters[i],
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 10,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ─── Wave loader ─────────────────────────────────────────────────────────────

class _WaveLoader extends StatefulWidget {
  const _WaveLoader();

  @override
  State<_WaveLoader> createState() => _WaveLoaderState();
}

class _WaveLoaderState extends State<_WaveLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            final phase = _ctrl.value * 2 * pi + (i * pi / 3);
            final y = sin(phase).abs() * 6;
            final alpha = (0.3 + 0.7 * sin(phase).abs()).clamp(0.0, 1.0);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Transform.translate(
                offset: Offset(0, -y),
                child: Opacity(
                  opacity: alpha,
                  child: Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
