import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:timely/api/attendance_api.dart';
import 'package:timely/api/history_api.dart';
import 'package:timely/models/absen_stats.dart';
import 'package:timely/models/historyabsen_model.dart';
import 'package:timely/services/history_service.dart';
import 'package:timely/utils/app_theme.dart';
import 'package:timely/views/all_users_page.dart';

enum ChartType { pie, bar }

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage>
    with
        TickerProviderStateMixin,
        AutomaticKeepAliveClientMixin<StatisticsPage> {
  @override
  bool get wantKeepAlive => true;

  final AttendanceApi _statsApi = AttendanceApi();
  final HistoryService _historyService = HistoryService(
    HistoryAbsenApiClient(),
  );
  AbsenStatsModel? _statsData;
  HistoryAbsenModel? _historyData;
  bool _isLoading = true;
  String _errorMessage = '';
  bool _isExporting = false;
  ChartType _selectedChartType = ChartType.pie;

  static const int _targetDays = 45;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _loadData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _errorMessage = '';
        });
      }
      _fadeController.reset();

      final stats = await _statsApi.getAbsenStats();
      final history = await _historyService.getHistoryAbsen();

      if (!mounted) return;
      setState(() {
        _statsData = stats;
        _historyData = history;
        _isLoading = false;
      });

      _fadeController.forward();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'stats.load_failed'.tr(args: [e.toString()]);
        _isLoading = false;
      });
    }
  }

  Future<void> _exportToPdf() async {
    if (_statsData == null || _statsData!.data == null) {
      _showSnackBar('stats.no_data_to_export'.tr(), isError: true);
      return;
    }
    setState(() => _isExporting = true);

    try {
      final pdf = pw.Document();
      final gamificationData = _calculateGamificationData();
      final currentLocale = context.locale.toString();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) => [
            pw.Center(
              child: pw.Text(
                'stats.report_title'.tr().toUpperCase(),
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 30),
            pw.Text(
              'stats.gamification_section'.tr().toUpperCase(),
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 15),
            _buildPdfGamificationSection(gamificationData),
            pw.SizedBox(height: 25),
            pw.Text(
              'stats.summary_section'.tr().toUpperCase(),
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 15),
            pw.Container(
              padding: const pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                children: [
                  _buildPdfStatRow(
                    'stats.total_days_absen'.tr(),
                    _statsData!.data!.totalAbsen ?? 0,
                  ),
                  _buildPdfStatRow(
                    'stats.total_present'.tr(),
                    _statsData!.data!.totalMasuk ?? 0,
                  ),
                  _buildPdfStatRow(
                    'stats.total_leave'.tr(),
                    _statsData!.data!.totalIzin ?? 0,
                  ),
                  _buildPdfStatRow(
                    'stats.total_alpha'.tr(),
                    _calculateTotalAlpha(),
                  ),
                ],
              ),
            ),
            if (_historyData != null &&
                _historyData!.data != null &&
                _historyData!.data!.isNotEmpty) ...[
              pw.SizedBox(height: 25),
              pw.Text(
                'stats.history_section'.tr().toUpperCase(),
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 15),
              _buildHistoryTableForPdf(_historyData!),
            ],
            pw.SizedBox(height: 25),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                'stats.generated_on'.tr(
                  args: [
                    DateFormat(
                      'dd MMMM yyyy HH:mm',
                      currentLocale,
                    ).format(DateTime.now()),
                  ],
                ),
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey600,
                ),
              ),
            ),
          ],
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
      _showSnackBar('stats.export_success'.tr());
    } catch (e) {
      _showSnackBar(
        'stats.export_failed'.tr(args: [e.toString()]),
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      isError
          ? AppTheme.errorSnackBar(message)
          : AppTheme.successSnackBar(message),
    );
  }

  int _calculateTotalAlpha() {
    if (_statsData == null || _statsData!.data == null) return 0;
    final totalAbsen = _statsData!.data!.totalAbsen ?? 0;
    final totalMasuk = _statsData!.data!.totalMasuk ?? 0;
    final totalIzin = _statsData!.data!.totalIzin ?? 0;
    final totalAlpha = totalAbsen - (totalMasuk + totalIzin);
    return totalAlpha > 0 ? totalAlpha : 0;
  }

  _GamificationData _calculateGamificationData() {
    final totalMasuk = _statsData?.data?.totalMasuk ?? 0;
    final progressPercentage =
        totalMasuk >= _targetDays ? 1.0 : totalMasuk / _targetDays;
    final xp = totalMasuk * 10;
    final level = _calculateLevel(xp);
    final currentLevelXp = _getXpForLevel(level);
    final nextLevelXp = _getXpForLevel(level + 1);
    final xpInLevel = xp - currentLevelXp;
    final xpForNextLevel = nextLevelXp - currentLevelXp;
    final levelProgress = xpForNextLevel > 0 ? xpInLevel / xpForNextLevel : 0.0;

    return _GamificationData(
      progress: progressPercentage,
      level: level,
      xp: xp,
      progressMessage: _getMotivationalMessage(progressPercentage),
      levelProgress: levelProgress,
    );
  }

  int _getXpForLevel(int level) {
    const levels = {
      1: 0,
      2: 20,
      3: 80,
      4: 200,
      5: 500,
      6: 1000,
      7: 1800,
      8: 2800,
      9: 4000,
      10: 5500,
    };
    return levels[level] ?? 100000;
  }

  int _calculateLevel(int xp) {
    if (xp >= 5500) return 10;
    if (xp >= 4000) return 9;
    if (xp >= 2800) return 8;
    if (xp >= 1800) return 7;
    if (xp >= 1000) return 6;
    if (xp >= 500) return 5;
    if (xp >= 200) return 4;
    if (xp >= 80) return 3;
    if (xp >= 20) return 2;
    return 1;
  }

  String _getMotivationalMessage(double progress) {
    if (progress >= 1.0) return 'stats.target_achieved'.tr();
    if (progress >= 0.8) return 'stats.almost_there'.tr();
    if (progress >= 0.5) return 'stats.halfway'.tr();
    if (progress > 0) return 'stats.good_start'.tr();
    return 'stats.start_your_journey'.tr();
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
          ? _buildLoadingView(isDarkMode)
          : _errorMessage.isNotEmpty
              ? _buildErrorView(isDarkMode)
              : _statsData == null || _statsData!.data == null
                  ? _buildEmptyView(isDarkMode)
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      color: theme.colorScheme.primary,
                      backgroundColor: AppTheme.getSurfaceColor(context),
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: CustomScrollView(
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
                                  "stats.title".tr(),
                                  style: GoogleFonts.manrope(
                                    fontWeight: FontWeight.bold,
                                    color: theme.textTheme.titleLarge?.color,
                                  ),
                                ),
                                background:
                                    Container(color: scaffoldBackgroundColor),
                              ),
                              actions: [
                                IconButton(
                                  icon: Icon(
                                    Icons.people_outline_rounded,
                                    color:
                                        AppTheme.getTextPrimaryColor(context),
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const AllUsersPage(),
                                      ),
                                    );
                                  },
                                  tooltip: 'all_users.title'.tr(),
                                ),
                                const SizedBox(width: AppTheme.spacing8),
                              ],
                            ),
                            SliverList(
                              delegate: SliverChildListDelegate([
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: AppTheme.spacing16),
                                  child: Column(
                                    children: [
                                      _buildGamificationCard(isDarkMode),
                                      const SizedBox(
                                          height: AppTheme.spacing16),
                                      _buildSummaryCard(isDarkMode),
                                      const SizedBox(
                                          height: AppTheme.spacing16),
                                      _buildExportCard(isDarkMode),
                                      const SizedBox(
                                          height: AppTheme.spacing24),
                                    ],
                                  ),
                                ),
                              ]),
                            ),
                          ],
                        ),
                      ),
                    ),
    );
  }

  Widget _buildGamificationCard(bool isDarkMode) {
    final data = _calculateGamificationData();
    final theme = Theme.of(context);
    final totalMasuk = _statsData?.data?.totalMasuk ?? 0;
    final totalIzin = _statsData?.data?.totalIzin ?? 0;
    final totalAlpha = _calculateTotalAlpha();
    final hasChartData = (totalMasuk + totalIzin + totalAlpha) > 0;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing20),
      decoration: AppTheme.elevatedCard(isDark: isDarkMode),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primary,
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: data.levelProgress,
                      strokeWidth: 5,
                      backgroundColor:
                          theme.colorScheme.onPrimary.withOpacity(0.3),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme.colorScheme.onPrimary,
                      ),
                    ),
                    Center(
                      child: Text(
                        '${data.level}',
                        style: GoogleFonts.manrope(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppTheme.spacing20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'stats.level_progress_title'.tr(),
                      style: GoogleFonts.manrope(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.getTextPrimaryColor(context),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppTheme.spacing4),
                    Text(
                      data.progressMessage,
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        color: AppTheme.getTextSecondaryColor(context),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppTheme.spacing8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacing12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(AppTheme.radius8),
                        border: Border.all(
                          color: theme.colorScheme.primary.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '${data.xp} XP',
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (hasChartData) ...[
            const SizedBox(height: AppTheme.spacing20),
            AppTheme.divider(isDark: isDarkMode),
            const SizedBox(height: AppTheme.spacing20),
            SegmentedButton<ChartType>(
              segments: <ButtonSegment<ChartType>>[
                ButtonSegment<ChartType>(
                  value: ChartType.pie,
                  label: Text(
                    'stats.pie_chart'.tr(),
                    style: GoogleFonts.manrope(fontSize: 12),
                  ),
                  icon: const Icon(Icons.pie_chart_outline_rounded, size: 18),
                ),
                ButtonSegment<ChartType>(
                  value: ChartType.bar,
                  label: Text(
                    'stats.bar_chart'.tr(),
                    style: GoogleFonts.manrope(fontSize: 12),
                  ),
                  icon: const Icon(Icons.bar_chart_rounded, size: 18),
                ),
              ],
              selected: {_selectedChartType},
              onSelectionChanged: (Set<ChartType> newSelection) =>
                  setState(() => _selectedChartType = newSelection.first),
              style: SegmentedButton.styleFrom(
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                foregroundColor: AppTheme.getTextSecondaryColor(context),
                selectedForegroundColor: theme.colorScheme.onPrimary,
                selectedBackgroundColor: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: AppTheme.spacing20),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(scale: animation, child: child),
                );
              },
              child: Container(
                key: ValueKey<ChartType>(_selectedChartType),
                child: _selectedChartType == ChartType.pie
                    ? _buildModernPieChart(isDarkMode)
                    : _buildModernBarChart(isDarkMode),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildModernPieChart(bool isDarkMode) {
    final theme = Theme.of(context);
    final totalMasuk = _statsData!.data!.totalMasuk ?? 0;
    final totalIzin = _statsData!.data!.totalIzin ?? 0;
    final totalAlpha = _calculateTotalAlpha();
    final total = totalMasuk + totalIzin + totalAlpha;

    final data = [
      _ChartData(
        'home.present_label'.tr(),
        totalMasuk,
        AppTheme.getStatusColor('present'),
      ),
      _ChartData(
        'home.leave_label'.tr(),
        totalIzin,
        AppTheme.getStatusColor('leave'),
      ),
      _ChartData(
        'home.alpha_label'.tr(),
        totalAlpha,
        AppTheme.getStatusColor('absent'),
      ),
    ].where((item) => item.value > 0).toList();

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: SfCircularChart(
            margin: EdgeInsets.zero,
            series: <CircularSeries<_ChartData, String>>[
              DoughnutSeries<_ChartData, String>(
                dataSource: data,
                xValueMapper: (_ChartData data, _) => data.label,
                yValueMapper: (_ChartData data, _) => data.value,
                pointColorMapper: (_ChartData data, _) => data.color,
                innerRadius: '65%',
                radius: '90%',
                strokeColor: AppTheme.getBackgroundColor(context),
                strokeWidth: 3,
                dataLabelMapper: (_ChartData data, _) => '${data.value}',
                dataLabelSettings: DataLabelSettings(
                  isVisible: true,
                  labelPosition: ChartDataLabelPosition.outside,
                  connectorLineSettings: ConnectorLineSettings(
                    type: ConnectorType.curve,
                    width: 2,
                    length: '15%',
                    color: AppTheme.getTextSecondaryColor(context)
                        .withOpacity(0.5),
                  ),
                  textStyle: GoogleFonts.manrope(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.getTextPrimaryColor(context),
                  ),
                  labelIntersectAction: LabelIntersectAction.shift,
                  useSeriesColor: false,
                ),
                explode: true,
                explodeOffset: '5%',
                explodeAll: false,
                explodeIndex: 0,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.spacing16),
        Container(
          padding: const EdgeInsets.all(AppTheme.spacing16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppTheme.radius12),
          ),
          child: Wrap(
            spacing: 20,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: data.map((item) {
              final percentage = (item.value / total * 100).toStringAsFixed(1);
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: item.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacing8),
                  Flexible(
                    child: Text(
                      '${item.label}: ',
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.getTextPrimaryColor(context),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '$percentage%',
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: item.color,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildModernBarChart(bool isDarkMode) {
    final theme = Theme.of(context);
    final totalMasuk = _statsData!.data!.totalMasuk ?? 0;
    final totalIzin = _statsData!.data!.totalIzin ?? 0;
    final totalAlpha = _calculateTotalAlpha();

    final data = [
      _ChartData(
        'home.present_label'.tr(),
        totalMasuk,
        AppTheme.getStatusColor('present'),
      ),
      _ChartData(
        'home.leave_label'.tr(),
        totalIzin,
        AppTheme.getStatusColor('leave'),
      ),
      _ChartData(
        'home.alpha_label'.tr(),
        totalAlpha,
        AppTheme.getStatusColor('absent'),
      ),
    ];

    return Container(
      height: 280,
      padding: const EdgeInsets.all(AppTheme.spacing12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppTheme.radius12),
      ),
      child: SfCartesianChart(
        plotAreaBorderWidth: 0,
        primaryXAxis: CategoryAxis(
          majorGridLines: const MajorGridLines(width: 0),
          axisLine: const AxisLine(width: 0),
          majorTickLines: const MajorTickLines(width: 0),
          labelStyle: GoogleFonts.manrope(
            color: AppTheme.getTextSecondaryColor(context),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        primaryYAxis: NumericAxis(
          majorGridLines: MajorGridLines(
            width: 1,
            color: theme.colorScheme.outline.withOpacity(0.3),
            dashArray: const <double>[5, 5],
          ),
          axisLine: const AxisLine(width: 0),
          majorTickLines: const MajorTickLines(width: 0),
          labelStyle: GoogleFonts.manrope(
            color: AppTheme.getTextSecondaryColor(context),
            fontSize: 11,
          ),
        ),
        series: <CartesianSeries>[
          ColumnSeries<_ChartData, String>(
            dataSource: data,
            xValueMapper: (_ChartData data, _) => data.label,
            yValueMapper: (_ChartData data, _) => data.value,
            pointColorMapper: (_ChartData data, _) => data.color,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(AppTheme.radius8),
              topRight: Radius.circular(AppTheme.radius8),
            ),
            width: 0.6,
            spacing: 0.15,
            dataLabelMapper: (_ChartData data, _) => '${data.value}',
            dataLabelSettings: DataLabelSettings(
              isVisible: true,
              labelAlignment: ChartDataLabelAlignment.top,
              textStyle: GoogleFonts.manrope(
                color: AppTheme.getTextPrimaryColor(context),
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(bool isDarkMode) {
    final totalAbsen = _statsData!.data!.totalAbsen ?? 0;
    final totalMasuk = _statsData!.data!.totalMasuk ?? 0;
    final totalIzin = _statsData!.data!.totalIzin ?? 0;
    final totalAlpha = _calculateTotalAlpha();

    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppTheme.spacing12,
        horizontal: AppTheme.spacing20,
      ),
      decoration: AppTheme.elevatedCard(isDark: isDarkMode),
      child: Column(
        children: [
          _buildStatRow(
            Icons.calendar_today_rounded,
            'stats.total_days_absen'.tr(),
            '$totalAbsen',
            AppTheme.getStatusColor('info'),
          ),
          _buildDivider(isDarkMode),
          _buildStatRow(
            Icons.check_circle_outline_rounded,
            'stats.total_present'.tr(),
            '$totalMasuk',
            AppTheme.getStatusColor('present'),
          ),
          _buildDivider(isDarkMode),
          _buildStatRow(
            Icons.info_outline_rounded,
            'stats.total_leave'.tr(),
            '$totalIzin',
            AppTheme.getStatusColor('leave'),
          ),
          _buildDivider(isDarkMode),
          _buildStatRow(
            Icons.highlight_off_rounded,
            'stats.total_alpha'.tr(),
            '$totalAlpha',
            AppTheme.getStatusColor('absent'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(IconData icon, String title, String value, Color color) {
    final iconBgColor = color.withOpacity(0.1);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacing12),
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: AppTheme.spacing16),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.manrope(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.getTextPrimaryColor(context),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.getTextPrimaryColor(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportCard(bool isDarkMode) {
    final color = AppTheme.getStatusColor('absent');
    final iconBgColor = color.withOpacity(0.1);

    return Container(
      decoration: AppTheme.elevatedCard(isDark: isDarkMode),
      child: ListTile(
        onTap: _isExporting ? null : _exportToPdf,
        leading: Container(
          padding: const EdgeInsets.all(AppTheme.spacing12),
          decoration: BoxDecoration(color: iconBgColor, shape: BoxShape.circle),
          child: Icon(
            Icons.picture_as_pdf_outlined,
            size: 22,
            color: color,
          ),
        ),
        title: Text(
          'stats.export_to_pdf'.tr(),
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: AppTheme.getTextPrimaryColor(context),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: _isExporting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.getTextSecondaryColor(context),
              ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacing20,
          vertical: AppTheme.spacing12,
        ),
      ),
    );
  }

  Widget _buildDivider(bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.only(left: 58.0),
      child: AppTheme.divider(isDark: isDarkMode),
    );
  }

  Widget _buildLoadingView(bool isDarkMode) =>
      AppTheme.loadingIndicator(isDark: isDarkMode);

  Widget _buildErrorView(bool isDarkMode) {
    return AppTheme.emptyState(
      title: 'history.error_title'.tr(),
      message: _errorMessage,
      icon: Icons.cloud_off_rounded,
      isDark: isDarkMode,
      action: ElevatedButton.icon(
        onPressed: _loadData,
        icon: const Icon(Icons.refresh_rounded, size: 18),
        label: Text('history.try_again'.tr()),
        style: Theme.of(context).elevatedButtonTheme.style,
      ),
    );
  }

  Widget _buildEmptyView(bool isDarkMode) {
    return AppTheme.emptyState(
      title: 'stats.no_data_title'.tr(),
      message: 'stats.no_data_subtitle'.tr(),
      icon: Icons.analytics_outlined,
      isDark: isDarkMode,
    );
  }
}

class _ChartData {
  final String label;
  final int value;
  final Color color;
  _ChartData(this.label, this.value, this.color);
}

class _GamificationData {
  final double progress;
  final int level;
  final int xp;
  final String progressMessage;
  final double levelProgress;

  _GamificationData({
    required this.progress,
    required this.level,
    required this.xp,
    required this.progressMessage,
    required this.levelProgress,
  });
}

pw.Widget _buildPdfStatRow(String label, int value) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 6),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 12)),
        pw.Text(
          value.toString(),
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
        ),
      ],
    ),
  );
}

pw.Widget _buildPdfGamificationSection(_GamificationData data) {
  return pw.Container(
    padding: const pw.EdgeInsets.all(15),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: PdfColors.grey300),
      borderRadius: pw.BorderRadius.circular(8),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'stats.current_level'.tr(),
              style: const pw.TextStyle(fontSize: 12),
            ),
            pw.Text(
              '${data.level} (${data.xp} XP)',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.purple700,
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'stats.attendance_progress'.tr(
            args: ['${(data.progress * 100).toStringAsFixed(0)}%'],
          ),
          style: const pw.TextStyle(fontSize: 12),
        ),
        pw.SizedBox(height: 5),
        pw.LinearProgressIndicator(
          value: data.progress,
          backgroundColor: PdfColors.grey200,
          valueColor: PdfColors.purple400,
        ),
      ],
    ),
  );
}

pw.Widget _buildHistoryTableForPdf(HistoryAbsenModel historyData) {
  final historyRecords = historyData.data!;
  return pw.Table(
    border: pw.TableBorder.all(color: PdfColors.grey300),
    columnWidths: {
      0: const pw.FlexColumnWidth(1.5),
      1: const pw.FlexColumnWidth(1),
      2: const pw.FlexColumnWidth(1),
      3: const pw.FlexColumnWidth(1),
    },
    children: [
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey100),
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Text(
              'stats.table_date'.tr(),
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Text(
              'home.check_in'.tr(),
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Text(
              'home.check_out'.tr(),
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Text(
              'stats.table_status'.tr(),
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
        ],
      ),
      ...historyRecords.take(20).map((record) {
        return pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                record.attendanceDate != null
                    ? DateFormat('dd/MM/yyyy').format(record.attendanceDate!)
                    : '-',
                style: const pw.TextStyle(fontSize: 10),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                record.checkInTime ?? '-',
                style: const pw.TextStyle(fontSize: 10),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                record.checkOutTime ?? '-',
                style: const pw.TextStyle(fontSize: 10),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                (record.status ?? '-').tr(),
                style: pw.TextStyle(
                  color: _getStatusColorPdf(record.status ?? ''),
                  fontSize: 10,
                ),
              ),
            ),
          ],
        );
      }),
    ],
  );
}

PdfColor _getStatusColorPdf(String status) {
  switch (status.toLowerCase()) {
    case 'hadir':
    case 'present':
      return PdfColors.green700;
    case 'terlambat':
    case 'late':
      return PdfColors.orange700;
    case 'izin':
    case 'leave':
      return PdfColors.blue700;
    case 'alpha':
      return PdfColors.red700;
    default:
      return PdfColors.black;
  }
}
