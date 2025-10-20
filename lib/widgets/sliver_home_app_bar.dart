import 'dart:async';
import 'dart:convert';
import 'dart:ui';

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
      duration: const Duration(milliseconds: 400),
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
      final List<dynamic> quotes = json.decode('quotes'.tr());
      if (quotes.isEmpty) {
        return 'quotes_fallback_empty'.tr();
      }
      return quotes[_now.day % quotes.length].toString();
    } catch (e) {
      return 'quotes_fallback_error'.tr();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = AppTheme.isDarkMode(context);

    // Define the solid background color based on the theme
    final solidBackgroundColor = isDarkMode
        ? AppTheme.getSurfaceColor(context)
        : theme.colorScheme.primary;

    Widget flexibleSpaceContent = Container(
      // Use solid color instead of gradient
      color: solidBackgroundColor,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final expandRatio = (constraints.biggest.height - kToolbarHeight) /
              (240.0 - kToolbarHeight);
          final isCollapsed = expandRatio < 0.3;

          return FlexibleSpaceBar(
            centerTitle: false,
            titlePadding: EdgeInsets.zero,
            stretchModes: const [
              StretchMode.zoomBackground,
              StretchMode.fadeTitle,
            ],
            title: AnimatedOpacity(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              opacity: isCollapsed ? 1.0 : 0.0,
              child: _buildCollapsedHeader(context, isCollapsed),
            ),
            background: Stack(
              fit: StackFit.expand,
              children: [
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  opacity: isCollapsed ? 0.0 : 1.0,
                  child: _buildExpandedHeader(context),
                ),
              ],
            ),
          );
        },
      ),
    );

    return SliverAppBar(
      expandedHeight: 240.0,
      pinned: true,
      elevation: 0,
      stretch: true,
      onStretchTrigger: () async {
        HapticFeedback.lightImpact();
      },
      stretchTriggerOffset: 80.0,
      backgroundColor:
          solidBackgroundColor, // Set a consistent background color
      flexibleSpace: isDarkMode
          ? ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: flexibleSpaceContent,
              ),
            )
          : flexibleSpaceContent,
      systemOverlayStyle:
          isDarkMode ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.light,
    );
  }

  Widget _buildCollapsedHeader(BuildContext context, bool isCollapsed) {
    final theme = Theme.of(context);
    final isDarkMode = AppTheme.isDarkMode(context);
    final solidBackgroundColor = isDarkMode
        ? AppTheme.getSurfaceColor(context)
        : theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: solidBackgroundColor, // Use solid color here too
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: kToolbarHeight,
          child: Row(
            children: [
              GestureDetector(
                onTap: widget.onProfileTap,
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.white.withOpacity(0.2),
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
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: Colors.white,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 12),
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
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      widget.userEmail,
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        color: Colors.white70,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildNotificationButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedHeader(BuildContext context) {
    final isDarkMode = AppTheme.isDarkMode(context);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [_buildNotificationButton(context)],
              ),
              const SizedBox(height: 20),
              Text(
                _getPersonalizedGreeting(),
                style: GoogleFonts.manrope(
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  height: 1.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                _getMotivationalQuote(context),
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.85),
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(isDarkMode ? 0.08 : 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 16,
                          color: Colors.white.withOpacity(0.9),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat(
                            'EEEE, dd MMM yyyy',
                            context.locale.toString(),
                          ).format(_now),
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: 1,
                      height: 20,
                      color: Colors.white.withOpacity(0.3),
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_outlined,
                          size: 16,
                          color: Colors.white.withOpacity(0.9),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('HH:mm').format(_now),
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationButton(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onNotificationTap?.call();
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Icon(
              Icons.notifications_outlined,
              size: 24,
              color: Colors.white,
            ),
          ),
          if (widget.notificationCount > 0)
            Positioned(
              right: 4,
              top: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                child: Center(
                  child: Text(
                    widget.notificationCount > 9
                        ? '9+'
                        : widget.notificationCount.toString(),
                    style: GoogleFonts.manrope(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
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
