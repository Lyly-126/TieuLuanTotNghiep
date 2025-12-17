// File: lib/screens/home/search_screen.dart
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
import '../card/flashcard_screen.dart';
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

  // ✅ Thêm biến lưu thông tin user hiện tại
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

  /// ✅ Load thông tin user hiện tại
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
      // Search categories và classes đồng thời
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

  /// ✅ Navigate to Category - Phân quyền theo owner
  void _navigateToCategory(CategoryModel category) {
    // ✅ FIX: Sử dụng userId thay vì id
    if (_currentUser != null && category.ownerUserId == _currentUser!.userId) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CategoryDetailScreen(category: category),
        ),
      );
    } else {
      // Nếu không phải chủ nhân → màn hình xem public + lưu category
      _showCategoryPublicDialog(category);
    }
  }

  /// ✅ Navigate to Class - Phân quyền theo owner
  void _navigateToClass(ClassModel classModel) {
    // ✅ FIX: Sử dụng userId thay vì id
    if (_currentUser != null && classModel.ownerId == _currentUser!.userId) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ClassDetailScreen(classId: classModel.id),
        ),
      );
    } else {
      // Nếu không phải chủ nhân → màn hình public (xem + tham gia)
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ClassDetailPublicScreen(classModel: classModel),
        ),
      );
    }
  }

  /// ✅ Hiển thị dialog cho category public (chưa phải chủ nhân)
  void _showCategoryPublicDialog(CategoryModel category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          category.name,
          style: AppTextStyles.heading2,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (category.description != null && category.description!.isNotEmpty)
              Text(
                category.description!,
                style: AppTextStyles.body,
              ),
            const SizedBox(height: 16),
            if (category.flashcardCount != null)
              Row(
                children: [
                  const Icon(Icons.style, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    '${category.flashcardCount} thẻ',
                    style: AppTextStyles.body,
                  ),
                ],
              ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '🌐 Chủ đề công khai',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              await _handleSaveCategory(category);
            },
            icon: Icon(
              category.isSaved ? Icons.bookmark : Icons.bookmark_border,
            ),
            label: Text(category.isSaved ? 'Đã lưu' : 'Lưu chủ đề'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// ✅ Xử lý lưu/bỏ lưu category
  Future<void> _handleSaveCategory(CategoryModel category) async {
    try {
      if (category.isSaved) {
        await CategoryService.unsaveCategory(category.id);
        _showSuccessSnackBar('Đã bỏ lưu chủ đề');
      } else {
        await CategoryService.saveCategory(category.id);
        _showSuccessSnackBar('Đã lưu chủ đề vào thư viện');
      }

      // Refresh search results
      _performSearch(_searchController.text);
    } catch (e) {
      _showErrorSnackBar('Lỗi: $e');
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            isDense: true,
            border: InputBorder.none,
            hintText: 'Tìm chủ đề, lớp học, mã lớp...',
            hintStyle: AppTextStyles.hint.copyWith(
              color: AppColors.textGray,
              fontSize: 16,
            ),
          ),
          style: AppTextStyles.body.copyWith(fontSize: 16),
          onChanged: (value) {
            // Debounce search
            Future.delayed(const Duration(milliseconds: 500), () {
              if (_searchController.text == value) {
                _performSearch(value);
              }
            });
          },
          onSubmitted: _performSearch,
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, color: AppColors.textGray),
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _categories = [];
                  _classes = [];
                  _hasSearched = false;
                  _errorMessage = null;
                });
              },
            ),
        ],
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
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.padding * 2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.textGray.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Đã có lỗi xảy ra',
                style: AppTextStyles.heading2.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
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

    if (!_hasSearched) {
      return _buildEmptyState();
    }

    if (_categories.isEmpty && _classes.isEmpty) {
      return _buildNoResults();
    }

    return ListView(
      padding: const EdgeInsets.all(AppConstants.padding),
      children: [
        // Categories section
        if (_categories.isNotEmpty) ...[
          _buildSectionHeader('Chủ đề (${_categories.length})'),
          const SizedBox(height: 12),
          ..._categories.map((category) => _buildCategoryCard(category)),
          const SizedBox(height: 24),
        ],

        // Classes section
        if (_classes.isNotEmpty) ...[
          _buildSectionHeader('Lớp học (${_classes.length})'),
          const SizedBox(height: 12),
          ..._classes.map((classModel) => _buildClassCard(classModel)),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: AppTextStyles.heading2.copyWith(
        color: AppColors.primaryDark,
      ),
    );
  }

  Widget _buildCategoryCard(CategoryModel category) {
    // ✅ FIX: Kiểm tra xem user có phải chủ nhân không - dùng userId
    final isOwner = _currentUser != null && category.ownerUserId == _currentUser!.userId;

    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.padding),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
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
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isOwner ? Icons.folder : Icons.public,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tên chủ đề
                    Text(
                      category.name,
                      style: AppTextStyles.heading3.copyWith(
                        color: AppColors.primaryDark,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Badge: Chủ nhân hoặc Public
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isOwner
                            ? AppColors.secondary.withOpacity(0.1)
                            : AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isOwner ? '👤 Của tôi' : '🌐 Công khai',
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 11,
                          color: isOwner ? AppColors.secondary : AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    // Description
                    if (category.description != null &&
                        category.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        category.description!,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textGray,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    // Flashcard count
                    if (category.flashcardCount != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.style,
                            size: 14,
                            color: AppColors.textGray,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${category.flashcardCount} thẻ',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textGray,
                            ),
                          ),
                          if (category.isSaved) ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.bookmark,
                              size: 14,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Đã lưu',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Arrow icon
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

  Widget _buildClassCard(ClassModel classModel) {
    // ✅ FIX: Kiểm tra xem user có phải chủ nhân không - dùng userId
    final isOwner = _currentUser != null && classModel.ownerId == _currentUser!.userId;

    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.padding),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
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
                    // Tên lớp
                    Text(
                      classModel.name,
                      style: AppTextStyles.heading3.copyWith(
                        color: AppColors.primaryDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Badge: Chủ nhân hoặc Public
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isOwner
                                ? AppColors.secondary.withOpacity(0.1)
                                : AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isOwner ? '👤 Của tôi' : '🌐 Công khai',
                            style: AppTextStyles.caption.copyWith(
                              fontSize: 11,
                              color: isOwner ? AppColors.secondary : AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        // Mã lớp
                        if (classModel.inviteCode != null &&
                            classModel.inviteCode!.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Mã: ${classModel.inviteCode}',
                              style: AppTextStyles.caption.copyWith(
                                fontSize: 11,
                                color: AppColors.accent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),

                    // Description
                    if (classModel.description != null &&
                        classModel.description!.isNotEmpty) ...[
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

                    // Owner & Members
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      children: [
                        if (classModel.ownerName != null) ...[
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.person,
                                size: 14,
                                color: AppColors.textGray,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                classModel.ownerName!,
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textGray,
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (classModel.memberCount != null) ...[
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.people,
                                size: 14,
                                color: AppColors.textGray,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${classModel.memberCount} thành viên',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textGray,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Arrow icon
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
}