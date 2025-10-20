import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timely/views/auth/login_page.dart';
import 'package:timely/views/main/main_wrapper.dart';
import 'package:timely/views/onboarding_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _masterController;
  late AnimationController _particleController;
  late AnimationController _glowController;

  // Letter animations
  late Animation<Offset> _tJumpAnimation;
  late Animation<double> _tScaleXAnimation;
  late Animation<double> _tScaleYAnimation;
  late Animation<double> _tRotateAnimation;
  late Animation<double> _tOpacityAnimation;

  // Individual letter animations for "imely"
  late List<Animation<double>> _letterScaleAnimations;
  late List<Animation<double>> _letterOpacityAnimations;
  late List<Animation<Offset>> _letterPositionAnimations;
  late List<Animation<double>> _letterRotationAnimations;

  // Effects
  late Animation<double> _impactWaveAnimation;
  late Animation<double> _impactWave2Animation;
  late Animation<double> _impactWave3Animation;
  late Animation<double> _cameraShakeAnimation;
  late Animation<double> _flashAnimation;
  late Animation<double> _dustParticleAnimation;

  // Slogan and UI elements
  late Animation<double> _sloganFadeInAnimation;
  late Animation<Offset> _sloganSlideAnimation;
  late Animation<double> _sloganScaleAnimation;

  // Background effects
  late Animation<double> _backgroundPulseAnimation;

  bool _hasNavigated = false;
  final List<Particle> _particles = [];

  @override
  void initState() {
    super.initState();
    _initializeParticles();
    _initializeAnimations();
    _checkUserState();
  }

  void _initializeParticles() {
    final random = math.Random();
    for (int i = 0; i < 20; i++) {
      _particles.add(Particle(
        angle: random.nextDouble() * 2 * math.pi,
        speed: 50 + random.nextDouble() * 100,
        size: 2 + random.nextDouble() * 4,
        life: 0.5 + random.nextDouble() * 0.5,
      ));
    }
  }

  void _initializeAnimations() {
    _masterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    );

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    // === T LETTER COMPLEX ANIMATION ===

    // T opacity fade in
    _tOpacityAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 10),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 90),
    ]).animate(_masterController);

    // T Jump with bezier-like curve
    _tJumpAnimation = TweenSequence<Offset>([
      // Initial anticipation - slight crouch
      TweenSequenceItem(
        tween: Tween(begin: Offset.zero, end: const Offset(0, 0.1))
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 8,
      ),
      // Launch upward
      TweenSequenceItem(
        tween: Tween(begin: const Offset(0, 0.1), end: const Offset(0, -3.5))
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 15,
      ),
      // Peak hang time
      TweenSequenceItem(
        tween: ConstantTween(const Offset(0, -3.5)),
        weight: 5,
      ),
      // Fast fall with acceleration
      TweenSequenceItem(
        tween: Tween(begin: const Offset(0, -3.5), end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 20,
      ),
      // Settle
      TweenSequenceItem(
        tween: ConstantTween(Offset.zero),
        weight: 52,
      ),
    ]).animate(_masterController);

    // T Scale X (width) - squash and stretch
    _tScaleXAnimation = TweenSequence<double>([
      // Anticipation - compress
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 5),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.85)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 3,
      ),
      // Launch - stretch tall/thin
      TweenSequenceItem(
        tween: Tween(begin: 0.85, end: 1.15)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 5,
      ),
      // In air - slightly compressed
      TweenSequenceItem(
        tween: Tween(begin: 1.15, end: 0.95)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 10,
      ),
      // Just before impact - thin and tall
      TweenSequenceItem(
        tween: Tween(begin: 0.95, end: 0.7)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 5,
      ),
      // Impact - wide squash
      TweenSequenceItem(
        tween: Tween(begin: 0.7, end: 1.4)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 4,
      ),
      // First bounce - compress
      TweenSequenceItem(
        tween: Tween(begin: 1.4, end: 0.9)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 6,
      ),
      // Second bounce
      TweenSequenceItem(
        tween: Tween(begin: 0.9, end: 1.1)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 5,
      ),
      // Settle with wobble
      TweenSequenceItem(
        tween: Tween(begin: 1.1, end: 0.98)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 5,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.98, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 52,
      ),
    ]).animate(_masterController);

    // T Scale Y (height) - opposite of X for volume conservation
    _tScaleYAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 5),
      // Anticipation - stretch
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.15)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 3,
      ),
      // Launch - compress
      TweenSequenceItem(
        tween: Tween(begin: 1.15, end: 0.85)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 5,
      ),
      // In air - slightly stretched
      TweenSequenceItem(
        tween: Tween(begin: 0.85, end: 1.05)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 10,
      ),
      // Before impact - tall stretch
      TweenSequenceItem(
        tween: Tween(begin: 1.05, end: 1.3)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 5,
      ),
      // Impact - squash flat
      TweenSequenceItem(
        tween: Tween(begin: 1.3, end: 0.5)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 4,
      ),
      // First bounce - stretch
      TweenSequenceItem(
        tween: Tween(begin: 0.5, end: 1.15)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 6,
      ),
      // Second bounce - slight squash
      TweenSequenceItem(
        tween: Tween(begin: 1.15, end: 0.95)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 5,
      ),
      // Settle
      TweenSequenceItem(
        tween: Tween(begin: 0.95, end: 1.02)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 5,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.02, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 52,
      ),
    ]).animate(_masterController);

    // T Rotation wobble
    _tRotateAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 40),
      // Impact rotation
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 0.12),
        weight: 4,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.12, end: -0.08),
        weight: 6,
      ),
      TweenSequenceItem(
        tween: Tween(begin: -0.08, end: 0.04),
        weight: 6,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.04, end: -0.02),
        weight: 5,
      ),
      TweenSequenceItem(
        tween: Tween(begin: -0.02, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 39,
      ),
    ]).animate(_masterController);

    // === INDIVIDUAL LETTER ANIMATIONS FOR "imely" ===
    _letterScaleAnimations = [];
    _letterOpacityAnimations = [];
    _letterPositionAnimations = [];
    _letterRotationAnimations = [];

    final letters = ['i', 'm', 'e', 'l', 'y'];
    for (int i = 0; i < letters.length; i++) {
      final delay = 0.02 + (i * 0.015); // Cascading effect
      const impactDelay = 0.48;

      // Each letter fades in
      _letterOpacityAnimations.add(
        TweenSequence<double>([
          TweenSequenceItem(tween: ConstantTween(0.0), weight: (delay * 100)),
          TweenSequenceItem(
            tween: Tween(begin: 0.0, end: 1.0)
                .chain(CurveTween(curve: Curves.easeIn)),
            weight: 10,
          ),
          TweenSequenceItem(
              tween: ConstantTween(1.0), weight: (90 - delay * 100)),
        ]).animate(_masterController),
      );

      // Scale animation with wave effect
      _letterScaleAnimations.add(
        TweenSequence<double>([
          TweenSequenceItem(
              tween: ConstantTween(1.0), weight: (impactDelay * 100)),
          // Anticipation
          TweenSequenceItem(
            tween: Tween(begin: 1.0, end: 0.85),
            weight: 3,
          ),
          // Pop up from T impact
          TweenSequenceItem(
            tween: Tween(begin: 0.85, end: 1.3)
                .chain(CurveTween(curve: Curves.easeOut)),
            weight: 5,
          ),
          // Settle down
          TweenSequenceItem(
            tween: Tween(begin: 1.3, end: 0.95),
            weight: 4,
          ),
          // Secondary bounce
          TweenSequenceItem(
            tween: Tween(begin: 0.95, end: 1.08),
            weight: 4,
          ),
          // Final settle
          TweenSequenceItem(
            tween: Tween(begin: 1.08, end: 1.0)
                .chain(CurveTween(curve: Curves.elasticOut)),
            weight: (84 - impactDelay * 100),
          ),
        ]).animate(_masterController),
      );

      // Position - bounce up from impact
      _letterPositionAnimations.add(
        TweenSequence<Offset>([
          TweenSequenceItem(
              tween: ConstantTween(Offset.zero),
              weight: (impactDelay * 100 + i * 1).toDouble()),
          // Jump up
          TweenSequenceItem(
            tween: Tween(begin: Offset.zero, end: Offset(0, -0.15 - i * 0.02))
                .chain(CurveTween(curve: Curves.easeOut)),
            weight: 8,
          ),
          // Fall down with bounce
          TweenSequenceItem(
            tween: Tween(begin: Offset(0, -0.15 - i * 0.02), end: Offset.zero)
                .chain(CurveTween(curve: Curves.bounceOut)),
            weight: (92 - impactDelay * 100 - i * 1).toDouble(),
          ),
        ]).animate(_masterController),
      );

      // Rotation wobble
      _letterRotationAnimations.add(
        TweenSequence<double>([
          TweenSequenceItem(
              tween: ConstantTween(0.0), weight: (impactDelay * 100 + i * 1.5)),
          TweenSequenceItem(
            tween: Tween(begin: 0.0, end: (i.isEven ? 0.1 : -0.1)),
            weight: 6,
          ),
          TweenSequenceItem(
            tween: Tween(
                begin: (i.isEven ? 0.1 : -0.1), end: (i.isEven ? -0.05 : 0.05)),
            weight: 6,
          ),
          TweenSequenceItem(
            tween: Tween(begin: (i.isEven ? -0.05 : 0.05), end: 0.0)
                .chain(CurveTween(curve: Curves.elasticOut)),
            weight: (88 - impactDelay * 100 - i * 1.5),
          ),
        ]).animate(_masterController),
      );
    }

    // === IMPACT EFFECTS ===

    // Camera shake
    _cameraShakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 48),
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 8.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: -6.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -6.0, end: 4.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 4.0, end: -2.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -2.0, end: 0.0), weight: 1),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 47),
    ]).animate(_masterController);

    // Flash on impact
    _flashAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 48),
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.3), weight: 1),
      TweenSequenceItem(
        tween: Tween(begin: 0.3, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 8,
      ),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 43),
    ]).animate(_masterController);

    // Multiple impact waves
    _impactWaveAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 48),
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 20,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 32),
    ]).animate(_masterController);

    _impactWave2Animation = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 50),
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 18,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 32),
    ]).animate(_masterController);

    _impactWave3Animation = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 52),
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 16,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 32),
    ]).animate(_masterController);

    // Dust particle effect
    _dustParticleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 48),
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 25,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 27),
    ]).animate(_masterController);

    // Background pulse
    _backgroundPulseAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 48),
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 5,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 10,
      ),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 37),
    ]).animate(_masterController);

    // === SLOGAN ANIMATIONS ===

    _sloganFadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.72, 0.92, curve: Curves.easeOut),
      ),
    );

    _sloganSlideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.8),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.72, 0.92, curve: Curves.easeOutCubic),
      ),
    );

    _sloganScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.72, 0.92, curve: Curves.easeOutBack),
      ),
    );

    _masterController.forward();

    // Trigger particle animation on impact
    _masterController.addListener(() {
      if (_masterController.value >= 0.48 && _masterController.value <= 0.49) {
        _particleController.forward(from: 0);
      }
    });
  }

  Future<void> _checkUserState() async {
    await Future.delayed(const Duration(milliseconds: 4200));

    if (!mounted || _hasNavigated) return;
    _hasNavigated = true;

    final prefs = await SharedPreferences.getInstance();
    final bool hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;
    final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    Widget destination;
    if (!hasSeenOnboarding) {
      destination = const Onboarding();
    } else if (isLoggedIn) {
      destination = const MainWrapper();
    } else {
      destination = const LoginPage();
    }

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => destination,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  void dispose() {
    _masterController.dispose();
    _particleController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final backgroundColor = isDark ? const Color(0xFF121212) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final secondaryTextColor =
        isDark ? Colors.white.withOpacity(0.7) : Colors.black.withOpacity(0.7);
    final accentColor =
        isDark ? const Color(0xFF6366F1) : const Color(0xFF4F46E5);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: AnimatedBuilder(
        animation: Listenable.merge(
            [_masterController, _particleController, _glowController]),
        builder: (context, child) {
          return Stack(
            children: [
              // Background pulse effect
              if (_backgroundPulseAnimation.value > 0)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.center,
                        radius: 1.0,
                        colors: [
                          accentColor.withOpacity(
                              0.15 * _backgroundPulseAnimation.value),
                          backgroundColor,
                        ],
                      ),
                    ),
                  ),
                ),

              // Impact waves (multiple layers)
              if (_impactWaveAnimation.value > 0) ...[
                _buildImpactWave(
                  _impactWaveAnimation.value,
                  textColor,
                  scale: 1.5,
                  opacity: 0.4,
                ),
                _buildImpactWave(
                  _impactWave2Animation.value,
                  textColor,
                  scale: 1.8,
                  opacity: 0.25,
                ),
                _buildImpactWave(
                  _impactWave3Animation.value,
                  textColor,
                  scale: 2.1,
                  opacity: 0.15,
                ),
              ],

              // Dust particles
              if (_dustParticleAnimation.value > 0)
                ..._particles.map((particle) => _buildParticle(
                      particle,
                      _particleController.value,
                      textColor,
                    )),

              // Flash effect on impact
              if (_flashAnimation.value > 0)
                Positioned.fill(
                  child: Container(
                    color: Colors.white.withOpacity(_flashAnimation.value),
                  ),
                ),

              // Camera shake effect
              Transform.translate(
                offset: Offset(_cameraShakeAnimation.value, 0),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Main Timely text with complex animations
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          // Glow effect
                          if (_glowController.value > 0.3)
                            Opacity(
                              opacity: 0.3 * (1 - _glowController.value),
                              child: Container(
                                width: 300,
                                height: 150,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: accentColor.withOpacity(0.3),
                                      blurRadius: 60,
                                      spreadRadius: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // The "T" with complex squash and stretch
                              Opacity(
                                opacity: _tOpacityAnimation.value,
                                child: SlideTransition(
                                  position: _tJumpAnimation,
                                  child: Transform.rotate(
                                    angle: _tRotateAnimation.value,
                                    child: Transform(
                                      transform: Matrix4.identity()
                                        ..scale(
                                          _tScaleXAnimation.value,
                                          _tScaleYAnimation.value,
                                        ),
                                      alignment: Alignment.center,
                                      child: ShaderMask(
                                        shaderCallback: (bounds) {
                                          return LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              textColor,
                                              textColor.withOpacity(0.8),
                                            ],
                                          ).createShader(bounds);
                                        },
                                        child: Text(
                                          "T",
                                          style: GoogleFonts.spaceGrotesk(
                                            fontSize: 90,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                            height: 1.0,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // Individual letters of "imely"
                              ...List.generate(5, (index) {
                                final letters = ['i', 'm', 'e', 'l', 'y'];
                                return Opacity(
                                  opacity:
                                      _letterOpacityAnimations[index].value,
                                  child: SlideTransition(
                                    position: _letterPositionAnimations[index],
                                    child: Transform.rotate(
                                      angle: _letterRotationAnimations[index]
                                          .value,
                                      child: Transform.scale(
                                        scale:
                                            _letterScaleAnimations[index].value,
                                        child: ShaderMask(
                                          shaderCallback: (bounds) {
                                            return LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [
                                                textColor,
                                                textColor.withOpacity(0.85),
                                              ],
                                            ).createShader(bounds);
                                          },
                                          child: Text(
                                            letters[index],
                                            style: GoogleFonts.spaceGrotesk(
                                              fontSize: 90,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                              height: 1.0,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 30),

                      // Slogan with scale and slide
                      SlideTransition(
                        position: _sloganSlideAnimation,
                        child: Transform.scale(
                          scale: _sloganScaleAnimation.value,
                          child: FadeTransition(
                            opacity: _sloganFadeInAnimation,
                            child: Text(
                              "Professional Attendance System",
                              style: GoogleFonts.manrope(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: secondaryTextColor,
                                letterSpacing: 0.6,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Loading indicator with pulse effect
              Positioned(
                bottom: 100,
                left: 0,
                right: 0,
                child: FadeTransition(
                  opacity: _sloganFadeInAnimation,
                  child: Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer pulse ring
                        AnimatedBuilder(
                          animation: _glowController,
                          builder: (context, child) {
                            return Container(
                              width: 40 + (20 * _glowController.value),
                              height: 40 + (20 * _glowController.value),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: accentColor.withOpacity(
                                    0.3 * (1 - _glowController.value),
                                  ),
                                  width: 2,
                                ),
                              ),
                            );
                          },
                        ),
                        // Inner spinner
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              accentColor.withOpacity(0.8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Footer text with fade in
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: FadeTransition(
                  opacity: _sloganFadeInAnimation,
                  child: Center(
                    child: Text(
                      "Supported by PPKD Jakarta Pusat",
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: secondaryTextColor.withOpacity(0.5),
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildImpactWave(double progress, Color color,
      {required double scale, required double opacity}) {
    if (progress == 0) return const SizedBox.shrink();

    return Center(
      child: Container(
        width: 250 * progress * scale,
        height: 250 * progress * scale,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: color.withOpacity(opacity * (1 - progress)),
            width: 3,
          ),
        ),
      ),
    );
  }

  Widget _buildParticle(Particle particle, double progress, Color color) {
    final distance = particle.speed * progress;
    final x = math.cos(particle.angle) * distance;
    final y = math.sin(particle.angle) * distance;
    final particleOpacity = (1 - progress) * particle.life;

    return Positioned(
      left: MediaQuery.of(context).size.width / 2 + x,
      top: MediaQuery.of(context).size.height / 2 + y,
      child: Opacity(
        opacity: particleOpacity,
        child: Container(
          width: particle.size * (1 - progress * 0.5),
          height: particle.size * (1 - progress * 0.5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.6),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4 * particleOpacity),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Particle {
  final double angle;
  final double speed;
  final double size;
  final double life;

  Particle({
    required this.angle,
    required this.speed,
    required this.size,
    required this.life,
  });
}
