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
    final totalHadir = statsData!.totalMasuk ?? 0;
    final totalIzin = statsData!.totalIzin ?? 0;
    final totalHariKerja = statsData!.totalAbsen ?? 0;
    final totalMangkir = totalHariKerja - totalHadir - totalIzin;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radius20),
        border: Border.all(
          color: theme.colorScheme.outline,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, totalHariKerja),
          Divider(height: 1, color: theme.dividerColor),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    icon: Icons.check_circle_rounded,
                    color: AppTheme.getStatusColor('present'),
                    value: totalHadir,
                    label: "attendance_stats.present".tr(),
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    icon: Icons.event_busy_rounded,
                    color: AppTheme.getStatusColor('leave'),
                    value: totalIzin,
                    label: "attendance_stats.leave".tr(),
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    icon: Icons.cancel_rounded,
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
    );
  }

  Widget _buildHeader(BuildContext context, int totalHariKerja) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "attendance_stats.title".tr(),
                  style: GoogleFonts.manrope(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "attendance_stats.total_days".tr(
                    args: [totalHariKerja.toString()],
                  ),
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    color: AppTheme.getTextSecondaryColor(context),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                fontWeight: FontWeight.bold,
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
        const SizedBox(height: 8),
        Text(
          value.toString(),
          style: GoogleFonts.manrope(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
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
