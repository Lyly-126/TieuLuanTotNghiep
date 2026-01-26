import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../services/text_extraction_service.dart';
import '../../services/category_service.dart';
import '../../models/category_model.dart';
import 'batch_creation_result_screen.dart';

/// Màn hình chọn category cho batch từ vựng và tạo flashcard
///
/// Flow:
/// 1. Nếu skipCategorySelection = true → tạo thẻ ngay
/// 2. Nếu không → Hiển thị danh sách category của user để chọn
/// 3. Chỉ hiện category do user sở hữu (không hiện system/public)
class BatchCategorySelectionScreen extends StatefulWidget {
  final List<ExtractedWord> selectedWords;
  final int? preselectedCategoryId;
  final String? preselectedCategoryName;
  final bool skipCategorySelection;

  const BatchCategorySelectionScreen({
    super.key,
    required this.selectedWords,
    this.preselectedCategoryId,
    this.preselectedCategoryName,
    this.skipCategorySelection = false,
  });

  @override
  State<BatchCategorySelectionScreen> createState() =>
      _BatchCategorySelectionScreenState();
}

class _BatchCategorySelectionScreenState
    extends State<BatchCategorySelectionScreen> {
  bool _isLoading = true;
  bool _isCreating = false;
  String? _errorMessage;

  BatchCategorySuggestionResult? _suggestionResult;
  List<CategoryModel> _userCategories = [];

  int? _selectedCategoryId;
  String? _selectedCategoryName;

  bool _generateAudio = true;

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.preselectedCategoryId;
    _selectedCategoryName = widget.preselectedCategoryName;

    // Nếu skip chọn category và đã có preselected → tạo thẻ ngay
    if (widget.skipCategorySelection &&
        widget.preselectedCategoryId != null &&
        widget.preselectedCategoryName != null) {
      // Delay một chút để UI kịp render
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _createFlashcards();
      });
    } else {
      _loadData();
    }
  }

  // ==================== DATA LOADING ====================

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load song song
      await Future.wait([
        _loadCategorySuggestions(),
        _loadUserCategories(),
      ]);
    } catch (e) {
      setState(() => _errorMessage = 'Lỗi tải dữ liệu: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadCategorySuggestions() async {
    try {
      final result = await TextExtractionService.suggestCategoryForBatch(
        widget.selectedWords,
      );
      setState(() => _suggestionResult = result);

      // Auto-select top suggestion nếu chưa có preselected
      if (_selectedCategoryId == null &&
          result.suggestions.isNotEmpty) {
        setState(() {
          _selectedCategoryId = result.suggestions.first.categoryId;
          _selectedCategoryName = result.suggestions.first.categoryName;
        });
      }
    } catch (e) {
      debugPrint('Error loading suggestions: $e');
    }
  }

  Future<void> _loadUserCategories() async {
    try {
      // Chỉ lấy category do user sở hữu (không lấy system, không lấy public của người khác)
      final categories = await CategoryService.getMyOwnedCategories();
      setState(() => _userCategories = categories);
    } catch (e) {
      debugPrint('Error loading categories: $e');
    }
  }

  // ==================== ACTIONS ====================

  void _selectCategory(int id, String name) {
    setState(() {
      _selectedCategoryId = id;
      _selectedCategoryName = name;
    });
  }

  Future<void> _createFlashcards() async {
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn một chủ đề'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
      final result = await TextExtractionService.createFlashcardsBatch(
        words: widget.selectedWords,
        categoryId: _selectedCategoryId!,
        generateAudio: _generateAudio,
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => BatchCreationResultScreen(
              result: result,
              categoryId: _selectedCategoryId!,
              categoryName: _selectedCategoryName!,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isCreating = false;
        _errorMessage = 'Lỗi tạo flashcard: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  // ==================== UI ====================

  @override
  Widget build(BuildContext context) {
    // Nếu đang skip và tạo thẻ ngay → hiển thị màn hình creating
    if (widget.skipCategorySelection && _selectedCategoryId != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: _buildCreating(),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: _isLoading
          ? _buildLoading()
          : _isCreating
          ? _buildCreating()
          : _buildContent(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chọn chủ đề',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          Text(
            '${widget.selectedWords.length} từ đã chọn',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
      centerTitle: false,
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Đang phân tích từ vựng...'),
        ],
      ),
    );
  }

  Widget _buildCreating() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Progress animation
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(
                    strokeWidth: 4,
                    valueColor: AlwaysStoppedAnimation(AppColors.primary),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Đang tạo flashcard...',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${widget.selectedWords.length} thẻ • $_selectedCategoryName',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary card
                _buildSummaryCard(),
                const SizedBox(height: 24),

                // AI Suggestions
                if (_suggestionResult != null &&
                    _suggestionResult!.suggestions.isNotEmpty) ...[
                  _buildSectionTitle(
                    icon: Icons.auto_awesome,
                    title: 'Gợi ý từ AI',
                    subtitle: 'Dựa trên chủ đề chung của các từ',
                  ),
                  const SizedBox(height: 12),
                  ..._suggestionResult!.suggestions.map(
                        (s) => _buildCategorySuggestionCard(
                      id: s.categoryId ?? 0,
                      name: s.categoryName ?? '',
                      description: s.description,
                      reason: s.reason,
                      confidenceScore: s.confidenceScore ?? 0.0,
                      isSelected: _selectedCategoryId == s.categoryId,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // User categories
                _buildSectionTitle(
                  icon: Icons.folder,
                  title: 'Chủ đề của bạn',
                  subtitle: 'Chọn một chủ đề để lưu các thẻ',
                ),
                const SizedBox(height: 12),
                if (_userCategories.isEmpty)
                  _buildEmptyCategoriesCard()
                else
                  ..._userCategories.map(
                        (c) => _buildCategoryCard(
                      id: c.id,
                      name: c.name,
                      description: c.description,
                      flashcardCount: c.flashcardCount ?? 0,
                      isSelected: _selectedCategoryId == c.id,
                    ),
                  ),

                const SizedBox(height: 24),

                // Audio option
                _buildAudioOption(),
              ],
            ),
          ),
        ),

        // Bottom bar
        _buildBottomBar(),
      ],
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.primary.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.style,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.selectedWords.length} thẻ sẽ được tạo',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Chọn chủ đề để xếp loại các thẻ',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle({
    required IconData icon,
    required String title,
    String? subtitle,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: AppColors.textPrimary,
              ),
            ),
            if (subtitle != null)
              Text(
                subtitle,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategorySuggestionCard({
    required int id,
    required String name,
    String? description,
    String? reason,
    required double confidenceScore,
    bool isSelected = false,
  }) {
    final confidencePercent = (confidenceScore * 100).round();
    final confidenceColor = _getConfidenceColor(confidenceScore);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () => _selectCategory(id, name),
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.border,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Icon
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withOpacity(0.1)
                            : AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.auto_awesome,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Name
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                            ),
                          ),
                          if (description != null && description.isNotEmpty)
                            Text(
                              description,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),

                    // Confidence
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
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

                    if (isSelected) ...[
                      const SizedBox(width: 8),
                      Icon(Icons.check_circle, color: AppColors.primary, size: 24),
                    ],
                  ],
                ),

                // Reason
                if (reason != null && reason.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          size: 16,
                          color: AppColors.warning,
                        ),
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
        ),
      ),
    );
  }

  Widget _buildCategoryCard({
    required int id,
    required String name,
    String? description,
    required int flashcardCount,
    bool isSelected = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => _selectCategory(id, name),
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.border,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withOpacity(0.1)
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.folder,
                    color: isSelected ? AppColors.primary : AppColors.textSecondary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),

                // Name & description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$flashcardCount thẻ',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                // Check icon
                if (isSelected)
                  Icon(Icons.check_circle, color: AppColors.primary, size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyCategoriesCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(Icons.folder_off, size: 48, color: AppColors.textGray),
          const SizedBox(height: 12),
          const Text(
            'Bạn chưa có chủ đề nào',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tạo chủ đề mới để lưu thẻ',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              // TODO: Navigate to create category
            },
            icon: const Icon(Icons.add),
            label: const Text('Tạo chủ đề mới'),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioOption() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(Icons.volume_up, color: AppColors.primary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tạo audio phát âm',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Tự động tạo audio cho mỗi thẻ',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          Switch(
            value: _generateAudio,
            onChanged: (value) => setState(() => _generateAudio = value),
            activeThumbColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
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
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_selectedCategoryName != null) ...[
                  Text(
                    _selectedCategoryName!,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${widget.selectedWords.length} thẻ sẽ được tạo',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ] else
                  Text(
                    'Chọn một chủ đề',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
          ),

          // Create button
          ElevatedButton(
            onPressed: _selectedCategoryId != null ? _createFlashcards : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              disabledBackgroundColor: AppColors.success.withOpacity(0.5),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.check, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  'Tạo thẻ',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getConfidenceColor(double score) {
    if (score >= 0.8) return AppColors.success;
    if (score >= 0.6) return AppColors.primary;
    if (score >= 0.4) return AppColors.warning;
    return AppColors.textGray;
  }
}