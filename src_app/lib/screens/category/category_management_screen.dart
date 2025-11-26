import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../models/category_model.dart';
import '../../services/category_service.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({Key? key}) : super(key: key);

  @override
  State<CategoryManagementScreen> createState() => _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  List<CategoryModel> _categories = [];
  bool _isLoading = false;
  String _errorMessage = '';

  // Filters
  String _selectedFilter = 'all'; // all, system, user, class

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  /// Load categories
  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final categories = await CategoryService.getMyCategories();
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

  /// Filter categories
  List<CategoryModel> get _filteredCategories {
    switch (_selectedFilter) {
      case 'system':
        return _categories.where((c) => c.isSystem).toList();
      case 'user':
        return _categories.where((c) => c.isUserCategory).toList();
      case 'class':
        return _categories.where((c) => c.isClassCategory).toList();
      default:
        return _categories;
    }
  }

  /// Hiển thị dialog tạo category cá nhân
  void _showCreateCategoryDialog() {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tạo category cá nhân'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Tên category *',
            hintText: 'VD: IT, Business, Education',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng nhập tên category')),
                );
                return;
              }

              try {
                await CategoryService.createUserCategory(
                  nameController.text.trim(),
                );

                Navigator.pop(context);
                _loadCategories();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✅ Tạo category thành công')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('❌ Lỗi: $e')),
                );
              }
            },
            child: const Text('Tạo'),
          ),
        ],
      ),
    );
  }

  /// Hiển thị dialog sửa category
  void _showEditCategoryDialog(CategoryModel category) {
    if (category.isSystem) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Không thể sửa category hệ thống')),
      );
      return;
    }

    final nameController = TextEditingController(text: category.name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sửa category'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Tên category *'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await CategoryService.updateCategory(
                  categoryId: category.id,
                  name: nameController.text.trim(),
                );

                Navigator.pop(context);
                _loadCategories();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✅ Cập nhật thành công')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('❌ Lỗi: $e')),
                );
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  /// Xóa category
  Future<void> _deleteCategory(CategoryModel category) async {
    if (category.isSystem) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Không thể xóa category hệ thống')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa category "${category.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await CategoryService.deleteCategory(category.id);
        _loadCategories();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Đã xóa category')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Lỗi: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredCategories = _filteredCategories;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Categories'),
        backgroundColor: AppColors.primary,
      ),
      body: Column(
        children: [
          // Filters
          Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Tất cả', 'all'),
                  const SizedBox(width: 8),
                  _buildFilterChip('🌐 Hệ thống', 'system'),
                  const SizedBox(width: 8),
                  _buildFilterChip('👤 Của tôi', 'user'),
                  const SizedBox(width: 8),
                  _buildFilterChip('🏫 Lớp học', 'class'),
                ],
              ),
            ),
          ),

          // List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage.isNotEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(_errorMessage),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadCategories,
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            )
                : filteredCategories.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.folder_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('Chưa có category nào'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _showCreateCategoryDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Tạo category'),
                  ),
                ],
              ),
            )
                : RefreshIndicator(
              onRefresh: _loadCategories,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredCategories.length,
                itemBuilder: (context, index) {
                  final category = filteredCategories[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: category.isSystem
                            ? Colors.blue
                            : category.isClassCategory
                            ? Colors.green
                            : Colors.orange,
                        child: Icon(
                          category.isSystem
                              ? Icons.public
                              : category.isClassCategory
                              ? Icons.school
                              : Icons.person,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(
                        category.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(category.typeDisplayName),
                          if (category.className != null)
                            Text('Lớp: ${category.className}'),
                          Text(
                            '📚 ${category.flashcardCount ?? 0} flashcards',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                      trailing: category.isSystem
                          ? null
                          : PopupMenuButton(
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Text('✏️ Sửa'),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('🗑️ Xóa'),
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
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateCategoryDialog,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    return FilterChip(
      label: Text(label),
      selected: _selectedFilter == value,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
      },
      backgroundColor: Colors.grey[200],
      selectedColor: AppColors.primary.withOpacity(0.3),
    );
  }
}