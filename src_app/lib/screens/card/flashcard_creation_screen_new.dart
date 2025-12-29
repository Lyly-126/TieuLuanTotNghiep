import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';
import '../../config/app_constants.dart';
import '../../services/flashcard_creation_service.dart';
import '../../services/category_suggestion_service.dart';
import '../../services/image_suggestion_service.dart';

/// Màn hình tạo Flashcard mới với flow:
/// 1. Nhập từ vựng
/// 2. Xem gợi ý từ từ điển
/// 3. Chọn ảnh từ 5 gợi ý
/// 4. Chọn category từ AI gợi ý
/// 5. Lưu flashcard
class FlashcardCreationScreenNew extends StatefulWidget {
  final int? initialCategoryId;

  const FlashcardCreationScreenNew({
    super.key,
    this.initialCategoryId,
  });

  @override
  State<FlashcardCreationScreenNew> createState() => _FlashcardCreationScreenNewState();
}

class _FlashcardCreationScreenNewState extends State<FlashcardCreationScreenNew> {
  // Controllers
  final TextEditingController _termController = TextEditingController();
  final TextEditingController _meaningController = TextEditingController();
  final TextEditingController _definitionController = TextEditingController();
  final TextEditingController _phoneticController = TextEditingController();
  final TextEditingController _exampleController = TextEditingController();

  // State
  int _currentStep = 0; // 0: Input, 1: Preview, 2: Select Image, 3: Select Category
  bool _isLoading = false;
  String? _errorMessage;

  // Preview data
  FlashcardPreviewResult? _previewResult;

  // Selected data
  String? _selectedImageUrl;
  int? _selectedCategoryId;
  String? _selectedCategoryName;
  String? _selectedPartOfSpeech;

  // Category suggestions
  CategorySuggestionResult? _categorySuggestions;
  bool _isLoadingCategories = false;

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.initialCategoryId;
  }

  @override
  void dispose() {
    _termController.dispose();
    _meaningController.dispose();
    _definitionController.dispose();
    _phoneticController.dispose();
    _exampleController.dispose();
    super.dispose();
  }

  /// Step 1: Preview flashcard
  Future<void> _previewFlashcard() async {
    final term = _termController.text.trim();
    if (term.isEmpty) {
      _showError('Vui lòng nhập từ vựng');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await FlashcardCreationService.preview(term);

      setState(() {
        _previewResult = result;
        _isLoading = false;
        _currentStep = 1;

        // Auto-fill data từ dictionary
        if (result.isFoundInDictionary) {
          _meaningController.text = result.vietnameseMeaning ?? '';
          _definitionController.text = result.englishDefinition ?? '';
          _phoneticController.text = result.phonetic ?? '';
          _selectedPartOfSpeech = result.partOfSpeech;
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Lỗi: $e';
      });
    }
  }

  /// Step 2: Go to image selection
  void _goToImageSelection() {
    if (_previewResult == null) return;
    setState(() {
      _currentStep = 2;
    });
  }

  /// Step 3: Load category suggestions
  Future<void> _loadCategorySuggestions() async {
    setState(() {
      _isLoadingCategories = true;
      _currentStep = 3;
    });

    try {
      final result = await FlashcardCreationService.suggestCategory(
        term: _termController.text.trim(),
        meaning: _meaningController.text.trim(),
        partOfSpeech: _selectedPartOfSpeech,
      );

      setState(() {
        _categorySuggestions = result;
        _isLoadingCategories = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingCategories = false;
        _errorMessage = 'Lỗi khi gợi ý category: $e';
      });
    }
  }

  /// Step 4: Create flashcard
  Future<void> _createFlashcard() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final request = FlashcardCreateRequest(
        term: _termController.text.trim(),
        partOfSpeech: _selectedPartOfSpeech,
        phonetic: _phoneticController.text.trim(),
        meaning: _meaningController.text.trim(),
        definition: _definitionController.text.trim(),
        example: _exampleController.text.trim(),
        selectedImageUrl: _selectedImageUrl,
        categoryId: _selectedCategoryId,
        generateAudio: true,
      );

      final result = await FlashcardCreationService.create(request);

      setState(() {
        _isLoading = false;
      });

      if (result.success) {
        _showSuccessDialog(result.flashcardId);
      } else {
        _showError(result.message ?? 'Không thể tạo flashcard');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError('Lỗi: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  void _showSuccessDialog(int? flashcardId) {
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
          'Flashcard đã được tạo thành công!',
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
              Navigator.pop(context);
              Navigator.pop(context, flashcardId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('Hoàn tất'),
          ),
        ],
      ),
    );
  }

  void _resetForm() {
    setState(() {
      _currentStep = 0;
      _termController.clear();
      _meaningController.clear();
      _definitionController.clear();
      _phoneticController.clear();
      _exampleController.clear();
      _previewResult = null;
      _selectedImageUrl = null;
      _selectedCategoryId = widget.initialCategoryId;
      _selectedCategoryName = null;
      _selectedPartOfSpeech = null;
      _categorySuggestions = null;
      _errorMessage = null;
    });
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
          'Tạo Flashcard',
          style: AppTextStyles.heading3,
        ),
        actions: [
          if (_currentStep > 0)
            TextButton(
              onPressed: () {
                setState(() {
                  _currentStep = _currentStep - 1;
                });
              },
              child: const Text('Quay lại'),
            ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBody() {
    switch (_currentStep) {
      case 0:
        return _buildInputStep();
      case 1:
        return _buildPreviewStep();
      case 2:
        return _buildImageSelectionStep();
      case 3:
        return _buildCategorySelectionStep();
      default:
        return _buildInputStep();
    }
  }

  /// Step 0: Input term
  Widget _buildInputStep() {
    return SingleChildScrollView(
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
                    'Nhập từ vựng để bắt đầu. Hệ thống sẽ tự động tra cứu từ điển và gợi ý hình ảnh.',
                    style: AppTextStyles.body.copyWith(color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Term input
          Text('Từ vựng *', style: AppTextStyles.heading4),
          const SizedBox(height: 8),
          TextField(
            controller: _termController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Ví dụ: apple, beautiful, run...',
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
              prefixIcon: Icon(Icons.search, color: AppColors.textGray),
            ),
            style: AppTextStyles.body,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _previewFlashcard(),
          ),

          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: AppColors.error, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: AppTextStyles.caption.copyWith(color: AppColors.error),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Step 1: Preview dictionary result
  Widget _buildPreviewStep() {
    if (_previewResult == null) return const SizedBox.shrink();

    final dict = _previewResult!.dictionaryResult;
    final foundInDict = dict?.found ?? false;

    return SingleChildScrollView(
      padding: AppConstants.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: foundInDict
                  ? AppColors.success.withOpacity(0.1)
                  : AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  foundInDict ? Icons.check_circle : Icons.info_outline,
                  size: 16,
                  color: foundInDict ? AppColors.success : AppColors.warning,
                ),
                const SizedBox(width: 6),
                Text(
                  foundInDict ? 'Tìm thấy trong từ điển' : 'Không có trong từ điển',
                  style: AppTextStyles.caption.copyWith(
                    color: foundInDict ? AppColors.success : AppColors.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Term display
          Text(
            _termController.text,
            style: AppTextStyles.heading1.copyWith(color: AppColors.primary),
          ),

          // Phonetic
          const SizedBox(height: 16),
          Text('Phiên âm', style: AppTextStyles.label),
          const SizedBox(height: 8),
          TextField(
            controller: _phoneticController,
            decoration: _buildInputDecoration('VD: /ˈæpəl/'),
          ),

          // Part of speech
          const SizedBox(height: 16),
          Text('Loại từ', style: AppTextStyles.label),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ['noun', 'verb', 'adjective', 'adverb', 'phrase', 'other']
                .map((pos) => ChoiceChip(
              label: Text(pos),
              selected: _selectedPartOfSpeech == pos,
              onSelected: (selected) {
                setState(() {
                  _selectedPartOfSpeech = selected ? pos : null;
                });
              },
              selectedColor: AppColors.primary.withOpacity(0.2),
            ))
                .toList(),
          ),

          // Meaning (Vietnamese)
          const SizedBox(height: 16),
          Text('Nghĩa tiếng Việt *', style: AppTextStyles.label),
          const SizedBox(height: 8),
          TextField(
            controller: _meaningController,
            decoration: _buildInputDecoration('VD: quả táo'),
            maxLines: 2,
          ),

          // Definition (English)
          const SizedBox(height: 16),
          Text('Định nghĩa tiếng Anh', style: AppTextStyles.label),
          const SizedBox(height: 8),
          TextField(
            controller: _definitionController,
            decoration: _buildInputDecoration('VD: A round fruit with red or green skin'),
            maxLines: 3,
          ),

          // Example
          const SizedBox(height: 16),
          Text('Ví dụ', style: AppTextStyles.label),
          const SizedBox(height: 8),
          TextField(
            controller: _exampleController,
            decoration: _buildInputDecoration('VD: I eat an apple every day'),
            maxLines: 2,
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  /// Step 2: Image selection
  Widget _buildImageSelectionStep() {
    final images = _previewResult?.imageSuggestions ?? [];

    return SingleChildScrollView(
      padding: AppConstants.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Chọn hình ảnh', style: AppTextStyles.heading3),
          const SizedBox(height: 8),
          Text(
            'Chọn 1 hình ảnh phù hợp cho flashcard',
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),

          if (images.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.inputBackground,
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              ),
              child: Column(
                children: [
                  Icon(Icons.image_not_supported,
                      size: 48, color: AppColors.textGray),
                  const SizedBox(height: 12),
                  Text('Không tìm thấy hình ảnh phù hợp',
                      style: AppTextStyles.body),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedImageUrl = null;
                      });
                      _loadCategorySuggestions();
                    },
                    child: const Text('Bỏ qua và tiếp tục'),
                  ),
                ],
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.2,
              ),
              itemCount: images.length,
              itemBuilder: (context, index) {
                final image = images[index];
                final isSelected = _selectedImageUrl == image.url;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedImageUrl = image.url;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : Colors.transparent,
                        width: 3,
                      ),
                    ),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            image.url,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: AppColors.inputBackground,
                              child: Icon(Icons.broken_image,
                                  color: AppColors.textGray),
                            ),
                          ),
                        ),
                        if (isSelected)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check,
                                  color: Colors.white, size: 16),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),

          const SizedBox(height: 16),

          // Skip button
          Center(
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _selectedImageUrl = null;
                });
                _loadCategorySuggestions();
              },
              icon: const Icon(Icons.skip_next),
              label: const Text('Bỏ qua, không dùng ảnh'),
            ),
          ),
        ],
      ),
    );
  }

  /// Step 3: Category selection
  Widget _buildCategorySelectionStep() {
    return SingleChildScrollView(
      padding: AppConstants.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Chọn chủ đề', style: AppTextStyles.heading3),
          const SizedBox(height: 8),
          Text(
            'AI đã phân tích và gợi ý các chủ đề phù hợp',
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),

          if (_isLoadingCategories)
            Center(
              child: Column(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text('Đang phân tích...', style: AppTextStyles.body),
                ],
              ),
            )
          else if (_categorySuggestions != null &&
              _categorySuggestions!.suggestions.isNotEmpty)
            Column(
              children: [
                // AI Suggestions
                Text('🤖 Gợi ý từ AI', style: AppTextStyles.heading4),
                const SizedBox(height: 12),
                ..._categorySuggestions!.suggestions.map((suggestion) =>
                    _buildCategorySuggestionCard(suggestion)),

                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),

                // Skip option
                Text('Hoặc', style: AppTextStyles.label),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedCategoryId = null;
                      _selectedCategoryName = null;
                    });
                    _createFlashcard();
                  },
                  icon: const Icon(Icons.skip_next),
                  label: const Text('Bỏ qua, không chọn chủ đề'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ],
            )
          else
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.inputBackground,
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              ),
              child: Column(
                children: [
                  Icon(Icons.category_outlined,
                      size: 48, color: AppColors.textGray),
                  const SizedBox(height: 12),
                  Text('Chưa có gợi ý category',
                      style: AppTextStyles.body),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _selectedCategoryId = null;
                      });
                      _createFlashcard();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    child: const Text('Tạo flashcard không có chủ đề'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCategorySuggestionCard(CategorySuggestion suggestion) {
    final isSelected = _selectedCategoryId == suggestion.categoryId;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategoryId = suggestion.categoryId;
          _selectedCategoryName = suggestion.categoryName;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.1)
              : AppColors.inputBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Radio-like indicator
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.textGray,
                  width: 2,
                ),
                color: isSelected ? AppColors.primary : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
            const SizedBox(width: 16),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    suggestion.categoryName,
                    style: AppTextStyles.heading4,
                  ),
                  if (suggestion.description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      suggestion.description!,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Confidence badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getConfidenceColor(suggestion.confidenceScore)
                              .withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${suggestion.confidencePercent}% phù hợp',
                          style: AppTextStyles.caption.copyWith(
                            color: _getConfidenceColor(suggestion.confidenceScore),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (suggestion.reason != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      '💡 ${suggestion.reason}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getConfidenceColor(double score) {
    if (score >= 0.8) return AppColors.success;
    if (score >= 0.6) return AppColors.primary;
    if (score >= 0.4) return AppColors.warning;
    return AppColors.textGray;
  }

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
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
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: _buildActionButton(),
      ),
    );
  }

  Widget _buildActionButton() {
    switch (_currentStep) {
      case 0:
        return SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _previewFlashcard,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                width: 24, height: 24,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
                : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.search),
                SizedBox(width: 8),
                Text('Tra cứu từ điển'),
              ],
            ),
          ),
        );

      case 1:
        return SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _meaningController.text.trim().isNotEmpty
                ? _goToImageSelection
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.image),
                SizedBox(width: 8),
                Text('Chọn hình ảnh'),
              ],
            ),
          ),
        );

      case 2:
        return SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _loadCategorySuggestions,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.category),
                const SizedBox(width: 8),
                Text(_selectedImageUrl != null
                    ? 'Tiếp tục với ảnh đã chọn'
                    : 'Tiếp tục không có ảnh'),
              ],
            ),
          ),
        );

      case 3:
        return SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _createFlashcard,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                width: 24, height: 24,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
                : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.save),
                SizedBox(width: 8),
                Text('Tạo Flashcard'),
              ],
            ),
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }
}