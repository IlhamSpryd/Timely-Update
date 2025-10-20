// lib/views/main/settings_search_page.dart

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timely/models/getprofile_model.dart';
import 'package:timely/utils/app_transitions.dart';
import 'package:timely/views/Settings%20Page/change_password_page.dart';
import 'package:timely/views/Settings%20Page/edit_profile_page.dart';
import 'package:timely/views/Settings%20Page/privacy_policy_page.dart';
import 'package:timely/views/Settings%20Page/terms_of_service_page.dart';

class SettingItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Widget? navigationTarget;

  SettingItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    this.navigationTarget,
  });
}

class SettingsSearchPage extends StatefulWidget {
  const SettingsSearchPage({super.key});

  @override
  State<SettingsSearchPage> createState() => _SettingsSearchPageState();
}

class _SettingsSearchPageState extends State<SettingsSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  List<SettingItem> _allSettings = [];
  List<SettingItem> _filteredSettings = [];
  List<String> _recentSearches = [];

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
    _searchController.addListener(() {
      _filterSettings(_searchController.text);
    });
  }

  // Use didChangeDependencies to safely access context and translations
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initializeSettings();
  }

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _recentSearches = prefs.getStringList('recent_searches') ?? [];
    });
  }

  Future<void> _addSearchTerm(String term) async {
    if (term.isEmpty || _recentSearches.contains(term)) return;

    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _recentSearches.remove(term);
      _recentSearches.insert(0, term);
      if (_recentSearches.length > 5) {
        _recentSearches = _recentSearches.sublist(0, 5);
      }
    });
    await prefs.setStringList('recent_searches', _recentSearches);
  }

  Future<void> _removeSearchTerm(String term) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _recentSearches.remove(term);
    });
    await prefs.setStringList('recent_searches', _recentSearches);
  }

  Future<void> _clearAllSearches() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _recentSearches.clear();
    });
    await prefs.setStringList('recent_searches', []);
    HapticFeedback.mediumImpact();
  }

  void _initializeSettings() {
    // Ensure that ModalRoute.of(context) is not null before accessing its settings
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args == null || args is! Data) {
      // Handle the case where arguments are not passed correctly
      // For instance, pop the page or show an error
      if (mounted) {
        // Schedule a pop to avoid calling Navigator during a build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) Navigator.of(context).pop();
        });
      }
      return;
    }

    final userProfile = args;

    _allSettings = [
      SettingItem(
        title: "settings.edit_profile".tr(),
        subtitle: "search.subtitle_edit_profile".tr(),
        icon: CupertinoIcons.person,
        iconColor: const Color(0xFF2563EB),
        navigationTarget: EditProfilePage(userProfile: userProfile),
      ),
      SettingItem(
        title: "settings.change_password".tr(),
        subtitle: "search.subtitle_change_password".tr(),
        icon: CupertinoIcons.lock,
        iconColor: const Color(0xFF10B981),
        navigationTarget: const ChangePasswordPage(),
      ),
      SettingItem(
        title: "settings.dark_mode".tr(),
        subtitle: "search.subtitle_dark_mode".tr(),
        icon: CupertinoIcons.moon,
        iconColor: const Color(0xFF8B5CF6),
      ),
      SettingItem(
        title: "settings.notifications".tr(),
        subtitle: "search.subtitle_notifications".tr(),
        icon: CupertinoIcons.bell,
        iconColor: const Color(0xFFF59E0B),
      ),
      SettingItem(
        title: "settings.language".tr(),
        subtitle: "search.subtitle_language".tr(),
        icon: CupertinoIcons.globe,
        iconColor: const Color(0xFF06B6D4),
      ),
      SettingItem(
        title: "settings.privacy_policy".tr(),
        subtitle: "search.subtitle_privacy".tr(),
        icon: CupertinoIcons.lock_shield,
        iconColor: const Color(0xFF14B8A6),
        navigationTarget: const PrivacyPolicyPage(),
      ),
      SettingItem(
        title: "settings.terms_of_service".tr(),
        subtitle: "search.subtitle_terms".tr(),
        icon: CupertinoIcons.doc_text,
        iconColor: const Color(0xFF6B7280),
        navigationTarget: const TermsOfServicePage(),
      ),
      SettingItem(
        title: "settings.logout".tr(),
        subtitle: "search.subtitle_logout".tr(),
        icon: CupertinoIcons.arrow_right_square,
        iconColor: const Color(0xFFEF4444),
      ),
    ];
    _filteredSettings = [];
  }

  void _filterSettings(String query) {
    if (query.isEmpty) {
      setState(() => _filteredSettings = []);
      return;
    }

    final lowerCaseQuery = query.toLowerCase();
    final results = _allSettings.where((setting) {
      final titleMatch = setting.title.toLowerCase().contains(lowerCaseQuery);
      final subtitleMatch = setting.subtitle.toLowerCase().contains(
            lowerCaseQuery,
          );
      // Also check against localized keys if needed, for more robust search
      // For simplicity, we stick to title and subtitle here.
      return titleMatch || subtitleMatch;
    }).toList();
    setState(() => _filteredSettings = results);
  }

  void _handleNavigation(Widget? target) {
    if (target != null) {
      HapticFeedback.lightImpact();
      Navigator.push(context, SlideFadeRoute(page: target));
    }
    // You might want to handle taps on items without navigationTarget,
    // like 'Dark Mode' or 'Notifications'.
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? Colors.black : Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            CupertinoIcons.back,
            color: isDarkMode ? Colors.white : Colors.grey.shade900,
          ),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).pop();
          },
        ),
        backgroundColor: backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 0,
        title: _buildSearchBar(isDarkMode),
      ),
      body: _buildBody(isDarkMode),
    );
  }

  Widget _buildSearchBar(bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.only(right: 16),
      height: 48,
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocus,
        autofocus: true,
        style: GoogleFonts.manrope(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: isDarkMode ? Colors.white : Colors.grey.shade900,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50,
          prefixIcon: Icon(
            CupertinoIcons.search,
            size: 20,
            color: Colors.grey.shade400,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    CupertinoIcons.xmark_circle_fill,
                    size: 20,
                    color: Colors.grey.shade400,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    HapticFeedback.selectionClick();
                  },
                )
              : null,
          hintText: 'search.hint'.tr(),
          hintStyle: GoogleFonts.manrope(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: Colors.grey.shade400,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade900,
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        onSubmitted: (value) => _addSearchTerm(value),
      ),
    );
  }

  Widget _buildBody(bool isDarkMode) {
    if (_searchController.text.isEmpty) {
      return _buildRecentSearches(isDarkMode);
    }
    if (_filteredSettings.isEmpty) {
      return _buildNoResults(isDarkMode);
    }
    return _buildSearchResults(isDarkMode);
  }

  Widget _buildRecentSearches(bool isDarkMode) {
    if (_recentSearches.isEmpty) {
      return _buildEmptyState(isDarkMode);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'search.recent_searches'.tr(),
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color:
                      isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
              TextButton(
                onPressed: _clearAllSearches,
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'search.clear_all'.tr(), // Using new translation key
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFEF4444),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _recentSearches.length,
            itemBuilder: (context, index) {
              final term = _recentSearches[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color:
                      isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDarkMode
                        ? Colors.grey.shade800
                        : Colors.grey.shade200,
                    width: 1,
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  leading: Icon(
                    CupertinoIcons.clock,
                    size: 20,
                    color: Colors.grey.shade400,
                  ),
                  title: Text(
                    term,
                    style: GoogleFonts.manrope(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: isDarkMode ? Colors.white : Colors.grey.shade900,
                    ),
                  ),
                  trailing: IconButton(
                    icon: Icon(
                      CupertinoIcons.xmark,
                      size: 18,
                      color: Colors.grey.shade400,
                    ),
                    onPressed: () {
                      _removeSearchTerm(term);
                      HapticFeedback.lightImpact();
                    },
                  ),
                  onTap: () {
                    _searchController.text = term;
                    _searchController.selection = TextSelection.fromPosition(
                      TextPosition(offset: term.length),
                    );
                    HapticFeedback.selectionClick();
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.search,
              size: 64,
              color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'search.empty_title'.tr(), // Using new translation key
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'search.empty_message'.tr(), // Using new translation key
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults(bool isDarkMode) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredSettings.length,
      itemBuilder: (context, index) {
        final setting = _filteredSettings[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
              width: 1,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: setting.iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                setting.icon,
                size: 20,
                color: setting.iconColor,
              ),
            ),
            title: Text(
              setting.title,
              style: GoogleFonts.manrope(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.white : Colors.grey.shade900,
              ),
            ),
            subtitle: Text(
              setting.subtitle,
              style: GoogleFonts.manrope(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
            trailing: Icon(
              CupertinoIcons.chevron_right,
              size: 18,
              color: Colors.grey.shade400,
            ),
            onTap: () {
              _addSearchTerm(_searchController.text.trim());
              _handleNavigation(setting.navigationTarget);
            },
          ),
        );
      },
    );
  }

  Widget _buildNoResults(bool isDarkMode) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.search_circle,
              size: 80,
              color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'search.no_results'.tr(),
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'search.no_results_message'.tr(), // Using new translation key
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }
}
