import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';
import '../../config/app_constants.dart';
import '../../services/flashcard_creation_service.dart';
import '../../services/category_service.dart';
import '../../models/category_model.dart';

/// 🎨 Màn hình tạo Flashcard - Quizlet Style
///
/// FLOW KHI CÓ initialCategoryId (từ CategoryDetailScreen):
///   Nhập từ → Preview & Chỉnh sửa → Chọn ảnh → Tạo thẻ (BỎ QUA bước chọn chủ đề)
///
/// FLOW KHI KHÔNG CÓ initialCategoryId:
///   Nhập từ → Preview & Chỉnh sửa → Chọn ảnh → Chọn chủ đề → Tạo thẻ
class FlashcardCreationScreen extends StatefulWidget {
  final int? initialCategoryId;
  final String? initialCategoryName;

  const FlashcardCreationScreen({
    super.key,
    this.initialCategoryId,
    this.initialCategoryName,
  });

  @override
  State<FlashcardCreationScreen> createState() => _FlashcardCreationScreenState();
}

class _FlashcardCreationScreenState extends State<FlashcardCreationScreen>
    with SingleTickerProviderStateMixin {
  // Controllers
  final TextEditingController _wordController = TextEditingController();
  final TextEditingController _meaningController = TextEditingController();
  final TextEditingController _phoneticController = TextEditingController();
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

  // Category data
  List<CategoryModel> _userCategories = [];
  dynamic _categorySuggestions;
  bool _isLoadingCategories = false;

  // ✅ Kiểm tra xem có bỏ qua bước chọn chủ đề không
  bool get _skipCategoryStep => widget.initialCategoryId != null;

  // ✅ Tổng số bước (3 nếu có initialCategoryId, 4 nếu không)
  int get _totalSteps => _skipCategoryStep ? 3 : 4;

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.initialCategoryId;
    _selectedCategoryName = widget.initialCategoryName;

    _animController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
    _animController.forward();

    // Load user categories nếu cần chọn chủ đề
    if (!_skipCategoryStep) {
      _loadUserCategories();
    }
  }

  @override
  void dispose() {
    _wordController.dispose();
    _meaningController.dispose();
    _phoneticController.dispose();
    _scrollController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  // ==================== LOAD USER CATEGORIES ====================

  Future<void> _loadUserCategories() async {
    try {
      final categories = await CategoryService.getMyCategories();
      setState(() {
        _userCategories = categories;
      });
    } catch (e) {
      debugPrint('Error loading categories: $e');
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
          _phoneticController.text = result.phonetic ?? '';
          _selectedPartOfSpeech = result.partOfSpeech;
          _selectedPartOfSpeechVi = result.partOfSpeechVi;
        }

        // ✅ TỰ ĐỘNG CHỌN ẢNH ĐẦU TIÊN
        if (result.imageSuggestions.isNotEmpty) {
          _selectedImageUrl = result.imageSuggestions.first.url;
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
    // ✅ NẾU ĐÃ CÓ CATEGORY → TẠO LUÔN
    if (_skipCategoryStep) {
      _createFlashcard();
      return;
    }

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
    // Validate category
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
              const Text('Tạo thẻ thành công!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                '"${_wordController.text}" đã được thêm vào ${_selectedCategoryName ?? "học phần"}',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context); // Close dialog
                        Navigator.pop(context, true); // Return to previous screen
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Hoàn tất'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _resetForm();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Thêm thẻ mới', style: TextStyle(color: Colors.white)),
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
      _phoneticController.clear();
      _previewResult = null;
      _selectedImageUrl = null;
      _selectedPartOfSpeech = null;
      _selectedPartOfSpeechVi = null;
      // Giữ nguyên category đã chọn
    });
    _animController.reset();
    _animController.forward();
  }

  // ==================== BUILD UI ====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildProgressIndicator(),
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: _buildCurrentStep(),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.close, color: AppColors.textPrimary),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        children: [
          const Text('Tạo thẻ mới', style: TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold, fontSize: 18)),
          if (_skipCategoryStep && _selectedCategoryName != null)
            Text(
              'vào "$_selectedCategoryName"',
              style: TextStyle(color: AppColors.textGray, fontSize: 12),
            ),
        ],
      ),
      centerTitle: true,
    );
  }

  Widget _buildProgressIndicator() {
    final steps = _skipCategoryStep
        ? ['Nhập từ', 'Chỉnh sửa', 'Chọn ảnh']
        : ['Nhập từ', 'Chỉnh sửa', 'Chọn ảnh', 'Chủ đề'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (index) {
          if (index.isOdd) {
            // Connector line
            final stepIndex = index ~/ 2;
            return Expanded(
              child: Container(
                height: 3,
                color: _currentStep > stepIndex ? AppColors.primary : AppColors.border,
              ),
            );
          } else {
            // Step circle
            final stepIndex = index ~/ 2;
            final isActive = _currentStep >= stepIndex;
            final isCompleted = _currentStep > stepIndex;

            return Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.primary : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isActive ? AppColors.primary : AppColors.border,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                        : Text(
                      '${stepIndex + 1}',
                      style: TextStyle(
                        color: isActive ? Colors.white : AppColors.textGray,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  steps[stepIndex],
                  style: TextStyle(
                    fontSize: 10,
                    color: isActive ? AppColors.primary : AppColors.textGray,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            );
          }
        }),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildWordInputStep();
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

  // ==================== STEP 1: WORD INPUT ====================

  Widget _buildWordInputStep() {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary.withOpacity(0.1), AppColors.accent.withOpacity(0.1)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.auto_awesome, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Tra cứu tự động', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryDark)),
                      const SizedBox(height: 4),
                      Text('Nhập từ tiếng Anh, AI sẽ tự động tra nghĩa, phiên âm và gợi ý ảnh', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Word input
          Text('Từ vựng', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          const SizedBox(height: 8),
          TextField(
            controller: _wordController,
            autofocus: true,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              hintText: 'Nhập từ tiếng Anh...',
              hintStyle: TextStyle(color: AppColors.textGray),
              prefixIcon: const Icon(Icons.abc, color: AppColors.primary),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _previewFlashcard(),
          ),

          const SizedBox(height: 24),

          // Example words
          Text('Ví dụ từ phổ biến', style: TextStyle(fontSize: 13, color: AppColors.textGray)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['apple', 'beautiful', 'computer', 'development', 'environment']
                .map((word) => ActionChip(
              label: Text(word),
              onPressed: () {
                _wordController.text = word;
                _previewFlashcard();
              },
              backgroundColor: AppColors.background,
            ))
                .toList(),
          ),
        ],
      ),
    );
  }

  // ==================== STEP 2: PREVIEW & EDIT ====================

  Widget _buildPreviewStep() {
    if (_previewResult == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Word header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.primary, AppColors.accent]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.spellcheck, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_wordController.text, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                      if (_phoneticController.text.isNotEmpty)
                        Text(_phoneticController.text, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
                    ],
                  ),
                ),
                if (_previewResult!.isFoundInDictionary)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle, color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        const Text('Đã tra cứu', style: TextStyle(color: Colors.white, fontSize: 11)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Part of speech
          if (_selectedPartOfSpeech != null) ...[
            Wrap(
              spacing: 8,
              children: [
                _buildPosChip(_selectedPartOfSpeech!, AppColors.primary),
                if (_selectedPartOfSpeechVi != null) _buildPosChip(_selectedPartOfSpeechVi!, AppColors.secondary),
              ],
            ),
            const SizedBox(height: 20),
          ],

          // Vietnamese meaning
          _buildInputSection(
            label: 'Nghĩa tiếng Việt',
            icon: Icons.translate,
            required: true,
            child: TextField(
              controller: _meaningController,
              maxLines: 2,
              decoration: _buildFieldDecoration('Nhập nghĩa tiếng Việt...'),
            ),
          ),
          const SizedBox(height: 16),

          // Phonetic
          _buildInputSection(
            label: 'Phiên âm',
            icon: Icons.record_voice_over_outlined,
            child: TextField(
              controller: _phoneticController,
              decoration: _buildFieldDecoration('Nhập phiên âm...'),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildPosChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
    );
  }

  Widget _buildInputSection({required String label, required IconData icon, required Widget child, bool required = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            if (required) const Text(' *', style: TextStyle(color: AppColors.error)),
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
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
      contentPadding: const EdgeInsets.all(16),
    );
  }

  // ==================== STEP 3: IMAGE SELECTION ====================

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
            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.textSecondary, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text('Hình ảnh giúp ghi nhớ tốt hơn. Ảnh đầu tiên đã được chọn sẵn.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13))),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Selected image preview
          if (_selectedImageUrl != null) ...[
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
                    child: Image.network(_selectedImageUrl!, width: 60, height: 60, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('✓ Ảnh đã chọn', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.success)),
                        Text('Bấm vào ảnh khác để thay đổi', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.error),
                    onPressed: () => setState(() => _selectedImageUrl = null),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Image grid
          if (images.isEmpty)
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  Icon(Icons.image_not_supported, size: 48, color: AppColors.textGray),
                  const SizedBox(height: 16),
                  Text('Không tìm thấy hình ảnh', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  Text('Bạn có thể bỏ qua bước này', style: TextStyle(color: AppColors.textGray)),
                ],
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1),
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
                      border: Border.all(color: isSelected ? AppColors.primary : Colors.transparent, width: 3),
                      boxShadow: isSelected ? [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 8)] : null,
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
                              return Container(color: AppColors.background, child: const Center(child: CircularProgressIndicator(strokeWidth: 2)));
                            },
                            errorBuilder: (context, error, stack) => Container(color: AppColors.background, child: Icon(Icons.broken_image, color: AppColors.textGray)),
                          ),
                          if (isSelected) Container(color: AppColors.primary.withOpacity(0.4), child: const Center(child: Icon(Icons.check_circle, color: Colors.white, size: 32))),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // ==================== STEP 4: CATEGORY SELECTION ====================

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
          else ...[
            // AI suggestion header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [AppColors.primary.withOpacity(0.1), AppColors.accent.withOpacity(0.1)]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.auto_awesome, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Chọn chủ đề', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                        Text('Tất cả chủ đề của bạn với độ phù hợp', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ✅ HIỂN THỊ TẤT CẢ CHỦ ĐỀ USER SỞ HỮU
            if (_userCategories.isEmpty)
              _buildNoCategoriesMessage()
            else
              ..._buildCategoryListWithScores(),
          ],
        ],
      ),
    );
  }

  Widget _buildNoCategoriesMessage() {
    return Container(
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
          const Text('Chưa có chủ đề nào', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Vui lòng tạo chủ đề trước khi thêm thẻ', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.add),
            label: const Text('Tạo chủ đề mới'),
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary),
          ),
        ],
      ),
    );
  }

  // ✅ BUILD CATEGORY LIST WITH SCORES
  List<Widget> _buildCategoryListWithScores() {
    // Lấy suggestions từ API (nếu có)
    Map<int, dynamic> suggestionMap = {};
    if (_categorySuggestions != null && _categorySuggestions.suggestions != null) {
      for (var sug in _categorySuggestions.suggestions) {
        suggestionMap[sug.categoryId] = sug;
      }
    }

    // Sort: có suggestion trước (theo score), không có suggestion sau
    List<CategoryModel> sortedCategories = List.from(_userCategories);
    sortedCategories.sort((a, b) {
      final scoreA = suggestionMap[a.id]?.confidenceScore ?? 0.0;
      final scoreB = suggestionMap[b.id]?.confidenceScore ?? 0.0;
      return scoreB.compareTo(scoreA);
    });

    return sortedCategories.asMap().entries.map((entry) {
      final index = entry.key;
      final cat = entry.value;
      final suggestion = suggestionMap[cat.id];
      final score = suggestion?.confidenceScore ?? 0.0;
      final reason = suggestion?.reason;
      final isSelected = _selectedCategoryId == cat.id;
      final isTopRecommended = index == 0 && score > 0;

      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _buildCategoryItemWithScore(
          id: cat.id,
          name: cat.name,
          description: cat.description,
          reason: reason,
          confidenceScore: score,
          isSelected: isSelected,
          isRecommended: isTopRecommended,
        ),
      );
    }).toList();
  }

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
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.border, width: isSelected ? 2 : 1),
          boxShadow: isSelected ? [BoxShadow(color: AppColors.primary.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4))] : null,
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
                  child: Icon(Icons.folder_outlined, color: isSelected ? AppColors.primary : AppColors.textSecondary, size: 20),
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
                            child: Text(name, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: isSelected ? AppColors.primary : AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                          if (isRecommended) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(gradient: LinearGradient(colors: [AppColors.warning, AppColors.warning.withOpacity(0.8)]), borderRadius: BorderRadius.circular(10)),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.star, color: Colors.white, size: 12),
                                  SizedBox(width: 4),
                                  Text('Đề xuất', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (description != null && description.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(description, style: TextStyle(fontSize: 12, color: AppColors.textGray), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ],
                  ),
                ),

                // Điểm phù hợp
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: confidenceColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                  child: Text('$confidencePercent%', style: TextStyle(color: confidenceColor, fontWeight: FontWeight.bold, fontSize: 13)),
                ),

                // Check icon
                if (isSelected) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.check_circle, color: AppColors.primary, size: 24),
                ],
              ],
            ),

            // Lý do AI gợi ý
            if (reason != null && reason.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lightbulb_outline, size: 16, color: AppColors.warning),
                    const SizedBox(width: 8),
                    Expanded(child: Text(reason, style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontStyle: FontStyle.italic, height: 1.4))),
                  ],
                ),
              ),
            ],
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

  // ==================== BOTTOM BAR ====================

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
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
                child: const Text('Quay lại', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            flex: _currentStep == 0 ? 1 : 1,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _getNextAction(),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isLastStep() ? AppColors.success : AppColors.primary,
                disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                  : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_getNextIcon(), size: 20, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(_getNextButtonText(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isLastStep() {
    if (_skipCategoryStep) {
      return _currentStep == 2; // Step 2 là bước cuối nếu skip category
    }
    return _currentStep == 3;
  }

  IconData _getNextIcon() {
    switch (_currentStep) {
      case 0:
        return Icons.search;
      case 1:
        return Icons.image;
      case 2:
        if (_skipCategoryStep) return Icons.check; // Tạo thẻ luôn
        return Icons.folder;
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
        if (_skipCategoryStep) return 'Tạo thẻ'; // Tạo thẻ luôn
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
        if (_skipCategoryStep) {
          return _createFlashcard; // Tạo thẻ luôn, bỏ qua chọn chủ đề
        }
        return _loadCategorySuggestions;
      case 3:
        return _selectedCategoryId != null ? _createFlashcard : null;
      default:
        return null;
    }
  }
}