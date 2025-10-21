import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timely/utils/app_theme.dart';
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

  late Animation<double> _logoFadeAnimation;
  late Animation<Offset> _logoSlideAnimation;
  late Animation<double> _logoScaleAnimation;

  late Animation<double> _uiFadeInAnimation;
  late Animation<Offset> _sloganSlideAnimation;

  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();

    _masterController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _checkUserState();
      }
    });

    _masterController.forward();
  }

  void _initializeAnimations() {
    _masterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    final logoCurve = CurvedAnimation(
      parent: _masterController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutQuint),
    );

    _logoFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(logoCurve);
    _logoSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
            .animate(logoCurve);
    _logoScaleAnimation =
        Tween<double>(begin: 0.9, end: 1.0).animate(logoCurve);

    final uiCurve = CurvedAnimation(
      parent: _masterController,
      curve: const Interval(0.4, 0.8, curve: Curves.easeOutQuint),
    );

    _uiFadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(uiCurve);
    _sloganSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero)
            .animate(uiCurve);
  }

  Future<void> _checkUserState() async {
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundColor = AppTheme.getBackgroundColor(context);
    final textColor = AppTheme.getTextPrimaryColor(context);
    final secondaryTextColor = AppTheme.getTextSecondaryColor(context);
    final accentColor = theme.colorScheme.secondary;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: AnimatedBuilder(
        animation: _masterController,
        builder: (context, child) {
          return Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FadeTransition(
                      opacity: _logoFadeAnimation,
                      child: SlideTransition(
                        position: _logoSlideAnimation,
                        child: Transform.scale(
                          scale: _logoScaleAnimation.value,
                          child: Text(
                            "Timely",
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 90,
                              fontWeight: FontWeight.w700,
                              color: textColor,
                              height: 1.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    FadeTransition(
                      opacity: _uiFadeInAnimation,
                      child: SlideTransition(
                        position: _sloganSlideAnimation,
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
                    const SizedBox(height: 50), // Jarak yang diminta
                    FadeTransition(
                      opacity: _uiFadeInAnimation,
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            accentColor.withOpacity(0.8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: 30,
                left: 0,
                right: 0,
                child: FadeTransition(
                  opacity: _uiFadeInAnimation,
                  child: Center(
                    child: Column(
                      children: [
                        Text(
                          "Supported By:",
                          style: GoogleFonts.manrope(
                            fontSize: 10,
                            fontWeight: FontWeight.w400,
                            color: secondaryTextColor.withOpacity(0.5),
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Image.asset(
                          'assets/images/logoppkd.png',
                          height: 28,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "PPKD Jakarta Pusat",
                          style: GoogleFonts.manrope(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: secondaryTextColor.withOpacity(0.5),
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
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
}
