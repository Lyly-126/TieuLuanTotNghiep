import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../services/text_extraction_service.dart';
import 'batch_category_selection_screen.dart';

/// Màn hình chọn từ vựng sau khi trích xuất từ ảnh/PDF
///
/// Flow:
/// 1. Hiển thị danh sách từ đã trích xuất
/// 2. User chọn/bỏ chọn từng từ hoặc chọn tất cả
/// 3. Nhấn "Tiếp tục" để chọn category
class WordSelectionScreen extends StatefulWidget {
  final TextExtractionResult extractionResult;
  final int? initialCategoryId;
  final String? initialCategoryName;

  const WordSelectionScreen({
    super.key,
    required this.extractionResult,
    this.initialCategoryId,
    this.initialCategoryName,
  });

  @override
  State<WordSelectionScreen> createState() => _WordSelectionScreenState();
}

class _WordSelectionScreenState extends State<WordSelectionScreen> {
  late List<ExtractedWord> _words;
  bool _selectAll = true;
  String _filterMode = 'all'; // all, dictionary, unknown
  String _searchQuery = '';

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Clone list và set tất cả selected = true mặc định
    _words = widget.extractionResult.extractedWords
        .map((w) => w.copyWith(selected: true))
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ==================== GETTERS ====================

  List<ExtractedWord> get _filteredWords {
    var filtered = _words;

    // Filter by mode
    switch (_filterMode) {
      case 'dictionary':
        filtered = filtered.where((w) => w.foundInDictionary).toList();
        break;
      case 'unknown':
        filtered = filtered.where((w) => !w.foundInDictionary).toList();
        break;
    }

    // Filter by search
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((w) => w.word.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    return filtered;
  }

  int get _selectedCount => _words.where((w) => w.selected).length;
  int get _dictionaryCount => _words.where((w) => w.foundInDictionary).length;

  // ==================== ACTIONS ====================

  void _toggleSelectAll() {
    setState(() {
      _selectAll = !_selectAll;
      for (var word in _filteredWords) {
        final index = _words.indexWhere((w) => w.word == word.word);
        if (index >= 0) {
          _words[index] = _words[index].copyWith(selected: _selectAll);
        }
      }
    });
  }

  void _toggleWordSelection(int index) {
    final wordToToggle = _filteredWords[index];
    final mainIndex = _words.indexWhere((w) => w.word == wordToToggle.word);

    if (mainIndex >= 0) {
      setState(() {
        _words[mainIndex] = _words[mainIndex].copyWith(
          selected: !_words[mainIndex].selected,
        );

        _selectAll = _filteredWords.every((w) {
          final idx = _words.indexWhere((ww) => ww.word == w.word);
          return idx >= 0 && _words[idx].selected;
        });
      });
    }
  }

  void _onContinue() {
    final selectedWords = _words.where((w) => w.selected).toList();

    if (selectedWords.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn ít nhất 1 từ'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Nếu đã có category (đang ở trong category detail) → tạo thẻ trực tiếp
    if (widget.initialCategoryId != null && widget.initialCategoryName != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BatchCategorySelectionScreen(
            selectedWords: selectedWords,
            preselectedCategoryId: widget.initialCategoryId,
            preselectedCategoryName: widget.initialCategoryName,
            skipCategorySelection: true, // Bỏ qua bước chọn, tạo luôn
          ),
        ),
      );
    } else {
      // Nếu từ Home/Library → chọn category
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BatchCategorySelectionScreen(
            selectedWords: selectedWords,
            preselectedCategoryId: null,
            preselectedCategoryName: null,
            skipCategorySelection: false,
          ),
        ),
      );
    }
  }

  // ==================== UI ====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildStatsAndFilter(),
          _buildSearchBar(),
          Expanded(child: _buildWordList()),
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
        icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chọn từ vựng',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          Text(
            'Từ ${widget.extractionResult.sourceType == 'IMAGE' ? 'ảnh' : 'PDF'}',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
      centerTitle: false,
      actions: [
        TextButton.icon(
          onPressed: _toggleSelectAll,
          icon: Icon(
            _selectAll ? Icons.deselect : Icons.select_all,
            size: 20,
          ),
          label: Text(_selectAll ? 'Bỏ chọn' : 'Chọn tất cả'),
          style: TextButton.styleFrom(foregroundColor: AppColors.primary),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildStatsAndFilter() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        children: [
          // Stats row
          Row(
            children: [
              _buildStatChip(
                label: 'Tổng',
                count: _words.length,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              _buildStatChip(
                label: 'Từ điển',
                count: _dictionaryCount,
                color: AppColors.success,
              ),
              const SizedBox(width: 8),
              _buildStatChip(
                label: 'Đã chọn',
                count: _selectedCount,
                color: AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                  label: 'Tất cả',
                  isSelected: _filterMode == 'all',
                  onTap: () => setState(() => _filterMode = 'all'),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Có trong từ điển',
                  isSelected: _filterMode == 'dictionary',
                  onTap: () => setState(() => _filterMode = 'dictionary'),
                  icon: Icons.check_circle_outline,
                  color: AppColors.success,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Chưa biết',
                  isSelected: _filterMode == 'unknown',
                  onTap: () => setState(() => _filterMode = 'unknown'),
                  icon: Icons.help_outline,
                  color: AppColors.warning,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required String label,
    required int count,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$count',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color.withOpacity(0.8),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    IconData? icon,
    Color? color,
  }) {
    final chipColor = color ?? AppColors.primary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? chipColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? chipColor : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : chipColor,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: 'Tìm kiếm từ...',
          hintStyle: TextStyle(color: AppColors.textGray),
          prefixIcon: Icon(Icons.search, color: AppColors.textGray),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
            icon: Icon(Icons.clear, color: AppColors.textGray),
            onPressed: () {
              _searchController.clear();
              setState(() => _searchQuery = '');
            },
          )
              : null,
          filled: true,
          fillColor: AppColors.background,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildWordList() {
    final filteredWords = _filteredWords;

    if (filteredWords.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: AppColors.textGray),
            const SizedBox(height: 16),
            Text(
              'Không tìm thấy từ nào',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: filteredWords.length,
      itemBuilder: (context, index) {
        final word = filteredWords[index];
        final mainIndex = _words.indexWhere((w) => w.word == word.word);
        final isSelected = mainIndex >= 0 && _words[mainIndex].selected;

        return _buildWordCard(word, index, isSelected);
      },
    );
  }

  Widget _buildWordCard(ExtractedWord word, int index, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => _toggleWordSelection(index),
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
                // Checkbox
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.border,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : null,
                ),
                const SizedBox(width: 14),

                // Word info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Word & phonetic
                      Row(
                        children: [
                          Text(
                            word.word,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (word.phonetic != null && word.phonetic!.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Text(
                              word.phonetic!,
                              style: TextStyle(
                                color: AppColors.textGray,
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Meaning or part of speech
                      if (word.meaning != null && word.meaning!.isNotEmpty)
                        Text(
                          word.meaning!,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        )
                      else if (word.partOfSpeech != null)
                        Text(
                          word.partOfSpeech!,
                          style: TextStyle(
                            color: AppColors.textGray,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                ),

                // Dictionary status badge
                if (word.foundInDictionary)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, color: AppColors.success, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          'Từ điển',
                          style: TextStyle(
                            color: AppColors.success,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.help_outline, color: AppColors.warning, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          'Chưa biết',
                          style: TextStyle(
                            color: AppColors.warning,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    final hasCategory = widget.initialCategoryId != null;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
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
          // Selected count
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$_selectedCount từ đã chọn',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                hasCategory
                    ? 'Tạo thẻ vào "${widget.initialCategoryName}"'
                    : 'Nhấn tiếp tục để chọn chủ đề',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const Spacer(),

          // Continue button
          ElevatedButton(
            onPressed: _selectedCount > 0 ? _onContinue : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: hasCategory ? AppColors.success : AppColors.primary,
              disabledBackgroundColor: (hasCategory ? AppColors.success : AppColors.primary).withOpacity(0.5),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  hasCategory ? 'Tạo thẻ' : 'Tiếp tục',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  hasCategory ? Icons.check : Icons.arrow_forward,
                  color: Colors.white,
                  size: 20,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}