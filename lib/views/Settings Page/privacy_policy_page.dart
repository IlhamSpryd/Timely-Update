import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class PrivacyPolicyPage extends StatefulWidget {
  const PrivacyPolicyPage({super.key});

  @override
  State<PrivacyPolicyPage> createState() => _PrivacyPolicyPageState();
}

class _PrivacyPolicyPageState extends State<PrivacyPolicyPage> {
  Future<void> _launchMailTo(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {
        'subject': 'Pertanyaan Mengenai Kebijakan Privasi',
      },
    );

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tidak dapat membuka aplikasi email. Alamat: $email'),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error launching email: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Terjadi kesalahan saat meluncurkan email.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? Colors.black : Colors.white;
    final formattedDate = DateFormat('MMMM dd, yyyy', context.locale.toString())
        .format(DateTime.now());

    final contactEmail = 'privacy_policy.contact_email'.tr();
    final questionsBody = 'privacy_policy.questions_body'.tr();
    final parts = questionsBody.split(contactEmail);

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
          "settings.privacy_policy".tr(),
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
            Text(
              'privacy_policy.header_title'.tr(),
              style: GoogleFonts.manrope(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: isDarkMode ? Colors.white : Colors.grey.shade900,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'privacy_policy.last_updated'.tr(args: [formattedDate]),
              style: GoogleFonts.manrope(
                color: Colors.grey.shade500,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            _buildPrivacySection(
              context: context,
              title: 'privacy_policy.title1'.tr(),
              body: 'privacy_policy.body1'.tr(),
              isDarkMode: isDarkMode,
            ),
            const SizedBox(height: 24),
            _buildPrivacySection(
              context: context,
              title: 'privacy_policy.title2'.tr(),
              body: 'privacy_policy.body2'.tr(),
              isDarkMode: isDarkMode,
            ),
            const SizedBox(height: 24),
            _buildPrivacySection(
              context: context,
              title: 'privacy_policy.title3'.tr(),
              body: 'privacy_policy.body3'.tr(),
              isDarkMode: isDarkMode,
            ),
            const SizedBox(height: 24),
            _buildPrivacySection(
              context: context,
              title: 'privacy_policy.title4'.tr(),
              body: 'privacy_policy.body4'.tr(),
              isDarkMode: isDarkMode,
            ),
            const SizedBox(height: 32),
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
                    'privacy_policy.questions_title'.tr(),
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: isDarkMode ? Colors.white : Colors.grey.shade900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  RichText(
                    text: TextSpan(
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        color: isDarkMode
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                        height: 1.5,
                      ),
                      children: <InlineSpan>[
                        TextSpan(
                          text: parts.isNotEmpty ? parts[0] : questionsBody,
                        ),
                        WidgetSpan(
                          child: GestureDetector(
                            onTap: () => _launchMailTo(contactEmail),
                            child: Text(
                              contactEmail,
                              style: GoogleFonts.manrope(
                                fontSize: 14,
                                height: 1.5,
                                color: Colors.blue.shade400,
                                decoration: TextDecoration.underline,
                                decorationColor: Colors.blue.shade400,
                              ),
                            ),
                          ),
                        ),
                        if (parts.length > 1)
                          TextSpan(
                            text: parts[1],
                          ),
                      ],
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

  Widget _buildPrivacySection({
    required BuildContext context,
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
