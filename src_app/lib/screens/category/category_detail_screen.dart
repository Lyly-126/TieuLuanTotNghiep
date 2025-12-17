import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';
import '../../config/app_text_styles.dart';
import '../../models/category_model.dart';
import '../../models/flashcard_model.dart';
import '../../services/category_service.dart';
import '../../services/flash_card_service.dart';
import '../card/flashcard_screen.dart';

class CategoryDetailScreen extends StatefulWidget {
  final CategoryModel category;

  const CategoryDetailScreen({
    Key? key,
    required this.category,
  }) : super(key: key);

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  bool _isLoading = true;
  bool _isSaved = false;
  List<FlashcardModel> _flashcards = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCategoryDetails();
  }

  Future<void> _loadCategoryDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load flashcards và trạng thái saved đồng thời
      final results = await Future.wait([
        FlashcardService.getFlashcardsByCategory(widget.category.id),
        CategoryService.isCategorySaved(widget.category.id),
      ]);

      setState(() {
        _flashcards = results[0] as List<FlashcardModel>;
        _isSaved = results[1] as bool;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleSaveCategory() async {
    try {
      if (_isSaved) {
        await CategoryService.unsaveCategory(widget.category.id);
        setState(() => _isSaved = false);
        _showSnackBar('Đã bỏ lưu chủ đề', isError: false);
      } else {
        await CategoryService.saveCategory(widget.category.id);
        setState(() => _isSaved = true);
        _showSnackBar('Đã lưu chủ đề', isError: false);
      }
    } catch (e) {
      _showSnackBar('Không thể thực hiện: $e', isError: true);
    }
  }

  void _navigateToStudy() {
    if (_flashcards.isEmpty) {
      _showSnackBar('Chưa có thẻ nào để học', isError: true);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FlashcardScreen(categoryId: widget.category.id),
      ),
    );
  }

  void _showSnackBar(String message, {required bool isError}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_errorMessage != null)
            SliverFillRemaining(child: _buildErrorState())
          else ...[
              SliverToBoxAdapter(child: _buildCategoryInfo()),
              SliverToBoxAdapter(child: _buildFlashcardsHeader()),
              _buildFlashcardsList(),
              // Thêm padding bottom để tránh bị che bởi bottom bar
              const SliverToBoxAdapter(
                child: SizedBox(height: 80),
              ),
            ],
        ],
      ),
      bottomNavigationBar: _isLoading || _errorMessage != null
          ? null
          : _buildBottomBar(),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: AppColors.primary,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        if (!_isLoading)
          IconButton(
            icon: Icon(
              _isSaved ? Icons.bookmark : Icons.bookmark_border,
              color: Colors.white,
            ),
            onPressed: _toggleSaveCategory,
            tooltip: _isSaved ? 'Bỏ lưu' : 'Lưu chủ đề',
          ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          widget.category.name,
          style: AppTextStyles.heading2.copyWith(
            color: Colors.white,
            fontSize: 18,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary,
                AppColors.primaryDark,
              ],
            ),
          ),
          child: Center(
            child: Icon(
              Icons.collections_bookmark,
              size: 80,
              color: Colors.white.withOpacity(0.3),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryInfo() {
    return Container(
      margin: const EdgeInsets.all(AppConstants.padding),
      padding: const EdgeInsets.all(AppConstants.padding * 1.5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tiêu đề
          Text(
            'Thông tin chủ đề',
            style: AppTextStyles.heading2.copyWith(
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 16),

          // Mô tả
          if (widget.category.description != null &&
              widget.category.description!.isNotEmpty) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.description,
                  size: 20,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.category.description!,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textPrimary,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
          ],

          // Thống kê
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.style,
                  label: 'Số thẻ',
                  value: '${_flashcards.length}',
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.category,
                  label: 'Loại',
                  value: widget.category.typeDisplayName,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),

          // Thông tin lớp học (nếu có)
          if (widget.category.classId != null &&
              widget.category.className != null) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              icon: Icons.school,
              label: 'Lớp học',
              value: widget.category.className!,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.heading2.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: color,
            ),
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlashcardsHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.padding,
        AppConstants.padding,
        AppConstants.padding,
        AppConstants.padding / 2,
      ),
      child: Row(
        children: [
          Icon(Icons.style, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            'Danh sách thẻ (${_flashcards.length})',
            style: AppTextStyles.heading2.copyWith(
              color: AppColors.primaryDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlashcardsList() {
    if (_flashcards.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inbox,
                size: 64,
                color: AppColors.textSecondary.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Chưa có thẻ nào',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(AppConstants.padding),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
              (context, index) {
            final flashcard = _flashcards[index];
            return _buildFlashcardItem(flashcard, index + 1);
          },
          childCount: _flashcards.length,
        ),
      ),
    );
  }

  Widget _buildFlashcardItem(FlashcardModel flashcard, int number) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.padding),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Số thứ tự và term (question)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '$number',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Term/Question
                      Text(
                        flashcard.question,
                        style: AppTextStyles.heading3.copyWith(
                          color: AppColors.primaryDark,
                        ),
                      ),

                      // Phonetic
                      if (flashcard.phonetic != null &&
                          flashcard.phonetic!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          flashcard.phonetic!,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.secondary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],

                      // Part of Speech
                      if (flashcard.partOfSpeech != null &&
                          flashcard.partOfSpeech!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            flashcard.partOfSpeech!,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.secondary,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            const Divider(height: 24),

            // Nghĩa (Answer/Meaning)
            Text(
              'Nghĩa:',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              flashcard.answer,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),

            // Hình ảnh (nếu có)
            if (flashcard.imageUrl != null &&
                flashcard.imageUrl!.isNotEmpty) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                child: Image.network(
                  flashcard.imageUrl!,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 150,
                      color: AppColors.background,
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 150,
                      color: AppColors.background,
                      child: Center(
                        child: Icon(
                          Icons.broken_image,
                          color: AppColors.textSecondary,
                          size: 48,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.padding),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _flashcards.isEmpty ? null : _navigateToStudy,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Bắt đầu học'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.textSecondary.withOpacity(0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              ),
            ),
          ),
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
              size: 64,
              color: AppColors.error,
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
              _errorMessage ?? 'Không thể tải thông tin chủ đề',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadCategoryDetails,
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