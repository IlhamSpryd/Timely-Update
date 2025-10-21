import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:timely/utils/app_theme.dart';

class AbsenStatusCard extends StatelessWidget {
  final bool isLoading;
  final String todayStatusKey;
  final bool hasCheckedIn;
  final bool hasCheckedOut;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final String attendanceBadgeKey;
  final String timeDifferenceMessage;
  final VoidCallback? onTap;

  const AbsenStatusCard({
    super.key,
    this.isLoading = false,
    required this.todayStatusKey,
    required this.hasCheckedIn,
    required this.hasCheckedOut,
    this.checkInTime,
    this.checkOutTime,
    required this.attendanceBadgeKey,
    required this.timeDifferenceMessage,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = AppTheme.isDarkMode(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: AppTheme.spacing4,
            bottom: AppTheme.spacing12,
          ),
          child: Text(
            "card_titles.today_status".tr().toUpperCase(),
            style: GoogleFonts.manrope(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.getTextSecondaryColor(context),
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          decoration: AppTheme.elevatedCard(isDark: isDarkMode),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isLoading ? null : onTap,
              borderRadius: BorderRadius.circular(AppTheme.radius16),
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacing20),
                child: isLoading
                    ? _buildLoadingState(context)
                    : _buildContentState(context),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = AppTheme.isDarkMode(context);

    return Shimmer.fromColors(
      baseColor: isDarkMode
          ? theme.colorScheme.surfaceContainerHighest
          : Colors.grey[300]!,
      highlightColor:
          isDarkMode ? theme.colorScheme.outline : Colors.grey[100]!,
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppTheme.radius12),
                ),
              ),
              const SizedBox(width: AppTheme.spacing16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 100,
                      height: 12,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 150,
                      height: 20,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 80,
                height: 24,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppTheme.radius8),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing20),
          Container(
            width: double.infinity,
            height: 80,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.radius12),
            ),
          ),
          const SizedBox(height: AppTheme.spacing16),
          Container(
            width: double.infinity,
            height: 16,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentState(BuildContext context) {
    final theme = Theme.of(context);
    Color statusColor;
    IconData statusIcon;
    String statusLabel;

    switch (todayStatusKey) {
      case "present":
      case "finished":
        statusColor = AppTheme.getStatusColor('present');
        statusIcon = Icons.check_circle_rounded;
        statusLabel = "attendance_status.$todayStatusKey".tr();
        break;
      case "leave":
        statusColor = AppTheme.getStatusColor('leave');
        statusIcon = Icons.event_busy_rounded;
        statusLabel = "attendance_status.$todayStatusKey".tr();
        break;
      default:
        statusColor = AppTheme.getTextSecondaryColor(context);
        statusIcon = Icons.schedule_rounded;
        statusLabel = "attendance_status.not_present".tr();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radius12),
                border: Border.all(
                  color: statusColor.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Icon(statusIcon, color: statusColor, size: 24),
            ),
            const SizedBox(width: AppTheme.spacing16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Status Hari Ini",
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.getTextSecondaryColor(context),
                      letterSpacing: -0.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    statusLabel,
                    style: GoogleFonts.manrope(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.getTextPrimaryColor(context),
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),
            if (attendanceBadgeKey.isNotEmpty)
              _buildBadge(context, attendanceBadgeKey),
          ],
        ),
        if (hasCheckedIn) ...[
          const SizedBox(height: AppTheme.spacing20),
          Container(
            padding: const EdgeInsets.all(AppTheme.spacing16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppTheme.radius12),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    child: _buildTimeInfo(
                      context,
                      "attendance_status.check_in".tr(),
                      checkInTime,
                      Icons.login_rounded,
                      AppTheme.getStatusColor('present'),
                    ),
                  ),
                  if (hasCheckedOut) ...[
                    Container(
                      width: 1,
                      margin: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacing16,
                      ),
                      color: theme.colorScheme.outline.withOpacity(0.3),
                    ),
                    Expanded(
                      child: _buildTimeInfo(
                        context,
                        "attendance_status.check_out".tr(),
                        checkOutTime,
                        Icons.logout_rounded,
                        AppTheme.getStatusColor('absent'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: AppTheme.spacing16),
        Container(
          padding: const EdgeInsets.all(AppTheme.spacing12),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(AppTheme.radius8),
            border: Border.all(
              color: theme.colorScheme.primary.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: AppTheme.spacing12),
              Expanded(
                child: Text(
                  timeDifferenceMessage,
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    color: AppTheme.getTextPrimaryColor(context),
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBadge(BuildContext context, String badgeKey) {
    final isTepatWaktu = badgeKey == 'on_time';
    final badgeText = "attendance_status.$badgeKey".tr();
    final color = isTepatWaktu
        ? AppTheme.getStatusColor('present')
        : AppTheme.getStatusColor('late');
    final icon = isTepatWaktu
        ? Icons.check_circle_outline_rounded
        : Icons.access_time_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radius8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            badgeText,
            style: GoogleFonts.manrope(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeInfo(
    BuildContext context,
    String label,
    DateTime? time,
    IconData icon,
    Color color,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: color.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(height: AppTheme.spacing8),
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 11,
            color: AppTheme.getTextSecondaryColor(context),
            fontWeight: FontWeight.w500,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          time != null ? DateFormat('HH:mm').format(time) : '--:--',
          style: GoogleFonts.manrope(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppTheme.getTextPrimaryColor(context),
            letterSpacing: -0.5,
            height: 1,
          ),
        ),
      ],
    );
  }
}
