import 'dart:async';
import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timely/utils/app_theme.dart';

class ModernSliverHomeAppBar extends StatefulWidget {
  final String userName;
  final String userEmail;
  final String? userAvatarUrl;
  final VoidCallback? onProfileTap;
  final VoidCallback? onNotificationTap;
  final int notificationCount;

  const ModernSliverHomeAppBar({
    super.key,
    required this.userName,
    required this.userEmail,
    this.userAvatarUrl,
    this.onProfileTap,
    this.onNotificationTap,
    this.notificationCount = 0,
  });

  @override
  State<ModernSliverHomeAppBar> createState() => _ModernSliverHomeAppBarState();
}

class _ModernSliverHomeAppBarState extends State<ModernSliverHomeAppBar>
    with SingleTickerProviderStateMixin {
  late Timer _timer;
  DateTime _now = DateTime.now();
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() => _now = DateTime.now());
      }
    });

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    _fadeController.dispose();
    super.dispose();
  }

  String _getPersonalizedGreeting() {
    final hour = _now.hour;
    final firstName = widget.userName.split(' ').first;
    if (hour >= 5 && hour < 11) {
      return 'greetings.morning'.tr(namedArgs: {'firstName': firstName});
    }
    if (hour >= 11 && hour < 15) {
      return 'greetings.afternoon'.tr(namedArgs: {'firstName': firstName});
    }
    if (hour >= 15 && hour < 19) {
      return 'greetings.evening'.tr(namedArgs: {'firstName': firstName});
    }
    return 'greetings.night'.tr(namedArgs: {'firstName': firstName});
  }

  String _getMotivationalQuote(BuildContext context) {
    try {
      final String quotesJsonString = 'quotes'.tr();
      final List<dynamic> quotes = json.decode(quotesJsonString);
      if (quotes.isEmpty) {
        return 'quotes_fallback_empty'.tr();
      }
      return quotes[_now.day % quotes.length].toString();
    } catch (e) {
      print("Error decoding quotes JSON: $e");
      return 'quotes_fallback_error'.tr();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = AppTheme.isDarkMode(context);
    final pageBackgroundColor = AppTheme.getBackgroundColor(context);
    final systemOverlayStyle = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness:
          isDarkMode ? Brightness.light : Brightness.dark,
    );

    return SliverAppBar(
      expandedHeight: 220.0,
      pinned: true,
      elevation: 0,
      stretch: true,
      onStretchTrigger: () async {
        HapticFeedback.lightImpact();
      },
      stretchTriggerOffset: 80.0,
      backgroundColor: pageBackgroundColor,
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final expandRatio = (constraints.biggest.height - kToolbarHeight) /
              (220.0 - kToolbarHeight);
          final isCollapsed = expandRatio < 0.4;

          return FlexibleSpaceBar(
            centerTitle: false,
            titlePadding: EdgeInsets.zero,
            stretchModes: const [
              StretchMode.zoomBackground,
              StretchMode.fadeTitle,
            ],
            title: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              opacity: isCollapsed ? 1.0 : 0.0,
              child: _buildCollapsedHeader(context, isCollapsed),
            ),
            background: Stack(
              fit: StackFit.expand,
              children: [
                Container(color: pageBackgroundColor),
                AnimatedOpacity(
                  duration:
                      const Duration(milliseconds: 300),
                  curve: Curves.easeIn,
                  opacity: isCollapsed ? 0.0 : 1.0,
                  child: _buildExpandedHeader(context),
                ),
              ],
            ),
          );
        },
      ),
      systemOverlayStyle: systemOverlayStyle,
    );
  }

  Widget _buildCollapsedHeader(BuildContext context, bool isCollapsed) {
    final theme = Theme.of(context);
    final isDarkMode = AppTheme.isDarkMode(context);
    final pageBackgroundColor = AppTheme.getBackgroundColor(context);
    final primaryTextColor = AppTheme.getTextPrimaryColor(context);
    final secondaryTextColor = AppTheme.getTextSecondaryColor(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
      color: pageBackgroundColor,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: kToolbarHeight,
          child: Row(
            children: [
              GestureDetector(
                onTap: widget.onProfileTap,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.colorScheme.outline.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor:
                        AppTheme.getSurfaceColor(context).withOpacity(0.5),
                    backgroundImage: widget.userAvatarUrl != null &&
                            widget.userAvatarUrl!.isNotEmpty
                        ? NetworkImage(widget.userAvatarUrl!)
                        : null,
                    child: (widget.userAvatarUrl == null ||
                            widget.userAvatarUrl!.isEmpty)
                        ? Text(
                            widget.userName.isNotEmpty
                                ? widget.userName[0].toUpperCase()
                                : 'U',
                            style: GoogleFonts.manrope(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: primaryTextColor,
                            ),
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spacing12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.userName,
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: primaryTextColor,
                        letterSpacing: -0.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.userEmail,
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: secondaryTextColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppTheme.spacing8),
              _buildNotificationButton(context, collapsed: true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedHeader(BuildContext context) {
    final primaryTextColor = AppTheme.getTextPrimaryColor(context);
    final secondaryTextColor = AppTheme.getTextSecondaryColor(context);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.spacing20,
            AppTheme.spacing16,
            AppTheme.spacing20,
            AppTheme.spacing20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buildNotificationButton(context, collapsed: false)
                ],
              ),
              const SizedBox(height: AppTheme.spacing32),
              Text(
                _getPersonalizedGreeting(),
                style: GoogleFonts.manrope(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: primaryTextColor,
                  height: 1.2,
                  letterSpacing: -0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                _getMotivationalQuote(context),
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: secondaryTextColor,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              _buildDateTimeCard(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateTimeCard(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = AppTheme.isDarkMode(context);
    final primaryTextColor = AppTheme.getTextPrimaryColor(context);
    final secondaryTextColor = AppTheme.getTextSecondaryColor(context);
    final cardBackgroundColor = AppTheme.getSurfaceColor(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing16,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: cardBackgroundColor,
        borderRadius: BorderRadius.circular(AppTheme.radius12),
        border: Border.all(

          color: theme.colorScheme.outline.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 15,
                  color: secondaryTextColor,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    DateFormat(
                      'EEEE, dd MMM yyyy',
                      context.locale.toString(),
                    ).format(_now),
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: primaryTextColor,
                      letterSpacing: -0.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 16,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            color: theme.colorScheme.outline.withOpacity(0.5),
          ),
          Row(
            children: [
              Icon(
                Icons.access_time_outlined,
                size: 15,
                color: secondaryTextColor,
              ),
              const SizedBox(width: 6),
              Text(
                DateFormat('HH:mm').format(_now),
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: primaryTextColor,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationButton(BuildContext context,
      {required bool collapsed}) {
    final theme = Theme.of(context);
    final iconColor = AppTheme.getTextPrimaryColor(context);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onNotificationTap?.call();
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(
            Icons.notifications_outlined,
            size: 20,
            color: iconColor,
          ),
          if (widget.notificationCount > 0)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 1.5,
                  ),
                ),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: Center(
                  child: Text(
                    widget.notificationCount > 9
                        ? '9+'
                        : widget.notificationCount.toString(),
                    style: GoogleFonts.manrope(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
