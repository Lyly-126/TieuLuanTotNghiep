import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';
import '../../config/app_constants.dart';
import '../../services/ai_flashcard_service.dart';
import '../../models/flashcard_model.dart';

class FlashcardCreationScreen extends StatefulWidget {
  final int? categoryId;

  const FlashcardCreationScreen({
    super.key,
    this.categoryId,
  });

  @override
  State<FlashcardCreationScreen> createState() =>
      _FlashcardCreationScreenState();
}

class _FlashcardCreationScreenState extends State<FlashcardCreationScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _termController = TextEditingController();
  final FocusNode _termFocusNode = FocusNode();

  bool _isGenerating = false;
  bool _generateImage = true;
  bool _generateAudio = true;

  GenerationResponse? _currentResponse;
  FlashcardModel? _generatedFlashcard;

  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    print('📱 [SCREEN] $runtimeType');
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _progressAnimation = Tween<double>(begin: 0.0, end: 0.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _termController.dispose();
    _termFocusNode.dispose();
    _progressController.dispose();
    super.dispose();
  }

  /// Tạo flashcard
  Future<void> _generateFlashcard() async {
    final term = _termController.text.trim();

    if (term.isEmpty) {
      _showErrorDialog('Vui lòng nhập từ vựng');
      return;
    }

    setState(() {
      _isGenerating = true;
      _currentResponse = null;
      _generatedFlashcard = null;
    });

    try {
      print('🚀 Starting flashcard generation for: $term');

      final response = await AIFlashcardService.generateFlashcard(
        term: term,
        categoryId: widget.categoryId,
        generateImage: _generateImage,
        generateAudio: _generateAudio,
      );

      setState(() {
        _currentResponse = response;
        _generatedFlashcard = response.flashcard;
        _isGenerating = false;
      });

      // Update progress animation
      _progressAnimation = Tween<double>(
        begin: _progressAnimation.value,
        end: response.steps.progress,
      ).animate(
        CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
      );
      _progressController.forward(from: 0.0);

      if (response.success) {
        _showSuccessDialog();
      } else {
        _showErrorDialog(response.message);
      }
    } catch (e) {
      setState(() {
        _isGenerating = false;
      });
      _showErrorDialog('Lỗi: $e');
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.success, size: 28),
            const SizedBox(width: 12),
            Text('Thành công!', style: AppTextStyles.heading3),
          ],
        ),
        content: Text(
          'Flashcard đã được tạo thành công!\n\nBạn có muốn xem flashcard này không?',
          style: AppTextStyles.body,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetForm();
            },
            child: const Text('Tạo thẻ khác'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context,
                  _generatedFlashcard); // Return to previous screen with flashcard
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('Xem flashcard'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: AppColors.error, size: 28),
            const SizedBox(width: 12),
            Text('Lỗi', style: AppTextStyles.heading3),
          ],
        ),
        content: Text(message, style: AppTextStyles.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _resetForm() {
    setState(() {
      _termController.clear();
      _currentResponse = null;
      _generatedFlashcard = null;
      _progressController.reset();
    });
    _termFocusNode.requestFocus();
  }

  Widget _buildProgressIndicator() {
    if (_currentResponse == null && !_isGenerating) {
      return const SizedBox.shrink();
    }

    final steps = _currentResponse?.steps;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: AppColors.primary, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _isGenerating ? 'Đang tạo flashcard...' : 'Hoàn thành!',
                  style: AppTextStyles.heading4,
                ),
              ),
              if (_isGenerating)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Progress bar
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return Column(
                children: [
                  LinearProgressIndicator(
                    value: steps?.progress ?? 0.0,
                    backgroundColor: AppColors.textGray.withOpacity(0.2),
                    valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${((steps?.progress ?? 0.0) * 100).toInt()}%',
                    style: AppTextStyles.label
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ],
              );
            },
          ),
          if (steps != null) ...[
            const SizedBox(height: 16),
            _buildStepItem(
                1, 'AI tạo nội dung', steps.aiContentGenerated, steps.aiError),
            _buildStepItem(
                2, 'Tạo file phát âm', steps.audioGenerated, steps.audioError),
            _buildStepItem(
                3, 'Tìm kiếm ảnh', steps.imageFound, steps.imageError),
            _buildStepItem(4, 'Lưu vào database', steps.savedToDatabase,
                steps.databaseError),
          ],
        ],
      ),
    );
  }

  Widget _buildStepItem(
      int step, String label, bool completed, String? error) {
    IconData icon;
    Color color;

    if (error != null) {
      icon = Icons.error_outline;
      color = AppColors.error;
    } else if (completed) {
      icon = Icons.check_circle;
      color = AppColors.success;
    } else {
      icon = Icons.circle_outlined;
      color = AppColors.textGray;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$step. $label',
                  style: AppTextStyles.body.copyWith(
                    color: completed
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontWeight:
                    completed ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                if (error != null)
                  Text(
                    error,
                    style:
                    AppTextStyles.caption.copyWith(color: AppColors.error),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneratedFlashcard() {
    if (_generatedFlashcard == null) {
      return const SizedBox.shrink();
    }

    final card = _generatedFlashcard!;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(color: AppColors.primary, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.star, color: AppColors.primary, size: 24),
              const SizedBox(width: 12),
              Text('Flashcard mới', style: AppTextStyles.heading4),
            ],
          ),
          const SizedBox(height: 16),

          // Image
          if (card.imageUrl != null && card.imageUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              child: Image.network(
                card.imageUrl!,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 180,
                  color: AppColors.inputBackground,
                  alignment: Alignment.center,
                  child: Icon(Icons.image_not_supported,
                      size: 48, color: AppColors.textGray),
                ),
              ),
            ),
          const SizedBox(height: 16),

          // Term
          Text(
            card.question,
            style: AppTextStyles.heading2.copyWith(color: AppColors.primary),
          ),
          if (card.phonetic != null && card.phonetic!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              card.phonetic!,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          if (card.partOfSpeech != null && card.partOfSpeech!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                card.partOfSpeech!,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),

          // Meaning
          Text(
            card.answer,
            style: AppTextStyles.body,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Tạo Flashcard bằng AI',
          style: AppTextStyles.heading3,
        ),
      ),
      body: SingleChildScrollView(
        padding: AppConstants.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Instruction
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Nhập một từ vựng và AI sẽ tự động tạo flashcard hoàn chỉnh với định nghĩa, phát âm, ví dụ và ảnh minh họa!',
                      style:
                      AppTextStyles.body.copyWith(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Input field
            Text('Từ vựng', style: AppTextStyles.heading4),
            const SizedBox(height: 8),
            TextField(
              controller: _termController,
              focusNode: _termFocusNode,
              enabled: !_isGenerating,
              decoration: InputDecoration(
                hintText: 'Ví dụ: bank, apple, computer...',
                filled: true,
                fillColor: AppColors.inputBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
              style: AppTextStyles.body,
              onSubmitted: (_) => _generateFlashcard(),
            ),
            const SizedBox(height: 16),

            // Options
            Row(
              children: [
                Expanded(
                  child: CheckboxListTile(
                    title: Text('Tìm ảnh', style: AppTextStyles.body),
                    value: _generateImage,
                    onChanged: _isGenerating
                        ? null
                        : (value) {
                      setState(() => _generateImage = value ?? true);
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                Expanded(
                  child: CheckboxListTile(
                    title: Text('Tạo audio', style: AppTextStyles.body),
                    value: _generateAudio,
                    onChanged: _isGenerating
                        ? null
                        : (value) {
                      setState(() => _generateAudio = value ?? true);
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Generate button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isGenerating ? null : _generateFlashcard,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(AppConstants.borderRadius),
                  ),
                ),
                child: _isGenerating
                    ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                    AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.auto_awesome, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      'Tạo Flashcard bằng AI',
                      style: AppTextStyles.button.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Progress indicator
            _buildProgressIndicator(),

            // Generated flashcard preview
            _buildGeneratedFlashcard(),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}