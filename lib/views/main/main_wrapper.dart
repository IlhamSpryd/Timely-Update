import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timely/views/Settings%20Page/settings_page.dart';
import 'package:timely/views/main/history_page.dart';
import 'package:timely/views/main/home_page.dart';
import 'package:timely/views/main/stats.dart';

class MainWrapper extends StatefulWidget {
  final void Function(ThemeMode)? updateTheme;

  const MainWrapper({super.key, this.updateTheme});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _currentIndex = 0;
  PageController? _pageController;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      ModernHomePage(showSnackBar: (msg) => _showSnackBar(msg)),
      const HistoryPage(),
      const StatisticsPage(),
      SettingsPage(updateTheme: widget.updateTheme),
    ];
    _loadAndSetInitialPage();
  }

  Future<void> _loadAndSetInitialPage() async {
    final prefs = await SharedPreferences.getInstance();
    final lastIndex = prefs.getInt('lastPageIndex') ?? 0;

    if (mounted) {
      setState(() {
        _currentIndex = lastIndex;
        _pageController = PageController(initialPage: _currentIndex);
      });
    }
  }

  Future<void> _saveCurrentIndex(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('lastPageIndex', index);
  }

  void _showSnackBar(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  void _onNavbarTap(int index) {
    HapticFeedback.lightImpact();
    _pageController?.animateToPage(
      index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
    _saveCurrentIndex(index);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final scaffoldBackgroundColor =
        isDarkMode ? Colors.black : const Color(0xFFF3F4F6);
    final cardBackgroundColor =
        isDarkMode ? const Color(0xFF1C1C1E) : Colors.white;

    if (_pageController == null) {
      return Scaffold(
        backgroundColor: scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator.adaptive()),
      );
    }

    return Scaffold(
      backgroundColor: scaffoldBackgroundColor,
      body: PageView(
        controller: _pageController!,
        physics: const BouncingScrollPhysics(),
        onPageChanged: _onPageChanged,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: cardBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDarkMode ? 0.4 : 0.1),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: GNav(
              selectedIndex: _currentIndex,
              onTabChange: _onNavbarTap,
              rippleColor: theme.colorScheme.primary.withOpacity(0.05),
              hoverColor: theme.colorScheme.primary.withOpacity(0.05),
              haptic: true,
              duration: const Duration(milliseconds: 400),
              gap: 8,
              activeColor: theme.colorScheme.onPrimary,
              iconSize: 24,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: isDarkMode
                  ? Colors.white.withOpacity(0.7)
                  : Colors.black.withOpacity(0.6),
              tabBackgroundColor: theme.colorScheme.primary,
              tabBorderRadius: 16,
              textStyle: GoogleFonts.manrope(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onPrimary,
              ),
              tabs: [
                GButton(icon: Icons.home_rounded, text: 'navbar.home'.tr()),
                GButton(
                  icon: Icons.history_rounded,
                  text: 'navbar.history'.tr(),
                ),
                GButton(
                  icon: Icons.bar_chart_rounded,
                  text: 'navbar.stats'.tr(),
                ),
                GButton(
                  icon: Icons.settings_rounded,
                  text: 'navbar.settings'.tr(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
