import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const _primaryDark = Color(0xFF1F1F1F);
  static const _primaryLight = Color(0xFFFFFFFF);

  static const _accentBlue = Color(0xFF2563EB);
  static const _accentGreen = Color(0xFF10B981);
  static const _accentRed = Color(0xFFEF4444);
  static const _accentAmber = Color(0xFFF59E0B);
  static const _accentPurple = Color(0xFF8B5CF6);

  static const _lightBackground = Color(0xFFFFFFFF);
  static const _lightSurface = Color(0xFFFAFAFA);
  static const _lightBorder = Color(0xFFE5E7EB);
  static const _lightDivider = Color(0xFFF3F4F6);

  static const _darkBackground = Color(0xFF000000);
  static const _darkSurface = Color(0xFF1F1F1F);
  static const _darkBorder = Color(0xFF374151);
  static const _darkDivider = Color(0xFF1F2937);

  static const _textPrimaryLight = Color(0xFF111827);
  static const _textSecondaryLight = Color(0xFF6B7280);
  static const _textTertiaryLight = Color(0xFF9CA3AF);

  static const _textPrimaryDark = Color(0xFFF9FAFB);
  static const _textSecondaryDark = Color(0xFF9CA3AF);
  static const _textTertiaryDark = Color(0xFF6B7280);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: _primaryDark,
      scaffoldBackgroundColor: _lightBackground,
      colorScheme: const ColorScheme.light(
        primary: _primaryDark,
        onPrimary: _primaryLight,
        secondary: _accentBlue,
        onSecondary: _primaryLight,
        surface: _lightBackground,
        onSurface: _textPrimaryLight,
        error: _accentRed,
        onError: _primaryLight,
        outline: _lightBorder,
        shadow: Color(0x0A000000),
        surfaceContainerHighest: _lightSurface,
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: _lightBackground,
        surfaceTintColor: Colors.transparent,
        foregroundColor: _textPrimaryLight,
        titleTextStyle: GoogleFonts.manrope(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: _textPrimaryLight,
          letterSpacing: -0.3,
        ),
        toolbarHeight: 56,
        iconTheme: const IconThemeData(
          color: _textPrimaryLight,
          size: 24,
        ),
        centerTitle: false,
        titleSpacing: 16,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
      ),
      textTheme: _buildTextTheme(_textPrimaryLight),
      cardTheme: CardThemeData(
        elevation: 0,
        color: _lightSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: _lightBorder, width: 1),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        clipBehavior: Clip.antiAlias,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: _primaryDark,
          foregroundColor: _primaryLight,
          disabledBackgroundColor: _lightBorder,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: GoogleFonts.manrope(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          backgroundColor: _primaryDark,
          foregroundColor: _primaryLight,
          disabledBackgroundColor: _lightBorder,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: GoogleFonts.manrope(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _primaryDark,
          side: const BorderSide(color: _lightBorder, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: GoogleFonts.manrope(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _primaryDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: GoogleFonts.manrope(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _primaryDark,
        foregroundColor: _primaryLight,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _lightSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _lightBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primaryDark, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _accentRed, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _accentRed, width: 2),
        ),
        labelStyle: GoogleFonts.manrope(
          color: _textSecondaryLight,
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
        hintStyle: GoogleFonts.manrope(
          color: _textTertiaryLight,
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
        errorStyle: GoogleFonts.manrope(
          color: _accentRed,
          fontSize: 13,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: _lightBackground,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        showDragHandle: true,
        dragHandleColor: _lightBorder,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: _lightBackground,
        surfaceTintColor: Colors.transparent,
        indicatorColor: _lightSurface,
        elevation: 0,
        height: 80,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _primaryDark,
            );
          }
          return GoogleFonts.manrope(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: _textSecondaryLight,
          );
        }),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        iconColor: _textSecondaryLight,
        textColor: _textPrimaryLight,
        titleTextStyle: GoogleFonts.manrope(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: _textPrimaryLight,
        ),
        subtitleTextStyle: GoogleFonts.manrope(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: _textSecondaryLight,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: _lightBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titleTextStyle: GoogleFonts.manrope(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: _textPrimaryLight,
        ),
        contentTextStyle: GoogleFonts.manrope(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: _textSecondaryLight,
          height: 1.5,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: _lightDivider,
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: _lightSurface,
        selectedColor: _primaryDark,
        labelStyle: GoogleFonts.manrope(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        side: const BorderSide(color: _lightBorder),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return _primaryLight;
          }
          return _lightBorder;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return _primaryDark;
          }
          return _lightDivider;
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return _primaryDark;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(_primaryLight),
        side: const BorderSide(color: _lightBorder, width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: _primaryDark,
        linearTrackColor: _lightDivider,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: _darkSurface,
        contentTextStyle: GoogleFonts.manrope(
          color: _textPrimaryDark,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: _primaryLight,
      scaffoldBackgroundColor: _darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: _primaryLight,
        onPrimary: _primaryDark,
        secondary: _accentBlue,
        onSecondary: _primaryLight,
        surface: _darkSurface,
        onSurface: _textPrimaryDark,
        error: _accentRed,
        onError: _primaryLight,
        outline: _darkBorder,
        shadow: Color(0x1A000000),
        surfaceContainerHighest: Color(0xFF161616),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: _darkBackground,
        surfaceTintColor: Colors.transparent,
        foregroundColor: _textPrimaryDark,
        titleTextStyle: GoogleFonts.manrope(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: _textPrimaryDark,
          letterSpacing: -0.3,
        ),
        toolbarHeight: 56,
        iconTheme: const IconThemeData(
          color: _textPrimaryDark,
          size: 24,
        ),
        centerTitle: false,
        titleSpacing: 16,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      ),
      textTheme: _buildTextTheme(_textPrimaryDark),
      cardTheme: CardThemeData(
        elevation: 0,
        color: _darkSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: _darkBorder, width: 1),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        clipBehavior: Clip.antiAlias,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: _primaryLight,
          foregroundColor: _primaryDark,
          disabledBackgroundColor: _darkBorder,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: GoogleFonts.manrope(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          backgroundColor: _primaryLight,
          foregroundColor: _primaryDark,
          disabledBackgroundColor: _darkBorder,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: GoogleFonts.manrope(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _primaryLight,
          side: const BorderSide(color: _darkBorder, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: GoogleFonts.manrope(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _primaryLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: GoogleFonts.manrope(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _primaryLight,
        foregroundColor: _primaryDark,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _darkSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _darkBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primaryLight, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _accentRed, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _accentRed, width: 2),
        ),
        labelStyle: GoogleFonts.manrope(
          color: _textSecondaryDark,
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
        hintStyle: GoogleFonts.manrope(
          color: _textTertiaryDark,
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
        errorStyle: GoogleFonts.manrope(
          color: _accentRed,
          fontSize: 13,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: _darkSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        showDragHandle: true,
        dragHandleColor: _darkBorder,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: _darkSurface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: _darkDivider,
        elevation: 0,
        height: 80,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _primaryLight,
            );
          }
          return GoogleFonts.manrope(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: _textSecondaryDark,
          );
        }),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        iconColor: _textSecondaryDark,
        textColor: _textPrimaryDark,
        titleTextStyle: GoogleFonts.manrope(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: _textPrimaryDark,
        ),
        subtitleTextStyle: GoogleFonts.manrope(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: _textSecondaryDark,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: _darkSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titleTextStyle: GoogleFonts.manrope(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: _textPrimaryDark,
        ),
        contentTextStyle: GoogleFonts.manrope(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: _textSecondaryDark,
          height: 1.5,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: _darkDivider,
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: _darkSurface,
        selectedColor: _primaryLight,
        labelStyle: GoogleFonts.manrope(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        side: const BorderSide(color: _darkBorder),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return _primaryDark;
          }
          return _darkBorder;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return _primaryLight;
          }
          return _darkDivider;
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return _primaryLight;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(_primaryDark),
        side: const BorderSide(color: _darkBorder, width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: _primaryLight,
        linearTrackColor: _darkDivider,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: _lightBorder,
        contentTextStyle: GoogleFonts.manrope(
          color: _textPrimaryLight,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  static TextTheme _buildTextTheme(Color baseColor) {
    return TextTheme(
      displayLarge: GoogleFonts.manrope(
        fontSize: 57,
        fontWeight: FontWeight.w700,
        color: baseColor,
        letterSpacing: -1,
      ),
      displayMedium: GoogleFonts.manrope(
        fontSize: 45,
        fontWeight: FontWeight.w700,
        color: baseColor,
        letterSpacing: -0.5,
      ),
      displaySmall: GoogleFonts.manrope(
        fontSize: 36,
        fontWeight: FontWeight.w600,
        color: baseColor,
        letterSpacing: -0.5,
      ),
      headlineLarge: GoogleFonts.manrope(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: baseColor,
        letterSpacing: -0.5,
      ),
      headlineMedium: GoogleFonts.manrope(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: baseColor,
        letterSpacing: -0.3,
      ),
      headlineSmall: GoogleFonts.manrope(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: baseColor,
      ),
      titleLarge: GoogleFonts.manrope(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: baseColor,
      ),
      titleMedium: GoogleFonts.manrope(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: baseColor,
      ),
      titleSmall: GoogleFonts.manrope(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: baseColor,
      ),
      bodyLarge: GoogleFonts.manrope(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: baseColor,
        height: 1.5,
      ),
      bodyMedium: GoogleFonts.manrope(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: baseColor,
        height: 1.5,
      ),
      bodySmall: GoogleFonts.manrope(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: baseColor,
        height: 1.4,
      ),
      labelLarge: GoogleFonts.manrope(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: baseColor,
      ),
      labelMedium: GoogleFonts.manrope(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: baseColor,
      ),
      labelSmall: GoogleFonts.manrope(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: baseColor,
      ),
    );
  }

  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'present':
      case 'hadir':
      case 'completed':
      case 'success':
      case 'on_time':
        return _accentGreen;
      case 'late':
      case 'warning':
      case 'pending':
        return _accentAmber;
      case 'absent':
      case 'error':
      case 'failed':
      case 'finished':
        return _accentRed;
      case 'leave':
      case 'info':
      case 'izin':
        return _accentPurple;
      default:
        return _textSecondaryLight;
    }
  }

  static bool isDarkMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  static Color getPrimaryColor(BuildContext context) {
    return isDarkMode(context) ? _primaryLight : _primaryDark;
  }

  static Color getSurfaceColor(BuildContext context) {
    return isDarkMode(context) ? _darkSurface : _lightSurface;
  }

  static Color getBackgroundColor(BuildContext context) {
    return isDarkMode(context) ? _darkBackground : _lightBackground;
  }

  static Color getTextPrimaryColor(BuildContext context) {
    return isDarkMode(context) ? _textPrimaryDark : _textPrimaryLight;
  }

  static Color getTextSecondaryColor(BuildContext context) {
    return isDarkMode(context) ? _textSecondaryDark : _textSecondaryLight;
  }

  static Color getTextDisabledColor({required bool isDark}) {
    return isDark ? _textTertiaryDark : _textTertiaryLight;
  }

  static const double spacing4 = 4.0;
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing20 = 20.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;

  static const double radius4 = 4.0;
  static const double radius8 = 8.0;
  static const double radius12 = 12.0;
  static const double radius16 = 16.0;
  static const double radius20 = 20.0;
  static const double radius28 = 28.0;

  static TextStyle heading1({required bool isDark}) {
    return GoogleFonts.manrope(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      color: isDark ? _textPrimaryDark : _textPrimaryLight,
      height: 1.2,
      letterSpacing: -0.5,
    );
  }

  static TextStyle heading2({required bool isDark}) {
    return GoogleFonts.manrope(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      color: isDark ? _textPrimaryDark : _textPrimaryLight,
      height: 1.3,
      letterSpacing: -0.3,
    );
  }

  static TextStyle heading3({required bool isDark}) {
    return GoogleFonts.manrope(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: isDark ? _textPrimaryDark : _textPrimaryLight,
      height: 1.4,
    );
  }

  static TextStyle bodyLarge({required bool isDark}) {
    return GoogleFonts.manrope(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: isDark ? _textPrimaryDark : _textPrimaryLight,
      height: 1.5,
    );
  }

  static TextStyle bodyMedium({required bool isDark}) {
    return GoogleFonts.manrope(
      fontSize: 15,
      fontWeight: FontWeight.w400,
      color: isDark ? _textSecondaryDark : _textSecondaryLight,
      height: 1.5,
    );
  }

  static TextStyle caption({required bool isDark}) {
    return GoogleFonts.manrope(
      fontSize: 13,
      fontWeight: FontWeight.w400,
      color: isDark ? _textTertiaryDark : _textTertiaryLight,
      height: 1.4,
    );
  }

  static TextStyle labelBold({required bool isDark}) {
    return GoogleFonts.manrope(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: isDark ? _textSecondaryDark : _textSecondaryLight,
    );
  }

  static TextStyle buttonText({required bool isDark}) {
    return GoogleFonts.manrope(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: isDark ? _primaryDark : _primaryLight,
    );
  }

  static BoxDecoration cardDecoration({required bool isDark}) {
    return BoxDecoration(
      color: isDark ? _darkSurface : _lightSurface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: isDark ? _darkBorder : _lightBorder,
        width: 1,
      ),
    );
  }

  static BoxDecoration elevatedCard({required bool isDark}) {
    return BoxDecoration(
      color: isDark ? _darkSurface : _lightBackground,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: isDark ? _darkBorder : _lightBorder,
        width: 1,
      ),
      boxShadow: isDark
          ? []
          : [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
    );
  }

  static BoxDecoration statusBadge(String status, {required bool isDark}) {
    final color = getStatusColor(status);
    return BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(
        color: color.withOpacity(0.3),
        width: 1,
      ),
    );
  }

  static InputDecoration inputDecoration({
    required String hint,
    required IconData icon,
    required bool isDark,
    Widget? suffixIcon,
    String? label,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      hintStyle: GoogleFonts.manrope(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: const Color(0xFF9CA3AF),
      ),
      prefixIcon: Icon(
        icon,
        size: 20,
        color: const Color(0xFF9CA3AF),
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: isDark ? _darkSurface : _lightSurface,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? _darkBorder : _lightBorder,
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? _primaryLight : _primaryDark,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _accentRed, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _accentRed, width: 2),
      ),
      errorStyle: GoogleFonts.manrope(fontSize: 13, height: 1.4),
    );
  }

  static SnackBar successSnackBar(String message) {
    return SnackBar(
      content: Row(
        children: [
          const Icon(
            Icons.check_circle,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.manrope(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: _accentGreen,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.all(16),
    );
  }

  static SnackBar errorSnackBar(String message) {
    return SnackBar(
      content: Row(
        children: [
          const Icon(
            Icons.error,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.manrope(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: _accentRed,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 4),
    );
  }

  static SnackBar infoSnackBar(String message) {
    return SnackBar(
      content: Row(
        children: [
          const Icon(
            Icons.info,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.manrope(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: _accentBlue,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.all(16),
    );
  }

  static Widget infoCard({
    required String title,
    required String description,
    required bool isDark,
    IconData icon = Icons.info,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? _darkSurface.withOpacity(0.5) : const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? _darkBorder : _lightBorder,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: isDark ? _textSecondaryDark : _textSecondaryLight,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: isDark ? _textPrimaryDark : _textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.manrope(
                    color: isDark ? _textSecondaryDark : _textSecondaryLight,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget divider({required bool isDark}) {
    return Container(
      height: 1,
      color: isDark ? _darkDivider : _lightDivider,
    );
  }

  static Widget shimmerBox({
    required double height,
    required double width,
    required bool isDark,
    double borderRadius = 8,
  }) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: isDark ? _darkSurface : _lightSurface,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }

  static Widget emptyState({
    required String title,
    required String message,
    required bool isDark,
    IconData icon = Icons.inbox,
    Widget? action,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: isDark ? _textTertiaryDark : _textTertiaryLight,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? _textPrimaryDark : _textPrimaryLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: isDark ? _textSecondaryDark : _textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: 24),
              action,
            ],
          ],
        ),
      ),
    );
  }

  static Widget loadingIndicator({required bool isDark}) {
    return Center(
      child: CircularProgressIndicator(
        color: isDark ? _primaryLight : _primaryDark,
        strokeWidth: 2,
      ),
    );
  }

  static Widget sectionHeader({
    required String title,
    required bool isDark,
    String? action,
    VoidCallback? onActionTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? _textPrimaryDark : _textPrimaryLight,
            ),
          ),
          if (action != null)
            InkWell(
              onTap: onActionTap,
              child: Text(
                action,
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _accentBlue,
                ),
              ),
            ),
        ],
      ),
    );
  }

  static Widget statusTag({
    required String label,
    required String status,
    required bool isDark,
  }) {
    final color = getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.manrope(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
