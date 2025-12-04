import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';
import '../../config/app_text_styles.dart';
import '../../models/class_model.dart';
import '../../models/category_model.dart';
import '../../services/category_service.dart';
import '../../widgets/custom_button.dart';

class ClassCategoriesScreen extends StatefulWidget {
  final ClassModel classModel;

  const ClassCategoriesScreen({Key? key, required this.classModel})
      : super(key: key);

  @override
  State<ClassCategoriesScreen> createState() => _ClassCategoriesScreenState();
}

class _ClassCategoriesScreenState extends State<ClassCategoriesScreen> {
  List<CategoryModel> _categories = [];
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  /// Load categories của lớp
  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final categories =
      await CategoryService.getCategoriesByClassId(widget.classModel.id); // ✅ Fixed method name
      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Hiển thị dialog tạo category mới
  void _showCreateCategoryDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius * 1.5),
        ),
        title: Text(
          'Tạo chủ đề mới',
          style: AppTextStyles.heading2.copyWith(
            color: AppColors.primaryDark,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Tên chủ đề *',
                hintText: 'VD: Từ vựng Unit 1',
                labelStyle: AppTextStyles.label,
                hintStyle: AppTextStyles.hint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(
                labelText: 'Mô tả',
                hintText: 'VD: 20 từ vựng về gia đình',
                labelStyle: AppTextStyles.label,
                hintStyle: AppTextStyles.hint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Hủy',
              style: AppTextStyles.label.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          CustomButton(
            text: 'Tạo',
            width: 100,
            height: 40,
            onPressed: () async {
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('⚠️ Vui lòng nhập tên chủ đề'),
                    backgroundColor: AppColors.warning,
                  ),
                );
                return;
              }

              try {
                // ✅ Fixed: Sử dụng đúng parameters từ CategoryService hiện có
                await CategoryService.createCategory(
                  name: nameController.text.trim(),
                  classId: widget.classModel.id,
                  description: descriptionController.text.trim().isNotEmpty
                      ? descriptionController.text.trim()
                      : null, // Make description optional
                );

                Navigator.pop(context);
                _loadCategories();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Tạo chủ đề thành công'),
                    backgroundColor: AppColors.success,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('❌ $e'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  /// Hiển thị dialog sửa category
  void _showEditCategoryDialog(CategoryModel category) {
    final nameController = TextEditingController(text: category.name);
    final descriptionController =
    TextEditingController(text: category.description ?? ''); // ✅ Fixed: Handle null

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius * 1.5),
        ),
        title: Text(
          'Sửa chủ đề',
          style: AppTextStyles.heading2.copyWith(
            color: AppColors.primaryDark,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Tên chủ đề *',
                labelStyle: AppTextStyles.label,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(
                labelText: 'Mô tả',
                labelStyle: AppTextStyles.label,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                ),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Hủy',
              style: AppTextStyles.label.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          CustomButton(
            text: 'Lưu',
            width: 100,
            height: 40,
            onPressed: () async {
              try {
                await CategoryService.updateCategory(
                  categoryId: category.id,
                  name: nameController.text.trim(),
                  description: descriptionController.text.trim().isNotEmpty
                      ? descriptionController.text.trim()
                      : null,
                );

                Navigator.pop(context);
                _loadCategories();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Cập nhật thành công'),
                    backgroundColor: AppColors.success,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('❌ $e'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  /// Xóa category
  Future<void> _deleteCategory(CategoryModel category) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius * 1.5),
        ),
        title: Text(
          'Xác nhận xóa',
          style: AppTextStyles.heading2.copyWith(
            color: AppColors.primaryDark,
          ),
        ),
        content: Text(
          'Bạn có chắc muốn xóa chủ đề "${category.name}"?\nTất cả flashcard trong chủ đề này sẽ bị xóa.',
          style: AppTextStyles.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Hủy',
              style: AppTextStyles.label.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          CustomButton(
            text: 'Xóa',
            backgroundColor: AppColors.error,
            width: 100,
            height: 40,
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await CategoryService.deleteCategory(category.id);
        _loadCategories();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Đã xóa chủ đề'),
            backgroundColor: AppColors.success,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header với gradient
          Container(
            height: 180,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary,
                  AppColors.primary.withOpacity(0.7),
                ],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // AppBar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded,
                              color: Colors.white, size: 22),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: Text(
                            widget.classModel.name,
                            style: AppTextStyles.heading2.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Title
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.folder_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Chủ đề học tập',
                                style: AppTextStyles.heading3.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_categories.length} chủ đề',
                                style: AppTextStyles.hint.copyWith(
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
                : _errorMessage.isNotEmpty
                ? Center(
              child: Padding(
                padding: AppConstants.screenPadding,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 80,
                      color: AppColors.error.withOpacity(0.5),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Không thể tải danh sách chủ đề',
                      style: AppTextStyles.heading2.copyWith(
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _errorMessage,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.hint.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    CustomButton(
                      text: 'Thử lại',
                      onPressed: _loadCategories,
                      width: 200,
                      icon: Icons.refresh_rounded,
                    ),
                  ],
                ),
              ),
            )
                : _categories.isEmpty
                ? Center(
              child: Padding(
                padding: AppConstants.screenPadding,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppColors.inputBackground,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.folder_open_rounded,
                        size: 60,
                        color: AppColors.primary.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Chưa có chủ đề nào',
                      style: AppTextStyles.heading2.copyWith(
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Tạo chủ đề đầu tiên để bắt đầu\nthêm flashcard vào lớp học',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.hint.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),
                    CustomButton(
                      text: 'Tạo chủ đề đầu tiên',
                      onPressed: _showCreateCategoryDialog,
                      icon: Icons.add_rounded,
                    ),
                  ],
                ),
              ),
            )
                : RefreshIndicator(
              onRefresh: _loadCategories,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(
                          AppConstants.borderRadius),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ListTile(
                      onTap: () {
                        // Navigate to flashcards screen
                        Navigator.pushNamed(
                          context,
                          '/class-category-flashcards',
                          arguments: {
                            'category': category,
                            'classModel': widget.classModel,
                          },
                        );
                      },
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      leading: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.primary,
                              AppColors.primary.withOpacity(0.7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.folder_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      title: Text(
                        category.name,
                        style: AppTextStyles.label.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          // ✅ Fixed: Check if description exists
                          if (category.description != null &&
                              category.description!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              category.description!,
                              style: AppTextStyles.hint,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.style_rounded,
                                size: 14,
                                color: AppColors.primary
                                    .withOpacity(0.7),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${category.flashcardCount ?? 0} thẻ',
                                style: AppTextStyles.hint.copyWith(
                                  fontSize: 12,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      trailing: PopupMenuButton(
                        icon: const Icon(Icons.more_vert_rounded),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              AppConstants.borderRadius),
                        ),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                const Icon(Icons.edit_outlined,
                                    size: 20,
                                    color: AppColors.primary),
                                const SizedBox(width: 12),
                                Text(
                                  'Sửa',
                                  style: AppTextStyles.label,
                                ),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                const Icon(Icons.delete_outlined,
                                    size: 20,
                                    color: AppColors.error),
                                const SizedBox(width: 12),
                                Text(
                                  'Xóa',
                                  style: AppTextStyles.label
                                      .copyWith(
                                    color: AppColors.error,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        onSelected: (value) {
                          if (value == 'edit') {
                            _showEditCategoryDialog(category);
                          } else if (value == 'delete') {
                            _deleteCategory(category);
                          }
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: !_isLoading && _categories.isNotEmpty
          ? FloatingActionButton(
        onPressed: _showCreateCategoryDialog,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_rounded, size: 28),
      )
          : null,
    );
  }
}