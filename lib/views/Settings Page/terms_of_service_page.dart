import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? Colors.black : Colors.white;
    final formattedDate = DateFormat('MMMM dd, yyyy', context.locale.toString())
        .format(DateTime.now());

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
          "settings.terms_of_service".tr(),
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
            // Header
            Text(
              'terms_of_service.header_title'.tr(),
              style: GoogleFonts.manrope(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: isDarkMode ? Colors.white : Colors.grey.shade900,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'terms_of_service.last_updated'.tr(args: [formattedDate]),
              style: GoogleFonts.manrope(
                color: Colors.grey.shade500,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),

            // Terms Sections
            _buildTermsSection(
              title: 'terms_of_service.title1'.tr(),
              body: 'terms_of_service.body1'.tr(),
              isDarkMode: isDarkMode,
            ),
            const SizedBox(height: 24),
            _buildTermsSection(
              title: 'terms_of_service.title2'.tr(),
              body: 'terms_of_service.body2'.tr(),
              isDarkMode: isDarkMode,
            ),
            const SizedBox(height: 24),
            _buildTermsSection(
              title: 'terms_of_service.title3'.tr(),
              body: 'terms_of_service.body3'.tr(),
              isDarkMode: isDarkMode,
            ),
            const SizedBox(height: 24),
            _buildTermsSection(
              title: 'terms_of_service.title4'.tr(),
              body: 'terms_of_service.body4'.tr(),
              isDarkMode: isDarkMode,
            ),
            const SizedBox(height: 32),

            // Agreement Notice
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? Colors.grey.shade900.withOpacity(0.5)
                    : const Color(0xFFFAFAFA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color:
                      isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'terms_of_service.agreement_title'.tr(),
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: isDarkMode ? Colors.white : Colors.grey.shade900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'terms_of_service.agreement_body'.tr(),
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTermsSection({
    required String title,
    required String body,
    required bool isDarkMode,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: isDarkMode ? Colors.white : Colors.grey.shade900,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          body,
          style: GoogleFonts.manrope(
            fontSize: 14,
            height: 1.6,
            color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}
