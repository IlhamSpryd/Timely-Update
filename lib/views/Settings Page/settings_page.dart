import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:timely/models/getprofile_model.dart';
import 'package:timely/services/auth_services.dart';
import 'package:timely/services/local_notification.dart';
import 'package:timely/services/profile_repository.dart';
import 'package:timely/utils/app_theme.dart';
import 'package:timely/utils/app_transitions.dart';
import 'package:timely/utils/theme_helper.dart';
import 'package:timely/utils/theme_provider.dart';
import 'package:timely/views/Settings%20Page/change_password_page.dart';
import 'package:timely/views/Settings%20Page/edit_profile_page.dart';
import 'package:timely/views/Settings%20Page/privacy_policy_page.dart';
import 'package:timely/views/Settings%20Page/profile_detail_page.dart';
import 'package:timely/views/Settings%20Page/settings_search_page.dart';
import 'package:timely/views/Settings%20Page/terms_of_service_page.dart';
import 'package:timely/views/auth/login_page.dart';

class SettingsPage extends StatefulWidget {
  final void Function(ThemeMode)? updateTheme;
  const SettingsPage({super.key, this.updateTheme});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with AutomaticKeepAliveClientMixin<SettingsPage>, TickerProviderStateMixin {
  @override
  bool get wantKeepAlive => true;

  Data? _userProfile;
  bool _isLoading = true;
  bool _isUploadingPhoto = false;
  bool _notificationsEnabled = true;

  final AuthService _authService = AuthService();
  final ProfileRepository _profileRepository = ProfileRepository();
  final Logger _logger = Logger();

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _loadUserProfile();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleNotifications(bool value) {
    if (mounted) {
      setState(() {
        _notificationsEnabled = value;
      });
    }

    if (value) {
      LocalNotificationService.showNotification(
        title: 'settings.notification_enabled_title'.tr(),
        body: 'settings.notification_enabled_body'.tr(),
      );
    } else {
      LocalNotificationService.cancelAll();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppTheme.infoSnackBar(
              'settings.notifications_disabled_snackbar'.tr()),
        );
      }
    }
  }

  Future<void> _loadUserProfile() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final profileModel = await _profileRepository.getProfile();
      if (mounted) {
        setState(() {
          _userProfile = profileModel.data;
        });
      }
    } catch (e) {
      _logger.e('Error loading profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppTheme.errorSnackBar('Failed to load profile: ${e.toString()}'),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _animationController.forward();
      }
    }
  }

  Future<void> _changeProfilePhoto() async {
    final picker = ImagePicker();
    final theme = Theme.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image == null) return;
      if (!mounted) return;

      final CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: image.path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop & Rotate',
            toolbarColor: theme.colorScheme.primary,
            toolbarWidgetColor: theme.colorScheme.onPrimary,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
            aspectRatioPresets: [
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9,
            ],
          ),
          IOSUiSettings(
            title: 'Crop & Rotate',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
            doneButtonTitle: 'Done',
            cancelButtonTitle: 'Cancel',
            aspectRatioPresets: [
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9,
            ],
          ),
        ],
      );

      if (croppedFile != null && mounted) {
        setState(() => _isUploadingPhoto = true);
        scaffoldMessenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            AppTheme.infoSnackBar('settings.uploading_photo_snackbar'.tr()),
          );
        await _profileRepository.updateProfilePhoto(croppedFile.path);
        if (mounted) {
          scaffoldMessenger
            ..hideCurrentSnackBar()
            ..showSnackBar(
              AppTheme.successSnackBar('settings.profile_photo_updated'.tr()),
            );
          await _loadUserProfile();
        }
      }
    } catch (e) {
      _logger.e('Failed to update profile photo: $e');
      if (mounted) {
        scaffoldMessenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            AppTheme.errorSnackBar(
              '${'settings.failed_update_photo'.tr()}: ${e.toString()}',
            ),
          );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
      }
    }
  }

  void _navigateToEditProfile() {
    if (_userProfile == null) return;
    Navigator.push(
      context,
      SlideFadeRoute(page: EditProfilePage(userProfile: _userProfile!)),
    ).then((result) {
      if (result == true && mounted) {
        _loadUserProfile();
      }
    });
  }

  void _navigateToChangePassword() {
    Navigator.push(context, SlideFadeRoute(page: const ChangePasswordPage()));
  }

  void _navigateToProfileDetail() {
    if (_userProfile == null) return;
    Navigator.push(
      context,
      SlideFadeRoute(page: ProfileDetailPage(userProfile: _userProfile!)),
    );
  }

  void _navigateToSearch() {
    if (_userProfile == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SettingsSearchPage(),
        settings: RouteSettings(arguments: _userProfile),
      ),
    );
  }

  void _navigateToPrivacyPolicy() {
    Navigator.push(context, SlideFadeRoute(page: const PrivacyPolicyPage()));
  }

  void _navigateToTermsOfService() {
    Navigator.push(context, SlideFadeRoute(page: const TermsOfServicePage()));
  }

  Future<void> _toggleTheme(bool isDark) async {
    final newThemeMode = isDark ? ThemeMode.dark : ThemeMode.light;

    if (mounted) {
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      themeProvider.setTheme(newThemeMode);
      widget.updateTheme?.call(newThemeMode);
    }

    await ThemeHelper.saveTheme(newThemeMode);
    HapticFeedback.lightImpact();
  }

  void _logout() async {
    await _authService.logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }

  void _showLogoutDialog() {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final theme = Theme.of(context);
        return AlertDialog(
          backgroundColor: theme.dialogTheme.backgroundColor,
          shape: theme.dialogTheme.shape,
          titleTextStyle: theme.dialogTheme.titleTextStyle,
          contentTextStyle: theme.dialogTheme.contentTextStyle,
          title: Text('settings.logout_confirm_title'.tr()),
          content: Text('settings.logout_confirm_body'.tr()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('settings.cancel'.tr()),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _logout();
              },
              child: Text(
                'settings.logout'.tr(),
                style: GoogleFonts.manrope(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _getCurrentLanguageSubtitle(Locale locale) {
    switch (locale.languageCode) {
      case 'id':
        return 'settings.language_subtitle_id'.tr();
      case 'en':
        return 'settings.language_subtitle_en'.tr();
      case 'ko':
        return 'settings.language_subtitle_ko'.tr();
      default:
        return 'settings.language_subtitle_en'.tr();
    }
  }

  void _showThemePicker() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.bottomSheetTheme.backgroundColor,
      shape: theme.bottomSheetTheme.shape,
      isScrollControlled: true,
      builder: (_) {
        return Container(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: AppTheme.spacing12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.bottomSheetTheme.dragHandleColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppTheme.spacing20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'settings.dark_mode'.tr(),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing20),
                    _buildSelectionOption(
                      title: 'settings.dark_mode_subtitle_on'.tr(),
                      isSelected: isDarkMode,
                      onTap: () {
                        _toggleTheme(true);
                        Navigator.pop(context);
                        HapticFeedback.selectionClick();
                      },
                    ),
                    const SizedBox(height: AppTheme.spacing12),
                    _buildSelectionOption(
                      title: 'settings.dark_mode_subtitle_off'.tr(),
                      isSelected: !isDarkMode,
                      onTap: () {
                        _toggleTheme(false);
                        Navigator.pop(context);
                        HapticFeedback.selectionClick();
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(
                height:
                    MediaQuery.of(context).padding.bottom + AppTheme.spacing20,
              ),
            ],
          ),
        );
      },
    );
  }

  void _showNotificationPicker() {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.bottomSheetTheme.backgroundColor,
      shape: theme.bottomSheetTheme.shape,
      isScrollControlled: true,
      builder: (_) {
        return Container(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: AppTheme.spacing12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.bottomSheetTheme.dragHandleColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppTheme.spacing20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'settings.notifications'.tr(),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing20),
                    _buildSelectionOption(
                      title: 'settings.notifications_subtitle_on'.tr(),
                      isSelected: _notificationsEnabled,
                      onTap: () {
                        _toggleNotifications(true);
                        Navigator.pop(context);
                        HapticFeedback.selectionClick();
                      },
                    ),
                    const SizedBox(height: AppTheme.spacing12),
                    _buildSelectionOption(
                      title: 'settings.notifications_subtitle_off'.tr(),
                      isSelected: !_notificationsEnabled,
                      onTap: () {
                        _toggleNotifications(false);
                        Navigator.pop(context);
                        HapticFeedback.selectionClick();
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(
                height:
                    MediaQuery.of(context).padding.bottom + AppTheme.spacing20,
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLanguagePicker() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.bottomSheetTheme.backgroundColor,
      shape: theme.bottomSheetTheme.shape,
      isScrollControlled: true,
      builder: (_) {
        return Container(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: AppTheme.spacing12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.bottomSheetTheme.dragHandleColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppTheme.spacing20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'settings.language'.tr(),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing20),
                    _buildSelectionOption(
                      title: 'English',
                      isSelected: context.locale.languageCode == 'en',
                      onTap: () {
                        context.setLocale(const Locale('en'));
                        Navigator.pop(context);
                        HapticFeedback.selectionClick();
                      },
                    ),
                    const SizedBox(height: AppTheme.spacing12),
                    _buildSelectionOption(
                      title: 'Bahasa Indonesia',
                      isSelected: context.locale.languageCode == 'id',
                      onTap: () {
                        context.setLocale(const Locale('id'));
                        Navigator.pop(context);
                        HapticFeedback.selectionClick();
                      },
                    ),
                    const SizedBox(height: AppTheme.spacing12),
                    _buildSelectionOption(
                      title: '한국어',
                      isSelected: context.locale.languageCode == 'ko',
                      onTap: () {
                        context.setLocale(const Locale('ko'));
                        Navigator.pop(context);
                        HapticFeedback.selectionClick();
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(
                height:
                    MediaQuery.of(context).padding.bottom + AppTheme.spacing20,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSelectionOption({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radius12),
        child: Container(
          padding: const EdgeInsets.all(AppTheme.spacing16),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primary.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radius12),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary.withOpacity(0.3)
                  : theme.colorScheme.outline,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isSelected
                        ? theme.colorScheme.primary
                        : AppTheme.getTextPrimaryColor(context),
                  ),
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle_rounded,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedItem(int index, Widget child) {
    final interval = Interval(
      0.1 * index,
      0.6 + 0.1 * index,
      curve: Curves.easeOutCubic,
    );
    return FadeTransition(
      opacity: _animationController.drive(CurveTween(curve: interval)),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.2),
          end: Offset.zero,
        ).animate(_animationController.drive(CurveTween(curve: interval))),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final isDarkMode = AppTheme.isDarkMode(context);
    final scaffoldBackgroundColor = AppTheme.getBackgroundColor(context);

    return Scaffold(
      backgroundColor: scaffoldBackgroundColor,
      body: _isLoading
          ? AppTheme.loadingIndicator(isDark: isDarkMode)
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverAppBar(
                  backgroundColor: scaffoldBackgroundColor,
                  pinned: true,
                  stretch: true,
                  expandedHeight: 120.0,
                  flexibleSpace: FlexibleSpaceBar(
                    titlePadding: const EdgeInsets.only(
                      left: AppTheme.spacing20,
                      bottom: AppTheme.spacing16,
                    ),
                    title: Text(
                      "settings.title".tr(),
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.getTextPrimaryColor(context),
                      ),
                    ),
                    background: Container(color: scaffoldBackgroundColor),
                  ),
                  actions: [
                    IconButton(
                      icon: Icon(
                        Icons.search,
                        color: AppTheme.getTextPrimaryColor(context),
                      ),
                      onPressed: _navigateToSearch,
                    ),
                    const SizedBox(width: AppTheme.spacing8),
                  ],
                ),
                SliverList(
                  delegate: SliverChildListDelegate([
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacing16,
                      ),
                      child: Column(
                        children: [
                          _buildAnimatedItem(
                            0,
                            _buildProfileHeader(isDarkMode),
                          ),
                          const SizedBox(height: AppTheme.spacing20),
                          _buildAnimatedItem(
                            1,
                            _buildSettingsCard(
                              context,
                              isDarkMode: isDarkMode,
                              children: [
                                _buildSettingTile(
                                  icon: Icons.person_outline_rounded,
                                  iconColor: AppTheme.getPrimaryColor(context),
                                  title: "settings.edit_profile".tr(),
                                  subtitle:
                                      "settings.edit_profile_subtitle".tr(),
                                  onTap: _navigateToEditProfile,
                                ),
                                _buildSettingTile(
                                  icon: Icons.lock_outline_rounded,
                                  iconColor: AppTheme.getStatusColor('present'),
                                  title: "settings.change_password".tr(),
                                  subtitle:
                                      "settings.change_password_subtitle".tr(),
                                  onTap: _navigateToChangePassword,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacing20),
                          _buildAnimatedItem(
                            2,
                            _buildSettingsCard(
                              context,
                              isDarkMode: isDarkMode,
                              children: [
                                _buildSettingTile(
                                  icon: Icons.dark_mode_outlined,
                                  iconColor: AppTheme.getStatusColor('leave'),
                                  title: "settings.dark_mode".tr(),
                                  subtitle: isDarkMode
                                      ? "settings.dark_mode_subtitle_on".tr()
                                      : "settings.dark_mode_subtitle_off".tr(),
                                  onTap: _showThemePicker,
                                ),
                                _buildSettingTile(
                                  icon: Icons.notifications_outlined,
                                  iconColor: AppTheme.getStatusColor('late'),
                                  title: "settings.notifications".tr(),
                                  subtitle: _notificationsEnabled
                                      ? "settings.notifications_subtitle_on"
                                          .tr()
                                      : "settings.notifications_subtitle_off"
                                          .tr(),
                                  onTap: _showNotificationPicker,
                                ),
                                _buildSettingTile(
                                  icon: Icons.language_rounded,
                                  iconColor: theme.colorScheme.secondary,
                                  title: "settings.language".tr(),
                                  subtitle: _getCurrentLanguageSubtitle(
                                    context.locale,
                                  ),
                                  onTap: _showLanguagePicker,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacing20),
                          _buildAnimatedItem(
                            3,
                            _buildSettingsCard(
                              context,
                              isDarkMode: isDarkMode,
                              children: [
                                _buildSettingTile(
                                  icon: Icons.privacy_tip_outlined,
                                  iconColor: AppTheme.getStatusColor('present'),
                                  title: "settings.privacy_policy".tr(),
                                  onTap: _navigateToPrivacyPolicy,
                                ),
                                _buildSettingTile(
                                  icon: Icons.description_outlined,
                                  iconColor:
                                      AppTheme.getTextSecondaryColor(context),
                                  title: "settings.terms_of_service".tr(),
                                  onTap: _navigateToTermsOfService,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacing20),
                          _buildAnimatedItem(
                            4,
                            _buildSettingsCard(
                              context,
                              isDarkMode: isDarkMode,
                              children: [
                                _buildSettingTile(
                                  icon: Icons.logout_rounded,
                                  iconColor: theme.colorScheme.error,
                                  title: "settings.logout".tr(),
                                  isDestructive: true,
                                  onTap: _showLogoutDialog,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacing24),
                        ],
                      ),
                    ),
                  ]),
                ),
              ],
            ),
    );
  }

  Widget _buildProfileHeader(bool isDarkMode) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: _navigateToProfileDetail,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacing20,
          vertical: AppTheme.spacing24,
        ),
        decoration: AppTheme.elevatedCard(isDark: isDarkMode),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _userProfile?.name ??
                        "settings.profile_name_placeholder".tr(),
                    style: GoogleFonts.manrope(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.getTextPrimaryColor(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppTheme.spacing4),
                  Text(
                    _userProfile?.email ??
                        "settings.profile_email_placeholder".tr(),
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      color: AppTheme.getTextSecondaryColor(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppTheme.spacing16),
            GestureDetector(
              onTap: _isUploadingPhoto ? null : _changeProfilePhoto,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                    backgroundImage: _userProfile?.profilePhotoUrl != null &&
                            _userProfile!.profilePhotoUrl!.isNotEmpty
                        ? NetworkImage(_userProfile!.profilePhotoUrl!)
                        : null,
                    child: _userProfile?.profilePhotoUrl == null ||
                            _userProfile!.profilePhotoUrl!.isEmpty
                        ? Icon(
                            Icons.person_rounded,
                            color: theme.colorScheme.primary,
                            size: 40,
                          )
                        : null,
                  ),
                  if (_isUploadingPhoto)
                    CircularProgressIndicator(
                      color: theme.colorScheme.primary,
                      strokeWidth: 2,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard(
    BuildContext context, {
    required List<Widget> children,
    required bool isDarkMode,
  }) {
    return Container(
      decoration: AppTheme.elevatedCard(isDark: isDarkMode),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing8),
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemBuilder: (context, index) => children[index],
        separatorBuilder: (context, index) =>
            AppTheme.divider(isDark: isDarkMode), 
        itemCount: children.length,
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final theme = Theme.of(context);
    final titleColor = isDestructive
        ? theme.colorScheme.error
        : AppTheme.getTextPrimaryColor(context);
    final iconBgColor = iconColor.withOpacity(0.1);

    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(AppTheme.spacing12),
        decoration: BoxDecoration(color: iconBgColor, shape: BoxShape.circle),
        child: Icon(icon, size: 22, color: iconColor),
      ),
      title: Text(
        title,
        style: GoogleFonts.manrope(
          fontWeight: FontWeight.w600,
          color: titleColor,
          fontSize: 16,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: GoogleFonts.manrope(
                color: AppTheme.getTextSecondaryColor(context),
                fontSize: 13,
              ),
            )
          : null,
      trailing: isDestructive
          ? null
          : Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.getTextSecondaryColor(context).withOpacity(0.6),
            ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing20,
        vertical: AppTheme.spacing8,
      ),
    );
  }
}
