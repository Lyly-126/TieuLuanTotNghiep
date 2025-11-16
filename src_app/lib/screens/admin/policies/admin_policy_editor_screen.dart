// File: lib/screens/admin/policy/admin_policy_editor_screen.dart
import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';
import '../../../config/app_constants.dart';
import '../../../config/app_text_styles.dart';
import '../../../services/policy_service.dart';

class AdminPolicyEditorScreen extends StatefulWidget {
  final int policyId;

  const AdminPolicyEditorScreen({super.key, required this.policyId});

  @override
  State<AdminPolicyEditorScreen> createState() => _AdminPolicyEditorScreenState();
}

class _AdminPolicyEditorScreenState extends State<AdminPolicyEditorScreen> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _bodyCtrl;

  // state
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  late String _status;
  late bool _dirty;
  late DateTime _lastUpdated;

  // originals để so sánh
  late String _originalTitle;
  late String _originalBody;
  late String _originalStatus;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController();
    _bodyCtrl = TextEditingController();
    _dirty = false;

    _titleCtrl.addListener(_watchDirty);
    _bodyCtrl.addListener(_watchDirty);

    _loadPolicy();
  }

  Future<void> _loadPolicy() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final policy = await PolicyService.getPolicyById(widget.policyId);

      _originalTitle = policy['title'];
      _originalBody = policy['body'];
      _originalStatus = policy['status'];

      _titleCtrl.text = _originalTitle;
      _bodyCtrl.text = _originalBody;
      _status = _originalStatus;
      _lastUpdated = DateTime.parse(policy['updatedAt']);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _watchDirty() {
    final changed = _titleCtrl.text != _originalTitle ||
        _bodyCtrl.text != _originalBody ||
        _status != _originalStatus;

    if (changed != _dirty) setState(() => _dirty = changed);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<bool> _onExit() async {
    if (!_dirty) return true;

    final leave = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Bỏ thay đổi?', style: AppTextStyles.heading3),
        content: Text(
          'Bạn có thay đổi chưa lưu. Bạn có chắc muốn rời màn hình?',
          style: AppTextStyles.label.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Ở lại', style: AppTextStyles.button.copyWith(color: AppColors.primary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Rời đi', style: AppTextStyles.button.copyWith(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    return leave ?? false;
  }

  Future<void> _save() async {
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

    setState(() => _isSaving = true);

    try {
      await PolicyService.updatePolicy(
        id: widget.policyId,
        title: _titleCtrl.text.trim(),
        body: _bodyCtrl.text.trim(),
        status: _status,
      );

      setState(() {
        _originalTitle = _titleCtrl.text.trim();
        _originalBody = _bodyCtrl.text.trim();
        _originalStatus = _status;
        _lastUpdated = DateTime.now();
        _dirty = false;
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã lưu thay đổi chính sách/điều khoản'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);

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

  InputDecoration _inputDecoration(String hint) => InputDecoration(
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
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primary, size: 22),
            onPressed: () => Navigator.pop(context),
          ),
          centerTitle: true,
          title: Text(
            'Điều khoản & Chính sách',
            style: AppTextStyles.heading2.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primary, size: 22),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 60, color: Colors.red),
              const SizedBox(height: 16),
              Text('Lỗi tải dữ liệu', style: AppTextStyles.heading3),
              const SizedBox(height: 8),
              Text(_error!, style: AppTextStyles.hint, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadPolicy,
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    return WillPopScope(
      onWillPop: _onExit,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primary, size: 22),
            onPressed: () async {
              if (await _onExit()) {
                Navigator.pop(context, _dirty == false); // true nếu đã save
              }
            },
          ),
          centerTitle: true,
          title: Text(
            'Điều khoản & Chính sách',
            style: AppTextStyles.heading2.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),

        // Nút Lưu
        bottomNavigationBar: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_dirty && !_isSaving) ? _save : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: const Color(0xFFB9D8C5),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(42)),
                  elevation: 0,
                ),
                child: _isSaving
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : Text(
                  'Lưu thay đổi',
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
              // --- Thẻ thông tin ---
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
                    // Chip ngày cập nhật
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F5F7),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Cập nhật lần cuối: '
                            '${_lastUpdated.day.toString().padLeft(2, '0')}/'
                            '${_lastUpdated.month.toString().padLeft(2, '0')}/'
                            '${_lastUpdated.year}',
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Dropdown status
                    Row(
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
                                _watchDirty();
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // --- Khối TIÊU ĐỀ ---
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
                      decoration: _inputDecoration('Nhập tiêu đề (ví dụ: Điều khoản sử dụng)'),
                      style: AppTextStyles.label,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // --- Khối NỘI DUNG ---
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
                      decoration: _inputDecoration(
                        'Nhập nội dung ở đây...\n\nVí dụ: Điều khoản sử dụng mô tả quyền và nghĩa vụ...',
                      ),
                      style: AppTextStyles.label.copyWith(height: 1.4),
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '${_bodyCtrl.text.length} ký tự',
                        style: AppTextStyles.hint.copyWith(color: AppColors.textSecondary),
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