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
import 'package:timely/utils/app_theme.dart';
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

  late Timer _timer;
  DateTime _now = DateTime.now();
  GoogleMapController? _mapController;
  LatLng _currentPosition = const LatLng(-6.200000, 106.816666);
  String _currentAddress = "location.getting_location".tr();
  final Set<Marker> _markers = {};
  Circle? _officeCircle;
  final LatLng _officeLocation =
      const LatLng(-6.210872482049023, 106.81294381543442);
  final double _officeRadius = 20.0;
  bool _isSubmitting = false;
  bool _isLoadingLocation = false;
  late final AnimationController _mainAnimationController;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 8, minute: 0);
  bool _reminderEnabled = true;
  Map<String, String> _randomQuestions = {};
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
      widget.showSnackBar("home.error.location_service_disabled".tr());
      return Future.error('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        widget.showSnackBar("home.error.location_permission_denied".tr());
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      widget.showSnackBar(
        "home.error.location_permission_denied_forever".tr(),
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
              : "location.address_not_found".tr();
          _updateMarkersAndCircle();
          _mapController?.animateCamera(
            CameraUpdate.newLatLng(_currentPosition),
          );
        });
      }
    } catch (e) {
      if (mounted) {
        setState(
            () => _currentAddress = "location.failed_to_get_location".tr());
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
        markerId: const MarkerId('ppkd'),
        position: _officeLocation,
        infoWindow: const InfoWindow(title: 'PPKD'),
      ),
    );
    _officeCircle = Circle(
      circleId: const CircleId('ppkdRadius'),
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
      widget.showSnackBar("location.out_radius".tr());
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
        ScaffoldMessenger.of(context).showSnackBar(
            AppTheme.successSnackBar("home.snackbar.check_in_success".tr()));
        HapticFeedback.mediumImpact();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(AppTheme.errorSnackBar(
          "forgot_password.generic_error".tr(args: [e.toString()])));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _onCheckOut() async {
    if (!_isInOfficeArea) {
      widget.showSnackBar("location.out_radius".tr());
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
        ScaffoldMessenger.of(context).showSnackBar(
            AppTheme.successSnackBar("home.snackbar.check_out_success".tr()));
        HapticFeedback.mediumImpact();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(AppTheme.errorSnackBar(
          "forgot_password.generic_error".tr(args: [e.toString()])));
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
        ScaffoldMessenger.of(context).showSnackBar(AppTheme.successSnackBar(
            "home.snackbar.leave_request_success".tr()));
        HapticFeedback.mediumImpact();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(AppTheme.errorSnackBar(
          "forgot_password.generic_error".tr(args: [e.toString()])));
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
    _randomQuestions = {
      'home.bot_check.q_number'.tr(): '9',
      'home.bot_check.q_day'.tr(): 'dayName',
      'home.bot_check.q_year'.tr(): 'yearEnd',
    };

    final random = Random();
    final keys = _randomQuestions.keys.toList();
    _currentQuestionText = keys[random.nextInt(keys.length)];
    _correctAnswer = _randomQuestions[_currentQuestionText] == 'dayName'
        ? DateFormat('EEEE', context.locale.toString()).format(DateTime.now())
        : (_randomQuestions[_currentQuestionText] == 'yearEnd'
            ? DateTime.now().year.toString().substring(2)
            : '9');
    _actionAfterQuestion = action;
  }

  void _showRandomQuestionDialog() {
    final answerController = TextEditingController();
    final theme = Theme.of(context);
    final isDarkMode = AppTheme.isDarkMode(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: theme.dialogTheme.backgroundColor,
        shape: theme.dialogTheme.shape,
        titleTextStyle: theme.dialogTheme.titleTextStyle,
        contentTextStyle: theme.dialogTheme.contentTextStyle,
        title: Text("home.bot_check.title".tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("home.bot_check.subtitle".tr()),
            const SizedBox(height: AppTheme.spacing16),
            Container(
              padding: const EdgeInsets.all(AppTheme.spacing16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(AppTheme.radius12),
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Text(
                _currentQuestionText,
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacing16),
            TextFormField(
              controller: answerController,
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.getTextPrimaryColor(context),
              ),
              decoration: InputDecoration(
                labelText: "home.bot_check.label".tr(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("home.cancel_button".tr()),
          ),
          ElevatedButton(
            onPressed: () {
              if (answerController.text.trim().toLowerCase() ==
                  _correctAnswer.toLowerCase()) {
                Navigator.pop(context);
                if (_actionAfterQuestion == 'checkin') _onCheckIn();
                if (_actionAfterQuestion == 'checkout') _onCheckOut();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                    AppTheme.errorSnackBar(
                        "home.bot_check.error_wrong_answer".tr()));
              }
            },
            child: Text("home.bot_check.submit_button".tr()),
          ),
        ],
      ),
    );
  }

  void _showIzinDialog() {
    final reasonController = TextEditingController();
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.dialogTheme.backgroundColor,
        shape: theme.dialogTheme.shape,
        titleTextStyle: theme.dialogTheme.titleTextStyle,
        contentTextStyle: theme.dialogTheme.contentTextStyle,
        title: Text("attendance_actions.request_leave".tr()),
        content: TextFormField(
          controller: reasonController,
          maxLines: 3,
          style: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.getTextPrimaryColor(context),
          ),
          decoration: InputDecoration(
            labelText: "history.reason".tr(),
            hintText: "home.leave_dialog.reason_hint".tr(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("home.cancel_button".tr()),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                    AppTheme.errorSnackBar(
                        "home.leave_dialog.error_reason_empty".tr()));
                return;
              }
              Navigator.pop(context);
              _onAjukanIzin(reasonController.text);
            },
            child: Text("home.leave_dialog.submit_button".tr()),
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
              titleTextStyle: theme.dialogTheme.titleTextStyle,
              contentTextStyle: theme.dialogTheme.contentTextStyle,
              title: Text("home.reminder.title".tr()),
              contentPadding: const EdgeInsets.only(top: AppTheme.spacing20),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: Text(
                      "home.reminder.enable_label".tr(),
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.getTextPrimaryColor(context),
                      ),
                    ),
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
                  AppTheme.divider(isDark: AppTheme.isDarkMode(context)),
                  ListTile(
                    enabled: tempEnabled,
                    title: Text(
                      "home.reminder.time_label".tr(),
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: tempEnabled
                            ? AppTheme.getTextPrimaryColor(context)
                            : AppTheme.getTextSecondaryColor(context),
                      ),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacing12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(AppTheme.radius8),
                        border: Border.all(
                          color: theme.colorScheme.outline.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        tempTime.format(context),
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: tempEnabled
                              ? theme.colorScheme.primary
                              : AppTheme.getTextSecondaryColor(context),
                        ),
                      ),
                    ),
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
                  child: Text("home.cancel_button".tr()),
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
                        'home.reminder.notification_title'.tr(),
                        'home.reminder.notification_body'.tr(),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                          AppTheme.successSnackBar(
                              "home.reminder.snackbar_enabled".tr(namedArgs: {
                        'time': _reminderTime.format(context)
                      })));
                    } else {
                      await LocalNotificationService.cancelAll();
                      ScaffoldMessenger.of(context).showSnackBar(
                          AppTheme.infoSnackBar(
                              "settings.notifications_disabled_snackbar".tr()));
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacing20,
                      vertical: AppTheme.spacing12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radius12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    "edit_profile.save_changes".tr(),
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
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
    final isDarkMode = AppTheme.isDarkMode(context);
    final scaffoldBackgroundColor = AppTheme.getBackgroundColor(context);

    final homeProvider = context.watch<HomeProvider>();
    final homeState = homeProvider.state;

    return Scaffold(
      backgroundColor: scaffoldBackgroundColor,
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _handleRefresh,
            color: theme.colorScheme.primary,
            backgroundColor: AppTheme.getSurfaceColor(context),
            strokeWidth: 2.5,
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
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.spacing16,
                    AppTheme.spacing16,
                    AppTheme.spacing16,
                    AppTheme.spacing24,
                  ),
                  sliver: _buildMainContent(homeProvider, homeState),
                ),
              ],
            ),
          ),
          if (_isSubmitting) AppTheme.loadingIndicator(isDark: isDarkMode),
        ],
      ),
    );
  }

  Widget _buildMainContent(HomeProvider homeProvider, HomeState homeState) {
    final isDarkMode = AppTheme.isDarkMode(context);

    if (homeState == HomeState.loading && homeProvider.user == null) {
      return SliverFillRemaining(
        child: AppTheme.loadingIndicator(isDark: isDarkMode),
      );
    }
    if (homeState == HomeState.error && homeProvider.user == null) {
      return SliverFillRemaining(
        child: AppTheme.emptyState(
          title: "all_users.error_title".tr(),
          message:
              homeProvider.errorMessage ?? "home.error.generic_fallback".tr(),
          icon: Icons.cloud_off_rounded,
          isDark: isDarkMode,
          action: ElevatedButton.icon(
            onPressed: () => context.read<HomeProvider>().fetchData(),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text("history.try_again".tr()),
          ),
        ),
      );
    }
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
        const SizedBox(height: AppTheme.spacing16),
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
        const SizedBox(height: AppTheme.spacing16),
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
        const SizedBox(height: AppTheme.spacing16),
        _buildAnimatedItem(
          3,
          AbsenStatsCard(statsData: homeProvider.absenStats?.data),
        ),
      ]),
    );
  }
}
