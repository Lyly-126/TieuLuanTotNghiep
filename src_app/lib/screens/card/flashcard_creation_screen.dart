import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';
import '../../config/app_constants.dart';
import '../../services/flashcard_creation_service.dart';

/// 🎨 Màn hình tạo Flashcard - Quizlet Style
/// Flow: Nhập từ → Preview → Chọn ảnh → Chọn category → Lưu
class FlashcardCreationScreen extends StatefulWidget {
  final int? initialCategoryId;

  const FlashcardCreationScreen({
    super.key,
    this.initialCategoryId,
  });

  @override
  State<FlashcardCreationScreen> createState() => _FlashcardCreationScreenState();
}

class _FlashcardCreationScreenState extends State<FlashcardCreationScreen>
    with SingleTickerProviderStateMixin {
  // Controllers
  final TextEditingController _wordController = TextEditingController();
  final TextEditingController _meaningController = TextEditingController();
  final TextEditingController _definitionController = TextEditingController();
  final TextEditingController _phoneticController = TextEditingController();
  final TextEditingController _exampleController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Animation
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  // State
  int _currentStep = 0;
  bool _isLoading = false;
  String? _errorMessage;

  // Preview data
  FlashcardPreviewResult? _previewResult;

  // Selected data
  String? _selectedImageUrl;
  int? _selectedCategoryId;
  String? _selectedCategoryName;
  String? _selectedPartOfSpeech;
  String? _selectedPartOfSpeechVi;

  // Category suggestions
  dynamic _categorySuggestions;
  bool _isLoadingCategories = false;

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.initialCategoryId;

    _animController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _wordController.dispose();
    _meaningController.dispose();
    _definitionController.dispose();
    _phoneticController.dispose();
    _exampleController.dispose();
    _scrollController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  // ==================== ACTIONS ====================

  Future<void> _previewFlashcard() async {
    final word = _wordController.text.trim();
    if (word.isEmpty) {
      _showError('Vui lòng nhập từ vựng');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await FlashcardCreationService.preview(word);

      setState(() {
        _previewResult = result;
        _isLoading = false;
        _currentStep = 1;

        if (result.isFoundInDictionary) {
          _meaningController.text = result.vietnameseMeaning ?? '';
          _definitionController.text = result.englishDefinition ?? '';
          _phoneticController.text = result.phonetic ?? '';
          _selectedPartOfSpeech = result.partOfSpeech;
          _selectedPartOfSpeechVi = result.partOfSpeechVi;
        }
      });

      _animController.reset();
      _animController.forward();
      _scrollToTop();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError('Lỗi tra cứu: $e');
    }
  }

  void _goToImageSelection() {
    if (_meaningController.text.trim().isEmpty) {
      _showError('Vui lòng nhập nghĩa tiếng Việt');
      return;
    }
    setState(() => _currentStep = 2);
    _animController.reset();
    _animController.forward();
    _scrollToTop();
  }

  Future<void> _loadCategorySuggestions() async {
    setState(() {
      _isLoadingCategories = true;
      _currentStep = 3;
    });
    _animController.reset();
    _animController.forward();
    _scrollToTop();

    try {
      final result = await FlashcardCreationService.suggestCategory(
        word: _wordController.text.trim(),
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
      });
    }
  }

  Future<void> _createFlashcard() async {
    // Validate category bắt buộc
    if (_selectedCategoryId == null) {
      _showError('Vui lòng chọn một chủ đề để lưu thẻ');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final request = FlashcardCreateRequest(
        word: _wordController.text.trim(),
        partOfSpeech: _selectedPartOfSpeech,
        partOfSpeechVi: _selectedPartOfSpeechVi,
        phonetic: _phoneticController.text.trim(),
        meaning: _meaningController.text.trim(),
        definition: _definitionController.text.trim(),
        example: _exampleController.text.trim(),
        selectedImageUrl: _selectedImageUrl,
        categoryId: _selectedCategoryId,
        generateAudio: true,
      );

      final result = await FlashcardCreationService.create(request);

      setState(() => _isLoading = false);

      if (result.success) {
        _showSuccessDialog(result.flashcardId);
      } else {
        _showError(result.message ?? 'Không thể tạo flashcard');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Lỗi: $e');
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _animController.reset();
      _animController.forward();
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccessDialog(int? flashcardId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle, color: AppColors.success, size: 48),
              ),
              const SizedBox(height: 20),
              Text('Tạo thẻ thành công!', style: AppTextStyles.heading3),
              const SizedBox(height: 8),
              Text(
                'Thẻ "${_wordController.text}" đã được thêm vào bộ sưu tập',
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _resetForm();
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(color: AppColors.primary),
                      ),
                      child: Text('Tạo thẻ khác', style: TextStyle(color: AppColors.primary)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context, flashcardId);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text('Hoàn tất', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _resetForm() {
    setState(() {
      _currentStep = 0;
      _wordController.clear();
      _meaningController.clear();
      _definitionController.clear();
      _phoneticController.clear();
      _exampleController.clear();
      _previewResult = null;
      _selectedImageUrl = null;
      _selectedCategoryId = widget.initialCategoryId;
      _selectedCategoryName = null;
      _selectedPartOfSpeech = null;
      _selectedPartOfSpeechVi = null;
      _categorySuggestions = null;
      _errorMessage = null;
    });
    _animController.reset();
    _animController.forward();
  }

  // ==================== BUILD ====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            _buildProgressIndicator(),
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: _buildContent(),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final titles = ['Tạo thẻ mới', 'Thông tin từ vựng', 'Chọn hình ảnh', 'Chọn chủ đề'];
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.close, color: AppColors.textPrimary, size: 20),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        titles[_currentStep],
        style: AppTextStyles.heading3.copyWith(color: AppColors.textPrimary, fontSize: 18),
      ),
      centerTitle: true,
      actions: [
        if (_currentStep > 0)
          TextButton(
            onPressed: _resetForm,
            child: Text('Làm lại', style: TextStyle(color: AppColors.textSecondary)),
          ),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Row(
        children: List.generate(4, (index) {
          final isActive = index <= _currentStep;
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 4,
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.primary : AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                if (index < 3) const SizedBox(width: 4),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading && _currentStep == 0) {
      return _buildLoadingState();
    }

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
        return const SizedBox.shrink();
    }
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Đang tra cứu từ điển...',
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  // ==================== STEP 1: INPUT ====================

  Widget _buildInputStep() {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.auto_awesome, color: Colors.white, size: 32),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Nhập từ vựng tiếng Anh',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'AI sẽ tự động tra cứu nghĩa và gợi ý hình ảnh',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Input field
          Text('Từ vựng', style: AppTextStyles.heading4.copyWith(color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: TextField(
              controller: _wordController,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              textCapitalization: TextCapitalization.none,
              decoration: InputDecoration(
                hintText: 'Ví dụ: beautiful, amazing...',
                hintStyle: TextStyle(color: AppColors.textGray, fontSize: 16),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(20),
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 16, right: 12),
                  child: Icon(Icons.search, color: AppColors.primary),
                ),
              ),
              onSubmitted: (_) => _previewFlashcard(),
            ),
          ),
          const SizedBox(height: 24),

          // Quick suggestions
          Text('Gợi ý nhanh', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['hello', 'beautiful', 'amazing', 'wonderful', 'fantastic']
                .map((word) => _buildSuggestionChip(word))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(String word) {
    return InkWell(
      onTap: () {
        _wordController.text = word;
        _previewFlashcard();
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(word, style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
      ),
    );
  }

  // ==================== STEP 2: PREVIEW ====================

  Widget _buildPreviewStep() {
    if (_previewResult == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Word card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _previewResult!.isFoundInDictionary
                        ? AppColors.success.withOpacity(0.1)
                        : AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _previewResult!.isFoundInDictionary ? Icons.check_circle : Icons.edit_note,
                        size: 16,
                        color: _previewResult!.isFoundInDictionary ? AppColors.success : AppColors.warning,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _previewResult!.isFoundInDictionary ? 'Đã tìm thấy' : 'Nhập thủ công',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _previewResult!.isFoundInDictionary ? AppColors.success : AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Word
                Text(
                  _previewResult!.word,
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                ),

                // Phonetic
                if (_phoneticController.text.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    _phoneticController.text,
                    style: TextStyle(fontSize: 16, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                  ),
                ],

                // Part of speech
                if (_selectedPartOfSpeech != null) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildPosChip(_selectedPartOfSpeech!, AppColors.primary),
                      if (_selectedPartOfSpeechVi != null)
                        _buildPosChip(_selectedPartOfSpeechVi!, AppColors.secondary),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Meaning input
          _buildInputSection(
            label: 'Nghĩa tiếng Việt',
            required: true,
            icon: Icons.translate,
            child: TextField(
              controller: _meaningController,
              style: const TextStyle(fontSize: 16),
              maxLines: 2,
              decoration: _buildFieldDecoration('Nhập nghĩa tiếng Việt...'),
            ),
          ),
          const SizedBox(height: 20),

          // Definition input
          _buildInputSection(
            label: 'Định nghĩa tiếng Anh',
            icon: Icons.description,
            child: TextField(
              controller: _definitionController,
              style: const TextStyle(fontSize: 16),
              maxLines: 2,
              decoration: _buildFieldDecoration('Nhập định nghĩa (tùy chọn)...'),
            ),
          ),
          const SizedBox(height: 20),

          // Phonetic input
          _buildInputSection(
            label: 'Phiên âm',
            icon: Icons.record_voice_over,
            child: TextField(
              controller: _phoneticController,
              style: const TextStyle(fontSize: 16),
              decoration: _buildFieldDecoration('Ví dụ: /ˈbjuːtɪfəl/'),
            ),
          ),
          const SizedBox(height: 20),

          // Example input
          _buildInputSection(
            label: 'Câu ví dụ',
            icon: Icons.format_quote,
            child: TextField(
              controller: _exampleController,
              style: const TextStyle(fontSize: 16),
              maxLines: 2,
              decoration: _buildFieldDecoration('Nhập câu ví dụ...'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPosChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
    );
  }

  Widget _buildInputSection({
    required String label,
    required IconData icon,
    required Widget child,
    bool required = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(label, style: AppTextStyles.heading4.copyWith(fontSize: 15)),
            if (required) ...[
              const SizedBox(width: 4),
              Text('*', style: TextStyle(color: AppColors.error)),
            ],
          ],
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }

  InputDecoration _buildFieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppColors.textGray),
      filled: true,
      fillColor: AppColors.background,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.all(16),
    );
  }

  // ==================== STEP 3: IMAGES ====================

  Widget _buildImageSelectionStep() {
    if (_previewResult == null) return const SizedBox.shrink();

    final images = _previewResult!.imageSuggestions;

    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.textSecondary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Hình ảnh giúp ghi nhớ tốt hơn, nhưng không bắt buộc',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          if (images.isEmpty)
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(Icons.image_not_supported, size: 48, color: AppColors.textGray),
                  const SizedBox(height: 16),
                  Text('Không tìm thấy hình ảnh', style: AppTextStyles.heading4.copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  Text('Bạn có thể bỏ qua bước này', style: TextStyle(color: AppColors.textGray)),
                ],
              ),
            )
          else
          // ✅ Grid 3 cột để hiển thị 6 ảnh (3x2)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,  // ✅ 3 cột
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1,
              ),
              itemCount: images.length,
              itemBuilder: (context, index) {
                final image = images[index];
                final isSelected = _selectedImageUrl == image.url;

                return GestureDetector(
                  onTap: () => setState(() => _selectedImageUrl = isSelected ? null : image.url),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: isSelected
                          ? [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
                          : null,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(9),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            image.url,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return Container(
                                color: AppColors.background,
                                child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                              );
                            },
                            errorBuilder: (context, error, stack) => Container(
                              color: AppColors.background,
                              child: Icon(Icons.broken_image, color: AppColors.textGray),
                            ),
                          ),
                          if (isSelected)
                            Container(
                              color: AppColors.primary.withOpacity(0.4),
                              child: const Center(child: Icon(Icons.check_circle, color: Colors.white, size: 32)),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

          // Ảnh đã chọn preview
          if (_selectedImageUrl != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.success.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      _selectedImageUrl!,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Đã chọn hình ảnh',
                          style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.success),
                        ),
                        Text(
                          'Nhấn vào ảnh để bỏ chọn',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _selectedImageUrl = null),
                    icon: Icon(Icons.close, color: AppColors.textGray),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ==================== STEP 4: CATEGORY ====================

  Widget _buildCategorySelectionStep() {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isLoadingCategories)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Đang phân tích và gợi ý chủ đề...'),
                  ],
                ),
              ),
            )
          else if (_categorySuggestions != null && _categorySuggestions.suggestions.isNotEmpty) ...[
            // AI suggestion header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary.withOpacity(0.1), AppColors.accent.withOpacity(0.1)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.auto_awesome, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('AI gợi ý chủ đề', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                        Text('Chọn chủ đề phù hợp nhất để lưu thẻ', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Category list với % phù hợp
            ..._categorySuggestions.suggestions.asMap().entries.map<Widget>((entry) {
              final index = entry.key;
              final cat = entry.value;
              final isSelected = _selectedCategoryId == cat.categoryId;
              final isTopRecommended = index == 0; // Category đầu tiên là recommend nhất

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildCategoryItemWithScore(
                  id: cat.categoryId,
                  name: cat.categoryName,
                  description: cat.description,
                  reason: cat.reason,
                  confidenceScore: cat.confidenceScore,
                  isSelected: isSelected,
                  isRecommended: isTopRecommended,
                ),
              );
            }).toList(),
          ] else
          // Không có category nào
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.warning.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Icon(Icons.folder_off_outlined, size: 48, color: AppColors.warning),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có chủ đề nào',
                    style: AppTextStyles.heading4.copyWith(color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Vui lòng tạo chủ đề trước khi thêm thẻ',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Tạo chủ đề mới'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Widget category item với điểm phù hợp
  Widget _buildCategoryItemWithScore({
    required int id,
    required String name,
    String? description,
    String? reason,
    required double confidenceScore,
    bool isSelected = false,
    bool isRecommended = false,
  }) {
    final confidencePercent = (confidenceScore * 100).round();
    final confidenceColor = _getConfidenceColor(confidenceScore);

    return GestureDetector(
      onTap: () => setState(() {
        _selectedCategoryId = id;
        _selectedCategoryName = name;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ] : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Icon folder
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary.withOpacity(0.1) : AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.folder_outlined,
                    color: isSelected ? AppColors.primary : AppColors.textSecondary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),

                // Tên và badge
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: isSelected ? AppColors.primary : AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isRecommended) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [AppColors.warning, AppColors.warning.withOpacity(0.8)],
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.star, color: Colors.white, size: 12),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Đề xuất',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (description != null && description.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          description,
                          style: TextStyle(fontSize: 12, color: AppColors.textGray),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),

                // Điểm phù hợp
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: confidenceColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$confidencePercent%',
                    style: TextStyle(
                      color: confidenceColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),

                // Check icon
                if (isSelected) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.check_circle, color: AppColors.primary, size: 24),
                ],
              ],
            ),

            // Lý do AI gợi ý
            if (reason != null && reason.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lightbulb_outline, size: 16, color: AppColors.warning),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        reason,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontStyle: FontStyle.italic,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Màu theo độ phù hợp
  Color _getConfidenceColor(double score) {
    if (score >= 0.8) return AppColors.success;
    if (score >= 0.6) return AppColors.primary;
    if (score >= 0.4) return AppColors.warning;
    return AppColors.textGray;
  }

  // ==================== BOTTOM BAR ====================

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5)),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: _previousStep,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  side: BorderSide(color: AppColors.border),
                ),
                child: Text('Quay lại', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: ElevatedButton(
              onPressed: _isLoading ? null : _getNextAction(),
              style: ElevatedButton.styleFrom(
                backgroundColor: _currentStep == 3 ? AppColors.success : AppColors.primary,
                disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
              )
                  : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_getNextIcon(), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    _getNextButtonText(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getNextIcon() {
    switch (_currentStep) {
      case 0:
        return Icons.search;
      case 1:
        return Icons.image;
      case 2:
        return Icons.category;
      case 3:
        return Icons.check;
      default:
        return Icons.arrow_forward;
    }
  }

  String _getNextButtonText() {
    switch (_currentStep) {
      case 0:
        return 'Tra cứu';
      case 1:
        return 'Chọn ảnh';
      case 2:
        return _selectedImageUrl != null ? 'Tiếp tục' : 'Bỏ qua';
      case 3:
        return _selectedCategoryId != null ? 'Tạo thẻ' : 'Chọn chủ đề';
      default:
        return 'Tiếp tục';
    }
  }

  VoidCallback? _getNextAction() {
    switch (_currentStep) {
      case 0:
        return _previewFlashcard;
      case 1:
        return _goToImageSelection;
      case 2:
        return _loadCategorySuggestions;
      case 3:
      // Chỉ cho phép tạo thẻ khi đã chọn category
        return _selectedCategoryId != null ? _createFlashcard : null;
      default:
        return null;
    }
  }
}