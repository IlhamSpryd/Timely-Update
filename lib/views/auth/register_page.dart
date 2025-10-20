import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timely/services/auth_repository.dart';
import 'package:timely/services/training_repository.dart';
import 'package:timely/utils/app_transitions.dart';
import 'package:timely/views/auth/login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with TickerProviderStateMixin {
  final AuthRepository _authRepository = AuthRepository();
  final TrainingRepository _trainingRepository = TrainingRepository();
  final _formKey = GlobalKey<FormState>();
  final PageController _pageController = PageController();

  // Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Focus Nodes
  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();

  String? _selectedTraining, _selectedBatch, _selectedGender;
  int? _selectedTrainingId, _selectedBatchId;
  List<Map<String, dynamic>> _trainings = [];
  List<Map<String, dynamic>> _batches = [];
  late List<String> _genders;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  int _currentStep = 0;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _loadDropdownData();
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    _genders = ['register.gender_male'.tr(), 'register.gender_female'.tr()];
  }

  Future<void> _loadDropdownData() async {
    try {
      final loadedTrainings = await _trainingRepository.getTrainings();
      if (loadedTrainings.data != null) {
        _trainings = List<Map<String, dynamic>>.from(
          loadedTrainings.data!.map(
            (t) => {'id': t.id, 'title': t.title ?? 'Training'},
          ),
        );
      }

      final loadedBatches = await _trainingRepository.getBatches();
      if (loadedBatches.data != null) {
        _batches = List<Map<String, dynamic>>.from(
          loadedBatches.data!.map(
            (b) => {'id': b.id, 'batch_ke': b.batchKe?.toString() ?? 'Batch'},
          ),
        );
      }
      if (mounted) setState(() {});
    } catch (e) {
      _handleError(e, 'register.data_load_failed'.tr());
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _nameController.text.trim().length >= 3 &&
            _emailController.text.isNotEmpty &&
            RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                .hasMatch(_emailController.text) &&
            _selectedGender != null;
      case 1:
        return _selectedTraining != null && _selectedBatch != null;
      case 2:
        return _passwordController.text.length >= 6 &&
            _passwordController.text == _confirmPasswordController.text;
      default:
        return false;
    }
  }

  void _nextStep() {
    if (_validateCurrentStep()) {
      if (_currentStep < 2) {
        HapticFeedback.lightImpact();
        _pageController.nextPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
        setState(() => _currentStep++);
      } else {
        _handleRegister();
      }
    } else {
      HapticFeedback.mediumImpact();
      _showErrorSnackBar('register.validation_error_prompt'.tr());
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      HapticFeedback.lightImpact();
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep--);
    }
  }

  void _handleRegister() async {
    setState(() => _isLoading = true);
    HapticFeedback.lightImpact();

    final genderToSend =
        _selectedGender == 'register.gender_male'.tr() ? "L" : "P";

    try {
      await _authRepository.register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        batchId: _selectedBatchId!,
        trainingId: _selectedTrainingId!,
        jenisKelamin: genderToSend,
      );

      if (mounted) {
        _showSuccessSnackBar('register.success_message'.tr());
        await Future.delayed(const Duration(milliseconds: 500));
        Navigator.pushAndRemoveUntil(
          context,
          SlideFadeRoute(page: const LoginPage()),
          (route) => false,
        );
      }
    } catch (e) {
      _handleError(e, 'register.registration_failed'.tr());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleError(dynamic error, String genericMessage) {
    if (mounted) {
      String displayMessage = error is Exception
          ? error.toString().replaceFirst('Exception: ', '')
          : genericMessage;
      _showErrorSnackBar(displayMessage);
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
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
  }

  void _showErrorSnackBar(String message) {
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
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            CupertinoIcons.back,
            color: isDarkMode ? Colors.white : Colors.grey.shade900,
          ),
          onPressed: () {
            HapticFeedback.lightImpact();
            if (_currentStep > 0) {
              _previousStep();
            } else {
              Navigator.of(context).pop();
            }
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
            child: Column(
              children: [
                _buildProgressIndicator(isDarkMode),
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      onPageChanged: (index) {
                        setState(() => _currentStep = index);
                      },
                      children: [
                        _buildStep1(isDarkMode),
                        _buildStep2(isDarkMode),
                        _buildStep3(isDarkMode),
                      ],
                    ),
                  ),
                ),
                _buildBottomSection(isDarkMode),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: List.generate(3, (index) {
          final isActive = index <= _currentStep;
          return Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: isActive
                    ? (isDarkMode ? Colors.white : Colors.grey.shade900)
                    : (isDarkMode
                        ? Colors.grey.shade800
                        : Colors.grey.shade200),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStep1(bool isDarkMode) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      physics: const ClampingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(
            'register.step1_title'.tr(),
            'register.step1_subtitle'.tr(),
            isDarkMode,
          ),
          const SizedBox(height: 32),
          _buildTextField(
            controller: _nameController,
            focusNode: _nameFocus,
            label: 'register.full_name_label'.tr(),
            hint: 'register.full_name_hint'.tr(),
            icon: CupertinoIcons.person,
            isDarkMode: isDarkMode,
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (_) {
              FocusScope.of(context).requestFocus(_emailFocus);
            },
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _emailController,
            focusNode: _emailFocus,
            label: 'register.email_label'.tr(),
            hint: 'register.email_hint'.tr(),
            icon: CupertinoIcons.mail,
            isDarkMode: isDarkMode,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (_) {
              FocusScope.of(context).unfocus();
            },
          ),
          const SizedBox(height: 20),
          _buildDropdownField(
            label: 'register.gender_label'.tr(),
            hint: 'register.gender_hint'.tr(),
            value: _selectedGender,
            items: _genders,
            icon: CupertinoIcons.person_2,
            isDarkMode: isDarkMode,
            onChanged: (v) => setState(() => _selectedGender = v),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2(bool isDarkMode) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      physics: const ClampingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(
            'register.step2_title'.tr(),
            'register.step2_subtitle'.tr(),
            isDarkMode,
          ),
          const SizedBox(height: 32),
          _buildDropdownField(
            label: 'register.training_program_label'.tr(),
            hint: 'register.training_program_hint'.tr(),
            value: _selectedTraining,
            items: _trainings.map((t) => t['title'] as String).toList(),
            icon: CupertinoIcons.book,
            isDarkMode: isDarkMode,
            onChanged: (value) {
              setState(() {
                _selectedTraining = value;
                _selectedTrainingId = _trainings.firstWhere(
                  (t) => t['title'] == value,
                )['id'];
              });
            },
          ),
          const SizedBox(height: 20),
          _buildDropdownField(
            label: 'register.batch_label'.tr(),
            hint: 'register.batch_hint'.tr(),
            value: _selectedBatch,
            items: _batches.map((b) => b['batch_ke'] as String).toList(),
            icon: CupertinoIcons.group,
            isDarkMode: isDarkMode,
            displayText: (value) => 'register.batch_display'.tr(args: [value]),
            onChanged: (value) {
              setState(() {
                _selectedBatch = value;
                _selectedBatchId = _batches.firstWhere(
                  (b) => b['batch_ke'] == value,
                )['id'];
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStep3(bool isDarkMode) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      physics: const ClampingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(
            'register.step3_title'.tr(),
            'register.step3_subtitle'.tr(),
            isDarkMode,
          ),
          const SizedBox(height: 32),
          _buildPasswordField(
            controller: _passwordController,
            focusNode: _passwordFocus,
            label: 'register.password_label'.tr(),
            hint: 'register.password_hint'.tr(),
            isDarkMode: isDarkMode,
            obscureText: _obscurePassword,
            onToggle: () =>
                setState(() => _obscurePassword = !_obscurePassword),
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (_) {
              FocusScope.of(context).requestFocus(_confirmPasswordFocus);
            },
          ),
          const SizedBox(height: 20),
          _buildPasswordField(
            controller: _confirmPasswordController,
            focusNode: _confirmPasswordFocus,
            label: 'register.confirm_password_label'.tr(),
            hint: 'register.confirm_password_hint'.tr(),
            isDarkMode: isDarkMode,
            obscureText: _obscureConfirmPassword,
            onToggle: () => setState(
                () => _obscureConfirmPassword = !_obscureConfirmPassword),
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _nextStep(),
          ),
          const SizedBox(height: 24),
          _buildPasswordRequirements(isDarkMode),
        ],
      ),
    );
  }

  Widget _buildHeader(String title, String subtitle, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
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
          subtitle,
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

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDarkMode,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    Function(String)? onFieldSubmitted,
  }) {
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
          focusNode: focusNode,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onFieldSubmitted: onFieldSubmitted,
          style: GoogleFonts.manrope(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: isDarkMode ? Colors.white : Colors.grey.shade900,
          ),
          decoration: _buildInputDecoration(
            hint: hint,
            icon: icon,
            isDarkMode: isDarkMode,
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    required bool isDarkMode,
    required bool obscureText,
    required VoidCallback onToggle,
    TextInputAction? textInputAction,
    Function(String)? onFieldSubmitted,
  }) {
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
          focusNode: focusNode,
          obscureText: obscureText,
          textInputAction: textInputAction,
          onFieldSubmitted: onFieldSubmitted,
          style: GoogleFonts.manrope(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: isDarkMode ? Colors.white : Colors.grey.shade900,
          ),
          decoration: _buildInputDecoration(
            hint: hint,
            icon: CupertinoIcons.lock,
            isDarkMode: isDarkMode,
            suffixIcon: IconButton(
              icon: Icon(
                obscureText ? CupertinoIcons.eye : CupertinoIcons.eye_slash,
                size: 20,
                color: Colors.grey.shade400,
              ),
              onPressed: () {
                onToggle();
                HapticFeedback.selectionClick();
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String hint,
    required String? value,
    required List<String> items,
    required IconData icon,
    required bool isDarkMode,
    String Function(String)? displayText,
    required void Function(String?) onChanged,
  }) {
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
        DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          onChanged: onChanged,
          style: GoogleFonts.manrope(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: isDarkMode ? Colors.white : Colors.grey.shade900,
          ),
          dropdownColor: isDarkMode ? Colors.grey.shade900 : Colors.white,
          icon: Icon(
            CupertinoIcons.chevron_down,
            size: 20,
            color: Colors.grey.shade400,
          ),
          items: items.map<DropdownMenuItem<String>>((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                displayText != null ? displayText(item) : item,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          decoration: _buildInputDecoration(
            hint: hint,
            icon: icon,
            isDarkMode: isDarkMode,
          ),
        ),
      ],
    );
  }

  InputDecoration _buildInputDecoration({
    required String hint,
    required IconData icon,
    required bool isDarkMode,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.manrope(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: Colors.grey.shade400,
      ),
      prefixIcon: Icon(
        icon,
        size: 20,
        color: Colors.grey.shade400,
      ),
      suffixIcon: suffixIcon,
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
            'register.password_requirements'.tr(),
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: isDarkMode ? Colors.white : Colors.grey.shade900,
            ),
          ),
          const SizedBox(height: 12),
          _buildRequirementItem(
            'register.password_min_char'.tr(),
            hasMinLength,
            isDarkMode,
          ),
          const SizedBox(height: 8),
          _buildRequirementItem(
            'register.password_match'.tr(),
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

  Widget _buildBottomSection(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.black : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade100,
            width: 1,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: _isLoading ? null : _nextStep,
              style: FilledButton.styleFrom(
                backgroundColor:
                    isDarkMode ? Colors.white : Colors.grey.shade900,
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
                      _currentStep < 2
                          ? 'register.continue_button'.tr()
                          : 'register.create_account_button'.tr(),
                      style: GoogleFonts.manrope(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'register.already_have_account'.tr(),
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey.shade600,
                ),
              ),
              TextButton(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  Navigator.of(context).pop();
                },
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'register.login_link'.tr(),
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDarkMode ? Colors.white : Colors.grey.shade900,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
