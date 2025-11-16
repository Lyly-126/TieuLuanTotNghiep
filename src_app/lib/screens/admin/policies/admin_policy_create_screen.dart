// File: lib/screens/admin/policy/admin_policy_create_screen.dart
import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';
import '../../../config/app_constants.dart';
import '../../../config/app_text_styles.dart';
import '../../../services/policy_service.dart';

class AdminPolicyCreateScreen extends StatefulWidget {
  const AdminPolicyCreateScreen({super.key});

  @override
  State<AdminPolicyCreateScreen> createState() => _AdminPolicyCreateScreenState();
}

class _AdminPolicyCreateScreenState extends State<AdminPolicyCreateScreen> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();

  String _status = 'ACTIVE';
  bool _canSave = false;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl.addListener(_recompute);
    _bodyCtrl.addListener(_recompute);
  }

  void _recompute() {
    final ok = _titleCtrl.text.trim().isNotEmpty && _bodyCtrl.text.trim().isNotEmpty;
    if (ok != _canSave) setState(() => _canSave = ok);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<bool> _confirmLeave() async {
    if (_titleCtrl.text.isEmpty && _bodyCtrl.text.isEmpty) return true;

    final leave = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Bỏ bản nháp?', style: AppTextStyles.heading3),
        content: Text(
          'Bạn đang nhập dở. Rời màn hình sẽ mất nội dung.',
          style: AppTextStyles.label.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Tiếp tục sửa',
              style: AppTextStyles.button.copyWith(color: AppColors.primary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Bỏ bản nháp',
              style: AppTextStyles.button.copyWith(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
    return leave ?? false;
  }

  Future<void> _create() async {
    // Validation
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tiêu đề không được để trống'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_bodyCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nội dung không được để trống'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
      await PolicyService.createPolicy(
        title: _titleCtrl.text.trim(),
        body: _bodyCtrl.text.trim(),
        status: _status,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã tạo điều khoản mới'),
            backgroundColor: Colors.green,
          ),
        );

        // Quay về danh sách và báo đã tạo thành công
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isCreating = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  InputDecoration _decor(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: AppTextStyles.hint.copyWith(color: AppColors.textSecondary),
    filled: true,
    fillColor: AppColors.inputBackground,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppConstants.borderRadius * 1.2),
      borderSide: const BorderSide(color: Color(0xFFE6E8EC)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppConstants.borderRadius * 1.2),
      borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppConstants.borderRadius * 1.2),
      borderSide: const BorderSide(color: Color(0xFFE6E8EC)),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _confirmLeave,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.primary,
              size: 22,
            ),
            onPressed: () async {
              if (await _confirmLeave()) Navigator.pop(context);
            },
          ),
          centerTitle: true,
          title: Text(
            'Thêm điều khoản mới',
            style: AppTextStyles.heading2.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),

        // Nút tạo
        bottomNavigationBar: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_canSave && !_isCreating) ? _create : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: const Color(0xFFB9D8C5),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(42),
                  ),
                  elevation: 0,
                ),
                child: _isCreating
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : Text(
                  'Tạo điều khoản',
                  style: AppTextStyles.button.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),

        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: AppConstants.screenPadding.copyWith(top: 16, bottom: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thông tin hiển thị
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppConstants.borderRadius * 1.2),
                  border: Border.all(color: const Color(0xFFE6E8EC)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('Trạng thái', style: AppTextStyles.label),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.inputBackground,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE6E8EC)),
                      ),
                      child: DropdownButton<String>(
                        value: _status,
                        underline: const SizedBox(),
                        items: const [
                          DropdownMenuItem(value: 'ACTIVE', child: Text('Công khai')),
                          DropdownMenuItem(value: 'INACTIVE', child: Text('Ẩn')),
                          DropdownMenuItem(value: 'DRAFT', child: Text('Nháp')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _status = value);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Tiêu đề
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppConstants.borderRadius * 1.2),
                  border: Border.all(color: const Color(0xFFE6E8EC)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tiêu đề',
                      style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _titleCtrl,
                      textInputAction: TextInputAction.next,
                      decoration: _decor('Nhập tiêu đề (ví dụ: Điều khoản sử dụng)'),
                      style: AppTextStyles.label,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Nội dung
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppConstants.borderRadius * 1.2),
                  border: Border.all(color: const Color(0xFFE6E8EC)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nội dung',
                      style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _bodyCtrl,
                      keyboardType: TextInputType.multiline,
                      maxLines: null,
                      minLines: 11,
                      decoration: _decor('Nhập nội dung điều khoản…'),
                      style: AppTextStyles.label.copyWith(height: 1.4),
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '${_bodyCtrl.text.length} ký tự',
                        style: AppTextStyles.hint.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}