import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timely/models/absen_stats.dart';
import 'package:timely/utils/app_theme.dart';

class AbsenStatsCard extends StatelessWidget {
  final Data? statsData;
  const AbsenStatsCard({super.key, this.statsData});

  @override
  Widget build(BuildContext context) {
    if (statsData == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isDarkMode = AppTheme.isDarkMode(context);
    final totalHadir = statsData!.totalMasuk ?? 0;
    final totalIzin = statsData!.totalIzin ?? 0;
    final totalHariKerja = statsData!.totalAbsen ?? 0;
    final totalMangkir = (totalHariKerja - totalHadir - totalIzin) < 0
        ? 0
        : (totalHariKerja - totalHadir - totalIzin);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: AppTheme.spacing4,
            bottom: AppTheme.spacing12,
          ),
          child: Text(
            "attendance_stats.title".tr().toUpperCase(),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCardSummary(context, totalHariKerja),
              AppTheme.divider(isDark: isDarkMode),
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppTheme.spacing16,
                  horizontal: AppTheme.spacing8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        context,
                        icon: Icons
                            .check_circle_outline_rounded,
                        color: AppTheme.getStatusColor('present'),
                        value: totalHadir,
                        label: "attendance_stats.present".tr(),
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        context,
                        icon: Icons.event_busy_outlined,
                        color: AppTheme.getStatusColor('leave'),
                        value: totalIzin,
                        label: "attendance_stats.leave".tr(),
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        context,
                        icon: Icons.cancel_outlined,
                        color: AppTheme.getStatusColor('absent'),
                        value: totalMangkir,
                        label: "attendance_stats.absent".tr(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  Widget _buildCardSummary(BuildContext context, int totalHariKerja) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacing20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "attendance_stats.total_days".tr(
                    args: [totalHariKerja.toString()],
                  ),
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    color: AppTheme.getTextSecondaryColor(context),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacing12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radius12),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Text(
              "attendance_stats.this_month".tr(),
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required int value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: AppTheme.spacing12),
        Text(
          value.toString(),
          style: GoogleFonts.manrope(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppTheme.getTextPrimaryColor(context),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: AppTheme.spacing4),
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 13,
            color: AppTheme.getTextSecondaryColor(context),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
