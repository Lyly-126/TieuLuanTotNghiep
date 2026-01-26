import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../config/app_colors.dart';

/// Màn hình nhập 100 từ vựng và xuất PDF template
///
/// Flow:
/// 1. User nhập tối đa 100 từ vào grid
/// 2. Nhấn "Xuất PDF" để tạo PDF chuẩn với marker
/// 3. Chọn: In/Xem trước, Chia sẻ, hoặc Quét ngay

class VocabularyInputScreen extends StatefulWidget {
  final int? initialCategoryId;
  final String? initialCategoryName;

  const VocabularyInputScreen({
    super.key,
    this.initialCategoryId,
    this.initialCategoryName,
  });

  @override
  State<VocabularyInputScreen> createState() => _VocabularyInputScreenState();
}

class _VocabularyInputScreenState extends State<VocabularyInputScreen>
    with SingleTickerProviderStateMixin {

  // Controllers
  final TextEditingController _titleController = TextEditingController(text: 'My Vocabulary List');
  final TextEditingController _dateController = TextEditingController();
  final List<TextEditingController> _wordControllers = List.generate(100, (_) => TextEditingController());
  final ScrollController _scrollController = ScrollController();

  // State
  bool _isExporting = false;
  int _filledCount = 0;

  // Animation
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  // Marker để nhận diện PDF từ app
  static const String APP_PDF_MARKER = 'FLASHCARD_APP_TEMPLATE';

  // Các ô được highlight (tạo pattern đẹp - góc và đường chéo)
  final Set<int> _highlightedBoxes = {
    0, 4, 9,           // Row 1
    10, 19,            // Row 2
    20, 24, 29,        // Row 3
    30, 39,            // Row 4
    40, 44, 49,        // Row 5
    50, 59,            // Row 6
    60, 64, 69,        // Row 7
    70, 79,            // Row 8
    80, 84, 89,        // Row 9
    90, 95, 99,        // Row 10
  };

  @override
  void initState() {
    super.initState();

    // Set ngày hiện tại
    final now = DateTime.now();
    _dateController.text = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';

    // Animation
    _animController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
    _animController.forward();

    // Listen to changes để đếm số từ đã nhập
    for (var controller in _wordControllers) {
      controller.addListener(_updateFilledCount);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _dateController.dispose();
    _scrollController.dispose();
    _animController.dispose();
    for (var controller in _wordControllers) {
      controller.removeListener(_updateFilledCount);
      controller.dispose();
    }
    super.dispose();
  }

  void _updateFilledCount() {
    final count = _wordControllers.where((c) => c.text.trim().isNotEmpty).length;
    if (count != _filledCount) {
      setState(() => _filledCount = count);
    }
  }

  // ==================== ACTIONS ====================

  /// Xuất PDF và hiển thị options
  Future<void> _exportToPdf() async {
    if (_filledCount == 0) {
      _showSnackBar('Vui lòng nhập ít nhất 1 từ vựng', isError: true);
      return;
    }

    setState(() => _isExporting = true);

    try {
      final pdfBytes = await _generatePdf();

      if (mounted) {
        _showExportOptionsDialog(pdfBytes);
      }
    } catch (e) {
      _showSnackBar('Lỗi tạo PDF: $e', isError: true);
    } finally {
      setState(() => _isExporting = false);
    }
  }

  /// Dialog chọn hành động sau khi tạo PDF
  void _showExportOptionsDialog(Uint8List pdfBytes) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),

            // Success icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_circle, color: AppColors.success, size: 48),
            ),
            const SizedBox(height: 16),

            Text(
              'PDF đã sẵn sàng!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$_filledCount từ vựng • ${_titleController.text}',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),

            const SizedBox(height: 28),

            // Options Grid
            Row(
              children: [
                Expanded(
                  child: _buildExportOptionCard(
                    icon: Icons.print_rounded,
                    title: 'In / Xem',
                    color: AppColors.primary,
                    onTap: () {
                      Navigator.pop(context);
                      _printPdf(pdfBytes);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                // Expanded(
                //   child: _buildExportOptionCard(
                //     icon: Icons.share_rounded,
                //     title: 'Chia sẻ',
                //     color: AppColors.info,
                //     onTap: () {
                //       Navigator.pop(context);
                //       _sharePdf(pdfBytes);
                //     },
                //   ),
                // ),
              ],
            ),

            const SizedBox(height: 16),

            // Primary action - Quét ngay
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _scanPdfDirectly();
                },
                icon: const Icon(Icons.flash_on_rounded),
                label: const Text(
                  'Tạo Flashcard ngay',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.warning,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                ),
              ),
            ),

            const SizedBox(height: 12),

            Text(
              'Bỏ qua bước upload PDF, tạo flashcard trực tiếp!',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textGray,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildExportOptionCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// In/Preview PDF - Dùng Printing package (hoạt động trên cả Web và Mobile)
  Future<void> _printPdf(Uint8List pdfBytes) async {
    await Printing.layoutPdf(
      onLayout: (format) async => pdfBytes,
      name: '${_titleController.text}.pdf',
    );
  }

  /// Chia sẻ PDF - Dùng Printing package
  // Future<void> _sharePdf(Uint8List pdfBytes) async {
  //   await Printing.sharePdf(
  //     bytes: pdfBytes,
  //     filename: '${_titleController.text.replaceAll(' ', '_')}.pdf',
  //   );
  // }

  /// Quét PDF trực tiếp (không cần upload lại)
  void _scanPdfDirectly() {
    final words = _wordControllers
        .map((c) => c.text.trim())
        .where((w) => w.isNotEmpty)
        .toList();

    if (words.isEmpty) {
      _showSnackBar('Không có từ vựng nào để tạo flashcard', isError: true);
      return;
    }

    // Trả về data cho màn hình trước
    Navigator.pop(context, {
      'words': words,
      'title': _titleController.text,
      'categoryId': widget.initialCategoryId,
      'categoryName': widget.initialCategoryName,
    });
  }

  /// Clear tất cả
  void _clearAll() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.warning),
            const SizedBox(width: 8),
            const Text('Xóa tất cả?'),
          ],
        ),
        content: const Text('Bạn có chắc muốn xóa toàn bộ từ vựng đã nhập?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              for (var controller in _wordControllers) {
                controller.clear();
              }
              _updateFilledCount();
              _showSnackBar('Đã xóa tất cả');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xóa tất cả'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ==================== PDF GENERATION (IMPROVED) ====================

  Future<Uint8List> _generatePdf() async {
    final pdf = pw.Document(
      creator: 'FlashcardApp',
      author: 'FlashcardApp',
      subject: APP_PDF_MARKER,
      keywords: '$APP_PDF_MARKER, vocabulary, flashcard',
      title: _titleController.text,
    );

    // Colors matching app theme
    final primaryColor = PdfColor.fromHex('#22C55E');
    final primaryDark = PdfColor.fromHex('#064E3B');
    final primaryLight = PdfColor.fromHex('#DCFCE7');
    final accentYellow = PdfColor.fromHex('#FEF3C7');
    final accentPink = PdfColor.fromHex('#FCE7F3');
    final borderColor = PdfColor.fromHex('#BBF7D0');
    final bgColor = PdfColor.fromHex('#F0FDF4');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (pw.Context context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              color: bgColor,
            ),
            child: pw.Padding(
              padding: const pw.EdgeInsets.all(24),
              child: pw.Container(
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  borderRadius: pw.BorderRadius.circular(16),
                  border: pw.Border.all(color: borderColor, width: 2),
                ),
                child: pw.Padding(
                  padding: const pw.EdgeInsets.all(20),
                  child: pw.Column(
                    children: [
                      // ===== HEADER =====
                      _buildPdfHeader(primaryColor, primaryDark, primaryLight, accentYellow, accentPink),

                      pw.SizedBox(height: 16),

                      // ===== WORD GRID =====
                      pw.Expanded(
                        child: _buildPdfWordGrid(primaryColor, primaryDark, primaryLight, borderColor),
                      ),

                      pw.SizedBox(height: 12),

                      // ===== FOOTER =====
                      _buildPdfFooter(primaryColor, primaryDark),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildPdfHeader(PdfColor primaryColor, PdfColor primaryDark, PdfColor primaryLight, PdfColor accentYellow, PdfColor accentPink) {
    return pw.Column(
      children: [
        // Decorative circles row
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            _buildDecoCircle(primaryColor, 20),
            _buildDecoCircle(accentYellow, 16),
            _buildDecoCircle(primaryLight, 14),
            _buildDecoCircle(accentPink, 16),
            _buildDecoCircle(primaryColor, 20),
          ],
        ),

        pw.SizedBox(height: 14),

        // Hidden marker for OCR
        pw.Text(
          APP_PDF_MARKER,
          style: pw.TextStyle(fontSize: 0.5, color: PdfColors.white),
        ),

        // Title
        pw.Text(
          _titleController.text.toUpperCase(),
          style: pw.TextStyle(
            fontSize: 22,
            fontWeight: pw.FontWeight.bold,
            color: primaryDark,
            letterSpacing: 1.5,
          ),
          textAlign: pw.TextAlign.center,
        ),

        pw.SizedBox(height: 6),

        // Decorative line
        pw.Container(
          width: 80,
          height: 3,
          decoration: pw.BoxDecoration(
            color: primaryColor,
            borderRadius: pw.BorderRadius.circular(2),
          ),
        ),

        pw.SizedBox(height: 12),

        // Info badges
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            _buildInfoBadge(_dateController.text, primaryLight, primaryDark),
            pw.SizedBox(width: 12),
            _buildInfoBadge('$_filledCount words', primaryLight, primaryDark),
            pw.SizedBox(width: 12),
            _buildInfoBadge('100 slots', accentYellow, PdfColor.fromHex('#92400E')),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildDecoCircle(PdfColor color, double size) {
    return pw.Container(
      width: size,
      height: size,
      decoration: pw.BoxDecoration(
        color: color,
        shape: pw.BoxShape.circle,
      ),
    );
  }

  pw.Widget _buildInfoBadge(String text, PdfColor bgColor, PdfColor textColor) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: pw.BoxDecoration(
        color: bgColor,
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  pw.Widget _buildPdfWordGrid(PdfColor primaryColor, PdfColor primaryDark, PdfColor primaryLight, PdfColor borderColor) {
    return pw.GridView(
      crossAxisCount: 10,
      childAspectRatio: 1,
      children: List.generate(100, (index) {
        final isHighlighted = _highlightedBoxes.contains(index);
        final word = _wordControllers[index].text.trim();
        final hasWord = word.isNotEmpty;

        return pw.Container(
          margin: const pw.EdgeInsets.all(1.5),
          decoration: pw.BoxDecoration(
            color: isHighlighted
                ? primaryLight
                : (hasWord ? PdfColors.white : PdfColor.fromHex('#F9FAFB')),
            border: pw.Border.all(
              color: hasWord ? primaryColor : borderColor,
              width: hasWord ? 1.5 : 0.8,
            ),
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Stack(
            children: [
              // Number - ✅ FIX: Bỏ background transparent, dùng điều kiện
              pw.Positioned(
                left: 2,
                top: 1,
                child: pw.Text(
                  '${index + 1}',
                  style: pw.TextStyle(
                    fontSize: 5,
                    fontWeight: pw.FontWeight.bold,
                    color: hasWord ? primaryDark : PdfColors.grey400,
                  ),
                ),
              ),
              // Word
              if (hasWord)
                pw.Center(
                  child: pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 7, left: 2, right: 2, bottom: 2),
                    child: pw.Text(
                      word,
                      style: pw.TextStyle(
                        fontSize: 7,
                        fontWeight: pw.FontWeight.bold,
                        color: primaryDark,
                      ),
                      textAlign: pw.TextAlign.center,
                      maxLines: 2,
                    ),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  pw.Widget _buildPdfFooter(PdfColor primaryColor, PdfColor primaryDark) {
    return pw.Column(
      children: [
        // Decorative elements
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            _buildDecoSquare(PdfColor.fromHex('#FFD700'), 12),
            pw.SizedBox(width: 6),
            _buildDecoCircle(primaryColor, 14),
            pw.SizedBox(width: 6),
            _buildDecoSquare(primaryDark, 12),
            pw.SizedBox(width: 6),
            _buildDecoCircle(PdfColor.fromHex('#FFD700'), 14),
            pw.SizedBox(width: 6),
            _buildDecoSquare(primaryColor, 12),
          ],
        ),

        pw.SizedBox(height: 8),

        // Footer text
        pw.Text(
          'Created with FlashcardApp',
          style: pw.TextStyle(
            fontSize: 8,
            color: PdfColors.grey500,
            fontStyle: pw.FontStyle.italic,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          APP_PDF_MARKER,
          style: pw.TextStyle(
            fontSize: 6,
            color: PdfColors.grey300,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildDecoSquare(PdfColor color, double size) {
    return pw.Container(
      width: size,
      height: size,
      decoration: pw.BoxDecoration(
        color: color,
        borderRadius: pw.BorderRadius.circular(3),
      ),
    );
  }

  // ==================== UI ====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildWordGrid()),
            _buildBottomBar(),
          ],
        ),
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
            'Nhập từ vựng',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          Text(
            'Tối đa 100 từ',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
      actions: [
        if (_filledCount > 0)
          TextButton.icon(
            onPressed: _clearAll,
            icon: Icon(Icons.delete_outline, color: AppColors.error, size: 20),
            label: Text('Xóa', style: TextStyle(color: AppColors.error)),
          ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        children: [
          // Title input
          TextField(
            controller: _titleController,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              labelText: 'Tiêu đề danh sách',
              labelStyle: TextStyle(color: AppColors.textSecondary),
              prefixIcon: Icon(Icons.title, color: AppColors.primary),
              filled: true,
              fillColor: AppColors.inputBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Stats row
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.edit_note_rounded,
                  value: '$_filledCount',
                  label: '/ 100 từ',
                  color: AppColors.primary,
                  bgColor: AppColors.primaryLight,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.calendar_today_rounded,
                  value: _dateController.text,
                  label: '',
                  color: AppColors.secondary,
                  bgColor: AppColors.secondaryLight,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Progress bar with percentage
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: _filledCount / 100,
                    backgroundColor: AppColors.border,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _filledCount >= 100 ? AppColors.success : AppColors.primary,
                    ),
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _filledCount >= 100
                      ? AppColors.success.withOpacity(0.1)
                      : AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$_filledCount%',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: _filledCount >= 100 ? AppColors.success : AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          if (label.isNotEmpty)
            Text(
              ' $label',
              style: TextStyle(
                fontSize: 13,
                color: color.withOpacity(0.7),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWordGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        int crossAxisCount;
        double fontSize;

        if (screenWidth >= 900) {
          crossAxisCount = 10;
          fontSize = 12;
        } else if (screenWidth >= 600) {
          crossAxisCount = 8;
          fontSize = 11;
        } else if (screenWidth >= 400) {
          crossAxisCount = 5;
          fontSize = 11;
        } else {
          crossAxisCount = 4;
          fontSize = 10;
        }

        return GridView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 1,
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
          ),
          itemCount: 100,
          itemBuilder: (context, index) => _buildWordCell(index, fontSize),
        );
      },
    );
  }

  Widget _buildWordCell(int index, double fontSize) {
    final isHighlighted = _highlightedBoxes.contains(index);
    final hasContent = _wordControllers[index].text.isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isHighlighted
            ? AppColors.primaryLight
            : (hasContent ? Colors.white : AppColors.inputBackground),
        border: Border.all(
          color: hasContent ? AppColors.primary : AppColors.border,
          width: hasContent ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: hasContent
            ? [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.15),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ]
            : null,
      ),
      child: Stack(
        children: [
          // Number badge
          Positioned(
            left: 3,
            top: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: hasContent
                    ? AppColors.primary.withOpacity(0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: hasContent ? AppColors.primary : AppColors.textGray,
                ),
              ),
            ),
          ),

          // Text field
          Padding(
            padding: const EdgeInsets.only(top: 14, left: 3, right: 3, bottom: 3),
            child: TextField(
              controller: _wordControllers[index],
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                hintText: '•••',
                hintStyle: TextStyle(
                  color: AppColors.textLight,
                  fontWeight: FontWeight.normal,
                  fontSize: 10,
                ),
              ),
              maxLines: 2,
              textInputAction: TextInputAction.next,
              onSubmitted: (_) {
                if (index < 99) {
                  FocusScope.of(context).nextFocus();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Status chip
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _filledCount > 0 ? AppColors.primaryLight : AppColors.background,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _filledCount > 0 ? AppColors.primary.withOpacity(0.3) : AppColors.border,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _filledCount > 0 ? Icons.check_circle : Icons.info_outline,
                    size: 18,
                    color: _filledCount > 0 ? AppColors.primary : AppColors.textGray,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _filledCount > 0 ? 'Sẵn sàng' : 'Nhập từ...',
                    style: TextStyle(
                      fontSize: 13,
                      color: _filledCount > 0 ? AppColors.primaryDark : AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Export button
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isExporting || _filledCount == 0 ? null : _exportToPdf,
                icon: _isExporting
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : const Icon(Icons.picture_as_pdf_rounded),
                label: Text(
                  _isExporting ? 'Đang tạo...' : 'Xuất PDF',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _filledCount > 0 ? AppColors.primary : AppColors.disabled,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.disabled,
                  disabledForegroundColor: AppColors.disabledText,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: _filledCount > 0 ? 2 : 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}