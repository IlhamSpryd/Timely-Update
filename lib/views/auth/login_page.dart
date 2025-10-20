import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timely/services/auth_repository.dart';
import 'package:timely/utils/app_transitions.dart';
import 'package:timely/views/auth/forgot_password_page.dart';
import 'package:timely/views/auth/register_page.dart';
import 'package:timely/views/main/main_wrapper.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _obscurePassword = true;
  bool _isLoading = false;
  final AuthRepository _authRepository = AuthRepository();

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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.mediumImpact();
      return;
    }

    HapticFeedback.lightImpact();
    setState(() => _isLoading = true);

    try {
      final success = await _authRepository.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      if (success && mounted) {
        _navigateToMain();
      }
    } catch (e) {
      String errorMessage;
      if (e.toString().contains('401')) {
        errorMessage = 'login.login_failed_credentials'.tr();
      } else if (e.toString().contains('Invalid login response') ||
          e.toString().contains('Exception:')) {
        errorMessage = e.toString().replaceFirst('Exception: ', '').trim();
      } else {
        errorMessage = 'login.login_failed_generic'.tr();
      }
      _showLoginError(errorMessage);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateToMain() {
    Navigator.pushReplacement(
      context,
      SlideFadeRoute(page: const MainWrapper()),
    );
  }

  void _showLoginError(String message) {
    if (mounted) {
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
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? Colors.black : Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
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
                    const SizedBox(height: 40),
                    _buildHeader(isDarkMode),
                    const SizedBox(height: 48),
                    _buildEmailField(isDarkMode),
                    const SizedBox(height: 20),
                    _buildPasswordField(isDarkMode),
                    const SizedBox(height: 8),
                    _buildForgotPasswordButton(isDarkMode),
                    const SizedBox(height: 32),
                    _buildLoginButton(isDarkMode),
                    const SizedBox(height: 32),
                    _buildDivider(isDarkMode),
                    const SizedBox(height: 24),
                    _buildRegisterSection(isDarkMode),
                    const SizedBox(height: 24),
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
          'login.welcome_message'.tr(),
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
          'login.subtitle'.tr(),
          style: GoogleFonts.manrope(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: Colors.grey.shade600,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildEmailField(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'login.email'.tr(),
          style: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _emailController,
          focusNode: _emailFocus,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          onFieldSubmitted: (_) {
            FocusScope.of(context).requestFocus(_passwordFocus);
          },
          style: GoogleFonts.manrope(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: isDarkMode ? Colors.white : Colors.grey.shade900,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'login.email_empty'.tr();
            }
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
              return 'login.email_invalid'.tr();
            }
            return null;
          },
          decoration: InputDecoration(
            hintText: 'login.email_hint'.tr(),
            hintStyle: GoogleFonts.manrope(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: Colors.grey.shade400,
            ),
            prefixIcon: Icon(
              CupertinoIcons.mail,
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
          'login.password'.tr(),
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
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _handleLogin(),
          style: GoogleFonts.manrope(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: isDarkMode ? Colors.white : Colors.grey.shade900,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'login.password_empty'.tr();
            }
            if (value.length < 6) {
              return 'login.password_min_char'.tr();
            }
            return null;
          },
          decoration: InputDecoration(
            hintText: '••••••••',
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

  Widget _buildForgotPasswordButton(bool isDarkMode) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () {
          HapticFeedback.selectionClick();
          Navigator.push(
            context,
            SlideFadeRoute(page: const ForgotPasswordPage()),
          );
        },
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          minimumSize: const Size(0, 0),
        ),
        child: Text(
          'login.forgot_password'.tr(),
          style: GoogleFonts.manrope(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton(bool isDarkMode) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        onPressed: _isLoading ? null : _handleLogin,
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
                'login.login_button'.tr(),
                style: GoogleFonts.manrope(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildDivider(bool isDarkMode) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
            thickness: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'login.or_divider'.tr(),
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade500,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
            thickness: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterSection(bool isDarkMode) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'login.no_account'.tr(),
          style: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Colors.grey.shade600,
          ),
        ),
        TextButton(
          onPressed: () {
            HapticFeedback.selectionClick();
            Navigator.push(
              context,
              SlideFadeRoute(page: const RegisterPage()),
            );
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
            minimumSize: const Size(0, 0),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'login.register'.tr(),
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDarkMode ? Colors.white : Colors.grey.shade900,
            ),
          ),
        ),
      ],
    );
  }
}
