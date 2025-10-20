// lib/stats.dart

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
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
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
    final isDarkMode = theme.brightness == Brightness.dark;
    final scaffoldBackgroundColor =
        isDarkMode ? Colors.black : const Color(0xFFF3F4F6);
    final cardBackgroundColor =
        isDarkMode ? const Color(0xFF1C1C1E) : Colors.white;

    return Scaffold(
      backgroundColor: scaffoldBackgroundColor,
      body: _isLoading
          ? _buildLoadingView()
          : _errorMessage.isNotEmpty
              ? _buildErrorView()
              : _statsData == null || _statsData!.data == null
                  ? _buildEmptyView()
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      color: theme.colorScheme.primary,
                      backgroundColor: cardBackgroundColor,
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
                                  left: 20,
                                  bottom: 16,
                                ),
                                title: Text(
                                  "stats.title".tr(),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.bold,
                                    color: theme.textTheme.titleLarge?.color,
                                  ),
                                ),
                                background:
                                    Container(color: scaffoldBackgroundColor),
                              ),
                              // --- AWAL PERUBAHAN ---
                              actions: [
                                IconButton(
                                  icon:
                                      const Icon(Icons.people_outline_rounded),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const AllUsersPage(),
                                      ),
                                    );
                                  },
                                  tooltip: 'Lihat Semua Pengguna',
                                ),
                                const SizedBox(width: 8),
                              ],
                              // --- AKHIR PERUBAHAN ---
                            ),
                            SliverList(
                              delegate: SliverChildListDelegate([
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0),
                                  child: Column(
                                    children: [
                                      _buildGamificationCard(
                                          cardBackgroundColor),
                                      const SizedBox(height: 20),
                                      _buildSummaryCard(cardBackgroundColor),
                                      const SizedBox(height: 20),
                                      _buildExportCard(cardBackgroundColor),
                                      const SizedBox(height: 24),
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

  Widget _buildGamificationCard(Color cardColor) {
    final data = _calculateGamificationData();
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final totalMasuk = _statsData?.data?.totalMasuk ?? 0;
    final totalIzin = _statsData?.data?.totalIzin ?? 0;
    final totalAlpha = _calculateTotalAlpha();
    final hasChartData = (totalMasuk + totalIzin + totalAlpha) > 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          // Level Section
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
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'stats.level_progress_title'.tr(),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      data.progressMessage,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: theme.colorScheme.primary.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '${data.xp} XP',
                        style: GoogleFonts.plusJakartaSans(
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

          // Chart Section
          if (hasChartData) ...[
            const SizedBox(height: 20),
            Divider(
              color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
              thickness: 1,
            ),
            const SizedBox(height: 20),

            // Chart Type Selector
            SegmentedButton<ChartType>(
              segments: <ButtonSegment<ChartType>>[
                ButtonSegment<ChartType>(
                  value: ChartType.pie,
                  label: Text(
                    'stats.pie_chart'.tr(),
                    style: const TextStyle(fontSize: 12),
                  ),
                  icon: const Icon(Icons.pie_chart_outline_rounded, size: 18),
                ),
                ButtonSegment<ChartType>(
                  value: ChartType.bar,
                  label: Text(
                    'stats.bar_chart'.tr(),
                    style: const TextStyle(fontSize: 12),
                  ),
                  icon: const Icon(Icons.bar_chart_rounded, size: 18),
                ),
              ],
              selected: {_selectedChartType},
              onSelectionChanged: (Set<ChartType> newSelection) =>
                  setState(() => _selectedChartType = newSelection.first),
              style: SegmentedButton.styleFrom(
                backgroundColor:
                    isDarkMode ? Colors.grey.shade900 : Colors.grey.shade100,
                foregroundColor:
                    isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                selectedForegroundColor: theme.colorScheme.onPrimary,
                selectedBackgroundColor: theme.colorScheme.primary,
              ),
            ),

            const SizedBox(height: 20),

            // Chart Display
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
                    ? _buildModernPieChart()
                    : _buildModernBarChart(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildModernPieChart() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final totalMasuk = _statsData!.data!.totalMasuk ?? 0;
    final totalIzin = _statsData!.data!.totalIzin ?? 0;
    final totalAlpha = _calculateTotalAlpha();
    final total = totalMasuk + totalIzin + totalAlpha;

    final data = [
      _ChartData(
        'home.present_label'.tr(),
        totalMasuk,
        const Color(0xFF10B981),
      ),
      _ChartData('home.leave_label'.tr(), totalIzin, const Color(0xFFF59E0B)),
      _ChartData('home.alpha_label'.tr(), totalAlpha, const Color(0xFFEF4444)),
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
                strokeColor:
                    isDarkMode ? const Color(0xFF1C1C1E) : Colors.white,
                strokeWidth: 3,
                dataLabelMapper: (_ChartData data, _) => '${data.value}',
                dataLabelSettings: DataLabelSettings(
                  isVisible: true,
                  labelPosition: ChartDataLabelPosition.outside,
                  connectorLineSettings: ConnectorLineSettings(
                    type: ConnectorType.curve,
                    width: 2,
                    length: '15%',
                    color: isDarkMode
                        ? Colors.grey.shade600
                        : Colors.grey.shade400,
                  ),
                  textStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
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
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
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
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      '${item.label}: ',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '$percentage%',
                    style: GoogleFonts.plusJakartaSans(
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

  Widget _buildModernBarChart() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final totalMasuk = _statsData!.data!.totalMasuk ?? 0;
    final totalIzin = _statsData!.data!.totalIzin ?? 0;
    final totalAlpha = _calculateTotalAlpha();

    final data = [
      _ChartData(
        'home.present_label'.tr(),
        totalMasuk,
        const Color(0xFF10B981),
      ),
      _ChartData('home.leave_label'.tr(), totalIzin, const Color(0xFFF59E0B)),
      _ChartData('home.alpha_label'.tr(), totalAlpha, const Color(0xFFEF4444)),
    ];

    return Container(
      height: 280,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SfCartesianChart(
        plotAreaBorderWidth: 0,
        primaryXAxis: CategoryAxis(
          majorGridLines: const MajorGridLines(width: 0),
          axisLine: const AxisLine(width: 0),
          majorTickLines: const MajorTickLines(width: 0),
          labelStyle: GoogleFonts.plusJakartaSans(
            color: isDarkMode ? Colors.white70 : Colors.black54,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        primaryYAxis: NumericAxis(
          majorGridLines: MajorGridLines(
            width: 1,
            color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300,
            dashArray: const <double>[5, 5],
          ),
          axisLine: const AxisLine(width: 0),
          majorTickLines: const MajorTickLines(width: 0),
          labelStyle: GoogleFonts.plusJakartaSans(
            color: isDarkMode ? Colors.white70 : Colors.black54,
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
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
            width: 0.6,
            spacing: 0.15,
            dataLabelMapper: (_ChartData data, _) => '${data.value}',
            dataLabelSettings: DataLabelSettings(
              isVisible: true,
              labelAlignment: ChartDataLabelAlignment.top,
              textStyle: GoogleFonts.plusJakartaSans(
                color: isDarkMode ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(Color cardColor) {
    final totalAbsen = _statsData!.data!.totalAbsen ?? 0;
    final totalMasuk = _statsData!.data!.totalMasuk ?? 0;
    final totalIzin = _statsData!.data!.totalIzin ?? 0;
    final totalAlpha = _calculateTotalAlpha();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          _buildStatRow(
            Icons.calendar_today_rounded,
            'stats.total_days_absen'.tr(),
            '$totalAbsen',
            Colors.blue,
          ),
          _buildDivider(),
          _buildStatRow(
            Icons.check_circle_outline_rounded,
            'stats.total_present'.tr(),
            '$totalMasuk',
            Colors.green,
          ),
          _buildDivider(),
          _buildStatRow(
            Icons.info_outline_rounded,
            'stats.total_leave'.tr(),
            '$totalIzin',
            Colors.orange,
          ),
          _buildDivider(),
          _buildStatRow(
            Icons.highlight_off_rounded,
            'stats.total_alpha'.tr(),
            '$totalAlpha',
            Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(IconData icon, String title, String value, Color color) {
    final iconBgColor = color.withOpacity(0.15);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportCard(Color cardColor) {
    final iconBgColor = Colors.red.withOpacity(0.15);

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: ListTile(
        onTap: _isExporting ? null : _exportToPdf,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: iconBgColor, shape: BoxShape.circle),
          child: const Icon(
            Icons.picture_as_pdf_outlined,
            size: 22,
            color: Colors.red,
          ),
        ),
        title: Text(
          'stats.export_to_pdf'.tr(),
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600,
            fontSize: 16,
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
            : Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      indent: 54,
      color: Theme.of(context).brightness == Brightness.dark
          ? Colors.grey.shade800
          : Colors.grey.shade200,
    );
  }

  Widget _buildLoadingView() =>
      const Center(child: CircularProgressIndicator.adaptive());

  Widget _buildErrorView() {
    return Center(
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
              onPressed: _loadData,
              icon: const Icon(Icons.refresh_rounded),
              label: Text('history.try_again'.tr()),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.analytics_outlined, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'stats.no_data_title'.tr(),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'stats.no_data_subtitle'.tr(),
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
