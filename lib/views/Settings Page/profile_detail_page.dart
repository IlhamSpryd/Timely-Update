// lib/views/Settings Page/profile_detail_page.dart

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timely/models/getprofile_model.dart';

class ProfileDetailPage extends StatefulWidget {
  final Data userProfile;
  const ProfileDetailPage({super.key, required this.userProfile});

  @override
  State<ProfileDetailPage> createState() => _ProfileDetailPageState();
}

class _ProfileDetailPageState extends State<ProfileDetailPage> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final user = widget.userProfile;
    final backgroundColor = isDarkMode ? Colors.black : Colors.white;

    final trainingTitle = user.trainingTitle.isNotEmpty == true
        ? user.trainingTitle
        : '-';
    final batchNumber = 'Batch ${user.batchKe}';

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
        title: Text(
          'profile_detail.title'.tr(),
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w600,
            fontSize: 17,
            color: isDarkMode ? Colors.white : Colors.grey.shade900,
          ),
        ),
        centerTitle: false,
        backgroundColor: backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header
            Center(
              child: Column(
                children: [
                  _buildProfileAvatar(user, theme, isDarkMode),
                  const SizedBox(height: 20),
                  Text(
                    user.name,
                    style: GoogleFonts.manrope(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: isDarkMode ? Colors.white : Colors.grey.shade900,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    user.email,
                    style: GoogleFonts.manrope(
                      fontSize: 15,
                      color: Colors.grey.shade500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Text(
              'profile_detail.information'.tr(),
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade500,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              isDarkMode: isDarkMode,
              children: [
                _buildInfoTile(
                  title: 'profile_detail.training_program'.tr(),
                  value: trainingTitle,
                  isDarkMode: isDarkMode,
                ),
                _buildDivider(isDarkMode),
                _buildInfoTile(
                  title: 'profile_detail.batch'.tr(),
                  value: batchNumber,
                  isDarkMode: isDarkMode,
                ),
                _buildDivider(isDarkMode),
                _buildInfoTile(
                  title: 'profile_detail.gender'.tr(),
                  value: user.jenisKelamin == 'L'
                      ? 'register.gender_male'.tr()
                      : 'register.gender_female'.tr(),
                  isDarkMode: isDarkMode,
                ),
                _buildDivider(isDarkMode),
                _buildInfoTile(
                  title: 'profile_detail.status'.tr(),
                  value: 'profile_detail.profile_active'.tr(),
                  isDarkMode: isDarkMode,
                  isLast: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileAvatar(Data user, ThemeData theme, bool isDarkMode) {
    final hasPhoto =
        user.profilePhotoUrl != null && user.profilePhotoUrl!.isNotEmpty;

    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
        border: Border.all(
          color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade200,
          width: 2,
        ),
      ),
      child: hasPhoto
          ? ClipOval(
              child: Image.network(
                user.profilePhotoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildDefaultAvatar(user, isDarkMode);
                },
              ),
            )
          : _buildDefaultAvatar(user, isDarkMode),
    );
  }

  Widget _buildDefaultAvatar(Data user, bool isDarkMode) {
    return Center(
      child: Text(
        user.name.isNotEmpty == true ? user.name[0].toUpperCase() : 'U',
        style: GoogleFonts.manrope(
          fontWeight: FontWeight.w700,
          fontSize: 40,
          color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required bool isDarkMode,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildInfoTile({
    required String title,
    required String value,
    required bool isDarkMode,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, isLast ? 16 : 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade500,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.white : Colors.grey.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(
        height: 1,
        thickness: 1,
        color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
      ),
    );
  }
}
