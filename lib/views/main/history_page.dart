import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timely/api/history_api.dart';
import 'package:timely/models/historyabsen_model.dart';
import 'package:timely/services/history_repository.dart';
import 'package:timely/services/history_service.dart';
import 'package:timely/utils/app_theme.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin<HistoryPage> {
  @override
  bool get wantKeepAlive => true;

  final HistoryAbsenRepository _historyRepository = HistoryService(
    HistoryAbsenApiClient(),
  );

  List<Datum> _attendanceHistory = [];
  DateTimeRange? _selectedRange;
  bool _isLoading = true;
  String _errorMessage = '';

  late AnimationController _listAnimationController;

  @override
  void initState() {
    super.initState();
    _listAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fetchAttendanceHistory();
  }

  @override
  void dispose() {
    _listAnimationController.dispose();
    super.dispose();
  }

  Future<void> _fetchAttendanceHistory() async {
    try {
      if (_attendanceHistory.isEmpty) {
        setState(() => _isLoading = true);
      }
      _errorMessage = '';
      final historyResponse = await _historyRepository.getHistoryAbsen();

      if (!mounted) return;

      setState(() {
        _attendanceHistory = historyResponse.data ?? [];
        _isLoading = false;
      });
      _listAnimationController.forward(from: 0.0);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'history.failed_to_load'.tr(args: [e.toString()]);
        _isLoading = false;
      });
    }
  }

  Future<void> _pickDateRange() async {
    final DateTime now = DateTime.now();
    final theme = Theme.of(context);
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024, 1, 1),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _selectedRange ??
          DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now),
      locale: context.locale,
      builder: (context, child) {
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: theme.colorScheme.primary,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedRange = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final scaffoldBackgroundColor =
        isDarkMode ? Colors.black : const Color(0xFFF3F4F6);
    final cardBackgroundColor =
        isDarkMode ? const Color(0xFF1C1C1E) : Colors.white;

    final List<Datum> filteredHistory = _selectedRange == null
        ? _attendanceHistory
        : _attendanceHistory.where((item) {
            final tgl = item.attendanceDate;
            if (tgl == null) return false;
            final start = DateUtils.dateOnly(_selectedRange!.start);
            final end = DateUtils.dateOnly(_selectedRange!.end);
            return (tgl.isAfter(start) || tgl.isAtSameMomentAs(start)) &&
                (tgl.isBefore(end) || tgl.isAtSameMomentAs(end));
          }).toList();

    return Scaffold(
      backgroundColor: scaffoldBackgroundColor,
      body: _isLoading
          ? _buildLoadingView()
          : _errorMessage.isNotEmpty
              ? _buildErrorView()
              : RefreshIndicator(
                  onRefresh: _fetchAttendanceHistory,
                  color: theme.colorScheme.primary,
                  backgroundColor: cardBackgroundColor,
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverAppBar(
                        backgroundColor: scaffoldBackgroundColor,
                        pinned: true,
                        stretch: true,
                        expandedHeight: 120.0,
                        flexibleSpace: FlexibleSpaceBar(
                          titlePadding:
                              const EdgeInsets.only(left: 20, bottom: 16),
                          title: Text(
                            "history.title".tr(),
                            style: GoogleFonts.manrope(
                              fontWeight: FontWeight.bold,
                              color: theme.textTheme.titleLarge?.color,
                            ),
                          ),
                        ),
                      ),
                      SliverPersistentHeader(
                        delegate: _FilterBarDelegate(
                          onPressed: _pickDateRange,
                          selectedRange: _selectedRange,
                          backgroundColor: scaffoldBackgroundColor,
                        ),
                        pinned: true,
                      ),
                      if (filteredHistory.isEmpty)
                        SliverFillRemaining(child: _buildEmptyView())
                      else
                        SliverList(
                          delegate:
                              SliverChildBuilderDelegate((context, index) {
                            final item = filteredHistory[index];
                            return _buildAnimatedListItem(
                              index: index,
                              child: _buildAttendanceCard(item),
                            );
                          }, childCount: filteredHistory.length),
                        ),
                      const SliverToBoxAdapter(
                          child: SizedBox(height: AppTheme.spacing24)),
                    ],
                  ),
                ),
    );
  }

  Widget _buildAnimatedListItem({required int index, required Widget child}) {
    final animation = CurvedAnimation(
      parent: _listAnimationController,
      curve: Interval(
        (index / 10).clamp(0.0, 1.0),
        1.0,
        curve: Curves.easeOutCubic,
      ),
    );

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.3),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }

  Widget _buildAttendanceCard(Datum item) {
    final theme = Theme.of(context);
    final isDarkMode = AppTheme.isDarkMode(context);
    final Color statusColor = AppTheme.getStatusColor(item.status ?? 'unknown');
    final IconData statusIcon;

    switch (item.status?.toLowerCase()) {
      case 'hadir':
      case 'present':
        statusIcon = Icons.check_circle_outline_rounded;
        break;
      case 'terlambat':
      case 'late':
        statusIcon = Icons.warning_amber_rounded;
        break;
      case 'izin':
      case 'leave':
        statusIcon = Icons.info_outline_rounded;
        break;
      case 'alpha':
        statusIcon = Icons.cancel_outlined;
        break;
      default:
        statusIcon = Icons.help_outline_rounded;
    }

    final dateFormatter = DateFormat(
      'EEEE, d MMM yyyy',
      context.locale.toString(),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing16,
        vertical: AppTheme.spacing8,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacing20),
        decoration: AppTheme.elevatedCard(isDark: isDarkMode),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 28),
                const SizedBox(width: AppTheme.spacing16),
                Expanded(
                  child: Text(
                    dateFormatter.format(item.attendanceDate ?? DateTime.now()),
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: AppTheme.getTextPrimaryColor(context),
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spacing8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacing12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radius20),
                  ),
                  child: Text(
                    (item.status ?? "-").tr(),
                    style: GoogleFonts.manrope(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(
                left: 44.0,
                top: AppTheme.spacing16,
                bottom: AppTheme.spacing16,
              ),
              child: AppTheme.divider(isDark: isDarkMode),
            ),
            Row(
              children: [
                Expanded(
                  child: _buildTimeInfo(
                    'home.check_in'.tr(),
                    item.checkInTime ?? '--',
                    'present',
                  ),
                ),
                const SizedBox(width: AppTheme.spacing16),
                Expanded(
                  child: _buildTimeInfo(
                    'home.check_out'.tr(),
                    item.checkOutTime ?? '--',
                    'absent',
                  ),
                ),
              ],
            ),
            if (item.alasanIzin != null && item.alasanIzin!.isNotEmpty) ...[
              const SizedBox(height: AppTheme.spacing16),
              _buildReasonInfo(item.alasanIzin!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimeInfo(String title, String time, String statusKey) {
    final color = AppTheme.getStatusColor(statusKey);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.manrope(
            fontSize: 13,
            color: AppTheme.getTextSecondaryColor(context),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppTheme.spacing4),
        Text(
          time,
          style: GoogleFonts.manrope(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildReasonInfo(String reason) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing12,
        vertical: AppTheme.spacing12,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppTheme.radius12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Text(
        "${'history.reason'.tr()}: $reason",
        style: GoogleFonts.manrope(
          fontSize: 13,
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w500,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildLoadingView() => Center(
        child: CircularProgressIndicator(
          color: Theme.of(context).colorScheme.primary,
        ),
      );

  Widget _buildErrorView() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 80, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'history.error_title'.tr(),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _fetchAttendanceHistory,
                icon: const Icon(Icons.refresh_rounded),
                label: Text('history.try_again'.tr()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildEmptyView() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.history_toggle_off_rounded,
                size: 80,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                'history.empty_data_title'.tr(),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'history.empty_data_subtitle'.tr(),
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      );
}

class _FilterBarDelegate extends SliverPersistentHeaderDelegate {
  final VoidCallback onPressed;
  final DateTimeRange? selectedRange;
  final Color backgroundColor;

  _FilterBarDelegate({
    required this.onPressed,
    required this.selectedRange,
    required this.backgroundColor,
  });

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final theme = Theme.of(context);
    final formatter = DateFormat('d MMM yyyy', context.locale.toString());
    final dateText = selectedRange == null
        ? 'history.all_period'.tr()
        : '${formatter.format(selectedRange!.start)} - ${formatter.format(selectedRange!.end)}';

    return Container(
      color: backgroundColor,
      padding: const EdgeInsets.fromLTRB(20, 8, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              dateText,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.filter_list_rounded,
              color: theme.colorScheme.primary,
            ),
            onPressed: onPressed,
          ),
        ],
      ),
    );
  }

  @override
  double get maxExtent => 56.0;

  @override
  double get minExtent => 56.0;

  @override
  bool shouldRebuild(covariant _FilterBarDelegate oldDelegate) {
    return selectedRange != oldDelegate.selectedRange ||
        backgroundColor != oldDelegate.backgroundColor;
  }
}
