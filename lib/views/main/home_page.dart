import 'dart:async';
import 'dart:math';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timely/providers/home_provider.dart';
import 'package:timely/widgets/absen_stats_card.dart';
import 'package:timely/widgets/absen_status_card.dart';
import 'package:timely/widgets/attendance_action_section.dart';
import 'package:timely/widgets/location_card.dart';
import 'package:timely/widgets/sliver_home_app_bar.dart';

import '../../services/local_notification.dart';

class ModernHomePage extends StatefulWidget {
  final void Function(String) showSnackBar;
  const ModernHomePage({super.key, required this.showSnackBar});

  @override
  State<ModernHomePage> createState() => _ModernHomePageState();
}

class _ModernHomePageState extends State<ModernHomePage>
    with
        TickerProviderStateMixin,
        WidgetsBindingObserver,
        AutomaticKeepAliveClientMixin<ModernHomePage> {
  @override
  bool get wantKeepAlive => true;

  // --- State Lokal (UI & Logika Non-Data) ---
  late Timer _timer;
  DateTime _now = DateTime.now();
  GoogleMapController? _mapController;
  LatLng _currentPosition = const LatLng(-6.200000, 106.816666);
  String _currentAddress = "Mendapatkan lokasi...";
  final Set<Marker> _markers = {};
  Circle? _officeCircle;
  final LatLng _officeLocation = const LatLng(
    -6.326006197470815,
    106.87298491839785,
  );
  final double _officeRadius = 50.0;
  bool _isSubmitting = false;
  bool _isLoadingLocation = false;
  late final AnimationController _mainAnimationController;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 8, minute: 0);
  bool _reminderEnabled = true;
  final Map<String, String> _randomQuestions = const {
    'Tuliskan angka 9': '9',
    'Tuliskan nama hari ini (contoh: Jumat)': 'dayName',
    'Tuliskan 2 digit terakhir tahun ini': 'yearEnd',
  };
  String _currentQuestionText = '';
  String _correctAnswer = '';
  String _actionAfterQuestion = '';

  static const int _checkInTargetHour = 8;
  static const int _checkInTargetMinute = 0;
  static const int _checkOutTargetHour = 15;
  static const int _checkOutTargetMinute = 0;

  bool get _isInOfficeArea {
    final distance = Geolocator.distanceBetween(
      _currentPosition.latitude,
      _currentPosition.longitude,
      _officeLocation.latitude,
      _officeLocation.longitude,
    );
    return distance <= _officeRadius;
  }

  bool _canCheckIn(HomeProvider provider) =>
      !provider.hasCheckedIn && provider.todayStatusKey != "leave";
  bool _canCheckOut(HomeProvider provider) =>
      provider.hasCheckedIn && !provider.hasCheckedOut;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _mainAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeProvider>().fetchData();
    });

    _loadReminderSettings();
    _getCurrentLocation();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final newTime = DateTime.now();
      if (_now.minute != newTime.minute) {
        if (mounted) setState(() => _now = newTime);
      } else {
        _now = newTime;
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _mainAnimationController.dispose();
    _mapController?.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    super.didChangePlatformBrightness();
    if (mounted) _setMapStyle();
  }

  Future<void> _handleRefresh() async {
    HapticFeedback.mediumImpact();
    await Future.wait([
      context.read<HomeProvider>().fetchData(),
      _getCurrentLocation(),
    ]);
  }

  Future<void> _handleLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      widget.showSnackBar('Layanan lokasi tidak aktif. Mohon aktifkan.');
      return Future.error('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        widget.showSnackBar('Izin lokasi ditolak.');
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      widget.showSnackBar(
        'Izin lokasi ditolak permanen, kami tidak dapat meminta izin.',
      );
      return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.',
      );
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      await _handleLocationPermission();
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (mounted) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
          _currentAddress = placemarks.isNotEmpty
              ? "${placemarks[0].street}, ${placemarks[0].subLocality}"
              : "Alamat tidak ditemukan";
          _updateMarkersAndCircle();
          _mapController?.animateCamera(
            CameraUpdate.newLatLng(_currentPosition),
          );
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _currentAddress = "Gagal mendapatkan lokasi.");
      }
      if (kDebugMode) print("Error getting location: $e");
    } finally {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  void _updateMarkersAndCircle() {
    final theme = Theme.of(context);
    _markers.clear();
    _markers.add(
      Marker(
        markerId: const MarkerId('office'),
        position: _officeLocation,
        infoWindow: const InfoWindow(title: 'Kantor'),
      ),
    );
    _officeCircle = Circle(
      circleId: const CircleId('officeRadius'),
      center: _officeLocation,
      radius: _officeRadius,
      fillColor: theme.colorScheme.primary.withOpacity(0.1),
      strokeColor: theme.colorScheme.primary,
      strokeWidth: 2,
    );
  }

  Future<void> _setMapStyle() async {
    try {
      final isDarkMode = Theme.of(context).brightness == Brightness.dark;
      final style = await rootBundle.loadString(
        isDarkMode
            ? 'assets/maps/maps_styles_dark.json'
            : 'assets/maps/maps_styles_ligh.json',
      );
      _mapController?.setMapStyle(style);
    } catch (e) {
      if (kDebugMode) print("Error setting map style: $e");
    }
  }

  Future<void> _onCheckIn() async {
    if (!_isInOfficeArea) {
      widget.showSnackBar("Anda berada di luar radius kantor yang diizinkan.");
      return;
    }
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      await context.read<HomeProvider>().checkIn(
            _currentPosition.latitude,
            _currentPosition.longitude,
            _currentAddress,
          );
      if (mounted) {
        widget.showSnackBar("Absen masuk berhasil!");
        HapticFeedback.mediumImpact();
      }
    } catch (e) {
      widget.showSnackBar("Gagal: $e");
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _onCheckOut() async {
    if (!_isInOfficeArea) {
      widget.showSnackBar("Anda berada di luar radius kantor yang diizinkan.");
      return;
    }
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      await context.read<HomeProvider>().checkOut(
            _currentPosition.latitude,
            _currentPosition.longitude,
            _currentAddress,
          );
      if (mounted) {
        widget.showSnackBar("Absen pulang berhasil!");
        HapticFeedback.mediumImpact();
      }
    } catch (e) {
      widget.showSnackBar("Gagal: $e");
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _onAjukanIzin(String reason) async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      await context.read<HomeProvider>().ajukanIzin(reason);
      if (mounted) {
        widget.showSnackBar("Pengajuan izin berhasil dikirim.");
        HapticFeedback.mediumImpact();
      }
    } catch (e) {
      widget.showSnackBar("Gagal: $e");
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _getTimeDifferenceMessage(HomeProvider provider) {
    if (!provider.hasCheckedIn && provider.todayStatusKey != "leave") {
      return _formatTimeDifference(
        _now,
        _checkInTargetHour,
        _checkInTargetMinute,
        'check_in',
      );
    }
    if (provider.hasCheckedIn && !provider.hasCheckedOut) {
      return _formatTimeDifference(
        _now,
        _checkOutTargetHour,
        _checkOutTargetMinute,
        'check_out',
      );
    }
    return 'messages.attendance_complete'.tr();
  }

  String _formatTimeDifference(
    DateTime now,
    int targetHour,
    int targetMinute,
    String actionKey,
  ) {
    final targetTime = DateTime(
      now.year,
      now.month,
      now.day,
      targetHour,
      targetMinute,
    );
    final difference = targetTime.difference(now);
    final action = 'actions.$actionKey'.tr();
    if (difference.inMinutes.abs() < 1) {
      return 'messages.time_to_act'.tr(namedArgs: {'action': action});
    }
    final isLate = difference.isNegative;
    final diff = difference.abs();
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
    final timeText = hours > 0
        ? 'messages.time_format_hm'.tr(
            namedArgs: {
              'hours': hours.toString(),
              'minutes': minutes.toString(),
            },
          )
        : 'messages.time_format_m'.tr(
            namedArgs: {'minutes': minutes.toString()},
          );
    return isLate
        ? 'messages.time_elapsed'.tr(
            namedArgs: {'time': timeText, 'action': action},
          )
        : 'messages.time_remaining'.tr(
            namedArgs: {'time': timeText, 'action': action},
          );
  }

  String _getAttendanceBadgeKey(HomeProvider provider) {
    if (provider.checkInTime == null) return '';
    final targetTime = DateTime(
      provider.checkInTime!.year,
      provider.checkInTime!.month,
      provider.checkInTime!.day,
      _checkInTargetHour,
      _checkInTargetMinute,
    );
    return provider.checkInTime!
            .isAfter(targetTime.add(const Duration(minutes: 1)))
        ? 'late'
        : 'on_time';
  }

  void _startAbsenProcess(String action) {
    if (_isLoadingLocation || _isSubmitting) return;
    _generateRandomQuestion(action);
    _showRandomQuestionDialog();
  }

  void _generateRandomQuestion(String action) {
    final random = Random();
    final keys = _randomQuestions.keys.toList();
    _currentQuestionText = keys[random.nextInt(keys.length)];
    _correctAnswer = _randomQuestions[_currentQuestionText] == 'dayName'
        ? DateFormat('EEEE', 'id_ID').format(DateTime.now())
        : (_randomQuestions[_currentQuestionText] == 'yearEnd'
            ? DateTime.now().year.toString().substring(2)
            : '9');
    _actionAfterQuestion = action;
  }

  void _showRandomQuestionDialog() {
    final answerController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Verifikasi Anti-Bot"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Untuk melanjutkan, mohon jawab pertanyaan berikut:\n"),
            Text(
              _currentQuestionText,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: answerController,
              decoration: const InputDecoration(labelText: "Jawaban Anda"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () {
              if (answerController.text.trim().toLowerCase() ==
                  _correctAnswer.toLowerCase()) {
                Navigator.pop(context);
                if (_actionAfterQuestion == 'checkin') _onCheckIn();
                if (_actionAfterQuestion == 'checkout') _onCheckOut();
              } else {
                widget.showSnackBar("Jawaban salah, silakan coba lagi.");
              }
            },
            child: const Text("Kirim"),
          ),
        ],
      ),
    );
  }

  void _showIzinDialog() {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Ajukan Izin/Cuti"),
        content: TextFormField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: "Alasan",
            hintText: "Sakit, keperluan keluarga, dll.",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                widget.showSnackBar("Alasan tidak boleh kosong.");
                return;
              }
              Navigator.pop(context);
              _onAjukanIzin(reasonController.text);
            },
            child: const Text("Ajukan"),
          ),
        ],
      ),
    );
  }

  Future<void> _loadReminderSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _reminderEnabled = prefs.getBool('reminderEnabled') ?? true;
      final hour = prefs.getInt('reminderHour') ?? 8;
      final minute = prefs.getInt('reminderMinute') ?? 0;
      _reminderTime = TimeOfDay(hour: hour, minute: minute);
    });
  }

  Future<void> _saveReminderSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('reminderEnabled', _reminderEnabled);
    await prefs.setInt('reminderHour', _reminderTime.hour);
    await prefs.setInt('reminderMinute', _reminderTime.minute);
  }

  void _showReminderSettings() {
    TimeOfDay tempTime = _reminderTime;
    bool tempEnabled = _reminderEnabled;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final theme = Theme.of(context);
            return AlertDialog(
              backgroundColor: theme.dialogTheme.backgroundColor,
              shape: theme.dialogTheme.shape,
              title: const Text("Pengaturan Pengingat"),
              contentPadding: const EdgeInsets.only(top: 20),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: const Text("Aktifkan Pengingat Harian"),
                    trailing: Transform.scale(
                      scale: 0.8,
                      child: CupertinoSwitch(
                        value: tempEnabled,
                        onChanged: (value) =>
                            setDialogState(() => tempEnabled = value),
                        activeTrackColor: theme.colorScheme.primary,
                      ),
                    ),
                    onTap: () =>
                        setDialogState(() => tempEnabled = !tempEnabled),
                  ),
                  ListTile(
                    enabled: tempEnabled,
                    title: const Text("Waktu Pengingat"),
                    trailing: Text(tempTime.format(context)),
                    onTap: () async {
                      if (!tempEnabled) return;
                      final newTime = await showTimePicker(
                        context: context,
                        initialTime: tempTime,
                      );
                      if (newTime != null) {
                        setDialogState(() => tempTime = newTime);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Batal"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    setState(() {
                      _reminderTime = tempTime;
                      _reminderEnabled = tempEnabled;
                    });
                    await _saveReminderSettings();
                    Navigator.pop(context);
                    if (_reminderEnabled) {
                      await LocalNotificationService.scheduleDailyReminder(
                        _reminderTime,
                        'Jangan Lupa Absen! ⏰',
                        'Sudah waktunya untuk melakukan absen masuk. Buka aplikasi sekarang.',
                      );
                      widget.showSnackBar(
                        "Pengingat diaktifkan pukul ${_reminderTime.format(context)}.",
                      );
                    } else {
                      await LocalNotificationService.cancelAll();
                      widget.showSnackBar("Pengingat dinonaktifkan.");
                    }
                  },
                  child: const Text("Simpan"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildAnimatedItem(int index, Widget child) {
    final interval = Interval(
      0.1 * index,
      0.6 + 0.1 * index,
      curve: Curves.easeOut,
    );
    return FadeTransition(
      opacity: _mainAnimationController.drive(CurveTween(curve: interval)),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.1),
          end: Offset.zero,
        ).animate(_mainAnimationController.drive(CurveTween(curve: interval))),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final scaffoldBackgroundColor = theme.scaffoldBackgroundColor;
    final cardBackgroundColor = theme.cardColor;
    final textPrimaryColor = theme.colorScheme.onSurface;
    final refreshIndicatorColor = theme.colorScheme.primary;

    final homeProvider = context.watch<HomeProvider>();
    final homeState = homeProvider.state;

    return Scaffold(
      backgroundColor: scaffoldBackgroundColor,
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _handleRefresh,
            color: refreshIndicatorColor,
            backgroundColor: cardBackgroundColor,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                ModernSliverHomeAppBar(
                  userName: homeProvider.userName,
                  userEmail: homeProvider.userEmail,
                  userAvatarUrl: homeProvider.profilePhotoUrl,
                  onNotificationTap: _showReminderSettings,
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  sliver: _buildMainContent(homeProvider, homeState),
                ),
              ],
            ),
          ),
          if (_isSubmitting)
            Container(
              color: Colors.black.withOpacity(0.4),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: cardBackgroundColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator.adaptive(),
                      const SizedBox(height: 16),
                      Text(
                        "Memproses...",
                        style: GoogleFonts.manrope(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: textPrimaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // --- FUNGSI UNTUK MENANGANI STATE UI ---

  Widget _buildMainContent(HomeProvider homeProvider, HomeState homeState) {
    // 1. LOADING STATE: Saat data user (paling penting) belum ada
    if (homeState == HomeState.loading && homeProvider.user == null) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator.adaptive()),
      );
    }

    // 2. ERROR STATE: Saat data user (paling penting) gagal dimuat
    if (homeState == HomeState.error && homeProvider.user == null) {
      return SliverFillRemaining(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Gagal memuat data utama: ${homeProvider.errorMessage}",
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.read<HomeProvider>().fetchData(),
                  child: const Text("Coba Lagi"),
                )
              ],
            ),
          ),
        ),
      );
    }

    // 3. LOADED STATE: Data user sudah ada, tampilkan semua konten
    return SliverList(
      delegate: SliverChildListDelegate.fixed([
        _buildAnimatedItem(
          0,
          AbsenStatusCard(
            isLoading: homeState == HomeState.loading &&
                homeProvider.absenToday == null,
            todayStatusKey: homeProvider.todayStatusKey,
            hasCheckedIn: homeProvider.hasCheckedIn,
            hasCheckedOut: homeProvider.hasCheckedOut,
            checkInTime: homeProvider.checkInTime,
            checkOutTime: homeProvider.checkOutTime,
            attendanceBadgeKey: _getAttendanceBadgeKey(homeProvider),
            timeDifferenceMessage: _getTimeDifferenceMessage(homeProvider),
            onTap: () => context.read<HomeProvider>().fetchData(),
          ),
        ),
        const SizedBox(height: 16),
        _buildAnimatedItem(
          1,
          LocationCard(
            currentAddress: _currentAddress,
            isLoadingLocation: _isLoadingLocation,
            isInOfficeArea: _isInOfficeArea,
            markers: _markers,
            officeCircle: _officeCircle,
            officeLocation: _officeLocation,
            onMapCreated: (controller) {
              _mapController = controller;
              _setMapStyle();
            },
            onRefreshLocation: _getCurrentLocation,
          ),
        ),
        const SizedBox(height: 16),
        _buildAnimatedItem(
          2,
          AttendanceActionsSection(
            isSubmitting: _isSubmitting,
            canCheckIn: _canCheckIn(homeProvider),
            canCheckOut: _canCheckOut(homeProvider),
            onCheckIn: () => _startAbsenProcess('checkin'),
            onCheckOut: () => _startAbsenProcess('checkout'),
            onAjukanIzin: _showIzinDialog,
          ),
        ),
        const SizedBox(height: 16),
        _buildAnimatedItem(
          3,
          homeState == HomeState.loading && homeProvider.absenStats == null
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator.adaptive(),
                  ),
                )
              : homeState == HomeState.error && homeProvider.absenStats == null
                  ? Center(
                      child: Text(
                          "Gagal memuat statistik: ${homeProvider.errorMessage}"))
                  : AbsenStatsCard(statsData: homeProvider.absenStats?.data),
        ),
      ]),
    );
  }
}
