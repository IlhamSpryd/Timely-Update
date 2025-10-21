import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timely/views/auth/login_page.dart';

class Onboarding extends StatefulWidget {
  const Onboarding({super.key});

  @override
  State<Onboarding> createState() => _OnboardingState();
}

class _OnboardingState extends State<Onboarding> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final Color backgroundColor = const Color(0xFF0D0D0D);
  final List<OnboardingPageData> _pages = [
    OnboardingPageData(
      title: "Selamat Datang di Timely",
      lottieAsset: "assets/images/Checking Phone.json",
      accentColor: const Color(0xFFFBBF24),
    ),
    OnboardingPageData(
      title: "Absensi Akurat Berbasis Lokasi",
      lottieAsset: "assets/images/GPS Navigation.json",
      accentColor: const Color(0xFF3B82F6),
    ),
    OnboardingPageData(
      title: "Laporan Kehadiran Otomatis",
      lottieAsset: "assets/images/onboard3.json",
      accentColor: const Color(0xFF6366F1),
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
    HapticFeedback.selectionClick();
  }

  void _navigate() async {
    HapticFeedback.mediumImpact();

    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('hasSeenOnboarding', true);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                physics: const BouncingScrollPhysics(),
                onPageChanged: _onPageChanged,
                itemBuilder: (context, index) {
                  return _buildPageContent(_pages[index]);
                },
              ),
            ),
            _buildBottomNavigation(),
          ],
        ),
      ),
    );
  }

  Widget _buildPageContent(OnboardingPageData pageData) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 5,
            child: Lottie.asset(
              pageData.lottieAsset,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: Icon(
                    Icons.image_not_supported,
                    color: Colors.white24,
                    size: 100,
                  ),
                );
              },
            ),
          ),
          const Spacer(flex: 1),
          Expanded(
            flex: 4,
            child: Text(
              pageData.title,
              textAlign: TextAlign.left,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 24, 40, 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: List.generate(_pages.length, (index) {
              final isActive = _currentPage == index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.only(right: 8),
                width: isActive ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color:
                      isActive ? Colors.white : Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
          GestureDetector(
            onTap: _navigate,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.black,
                size: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingPageData {
  final String title;
  final String lottieAsset;
  final Color accentColor;

  OnboardingPageData({
    required this.title,
    required this.lottieAsset,
    required this.accentColor,
  });
}
