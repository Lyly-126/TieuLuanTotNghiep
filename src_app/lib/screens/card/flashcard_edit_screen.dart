import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';
import '../../models/flashcard_model.dart';
import '../../services/flash_card_service.dart';

/// 🎨 Màn hình chỉnh sửa flashcard
/// ✅ Sửa được: từ vựng, nghĩa, phiên âm, loại từ EN, loại từ VN
/// ✅ KHÔNG sửa được: hình ảnh
class FlashcardEditScreen extends StatefulWidget {
  final FlashcardModel flashcard;
  final int categoryId;

  const FlashcardEditScreen({Key? key, required this.flashcard, required this.categoryId}) : super(key: key);

  @override
  State<FlashcardEditScreen> createState() => _FlashcardEditScreenState();
}

class _FlashcardEditScreenState extends State<FlashcardEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _wordController;
  late TextEditingController _meaningController;
  late TextEditingController _phoneticController;
  late TextEditingController _partOfSpeechController;
  late TextEditingController _partOfSpeechViController;
  bool _isLoading = false;
  bool _hasChanges = false;

  final List<Map<String, String>> _posOptions = [
    {'en': 'noun', 'vi': 'Danh từ'}, {'en': 'verb', 'vi': 'Động từ'},
    {'en': 'adjective', 'vi': 'Tính từ'}, {'en': 'adverb', 'vi': 'Trạng từ'},
    {'en': 'pronoun', 'vi': 'Đại từ'}, {'en': 'preposition', 'vi': 'Giới từ'},
    {'en': 'conjunction', 'vi': 'Liên từ'}, {'en': 'interjection', 'vi': 'Thán từ'},
    {'en': 'phrase', 'vi': 'Cụm từ'},
  ];

  @override
  void initState() {
    super.initState();
    _wordController = TextEditingController(text: widget.flashcard.word);
    _meaningController = TextEditingController(text: _getMainMeaning(widget.flashcard.meaning));
    _phoneticController = TextEditingController(text: widget.flashcard.phonetic ?? '');
    _partOfSpeechController = TextEditingController(text: widget.flashcard.partOfSpeech ?? '');
    _partOfSpeechViController = TextEditingController(text: widget.flashcard.partOfSpeechVi ?? '');
    _wordController.addListener(_checkChanges);
    _meaningController.addListener(_checkChanges);
    _phoneticController.addListener(_checkChanges);
    _partOfSpeechController.addListener(_checkChanges);
    _partOfSpeechViController.addListener(_checkChanges);
    print('📱 [SCREEN] $runtimeType');
  }

  String _getMainMeaning(String meaning) {
    if (meaning.isEmpty) return '';
    if (meaning.contains('\n\n')) {
      for (var part in meaning.split('\n\n')) {
        final t = part.trim();
        if (!t.startsWith('📖') && !t.startsWith('📝') && !t.toLowerCase().startsWith('example')) return t;
      }
    }
    if (meaning.contains('📖') || meaning.contains('📝')) {
      final i1 = meaning.indexOf('📖'), i2 = meaning.indexOf('📝');
      final min = i1 == -1 ? i2 : (i2 == -1 ? i1 : (i1 < i2 ? i1 : i2));
      if (min > 0) return meaning.substring(0, min).trim();
    }
    return meaning.trim();
  }

  void _checkChanges() {
    final changed = _wordController.text != widget.flashcard.word ||
        _meaningController.text != _getMainMeaning(widget.flashcard.meaning) ||
        _phoneticController.text != (widget.flashcard.phonetic ?? '') ||
        _partOfSpeechController.text != (widget.flashcard.partOfSpeech ?? '') ||
        _partOfSpeechViController.text != (widget.flashcard.partOfSpeechVi ?? '');
    if (changed != _hasChanges) setState(() => _hasChanges = changed);
  }

  @override
  void dispose() {
    _wordController.dispose(); _meaningController.dispose(); _phoneticController.dispose();
    _partOfSpeechController.dispose(); _partOfSpeechViController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_hasChanges) { Navigator.pop(context); return; }
    setState(() => _isLoading = true);
    try {
      await FlashcardService.updateFlashcard(widget.flashcard.id,
        word: _wordController.text.trim(),
        meaning: _meaningController.text.trim(),
        phonetic: _phoneticController.text.trim().isEmpty ? null : _phoneticController.text.trim(),
        partOfSpeech: _partOfSpeechController.text.trim().isEmpty ? null : _partOfSpeechController.text.trim(),
        partOfSpeechVi: _partOfSpeechViController.text.trim().isEmpty ? null : _partOfSpeechViController.text.trim(),
        categoryId: widget.categoryId,
      );
      if (mounted) { _snackBar('Đã lưu', false); Navigator.pop(context, true); }
    } catch (e) { if (mounted) _snackBar('Lỗi: $e', true); }
    finally { if (mounted) setState(() => _isLoading = false); }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(context: context, builder: (c) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Xóa thẻ?'), content: const Text('Bạn có chắc muốn xóa?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Hủy')),
        ElevatedButton(onPressed: () => Navigator.pop(c, true), style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white), child: const Text('Xóa')),
      ],
    ));
    if (ok != true) return;
    setState(() => _isLoading = true);
    try {
      await FlashcardService.deleteFlashcard(widget.flashcard.id);
      if (mounted) { _snackBar('Đã xóa', false); Navigator.pop(context, true); }
    } catch (e) { if (mounted) _snackBar('Lỗi: $e', true); }
    finally { if (mounted) setState(() => _isLoading = false); }
  }

  void _snackBar(String msg, bool err) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg), backgroundColor: err ? AppColors.error : AppColors.primary,
    behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  ));

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;
    return await showDialog<bool>(context: context, builder: (c) => AlertDialog(
      title: const Text('Hủy thay đổi?'), content: const Text('Thay đổi chưa lưu sẽ mất.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Tiếp tục sửa')),
        TextButton(onPressed: () => Navigator.pop(c, true), style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text('Hủy')),
      ],
    )) ?? false;
  }

  void _selectPos() => showModalBottomSheet(context: context,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (c) => Padding(padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Chọn loại từ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 16),
      Wrap(spacing: 8, runSpacing: 8, children: _posOptions.map((o) {
        final sel = _partOfSpeechController.text.toLowerCase() == o['en']!.toLowerCase();
        return GestureDetector(
          onTap: () { setState(() { _partOfSpeechController.text = o['en']!; _partOfSpeechViController.text = o['vi']!; }); Navigator.pop(c); },
          child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(color: sel ? AppColors.primary : Colors.grey.shade100, borderRadius: BorderRadius.circular(20), border: Border.all(color: sel ? AppColors.primary : Colors.grey.shade300)),
            child: Text('${o['en']} (${o['vi']})', style: TextStyle(color: sel ? Colors.white : AppColors.textPrimary, fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
          ),
        );
      }).toList()),
      const SizedBox(height: 20),
    ])),
  );

  @override
  Widget build(BuildContext context) => WillPopScope(onWillPop: _onWillPop, child: Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      backgroundColor: Colors.white, elevation: 0,
      leading: IconButton(icon: const Icon(Icons.close, color: Colors.black87), onPressed: () async { if (await _onWillPop() && mounted) Navigator.pop(context); }),
      title: const Text('Chỉnh sửa thẻ', style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold)),
      actions: [
        IconButton(icon: const Icon(Icons.delete_outline, color: AppColors.error), onPressed: _delete),
        TextButton(onPressed: _hasChanges && !_isLoading ? _save : null, child: Text('Lưu', style: TextStyle(color: _hasChanges && !_isLoading ? AppColors.primary : Colors.grey, fontWeight: FontWeight.bold, fontSize: 16))),
        const SizedBox(width: 8),
      ],
    ),
    body: _isLoading ? const Center(child: CircularProgressIndicator()) : Form(key: _formKey, child: ListView(padding: const EdgeInsets.all(20), children: [
      // Image (read-only)
      if (widget.flashcard.imageUrl != null && widget.flashcard.imageUrl!.isNotEmpty) ...[
        Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(widget.flashcard.imageUrl!, height: 160, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(height: 160, color: Colors.grey.shade200, child: const Icon(Icons.image_not_supported, size: 48, color: Colors.grey))),
            ),
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16))),
              child: Row(children: [Icon(Icons.info_outline, size: 16, color: AppColors.textGray), const SizedBox(width: 8), Text('Hình ảnh không thể chỉnh sửa', style: TextStyle(fontSize: 13, color: AppColors.textGray))]),
            ),
          ]),
        ),
        const SizedBox(height: 24),
      ],

      // MẶT TRƯỚC
      _header('MẶT TRƯỚC', Icons.flip_to_front), const SizedBox(height: 12),
      _field(_wordController, 'Từ vựng', 'Nhập từ tiếng Anh', Icons.text_fields, validator: (v) => v == null || v.trim().isEmpty ? 'Bắt buộc' : null),
      const SizedBox(height: 16),
      GestureDetector(onTap: _selectPos, child: AbsorbPointer(child: _field(_partOfSpeechController, 'Loại từ (EN)', 'Chọn loại từ', Icons.category, suffix: Icons.arrow_drop_down))),
      const SizedBox(height: 16),
      _field(_phoneticController, 'Phiên âm', '/həˈloʊ/', Icons.record_voice_over),
      const SizedBox(height: 32),

      // MẶT SAU
      _header('MẶT SAU', Icons.flip_to_back), const SizedBox(height: 12),
      _field(_meaningController, 'Nghĩa tiếng Việt', 'Nhập nghĩa', Icons.translate, lines: 3, validator: (v) => v == null || v.trim().isEmpty ? 'Bắt buộc' : null),
      const SizedBox(height: 16),
      _field(_partOfSpeechViController, 'Loại từ (VN)', 'Danh từ, Động từ...', Icons.category_outlined),
      const SizedBox(height: 32),

      if (_hasChanges) ElevatedButton(onPressed: _isLoading ? null : _save,
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        child: _isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white))) : const Text('Lưu thay đổi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      const SizedBox(height: 40),
    ])),
  ));

  Widget _header(String t, IconData i) => Row(children: [
    Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(i, color: AppColors.primary, size: 20)),
    const SizedBox(width: 12), Text(t, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
  ]);

  Widget _field(TextEditingController c, String label, String hint, IconData icon, {int lines = 1, IconData? suffix, String? Function(String?)? validator}) => TextFormField(
    controller: c, maxLines: lines, validator: validator,
    decoration: InputDecoration(
      labelText: label, hintText: hint, prefixIcon: Icon(icon, color: AppColors.primary),
      suffixIcon: suffix != null ? Icon(suffix, color: AppColors.textGray) : null,
      filled: true, fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.primary, width: 2)),
      contentPadding: const EdgeInsets.all(16),
    ),
  );
}