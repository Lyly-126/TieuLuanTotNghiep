import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../models/class_model.dart';
import '../../services/class_service.dart';

class ClassManagementScreen extends StatefulWidget {
  const ClassManagementScreen({Key? key}) : super(key: key);

  @override
  State<ClassManagementScreen> createState() => _ClassManagementScreenState();
}

class _ClassManagementScreenState extends State<ClassManagementScreen> {
  List<ClassModel> _classes = [];
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  /// Load danh sách lớp học
  Future<void> _loadClasses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final classes = await ClassService.getMyClasses();
      setState(() {
        _classes = classes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Hiển thị dialog tạo lớp mới
  void _showCreateClassDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tạo lớp học mới'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Tên lớp *',
                hintText: 'VD: Lớp 12A1',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Mô tả',
                hintText: 'VD: Lớp toán nâng cao',
              ),
              maxLines: 3,
            ),
          ],
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
                  const SnackBar(content: Text('Vui lòng nhập tên lớp')),
                );
                return;
              }

              try {
                await ClassService.createClass(
                  name: nameController.text.trim(),
                  description: descriptionController.text.trim(),
                );

                Navigator.pop(context);
                _loadClasses();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✅ Tạo lớp thành công')),
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

  /// Hiển thị dialog sửa lớp
  void _showEditClassDialog(ClassModel classModel) {
    final nameController = TextEditingController(text: classModel.name);
    final descriptionController = TextEditingController(text: classModel.description);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sửa lớp học'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Tên lớp *'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Mô tả'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await ClassService.updateClass(
                  classId: classModel.id,
                  name: nameController.text.trim(),
                  description: descriptionController.text.trim(),
                );

                Navigator.pop(context);
                _loadClasses();
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

  /// Xóa lớp
  Future<void> _deleteClass(ClassModel classModel) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa lớp "${classModel.name}"?'),
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
        await ClassService.deleteClass(classModel.id);
        _loadClasses();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Đã xóa lớp')),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý lớp học'),
        backgroundColor: AppColors.primary,
      ),
      body: _isLoading
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
              onPressed: _loadClasses,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      )
          : _classes.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.school_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('Chưa có lớp học nào'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _showCreateClassDialog,
              icon: const Icon(Icons.add),
              label: const Text('Tạo lớp đầu tiên'),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _loadClasses,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _classes.length,
          itemBuilder: (context, index) {
            final classModel = _classes[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: Icon(Icons.school, color: Colors.white),
                ),
                title: Text(
                  classModel.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (classModel.description != null)
                      Text(classModel.description!),
                    const SizedBox(height: 4),
                    Text(
                      '📚 ${classModel.categoryCount ?? 0} categories',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                trailing: PopupMenuButton(
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text('✏️ Sửa'),
                    ),
                    const PopupMenuItem(
                      value: 'categories',
                      child: Text('📂 Categories'),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('🗑️ Xóa'),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showEditClassDialog(classModel);
                    } else if (value == 'categories') {
                      // Navigate to categories of this class
                      Navigator.pushNamed(
                        context,
                        '/class-categories',
                        arguments: classModel,
                      );
                    } else if (value == 'delete') {
                      _deleteClass(classModel);
                    }
                  },
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: _classes.isNotEmpty
          ? FloatingActionButton(
        onPressed: _showCreateClassDialog,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      )
          : null,
    );
  }
}