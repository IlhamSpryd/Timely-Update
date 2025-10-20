import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timely/models/alldatauser_model.dart';
import 'package:timely/models/traininglist_model.dart';
import 'package:timely/services/training_repository.dart';
import 'package:timely/services/user_repository.dart';

class AllUsersPage extends StatefulWidget {
  const AllUsersPage({super.key});

  @override
  State<AllUsersPage> createState() => _AllUsersPageState();
}

class _AllUsersPageState extends State<AllUsersPage> {
  final UserRepository _userRepository = UserRepository();
  final TrainingRepository _trainingRepository = TrainingRepository();
  final TextEditingController _searchController = TextEditingController();

  List<UserModel> _allUsers = [];
  List<UserModel> _filteredUsers = [];
  Map<int, String> _trainingTitles = {};
  bool _isLoading = true;
  String? _error;

  String? _selectedBatch;
  String? _selectedTraining;
  String? _selectedGender;
  List<String> _uniqueBatches = [];
  List<String> _uniqueTrainings = [];
  late List<String> _genders;

  bool _hasActiveFilters = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_applyFiltersAndSearch);
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _genders = ['register.gender_male'.tr(), 'register.gender_female'.tr()];
  }

  @override
  void dispose() {
    _searchController.removeListener(_applyFiltersAndSearch);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _userRepository.getAllUsers(),
        _trainingRepository.getTrainings(),
      ]);

      final userModel = results[0] as AllDataUserModel;
      final trainingModel = results[1] as ListTrainingModel;

      final users = userModel.data ?? [];
      final trainings = trainingModel.data ?? [];

      final trainingMap = <int, String>{};
      for (var training in trainings) {
        if (training.id != null && training.title != null) {
          trainingMap[training.id!] = training.title!;
        }
      }

      if (!mounted) return;

      setState(() {
        _allUsers = users;
        _filteredUsers = users;
        _trainingTitles = trainingMap;
        _extractFilterOptions();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _extractFilterOptions() {
    final batchSet = <String>{};
    final trainingSet = <String>{};
    for (var user in _allUsers) {
      if (user.batchId != null) {
        batchSet.add(user.batchId!.toString());
      }
      if (user.trainingId != null &&
          _trainingTitles.containsKey(user.trainingId)) {
        trainingSet.add(_trainingTitles[user.trainingId]!);
      }
    }
    _uniqueBatches = batchSet.toList()..sort();
    _uniqueTrainings = trainingSet.toList()..sort();
  }

  void _applyFiltersAndSearch() {
    List<UserModel> tempUsers = List.from(_allUsers);
    final searchQuery = _searchController.text.toLowerCase().trim();

    if (_selectedBatch != null) {
      tempUsers = tempUsers
          .where((u) => u.batchId?.toString() == _selectedBatch)
          .toList();
    }
    if (_selectedTraining != null) {
      tempUsers = tempUsers.where((u) {
        final userTrainingTitle = _trainingTitles[u.trainingId];
        return userTrainingTitle == _selectedTraining;
      }).toList();
    }
    if (_selectedGender != null) {
      final genderValue = _selectedGender == 'register.gender_male'.tr()
          ? 'L'
          : 'P';
      tempUsers = tempUsers
          .where((u) => u.jenisKelamin == genderValue)
          .toList();
    }

    if (searchQuery.isNotEmpty) {
      tempUsers = tempUsers.where((user) {
        final nameMatch =
            user.name?.toLowerCase().contains(searchQuery) ?? false;
        final emailMatch =
            user.email?.toLowerCase().contains(searchQuery) ?? false;
        return nameMatch || emailMatch;
      }).toList();
    }

    setState(() {
      _filteredUsers = tempUsers;
      _hasActiveFilters =
          _selectedBatch != null ||
          _selectedTraining != null ||
          _selectedGender != null;
    });
  }

  void _resetFilters() {
    setState(() {
      _selectedBatch = null;
      _selectedTraining = null;
      _selectedGender = null;
      _hasActiveFilters = false;
    });
    _applyFiltersAndSearch();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? Colors.black : Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(theme, isDarkMode),
            _buildSearchAndFilter(theme, isDarkMode),
            if (_hasActiveFilters) _buildActiveFiltersChips(theme, isDarkMode),
            Expanded(child: _buildBodyContent(theme, isDarkMode)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'all_users.title'.tr(),
                  style: GoogleFonts.manrope(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: isDarkMode ? Colors.white : Colors.grey.shade900,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'all_users.subtitle'.tr(
                    args: [
                      _filteredUsers.length.toString(),
                      _allUsers.length.toString(),
                    ],
                  ),
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter(ThemeData theme, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDarkMode
                      ? Colors.grey.shade800
                      : Colors.grey.shade200,
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _searchController,
                style: GoogleFonts.manrope(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: 'all_users.search_hint'.tr(),
                  hintStyle: GoogleFonts.manrope(
                    color: Colors.grey.shade400,
                    fontSize: 15,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: Colors.grey.shade400,
                    size: 20,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.close_rounded,
                            color: Colors.grey.shade400,
                            size: 18,
                          ),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: _hasActiveFilters
                  ? (isDarkMode ? Colors.white : Colors.grey.shade900)
                  : (isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _hasActiveFilters
                    ? (isDarkMode ? Colors.white : Colors.grey.shade900)
                    : (isDarkMode
                          ? Colors.grey.shade800
                          : Colors.grey.shade200),
                width: 1,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _showFilterModal,
                borderRadius: BorderRadius.circular(12),
                child: Icon(
                  Icons.tune_rounded,
                  color: _hasActiveFilters
                      ? (isDarkMode ? Colors.black : Colors.white)
                      : Colors.grey.shade400,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFiltersChips(ThemeData theme, bool isDarkMode) {
    List<Widget> chips = [];

    if (_selectedBatch != null) {
      chips.add(
        _buildFilterChip(
          'all_users.chip_batch'.tr(args: [_selectedBatch!]),
          () {
            setState(() => _selectedBatch = null);
            _applyFiltersAndSearch();
          },
          theme,
          isDarkMode,
        ),
      );
    }
    if (_selectedTraining != null) {
      chips.add(
        _buildFilterChip(
          _selectedTraining!,
          () {
            setState(() => _selectedTraining = null);
            _applyFiltersAndSearch();
          },
          theme,
          isDarkMode,
        ),
      );
    }
    if (_selectedGender != null) {
      chips.add(
        _buildFilterChip(
          _selectedGender!,
          () {
            setState(() => _selectedGender = null);
            _applyFiltersAndSearch();
          },
          theme,
          isDarkMode,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const ClampingScrollPhysics(),
              child: Row(
                children: chips.map((chip) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: chip,
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _resetFilters,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Text(
                  'all_users.clear_filters'.tr(),
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode
                        ? Colors.grey.shade400
                        : Colors.grey.shade600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    VoidCallback onRemove,
    ThemeData theme,
    bool isDarkMode,
  ) {
    String displayLabel = label;
    if (label.length > 20) {
      displayLabel = '${label.substring(0, 20)}...';
    }

    return Container(
      constraints: const BoxConstraints(maxWidth: 200),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: Text(
              displayLabel,
              style: GoogleFonts.manrope(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Icon(
              Icons.close_rounded,
              size: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyContent(ThemeData theme, bool isDarkMode) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isDarkMode ? Colors.white : Colors.grey.shade900,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'all_users.loading'.tr(),
              style: GoogleFonts.manrope(
                color: Colors.grey.shade500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return _buildErrorView(_error!, theme, isDarkMode);
    }

    if (_filteredUsers.isEmpty) {
      return _buildEmptyView(
        isSearchResult: _searchController.text.isNotEmpty || _hasActiveFilters,
        theme: theme,
        isDarkMode: isDarkMode,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: isDarkMode ? Colors.white : Colors.grey.shade900,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        itemCount: _filteredUsers.length,
        itemBuilder: (context, index) {
          final user = _filteredUsers[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildUserCard(user, theme, isDarkMode),
          );
        },
      ),
    );
  }

  Widget _buildUserCard(UserModel user, ThemeData theme, bool isDarkMode) {
    final trainingTitle = _trainingTitles[user.trainingId] ?? '-';

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showUserDetailModal(user, theme, isDarkMode),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildAvatar(user, theme, isDarkMode),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name ?? 'all_users.name_unavailable'.tr(),
                        style: GoogleFonts.manrope(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: isDarkMode
                              ? Colors.white
                              : Colors.grey.shade900,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email ?? 'all_users.email_unavailable'.tr(),
                        style: GoogleFonts.manrope(
                          color: Colors.grey.shade500,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        trainingTitle,
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(UserModel user, ThemeData theme, bool isDarkMode) {
    if (user.profilePhoto != null &&
        Uri.tryParse(user.profilePhoto!)?.hasAbsolutePath == true) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
            width: 1,
          ),
        ),
        child: ClipOval(
          child: Image.network(
            user.profilePhoto!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildDefaultAvatar(user, theme, isDarkMode);
            },
          ),
        ),
      );
    }
    return _buildDefaultAvatar(user, theme, isDarkMode);
  }

  Widget _buildDefaultAvatar(UserModel user, ThemeData theme, bool isDarkMode) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
      ),
      child: Center(
        child: Text(
          user.name?.isNotEmpty == true ? user.name![0].toUpperCase() : 'U',
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  void _showUserDetailModal(UserModel user, ThemeData theme, bool isDarkMode) {
    final bgColor = isDarkMode ? Colors.grey.shade900 : Colors.white;
    final trainingTitle = _trainingTitles[user.trainingId] ?? '-';
    final gender = (user.jenisKelamin == 'L')
        ? 'register.gender_male'.tr()
        : 'register.gender_female'.tr();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildAvatar(user, theme, isDarkMode),
                  const SizedBox(height: 16),
                  Text(
                    user.name ?? 'all_users.name_unavailable'.tr(),
                    style: GoogleFonts.manrope(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white : Colors.grey.shade900,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    user.email ?? 'all_users.email_unavailable'.tr(),
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? Colors.grey.shade800.withOpacity(0.5)
                          : const Color(0xFFFAFAFA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDarkMode
                            ? Colors.grey.shade800
                            : Colors.grey.shade200,
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow(
                          title: 'profile_detail.batch'.tr(),
                          value: user.batchId?.toString() ?? '-',
                          theme: theme,
                          isDarkMode: isDarkMode,
                        ),
                        const SizedBox(height: 16),
                        Divider(
                          height: 1,
                          color: isDarkMode
                              ? Colors.grey.shade800
                              : Colors.grey.shade200,
                        ),
                        const SizedBox(height: 16),
                        _buildDetailRow(
                          title: 'profile_detail.training_program'.tr(),
                          value: trainingTitle,
                          theme: theme,
                          isDarkMode: isDarkMode,
                        ),
                        const SizedBox(height: 16),
                        Divider(
                          height: 1,
                          color: isDarkMode
                              ? Colors.grey.shade800
                              : Colors.grey.shade200,
                        ),
                        const SizedBox(height: 16),
                        _buildDetailRow(
                          title: 'profile_detail.gender'.tr(),
                          value: gender,
                          theme: theme,
                          isDarkMode: isDarkMode,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context),
                      style: FilledButton.styleFrom(
                        backgroundColor: isDarkMode
                            ? Colors.white
                            : Colors.grey.shade900,
                        foregroundColor: isDarkMode
                            ? Colors.black
                            : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'all_users.close'.tr(),
                        style: GoogleFonts.manrope(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow({
    required String title,
    required String value,
    required ThemeData theme,
    required bool isDarkMode,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.manrope(
            fontSize: 13,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : Colors.grey.shade900,
            ),
            textAlign: TextAlign.right,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorView(String error, ThemeData theme, bool isDarkMode) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                size: 48,
                color: Color(0xFFEF4444),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'all_users.error_title'.tr(),
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.white : Colors.grey.shade900,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'all_users.error_body'.tr(),
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: _loadData,
                style: FilledButton.styleFrom(
                  backgroundColor: isDarkMode
                      ? Colors.white
                      : Colors.grey.shade900,
                  foregroundColor: isDarkMode ? Colors.black : Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'all_users.try_again'.tr(),
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
    );
  }

  Widget _buildEmptyView({
    required bool isSearchResult,
    required ThemeData theme,
    required bool isDarkMode,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade200.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSearchResult
                    ? Icons.search_off_rounded
                    : Icons.people_outline_rounded,
                size: 48,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isSearchResult
                  ? 'all_users.empty_title_search'.tr()
                  : 'all_users.empty_title_no_users'.tr(),
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.white : Colors.grey.shade900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isSearchResult
                  ? 'all_users.empty_body_search'.tr()
                  : 'all_users.empty_body_no_users'.tr(),
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
            if (isSearchResult) ...[
              const SizedBox(height: 24),
              TextButton(
                onPressed: () {
                  _searchController.clear();
                  _resetFilters();
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                child: Text(
                  'all_users.clear_search_and_filters'.tr(),
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: isDarkMode
                        ? Colors.grey.shade400
                        : Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showFilterModal() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final bgColor = isDarkMode ? Colors.grey.shade900 : Colors.white;

    String? tempBatch = _selectedBatch;
    String? tempTraining = _selectedTraining;
    String? tempGender = _selectedGender;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.only(
                    top: 24,
                    left: 24,
                    right: 24,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade400,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'all_users.filter_title'.tr(),
                              style: GoogleFonts.manrope(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: isDarkMode
                                    ? Colors.white
                                    : Colors.grey.shade900,
                              ),
                            ),
                          ),
                          if (tempBatch != null ||
                              tempTraining != null ||
                              tempGender != null)
                            TextButton(
                              onPressed: () {
                                setModalState(() {
                                  tempBatch = null;
                                  tempTraining = null;
                                  tempGender = null;
                                });
                              },
                              child: Text(
                                'all_users.reset'.tr(),
                                style: GoogleFonts.manrope(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: isDarkMode
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade700,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildModernDropdown(
                        label: 'profile_detail.batch'.tr(),
                        value: tempBatch,
                        items: _uniqueBatches,
                        onChanged: (val) =>
                            setModalState(() => tempBatch = val),
                        theme: theme,
                        isDarkMode: isDarkMode,
                      ),
                      const SizedBox(height: 16),
                      _buildModernDropdown(
                        label: 'all_users.training'.tr(),
                        value: tempTraining,
                        items: _uniqueTrainings,
                        onChanged: (val) =>
                            setModalState(() => tempTraining = val),
                        theme: theme,
                        isDarkMode: isDarkMode,
                      ),
                      const SizedBox(height: 16),
                      _buildModernDropdown(
                        label: 'profile_detail.gender'.tr(),
                        value: tempGender,
                        items: _genders,
                        onChanged: (val) =>
                            setModalState(() => tempGender = val),
                        theme: theme,
                        isDarkMode: isDarkMode,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 48,
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  side: BorderSide(
                                    color: isDarkMode
                                        ? Colors.grey.shade800
                                        : Colors.grey.shade300,
                                  ),
                                ),
                                child: Text(
                                  'home.cancel_button'.tr(),
                                  style: GoogleFonts.manrope(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SizedBox(
                              height: 48,
                              child: FilledButton(
                                onPressed: () {
                                  setState(() {
                                    _selectedBatch = tempBatch;
                                    _selectedTraining = tempTraining;
                                    _selectedGender = tempGender;
                                  });
                                  _applyFiltersAndSearch();
                                  Navigator.pop(context);
                                },
                                style: FilledButton.styleFrom(
                                  backgroundColor: isDarkMode
                                      ? Colors.white
                                      : Colors.grey.shade900,
                                  foregroundColor: isDarkMode
                                      ? Colors.black
                                      : Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  'all_users.apply'.tr(),
                                  style: GoogleFonts.manrope(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildModernDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required ThemeData theme,
    required bool isDarkMode,
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
        Container(
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade200,
              width: 1,
            ),
          ),
          child: DropdownButtonFormField<String>(
            initialValue: value,
            onChanged: onChanged,
            isExpanded: true,
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              hintText: 'all_users.select_hint'.tr(args: [label]),
              hintStyle: GoogleFonts.manrope(
                color: Colors.grey.shade400,
                fontSize: 15,
              ),
            ),
            style: GoogleFonts.manrope(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: isDarkMode ? Colors.white : Colors.grey.shade900,
            ),
            dropdownColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Colors.grey.shade400,
            ),
            items: [
              DropdownMenuItem<String>(
                value: null,
                child: Text(
                  'all_users.all_option'.tr(args: [label]),
                  style: GoogleFonts.manrope(
                    color: Colors.grey.shade500,
                    fontSize: 15,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              ...items.map((item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    style: GoogleFonts.manrope(fontSize: 15),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}
