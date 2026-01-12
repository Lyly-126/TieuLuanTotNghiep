import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../services/flashcard_creation_service.dart';
import '../../models/category_model.dart';
import '../category/category_detail_screen.dart';
import 'text_extraction_screen.dart';
import '../../routes/app_routes.dart';

/// Màn hình hiển thị kết quả tạo flashcard hàng loạt
///
/// ✅ FIX v2: Sửa navigation để có thể quay về Home đúng cách
/// - "Xem chủ đề": Xóa tất cả routes, đặt Home làm root, push CategoryDetailScreen
/// - "Tạo thêm": Thay thế màn hình hiện tại bằng TextExtractionScreen
class BatchCreationResultScreen extends StatelessWidget {
  final BatchCreateResult result;
  final int categoryId;
  final String categoryName;

  const BatchCreationResultScreen({
    super.key,
    required this.result,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  Widget build(BuildContext context) {
    final successRate = result.totalRequested > 0
        ? (result.successCount / result.totalRequested * 100).round()
        : 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header with result
            _buildResultHeader(successRate),

            // Stats row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildStatsRow(),
            ),

            // Details list
            Expanded(
              child: _buildDetailsList(),
            ),

            // Bottom buttons
            _buildBottomButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildResultHeader(int successRate) {
    final isSuccess = result.success || successRate >= 80;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isSuccess
              ? [AppColors.success, AppColors.success.withOpacity(0.8)]
              : [AppColors.warning, AppColors.warning.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isSuccess ? Icons.check_circle : Icons.warning_rounded,
              size: 48,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            isSuccess ? 'Tạo thẻ thành công!' : 'Hoàn thành với một số lỗi',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          // Subtitle
          Text(
            'Đã tạo ${result.successCount}/${result.totalRequested} thẻ vào "$categoryName"',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 20),

          // Success rate card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: IntrinsicHeight(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Progress circle
                  SizedBox(
                    width: 64,
                    height: 64,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 64,
                          height: 64,
                          child: CircularProgressIndicator(
                            value: successRate / 100,
                            strokeWidth: 6,
                            backgroundColor: AppColors.border,
                            valueColor: AlwaysStoppedAnimation(
                              isSuccess ? AppColors.success : AppColors.warning,
                            ),
                          ),
                        ),
                        Text(
                          '$successRate%',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: isSuccess ? AppColors.success : AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 24),

                  // Divider
                  Container(
                    width: 1,
                    color: AppColors.border,
                  ),

                  const SizedBox(width: 24),

                  // Stats text
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMiniStat(
                        icon: Icons.check_circle,
                        color: AppColors.success,
                        label: 'Thành công',
                        value: result.successCount.toString(),
                      ),
                      const SizedBox(height: 10),
                      _buildMiniStat(
                        icon: Icons.cancel,
                        color: AppColors.error,
                        label: 'Thất bại',
                        value: result.failCount.toString(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _buildStatItem(
                icon: Icons.folder_rounded,
                label: 'Chủ đề',
                value: categoryName,
                color: AppColors.primary,
              ),
            ),
            Container(
              width: 1,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              color: AppColors.border,
            ),
            Expanded(
              child: _buildStatItem(
                icon: Icons.style_rounded,
                label: 'Tổng thẻ',
                value: result.totalRequested.toString(),
                color: AppColors.success,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: AppColors.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsList() {
    if (result.results.isEmpty) {
      return const Center(
        child: Text('Không có chi tiết'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: result.results.length,
      itemBuilder: (context, index) {
        final item = result.results[index];
        return _buildResultItem(item, index);
      },
    );
  }

  Widget _buildResultItem(FlashcardCreateResult item, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: item.success ? AppColors.success.withOpacity(0.3) : AppColors.error.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          // Status icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: item.success
                  ? AppColors.success.withOpacity(0.1)
                  : AppColors.error.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              item.success ? Icons.check : Icons.close,
              color: item.success ? AppColors.success : AppColors.error,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),

          // Word info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.flashcard?.word ?? 'Từ #${index + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (item.message != null && !item.success)
                  Text(
                    item.message!,
                    style: TextStyle(
                      color: AppColors.error,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),

          // Status text
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: item.success
                  ? AppColors.success.withOpacity(0.1)
                  : AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              item.success ? 'Thành công' : 'Lỗi',
              style: TextStyle(
                color: item.success ? AppColors.success : AppColors.error,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          // ✅ Nút "Tạo thêm" - Mở lại TextExtractionScreen với cùng category
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                // Push màn hình TextExtractionScreen mới với cùng category
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TextExtractionScreen(
                      initialCategoryId: categoryId,
                      initialCategoryName: categoryName,
                    ),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: BorderSide(color: AppColors.primary),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Tạo thêm',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),

          // ✅ FIX: Nút "Xem chủ đề" - Xóa tất cả routes, đặt Home làm root, push CategoryDetail
          Expanded(
            child: ElevatedButton(
              onPressed: () => _navigateToCategoryDetail(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.folder_open, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Xem chủ đề',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ✅ FIX v2: Navigation đúng cách để có thể quay về Home
  void _navigateToCategoryDetail(BuildContext context) {
    // Tạo CategoryModel từ thông tin có sẵn
    final category = CategoryModel(
      id: categoryId,
      name: categoryName,
      isUserCategory: true,
    );

    // ✅ FIX: Xóa tất cả routes và đặt Home làm root
    // Sau đó push CategoryDetailScreen lên trên Home
    // Điều này đảm bảo stack: Home → CategoryDetail
    // Khi user bấm back từ CategoryDetail, sẽ về Home đúng cách

    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.home,  // '/home'
          (route) => false,  // Xóa tất cả routes
    ).then((_) {
      // Push CategoryDetail sau khi đã về Home
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CategoryDetailScreen(
            category: category,
            isOwner: true,
          ),
        ),
      );
    });
  }
}