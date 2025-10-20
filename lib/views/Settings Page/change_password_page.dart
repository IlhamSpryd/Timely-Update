import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  bool _isCurrentPasswordObscured = true;
  bool _isNewPasswordObscured = true;
  bool _isConfirmPasswordObscured = true;

  double _passwordStrength = 0.0;
  Color _passwordStrengthColor = Colors.grey.shade300;

  final _currentPasswordFocus = FocusNode();
  final _newPasswordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _newPasswordController.addListener(_checkPasswordStrength);
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _currentPasswordFocus.dispose();
    _newPasswordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  void _checkPasswordStrength() {
    final password = _newPasswordController.text;
    double strength = 0.0;
    Color color = Colors.grey.shade300;

    if (password.isEmpty) {
      strength = 0.0;
    } else if (password.length < 6) {
      strength = 0.25;
      color = const Color(0xFFEF4444);
    } else if (password.length < 8) {
      strength = 0.5;
      color = const Color(0xFFF59E0B);
    } else {
      bool hasUppercase = password.contains(RegExp(r'[A-Z]'));
      bool hasLowercase = password.contains(RegExp(r'[a-z]'));
      bool hasDigits = password.contains(RegExp(r'[0-9]'));
      bool hasSpecialChar = password.contains(
        RegExp(r'[!@#$%^&*(),.?":{}|<>]'),
      );

      int complexityCount = 0;
      if (hasUppercase) complexityCount++;
      if (hasLowercase) complexityCount++;
      if (hasDigits) complexityCount++;
      if (hasSpecialChar) complexityCount++;

      if (complexityCount >= 3) {
        strength = 1.0;
        color = const Color(0xFF10B981);
      } else {
        strength = 0.75;
        color = const Color(0xFF84CC16);
      }
    }

    setState(() {
      _passwordStrength = strength;
      _passwordStrengthColor = color;
    });
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.mediumImpact();
      return;
    }
    setState(() => _isLoading = true);
    HapticFeedback.lightImpact();

    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      HapticFeedback.heavyImpact();
      _showSuccessDialog();
    }

    if (mounted) setState(() => _isLoading = false);
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Color(0xFF10B981),
                  size: 32,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'change_password.success_dialog_title'.tr(),
                style: GoogleFonts.manrope(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'change_password.success_dialog_body'.tr(),
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context, true);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.grey.shade900,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'change_password.success_dialog_button'.tr(),
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordFormField({
    required TextEditingController controller,
    required String label,
    required bool isObscured,
    required VoidCallback toggleVisibility,
    required String? Function(String?)? validator,
    required FocusNode focusNode,
    FocusNode? nextFocus,
    bool showStrengthIndicator = false,
  }) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: isObscured,
          validator: validator,
          focusNode: focusNode,
          textInputAction: nextFocus != null
              ? TextInputAction.next
              : TextInputAction.done,
          onFieldSubmitted: (_) {
            if (nextFocus != null) {
              FocusScope.of(context).requestFocus(nextFocus);
            } else {
              _changePassword();
            }
          },
          style: GoogleFonts.manrope(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: isDarkMode ? Colors.white : Colors.grey.shade900,
          ),
          decoration: InputDecoration(
            hintText: '••••••••',
            hintStyle: GoogleFonts.manrope(
              color: Colors.grey.shade400,
              fontWeight: FontWeight.w400,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                isObscured ? CupertinoIcons.eye : CupertinoIcons.eye_slash,
                color: Colors.grey.shade400,
                size: 20,
              ),
              onPressed: () {
                HapticFeedback.selectionClick();
                toggleVisibility();
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
        if (showStrengthIndicator && _newPasswordController.text.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _passwordStrength,
                backgroundColor: Colors.grey.shade200,
                color: _passwordStrengthColor,
                minHeight: 4,
              ),
            ),
          ),
      ],
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
        title: Text(
          "change_password.title".tr(),
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w600,
            fontSize: 17,
            color: isDarkMode ? Colors.white : Colors.grey.shade900,
          ),
        ),
        centerTitle: false,
        backgroundColor: backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        physics: const ClampingScrollPhysics(),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'change_password.header_title'.tr(),
                style: GoogleFonts.manrope(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: isDarkMode ? Colors.white : Colors.grey.shade900,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'change_password.header_subtitle'.tr(),
                style: GoogleFonts.manrope(
                  color: Colors.grey.shade600,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),
              _buildPasswordFormField(
                controller: _currentPasswordController,
                label: 'change_password.current_password'.tr(),
                isObscured: _isCurrentPasswordObscured,
                toggleVisibility: () => setState(
                  () =>
                      _isCurrentPasswordObscured = !_isCurrentPasswordObscured,
                ),
                focusNode: _currentPasswordFocus,
                nextFocus: _newPasswordFocus,
                validator: (v) => v == null || v.isEmpty
                    ? 'change_password.validation_empty'.tr()
                    : null,
              ),
              const SizedBox(height: 24),
              _buildPasswordFormField(
                controller: _newPasswordController,
                label: 'change_password.new_password'.tr(),
                isObscured: _isNewPasswordObscured,
                toggleVisibility: () => setState(
                  () => _isNewPasswordObscured = !_isNewPasswordObscured,
                ),
                focusNode: _newPasswordFocus,
                nextFocus: _confirmPasswordFocus,
                showStrengthIndicator: true,
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return 'change_password.validation_empty'.tr();
                  }
                  if (v.length < 6) {
                    return 'change_password.validation_min_char'.tr();
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              _buildPasswordFormField(
                controller: _confirmPasswordController,
                label: 'change_password.confirm_new_password'.tr(),
                isObscured: _isConfirmPasswordObscured,
                toggleVisibility: () => setState(
                  () =>
                      _isConfirmPasswordObscured = !_isConfirmPasswordObscured,
                ),
                focusNode: _confirmPasswordFocus,
                validator: (v) {
                  if (v != _newPasswordController.text) {
                    return 'change_password.validation_not_match'.tr();
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? Colors.grey.shade900.withOpacity(0.5)
                      : const Color(0xFFFAFAFA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDarkMode
                        ? Colors.grey.shade800
                        : Colors.grey.shade200,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'change_password.tips_title'.tr(),
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: isDarkMode ? Colors.white : Colors.grey.shade900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildRequirement('change_password.tip1'.tr()),
                    _buildRequirement('change_password.tip2'.tr()),
                    _buildRequirement('change_password.tip3'.tr()),
                    _buildRequirement(
                      'change_password.tip4'.tr(),
                      isLast: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
          24,
          16,
          24,
          MediaQuery.of(context).padding.bottom + 16,
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border(
            top: BorderSide(
              color: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade100,
              width: 1,
            ),
          ),
        ),
        child: SizedBox(
          height: 52,
          child: FilledButton(
            onPressed: _isLoading ? null : _changePassword,
            style: FilledButton.styleFrom(
              backgroundColor: isDarkMode ? Colors.white : Colors.grey.shade900,
              foregroundColor: isDarkMode ? Colors.black : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              disabledBackgroundColor: Colors.grey.shade300,
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
                    'change_password.update_button'.tr(),
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildRequirement(String text, {bool isLast = false}) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.manrope(
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
