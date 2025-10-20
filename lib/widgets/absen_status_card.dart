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
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12.0, bottom: 12.0),
          child: Text(
            "card_titles.today_status".tr().toUpperCase(),
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.getTextSecondaryColor(context),
            ),
          ),
        ),
        InkWell(
          onTap: isLoading ? null : onTap,
          borderRadius: BorderRadius.circular(AppTheme.radius20),
          child: Ink(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(AppTheme.radius20),
              border: Border.all(
                color: theme.colorScheme.outline,
                width: 1,
              ),
            ),
            child: isLoading
                ? _buildLoadingState(context)
                : _buildContentState(context),
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
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppTheme.radius12),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 100,
                    height: 14,
                    color: theme.colorScheme.surface,
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 150,
                    height: 20,
                    color: theme.colorScheme.surface,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            height: 60,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.radius16),
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

    switch (todayStatusKey) {
      case "present":
      case "finished":
        statusColor = AppTheme.getStatusColor('present');
        statusIcon = Icons.check_circle_rounded;
        break;
      case "leave":
        statusColor = AppTheme.getStatusColor('leave');
        statusIcon = Icons.event_busy_rounded;
        break;
      default:
        statusColor = AppTheme.getTextSecondaryColor(context);
        statusIcon = Icons.schedule_rounded;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(AppTheme.radius12),
            ),
            child: Icon(statusIcon, color: statusColor, size: 24),
          ),
          title: Text(
            "attendance_status.$todayStatusKey".tr(),
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          trailing: attendanceBadgeKey.isNotEmpty
              ? _buildBadge(context, attendanceBadgeKey)
              : null,
        ),
        if (hasCheckedIn)
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
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
                    VerticalDivider(color: theme.dividerColor, thickness: 1),
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
        const SizedBox(height: 16),
        Row(
          children: [
            Icon(
              Icons.info_outline_rounded,
              size: 18,
              color: AppTheme.getTextSecondaryColor(context),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                timeDifferenceMessage,
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  color: AppTheme.getTextSecondaryColor(context),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppTheme.radius8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            badgeText,
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
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
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 12,
            color: AppTheme.getTextSecondaryColor(context),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          time != null ? DateFormat('HH:mm').format(time) : '-',
          style: GoogleFonts.manrope(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
