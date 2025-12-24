// File: lib/screens/class/join_class_via_link_screen.dart

import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';
import '../../services/class_service.dart';
import '../../models/class_model.dart';
import 'class_detail_public_screen.dart';

class JoinClassViaLinkScreen extends StatefulWidget {
  final String inviteCode;

  const JoinClassViaLinkScreen({
    super.key,
    required this.inviteCode,
  });

  @override
  State<JoinClassViaLinkScreen> createState() => _JoinClassViaLinkScreenState();
}

class _JoinClassViaLinkScreenState extends State<JoinClassViaLinkScreen> {
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  ClassModel? _classInfo;

  @override
  void initState() {
    super.initState();
    print('🎓 JoinClassViaLinkScreen: Invite code = ${widget.inviteCode}');
    _loadClassInfo();
  }

  Future<void> _loadClassInfo() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      print('📡 Loading class info...');
      final response = await ClassService.getClassByInviteCode(widget.inviteCode);

      print('✅ Class info loaded: ${response.name}');
      setState(() {
        _classInfo = response;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading class info: $e');
      setState(() {
        _hasError = true;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _joinClass() async {
    if (_classInfo == null) return;

    setState(() => _isLoading = true);

    try {
      print('📝 Joining class...');
      await ClassService.joinClass(_classInfo!.id);
      if (!mounted) return;

      print('✅ Joined successfully');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã tham gia lớp "${_classInfo!.name}"'),
          backgroundColor: AppColors.success,
        ),
      );

      // Navigate to class detail
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => ClassDetailPublicScreen(
            classModel: _classInfo!,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      print('❌ Join failed: $e');
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Tham gia lớp'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_hasError) {
      return _buildErrorView();
    }

    if (_classInfo == null) {
      return _buildErrorView();
    }

    return _buildClassPreview();
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: AppColors.error,
            ),
            const SizedBox(height: 24),
            Text(
              'Không tìm thấy lớp học',
              style: AppTextStyles.heading2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Mã lớp không hợp lệ hoặc đã hết hạn',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textGray,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _loadClassInfo,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Quay lại'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassPreview() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            Icons.school,
            size: 80,
            color: AppColors.primary,
          ),
          const SizedBox(height: 24),

          Text(
            'Bạn được mời tham gia',
            style: AppTextStyles.body.copyWith(
              color: AppColors.textGray,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          Text(
            _classInfo!.name,
            style: AppTextStyles.heading1,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          _buildInfoCard(),
          const SizedBox(height: 32),

          ElevatedButton(
            onPressed: _isLoading ? null : _joinClass,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
                : const Text(
              'Tham gia ngay',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 12),

          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_classInfo!.description != null && _classInfo!.description!.isNotEmpty) ...[
            _buildInfoRow(
              icon: Icons.description,
              label: 'Mô tả',
              value: _classInfo!.description!,
            ),
            const Divider(height: 24),
          ],

          _buildInfoRow(
            icon: Icons.person,
            label: 'Giáo viên',
            value: _classInfo!.ownerName ?? 'Không rõ',
          ),
          const Divider(height: 24),

          _buildInfoRow(
            icon: Icons.people,
            label: 'Thành viên',
            value: '${_classInfo!.memberCount ?? 0} người',
          ),
          const Divider(height: 24),

          _buildInfoRow(
            icon: _classInfo!.isPublic ? Icons.public : Icons.lock,
            label: 'Trạng thái',
            value: _classInfo!.isPublic ? 'Công khai' : 'Riêng tư',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: AppColors.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textGray,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: AppTextStyles.body,
              ),
            ],
          ),
        ),
      ],
    );
  }
}