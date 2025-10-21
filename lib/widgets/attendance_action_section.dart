import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timely/utils/app_theme.dart';

class AttendanceActionsSection extends StatefulWidget {
  final bool isSubmitting;
  final bool canCheckIn;
  final bool canCheckOut;
  final VoidCallback onCheckIn;
  final VoidCallback onCheckOut;
  final VoidCallback onAjukanIzin;

  const AttendanceActionsSection({
    super.key,
    required this.isSubmitting,
    required this.canCheckIn,
    required this.canCheckOut,
    required this.onCheckIn,
    required this.onCheckOut,
    required this.onAjukanIzin,
  });

  @override
  State<AttendanceActionsSection> createState() =>
      _AttendanceActionsSectionState();
}

class _AttendanceActionsSectionState extends State<AttendanceActionsSection>
    with TickerProviderStateMixin {
  double _swipeProgressCheckIn = 0.0;
  double _swipeProgressCheckOut = 0.0;
  bool _isAnimatingCheckIn = false;
  bool _isAnimatingCheckOut = false;
  bool _isLoadingCheckIn = false;
  bool _isLoadingCheckOut = false;

  // Konstanta untuk ukuran knob dan padding
  static const double _knobSize = 52.0; // Sedikit lebih kecil
  static const double _padding = AppTheme.spacing4;
  static const double _buttonHeight = 60.0;

  void _onSwipeUpdate(
    DragUpdateDetails details,
    double maxExtent, {
    required bool isCheckIn,
  }) {
    if (widget.isSubmitting) return;
    if (isCheckIn && _isAnimatingCheckIn) return;
    if (!isCheckIn && _isAnimatingCheckOut) return;

    final effectiveWidth = maxExtent - (2 * _padding) - _knobSize;
    if (effectiveWidth <= 0) return; // Hindari pembagian dengan nol

    double newProgress;
    if (isCheckIn) {
      newProgress = (details.localPosition.dx - (_knobSize / 2) - _padding) /
          effectiveWidth;
    } else {
      newProgress =
          (maxExtent - details.localPosition.dx - (_knobSize / 2) - _padding) /
              effectiveWidth;
    }

    newProgress = newProgress.clamp(0.0, 1.0);

    setState(() {
      if (isCheckIn) {
        _swipeProgressCheckIn = newProgress;
      } else {
        _swipeProgressCheckOut = newProgress;
      }
    });

    if (newProgress > 0.85) {
      HapticFeedback.selectionClick();
    }
  }

  void _onSwipeEnd(VoidCallback onCompleted, {required bool isCheckIn}) {
    final currentProgress =
        isCheckIn ? _swipeProgressCheckIn : _swipeProgressCheckOut;
    final isCompleted = currentProgress > 0.85;
    final target = isCompleted ? 1.0 : 0.0;

    setState(() {
      if (isCheckIn) {
        _isAnimatingCheckIn = true;
      } else {
        _isAnimatingCheckOut = true;
      }
    });

    final controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: isCompleted ? 300 : 250),
    );
    final animation =
        Tween<double>(begin: currentProgress, end: target).animate(
      CurvedAnimation(
        parent: controller,
        curve: isCompleted ? Curves.easeInOutCubic : Curves.easeOutCubic,
      ),
    );
    animation.addListener(() {
      setState(() {
        if (isCheckIn) {
          _swipeProgressCheckIn = animation.value;
        } else {
          _swipeProgressCheckOut = animation.value;
        }
      });
    });

    controller.forward().whenComplete(() {
      controller.dispose();
      if (isCompleted) {
        HapticFeedback.mediumImpact();
        setState(() {
          if (isCheckIn) {
            _isLoadingCheckIn = true;
          } else {
            _isLoadingCheckOut = true;
          }
        });

        // Simulasi loading
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (mounted) {
            onCompleted(); // Panggil callback setelah simulasi
            setState(() {
              if (isCheckIn) {
                _isLoadingCheckIn = false;
                _swipeProgressCheckIn = 0.0; // Reset setelah onCompleted
                _isAnimatingCheckIn = false;
              } else {
                _isLoadingCheckOut = false;
                _swipeProgressCheckOut = 0.0; // Reset setelah onCompleted
                _isAnimatingCheckOut = false;
              }
            });
          }
        });
      } else {
        setState(() {
          if (isCheckIn) {
            _swipeProgressCheckIn = 0.0;
            _isAnimatingCheckIn = false;
          } else {
            _swipeProgressCheckOut = 0.0;
            _isAnimatingCheckOut = false;
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSlideButton(
          context,
          label: 'attendance_actions.swipe_to_check_in'.tr(),
          icon: Icons.arrow_forward_ios_rounded,
          color: AppTheme.getStatusColor('present'),
          isCheckIn: true,
          isDisabled: !widget.canCheckIn,
          progress: _swipeProgressCheckIn,
          isLoading: _isLoadingCheckIn,
          onSwipe: () => _onSwipeEnd(widget.onCheckIn, isCheckIn: true),
        ),
        const SizedBox(height: AppTheme.spacing12), 
        _buildSlideButton(
          context,
          label: 'attendance_actions.swipe_to_check_out'.tr(),
          icon: Icons.arrow_back_ios_rounded,
          color: AppTheme.getStatusColor('absent'),
          isCheckIn: false,
          isDisabled: !widget.canCheckOut,
          progress: _swipeProgressCheckOut,
          isLoading: _isLoadingCheckOut,
          onSwipe: () => _onSwipeEnd(widget.onCheckOut, isCheckIn: false),
        ),
        const SizedBox(height: AppTheme.spacing16), 
        _buildPermitButton(context),
      ],
    );
  }

  Widget _buildSlideButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required bool isCheckIn,
    required bool isDisabled,
    required double progress,
    required bool isLoading,
    required VoidCallback onSwipe,
  }) {
    final theme = Theme.of(context);
    final isDarkMode = AppTheme.isDarkMode(context);
    final double maxExtent = MediaQuery.of(context).size.width -
        (2 * AppTheme.spacing16);
    final effectiveWidth = maxExtent - (2 * _padding) - _knobSize;
    final knobPosition = _padding + (progress * effectiveWidth);
    final textColor = theme.colorScheme.onPrimary;

    return LayoutBuilder(builder: (context, constraints) {
      final double layoutWidth = constraints.maxWidth;
      return IgnorePointer(
        ignoring: isDisabled || widget.isSubmitting || isLoading,
        child: GestureDetector(
          onHorizontalDragUpdate: (details) =>
              _onSwipeUpdate(details, layoutWidth, isCheckIn: isCheckIn),
          onHorizontalDragEnd: (details) => onSwipe(),
          child: Container(
            height: _buttonHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radius28),
              color: isDisabled
                  ? theme.colorScheme.surfaceContainerHighest
                  : color,
              boxShadow: isDisabled || isDarkMode
                  ? []
                  : [
                      BoxShadow(
                        color: color.withOpacity(0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedOpacity(
                  opacity: progress < 0.3 ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 150),
                  child: Text(
                    label,
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: isDisabled
                          ? AppTheme.getTextDisabledColor(isDark: isDarkMode)
                          : textColor,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                AnimatedPositioned(
                  duration: Duration.zero,
                  curve: Curves.linear,
                  left: isCheckIn ? knobPosition : null,
                  right: isCheckIn ? null : knobPosition,
                  top: _padding,
                  bottom: _padding,
                  child: Container(
                    width: _knobSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.getSurfaceColor(context),
                      boxShadow: isDarkMode
                          ? []
                          : [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                    ),
                    child: Center(
                      child: isLoading
                          ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(color),
                              ),
                            )
                          : Icon(
                              icon,
                              color: AppTheme.getTextSecondaryColor(context),
                              size: 20,
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildPermitButton(BuildContext context) {
    final theme = Theme.of(context);
    final isDisabled = widget.isSubmitting || !widget.canCheckIn;
    return SizedBox(
      height: _buttonHeight,
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: isDisabled ? null : widget.onAjukanIzin,
        icon: const Icon(
          Icons.calendar_today_rounded,
          size: 18,
        ),
        label: Text(
          'attendance_actions.request_leave'.tr(),
        ),
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radius28),
          ),
        ).copyWith(
          padding: WidgetStateProperty.all(EdgeInsets.zero),
        ),
      ),
    );
  }
}
