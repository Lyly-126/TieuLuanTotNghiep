import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';
import '../../models/flashcard_model.dart';
import '../../services/flash_card_service.dart';

/// 🎨 Màn hình chỉnh sửa flashcard - Quizlet style
class FlashcardEditScreen extends StatefulWidget {
  final FlashcardModel flashcard;
  final int categoryId;

  const FlashcardEditScreen({
    Key? key,
    required this.flashcard,
    required this.categoryId,
  }) : super(key: key);

  @override
  State<FlashcardEditScreen> createState() => _FlashcardEditScreenState();
}

class _FlashcardEditScreenState extends State<FlashcardEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _termController;
  late TextEditingController _meaningController;
  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    print('📱 [SCREEN] $runtimeType');
    _termController = TextEditingController(text: widget.flashcard.question);
    _meaningController = TextEditingController(text: widget.flashcard.answer);

    // Track changes
    _termController.addListener(_onTextChanged);
    _meaningController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final hasChanges = _termController.text != widget.flashcard.question ||
        _meaningController.text != widget.flashcard.answer;

    if (hasChanges != _hasChanges) {
      setState(() => _hasChanges = hasChanges);
    }
  }

  @override
  void dispose() {
    _termController.dispose();
    _meaningController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_hasChanges) {
      Navigator.pop(context);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FlashcardService.updateFlashcard(
        widget.flashcard.id,
        term: _termController.text.trim(),
        meaning: _meaningController.text.trim(),
        categoryId: widget.categoryId,
      );

      if (!mounted) return;
      _showSnackBar('Đã lưu thay đổi', isError: false);
      Navigator.pop(context, true); // Return true to indicate changes saved
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Lỗi: ${e.toString()}', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteFlashcard() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc muốn xóa thẻ này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      await FlashcardService.deleteFlashcard(widget.flashcard.id);
      if (!mounted) return;
      _showSnackBar('Đã xóa thẻ', isError: false);
      Navigator.pop(context, true); // Return true to indicate deletion
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Lỗi: ${e.toString()}', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    final shouldDiscard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hủy thay đổi?'),
        content: const Text('Các thay đổi chưa được lưu sẽ bị mất.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Tiếp tục chỉnh sửa'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hủy'),
          ),
        ],
      ),
    );

    return shouldDiscard ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: _buildAppBar(),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildBody(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.close, color: Colors.black87),
        onPressed: () async {
          if (await _onWillPop()) {
            if (mounted) Navigator.pop(context);
          }
        },
      ),
      title: Text(
        'Chỉnh sửa thẻ',
        style: AppTextStyles.heading2.copyWith(
          color: Colors.black87,
          fontSize: 18,
        ),
      ),
      actions: [
        // Delete button
        IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: _deleteFlashcard,
        ),
        // Save button
        TextButton(
          onPressed: _hasChanges && !_isLoading ? _saveChanges : null,
          child: Text(
            'Lưu',
            style: AppTextStyles.body.copyWith(
              color: _hasChanges && !_isLoading
                  ? AppColors.primary
                  : Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildBody() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Info card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Chỉnh sửa nội dung của thẻ bên dưới',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Term (Front) card
          _buildCardSection(
            title: 'Thuật ngữ (Mặt trước)',
            icon: Icons.text_fields,
            child: TextFormField(
              controller: _termController,
              style: AppTextStyles.body.copyWith(fontSize: 16),
              maxLines: null,
              decoration: InputDecoration(
                hintText: 'Nhập thuật ngữ, từ vựng...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.primary,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập thuật ngữ';
                }
                return null;
              },
              textInputAction: TextInputAction.next,
            ),
          ),
          const SizedBox(height: 24),

          // Meaning (Back) card
          _buildCardSection(
            title: 'Định nghĩa (Mặt sau)',
            icon: Icons.description,
            child: TextFormField(
              controller: _meaningController,
              style: AppTextStyles.body.copyWith(fontSize: 16),
              maxLines: null,
              minLines: 3,
              decoration: InputDecoration(
                hintText: 'Nhập định nghĩa, ý nghĩa...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.primary,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập định nghĩa';
                }
                return null;
              },
              textInputAction: TextInputAction.done,
            ),
          ),

          const SizedBox(height: 32),

          // Save button (large)
          if (_hasChanges)
            ElevatedButton(
              onPressed: _isLoading ? null : _saveChanges,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: _isLoading
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
                  : const Text(
                'Lưu thay đổi',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCardSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}