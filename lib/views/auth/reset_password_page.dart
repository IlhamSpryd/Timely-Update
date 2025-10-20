import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timely/services/auth_repository.dart';
import 'package:timely/utils/app_transitions.dart';
import 'package:timely/views/auth/login_page.dart';

class ResetPasswordPage extends StatefulWidget {
  final String email;

  const ResetPasswordPage({super.key, required this.email});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final AuthRepository _authRepository = AuthRepository();

  final _otpFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _slideController,
        curve: Curves.easeOutCubic,
      ),
    );
    _fadeController.forward();
    _slideController.forward();
  }

  Future<void> _submitResetPassword() async {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.mediumImpact();
      return;
    }
    setState(() => _isLoading = true);
    HapticFeedback.lightImpact();

    try {
      final result = await _authRepository.resetPassword(
        email: widget.email,
        otp: _otpController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (mounted) {
        _showSuccessSnackBar(
          result.message ?? 'reset_password.success_message'.tr(),
        );
        await Future.delayed(const Duration(milliseconds: 1500));
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            SlideFadeRoute(page: const LoginPage()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = e.toString().replaceAll("Exception: ", "");
        _showErrorSnackBar(
          'reset_password.generic_error'.tr(args: [errorMessage]),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _otpFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              CupertinoIcons.check_mark_circled_solid,
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
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              CupertinoIcons.exclamationmark_circle_fill,
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
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? Colors.black : Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            CupertinoIcons.back,
            color: isDarkMode ? Colors.white : Colors.grey.shade900,
          ),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).pop();
          },
        ),
        backgroundColor: backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              physics: const ClampingScrollPhysics(),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(isDarkMode),
                    const SizedBox(height: 48),
                    _buildOTPField(isDarkMode),
                    const SizedBox(height: 20),
                    _buildPasswordField(isDarkMode),
                    const SizedBox(height: 20),
                    _buildConfirmPasswordField(isDarkMode),
                    const SizedBox(height: 24),
                    _buildPasswordRequirements(isDarkMode),
                    const SizedBox(height: 32),
                    _buildSubmitButton(isDarkMode),
                    const SizedBox(height: 24),
                    _buildInfoCard(isDarkMode),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'reset_password.title'.tr(),
          style: GoogleFonts.manrope(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: isDarkMode ? Colors.white : Colors.grey.shade900,
            height: 1.2,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'reset_password.subtitle'.tr(),
          style: GoogleFonts.manrope(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: Colors.grey.shade600,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isDarkMode
                ? Colors.grey.shade900.withOpacity(0.5)
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                CupertinoIcons.mail_solid,
                size: 16,
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  widget.email,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDarkMode
                        ? Colors.grey.shade300
                        : Colors.grey.shade700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOTPField(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'reset_password.otp_label'.tr(),
          style: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _otpController,
          focusNode: _otpFocus,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          onFieldSubmitted: (_) {
            FocusScope.of(context).requestFocus(_passwordFocus);
          },
          style: GoogleFonts.manrope(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: isDarkMode ? Colors.white : Colors.grey.shade900,
            letterSpacing: 2,
          ),
          validator: (v) =>
              (v?.isEmpty ?? true) ? 'reset_password.otp_empty'.tr() : null,
          decoration: InputDecoration(
            hintText: 'reset_password.otp_hint'.tr(),
            hintStyle: GoogleFonts.manrope(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: Colors.grey.shade400,
              letterSpacing: 0,
            ),
            prefixIcon: Icon(
              CupertinoIcons.lock_shield,
              size: 20,
              color: Colors.grey.shade400,
            ),
            filled: true,
            fillColor: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50,
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
                color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade900,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
            ),
            errorStyle: GoogleFonts.manrope(fontSize: 13, height: 1.4),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'reset_password.new_password_label'.tr(),
          style: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _passwordController,
          focusNode: _passwordFocus,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.next,
          onFieldSubmitted: (_) {
            FocusScope.of(context).requestFocus(_confirmPasswordFocus);
          },
          onChanged: (_) => setState(() {}),
          style: GoogleFonts.manrope(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: isDarkMode ? Colors.white : Colors.grey.shade900,
          ),
          validator: (v) => (v?.length ?? 0) < 6
              ? 'reset_password.password_min_char'.tr()
              : null,
          decoration: InputDecoration(
            hintText: 'reset_password.password_hint'.tr(),
            hintStyle: GoogleFonts.manrope(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: Colors.grey.shade400,
            ),
            prefixIcon: Icon(
              CupertinoIcons.lock,
              size: 20,
              color: Colors.grey.shade400,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? CupertinoIcons.eye
                    : CupertinoIcons.eye_slash,
                size: 20,
                color: Colors.grey.shade400,
              ),
              onPressed: () {
                setState(() => _obscurePassword = !_obscurePassword);
                HapticFeedback.selectionClick();
              },
            ),
            filled: true,
            fillColor: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50,
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
                color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade900,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
            ),
            errorStyle: GoogleFonts.manrope(fontSize: 13, height: 1.4),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmPasswordField(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'reset_password.confirm_password_label'.tr(),
          style: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _confirmPasswordController,
          focusNode: _confirmPasswordFocus,
          obscureText: _obscureConfirmPassword,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _submitResetPassword(),
          onChanged: (_) => setState(() {}),
          style: GoogleFonts.manrope(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: isDarkMode ? Colors.white : Colors.grey.shade900,
          ),
          validator: (v) => v != _passwordController.text
              ? 'reset_password.password_not_match'.tr()
              : null,
          decoration: InputDecoration(
            hintText: 'reset_password.password_hint'.tr(),
            hintStyle: GoogleFonts.manrope(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: Colors.grey.shade400,
            ),
            prefixIcon: Icon(
              CupertinoIcons.lock,
              size: 20,
              color: Colors.grey.shade400,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword
                    ? CupertinoIcons.eye
                    : CupertinoIcons.eye_slash,
                size: 20,
                color: Colors.grey.shade400,
              ),
              onPressed: () {
                setState(
                    () => _obscureConfirmPassword = !_obscureConfirmPassword);
                HapticFeedback.selectionClick();
              },
            ),
            filled: true,
            fillColor: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50,
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
                color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade900,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
            ),
            errorStyle: GoogleFonts.manrope(fontSize: 13, height: 1.4),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordRequirements(bool isDarkMode) {
    final hasMinLength = _passwordController.text.length >= 6;
    final passwordsMatch = _passwordController.text.isNotEmpty &&
        _passwordController.text == _confirmPasswordController.text;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.grey.shade900.withOpacity(0.5)
            : const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'reset_password.password_requirements'.tr(),
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: isDarkMode ? Colors.white : Colors.grey.shade900,
            ),
          ),
          const SizedBox(height: 12),
          _buildRequirementItem(
            'reset_password.password_min_char'.tr(),
            hasMinLength,
            isDarkMode,
          ),
          const SizedBox(height: 8),
          _buildRequirementItem(
            'reset_password.password_match'.tr(),
            passwordsMatch,
            isDarkMode,
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementItem(String text, bool isMet, bool isDarkMode) {
    return Row(
      children: [
        Icon(
          isMet
              ? CupertinoIcons.check_mark_circled_solid
              : CupertinoIcons.circle,
          size: 16,
          color: isMet
              ? const Color(0xFF10B981)
              : (isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.manrope(
              fontSize: 13,
              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(bool isDarkMode) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        onPressed: _isLoading ? null : _submitResetPassword,
        style: FilledButton.styleFrom(
          backgroundColor: isDarkMode ? Colors.white : Colors.grey.shade900,
          foregroundColor: isDarkMode ? Colors.black : Colors.white,
          disabledBackgroundColor: Colors.grey.shade300,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: isDarkMode ? Colors.black : Colors.white,
                ),
              )
            : Text(
                'reset_password.submit_button'.tr(),
                style: GoogleFonts.manrope(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildInfoCard(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.grey.shade900.withOpacity(0.5)
            : const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            CupertinoIcons.info_circle,
            size: 20,
            color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'reset_password.info_title'.tr(),
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: isDarkMode ? Colors.white : Colors.grey.shade900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'reset_password.info_description'.tr(),
                  style: GoogleFonts.manrope(
                    color: isDarkMode
                        ? Colors.grey.shade400
                        : Colors.grey.shade600,
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
}
