import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';
import '../../config/app_text_styles.dart';
import '../../models/category_model.dart';
import '../../models/class_model.dart';
import '../../models/user_model.dart';
import '../../services/category_service.dart';
import '../../services/class_service.dart';
import '../../services/user_service.dart';
import '../class/class_detail_screen.dart';
import '../class/class_detail_public_screen.dart';
import '../category/category_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<CategoryModel> _categories = [];
  List<ClassModel> _classes = [];

  bool _isSearching = false;
  bool _hasSearched = false;
  String? _errorMessage;

  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await UserService.getCurrentUser();
      setState(() {
        _currentUser = user;
      });
    } catch (e) {
      print('⚠️ Error loading current user: $e');
    }
  }

  Future<void> _performSearch(String keyword) async {
    if (keyword.trim().isEmpty) {
      setState(() {
        _categories = [];
        _classes = [];
        _hasSearched = false;
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        CategoryService.searchCategories(keyword),
        ClassService.searchClasses(keyword),
      ]);

      if (!mounted) return;

      setState(() {
        _categories = results[0] as List<CategoryModel>;
        _classes = results[1] as List<ClassModel>;
        _hasSearched = true;
        _isSearching = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isSearching = false;
        _hasSearched = true;
      });
    }
  }

  void _navigateToCategory(CategoryModel category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryDetailScreen(
          category: category,
          isOwner: category.ownerUserId == _currentUser?.userId,
        ),
      ),
    );
  }

  /// Navigate to Class
  void _navigateToClass(ClassModel classModel) {
    if (_currentUser != null && classModel.ownerId == _currentUser!.userId) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ClassDetailScreen(classId: classModel.id),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ClassDetailPublicScreen(classModel: classModel),
        ),
      );
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Container(
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.inputBackground,
            borderRadius: BorderRadius.circular(22),
          ),
          child: TextField(
            controller: _searchController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Tìm chủ đề, lớp học, hoặc nhập mã lớp...',
              hintStyle: AppTextStyles.hint,
              prefixIcon: const Icon(Icons.search, color: AppColors.textGray),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.clear, color: AppColors.textGray),
                onPressed: () {
                  _searchController.clear();
                  _performSearch('');
                },
              )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onChanged: (value) {
              setState(() {});
              if (value.length >= 2) {
                _performSearch(value);
              }
            },
            onSubmitted: _performSearch,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isSearching) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (!_hasSearched) {
      return _buildEmptyState();
    }

    if (_categories.isEmpty && _classes.isEmpty) {
      return _buildNoResults();
    }

    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Categories Section
        if (_categories.isNotEmpty) ...[
          _buildSectionHeader('Chủ đề', Icons.style, _categories.length),
          const SizedBox(height: 12),
          ..._categories.map((category) => _buildCategoryItem(category)),
          const SizedBox(height: 24),
        ],

        // Classes Section
        if (_classes.isNotEmpty) ...[
          _buildSectionHeader('Lớp học', Icons.school, _classes.length),
          const SizedBox(height: 12),
          ..._classes.map((classModel) => _buildClassItem(classModel)),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, int count) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: AppTextStyles.heading2.copyWith(
            color: AppColors.primaryDark,
            fontSize: 18,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryItem(CategoryModel category) {
    final isOwner = category.ownerUserId == _currentUser?.userId;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _navigateToCategory(category),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.padding),
          child: Row(
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.accent],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.style,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      style: AppTextStyles.heading3.copyWith(
                        color: AppColors.primaryDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildBadge(
                          text: '${category.flashcardCount} thẻ',
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        if (isOwner)
                          _buildBadge(
                            text: '👤 Của tôi',
                            color: AppColors.secondary,
                          )
                        else
                          _buildBadge(
                            text: category.isPublic ? '🌐 Công khai' : '🔒 Riêng tư',
                            color: category.isPublic ? AppColors.success : AppColors.warning,
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Arrow
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppColors.textGray,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClassItem(ClassModel classModel) {
    final isOwner = _currentUser != null && classModel.ownerId == _currentUser!.userId;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _navigateToClass(classModel),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.padding),
          child: Row(
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isOwner ? Icons.school : Icons.group,
                  color: AppColors.secondary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      classModel.name,
                      style: AppTextStyles.heading3.copyWith(
                        color: AppColors.primaryDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // ✅ FIX: Badge hiển thị đúng trạng thái
                    Row(
                      children: [
                        // Badge 1: Của tôi / Công khai / Riêng tư
                        if (isOwner)
                          _buildBadge(
                            text: '👤 Của tôi',
                            color: AppColors.secondary,
                          )
                        else
                          _buildBadge(
                            text: classModel.isPublic ? '🌐 Công khai' : '🔒 Riêng tư',
                            color: classModel.isPublic ? AppColors.success : AppColors.warning,
                          ),

                        // Badge 2: Mã mời (nếu có)
                        if (classModel.inviteCode != null && classModel.inviteCode!.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          _buildBadge(
                            text: 'Mã: ${classModel.inviteCode}',
                            color: AppColors.accent,
                          ),
                        ],
                      ],
                    ),

                    // Description
                    if (classModel.description != null && classModel.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        classModel.description!,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textGray,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    // Owner & member count
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (classModel.ownerName != null) ...[
                          Icon(Icons.person, size: 14, color: AppColors.textGray),
                          const SizedBox(width: 4),
                          Text(
                            classModel.ownerName!,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textGray,
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        if (classModel.memberCount != null) ...[
                          Icon(Icons.people, size: 14, color: AppColors.textGray),
                          const SizedBox(width: 4),
                          Text(
                            '${classModel.memberCount} thành viên',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textGray,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Arrow
              Icon(
                isOwner ? Icons.settings : Icons.arrow_forward_ios,
                size: 16,
                color: AppColors.textGray,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ✅ Helper: Build Badge
  Widget _buildBadge({required String text, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: AppTextStyles.caption.copyWith(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.padding * 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 80,
              color: AppColors.textGray.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Tìm kiếm chủ đề hoặc lớp học',
              style: AppTextStyles.heading2.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Nhập tên chủ đề, tên lớp, hoặc mã lớp để tìm kiếm',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textGray,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.padding * 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 80,
              color: AppColors.textGray.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Không tìm thấy kết quả',
              style: AppTextStyles.heading2.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Thử tìm kiếm với từ khóa khác',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textGray,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.padding * 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: AppColors.error.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Đã có lỗi xảy ra',
              style: AppTextStyles.heading2.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Vui lòng thử lại',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textGray,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _performSearch(_searchController.text),
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}