// File: lib/screens/legal/terms_privacy_screen.dart
import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';
import '../../config/app_text_styles.dart';
import '../../services/policy_service.dart';

class TermsPrivacyScreen extends StatefulWidget {
  const TermsPrivacyScreen({super.key});

  @override
  State<TermsPrivacyScreen> createState() => _TermsPrivacyScreenState();
}

class _TermsPrivacyScreenState extends State<TermsPrivacyScreen> {
  List<Map<String, dynamic>> _policies = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPolicies();
  }

  Future<void> _loadPolicies() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final policies = await PolicyService.getActivePolicies();
      setState(() {
        _policies = policies;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
          'Chính sách & Điều khoản',
          style: AppTextStyles.heading2.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Không thể tải điều khoản',
              style: AppTextStyles.heading3.copyWith(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: AppTextStyles.hint,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadPolicies,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      )
          : _policies.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.description_outlined, size: 60, color: AppColors.textGray),
            const SizedBox(height: 16),
            Text(
              'Chưa có điều khoản nào',
              style: AppTextStyles.heading3.copyWith(color: AppColors.textPrimary),
            ),
          ],
        ),
      )
          : ListView.builder(
        padding: AppConstants.screenPadding.copyWith(top: 16, bottom: 24),
        physics: const BouncingScrollPhysics(),
        itemCount: _policies.length,
        itemBuilder: (context, index) {
          final policy = _policies[index];
          return _buildPolicyCard(policy);
        },
      ),
    );
  }

  Widget _buildPolicyCard(Map<String, dynamic> policy) {
    final updatedAt = DateTime.parse(policy['updatedAt']);
    final formattedDate = '${updatedAt.day.toString().padLeft(2, '0')}/'
        '${updatedAt.month.toString().padLeft(2, '0')}/'
        '${updatedAt.year}';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius * 1.2),
        border: Border.all(color: const Color(0xFFE6E8EC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppConstants.borderRadius * 1.2),
                topRight: Radius.circular(AppConstants.borderRadius * 1.2),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    policy['title'],
                    style: AppTextStyles.heading3.copyWith(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F5F7),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    formattedDate,
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              policy['body'],
              style: AppTextStyles.label.copyWith(height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}