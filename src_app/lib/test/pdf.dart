import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

void main() => runApp(MaterialApp(
  home: Happy100WordsPage(),
  debugShowCheckedModeBanner: false,
));

class Happy100WordsPage extends StatefulWidget {
  @override
  _Happy100WordsPageState createState() => _Happy100WordsPageState();
}

class _Happy100WordsPageState extends State<Happy100WordsPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final List<TextEditingController> wordControllers = List.generate(100, (_) => TextEditingController());

  // Các ô được tô màu xanh nhạt (theo hình mẫu)
  final Set<int> highlightedBoxes = {
    2, 8, 16, 18, 24, 32, 40, 48, 56, 57, 64, 72, 80, 88, 96
  };

  @override
  void dispose() {
    nameController.dispose();
    dateController.dispose();
    for (var controller in wordControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: Color(0xFFE8F3ED),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 12 : 20,
                  vertical: isMobile ? 12 : 20,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.all(isMobile ? 16 : 24),
                  child: Column(
                    children: [
                      // Decorations ở góc
                      _buildDecorations(),

                      SizedBox(height: isMobile ? 12 : 20),

                      // Title
                      Text(
                        "MY HAPPY 100 WORDS",
                        style: TextStyle(
                          fontSize: isMobile ? 20 : 26,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D5F4D),
                          letterSpacing: isMobile ? 0.5 : 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      SizedBox(height: isMobile ? 16 : 30),

                      // Name and Date inputs
                      isMobile
                          ? Column(
                        children: [
                          _buildInputField("NAME:", nameController),
                          SizedBox(height: 12),
                          _buildInputField("DATE:", dateController),
                        ],
                      )
                          : Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: _buildInputField("NAME:", nameController),
                          ),
                          SizedBox(width: 20),
                          Expanded(
                            flex: 2,
                            child: _buildInputField("DATE:", dateController),
                          ),
                        ],
                      ),

                      SizedBox(height: isMobile ? 12 : 20),

                      // Subtitle
                      Text(
                        "Fill in 100 words that bring you joy!",
                        style: TextStyle(
                          fontSize: isMobile ? 12 : 14,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      SizedBox(height: isMobile ? 12 : 20),

                      // Grid 100 ô
                      _buildWordGrid(),

                      SizedBox(height: isMobile ? 12 : 20),

                      // Bottom decorations
                      _buildBottomDecorations(),
                    ],
                  ),
                ),
              ),
            ),

            // Button xuất PDF
            Container(
              padding: EdgeInsets.all(isMobile ? 12 : 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _exportToPdf,
                  icon: Icon(Icons.picture_as_pdf, size: isMobile ? 20 : 24),
                  label: Text(
                    "Export to PDF",
                    style: TextStyle(fontSize: isMobile ? 14 : 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF7FB5A0),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      vertical: isMobile ? 14 : 16,
                      horizontal: isMobile ? 24 : 32,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDecorations() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final iconSize = isMobile ? 20.0 : 30.0;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(Icons.wb_sunny_outlined, color: Color(0xFFFFD700), size: iconSize),
            Icon(Icons.yard, color: Color(0xFF7FB5A0), size: iconSize),
            Icon(Icons.music_note, color: Color(0xFF7FB5A0), size: iconSize),
            Icon(Icons.palette_outlined, color: Color(0xFFFFB6C1), size: iconSize),
          ],
        );
      },
    );
  }

  Widget _buildBottomDecorations() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final iconSize = isMobile ? 20.0 : 28.0;
        final boxSize = isMobile ? 15.0 : 20.0;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Icon(Icons.lightbulb_outline, color: Color(0xFFFFD700), size: iconSize),
            Container(
              width: boxSize,
              height: boxSize,
              decoration: BoxDecoration(
                color: Color(0xFF2D5F4D),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            Container(
              width: boxSize,
              height: boxSize,
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            Icon(Icons.note, color: Color(0xFF7FB5A0), size: iconSize),
            Icon(Icons.wb_sunny_outlined, color: Color(0xFFFFD700), size: iconSize),
            Icon(Icons.lightbulb_outline, color: Color(0xFFFFD700), size: iconSize),
          ],
        );
      },
    );
  }

  Widget _buildInputField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D5F4D),
          ),
        ),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(vertical: 8),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey[400]!),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF7FB5A0), width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWordGrid() {
    // Tính toán số cột dựa trên chiều rộng màn hình
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        int crossAxisCount = 10; // Mặc định cho tablet/desktop
        double fontSize = 10;
        double numberSize = 8;

        if (screenWidth < 360) {
          // Màn hình rất nhỏ
          crossAxisCount = 5;
          fontSize = 9;
          numberSize = 7;
        } else if (screenWidth < 600) {
          // Điện thoại thông thường
          crossAxisCount = 5;
          fontSize = 10;
          numberSize = 8;
        } else if (screenWidth < 900) {
          // Điện thoại lớn / tablet nhỏ
          crossAxisCount = 8;
          fontSize = 11;
          numberSize = 8;
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 1,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
          ),
          itemCount: 100,
          itemBuilder: (context, index) {
            final isHighlighted = highlightedBoxes.contains(index);
            return Container(
              decoration: BoxDecoration(
                color: isHighlighted ? Color(0xFFD4E8DD) : Colors.white,
                border: Border.all(
                  color: Color(0xFFA8C9B8),
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Stack(
                children: [
                  // Số thứ tự ở góc
                  Positioned(
                    left: 2,
                    top: 1,
                    child: Text(
                      "${index + 1}",
                      style: TextStyle(
                        fontSize: numberSize,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  // TextField để nhập từ
                  Padding(
                    padding: EdgeInsets.only(top: 10, left: 3, right: 3, bottom: 3),
                    child: TextField(
                      controller: wordControllers[index],
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _exportToPdf() async {
    final pdf = await _generatePdf();
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf);
  }

  Future<Uint8List> _generatePdf() async {
    final pdf = pw.Document();

    final primaryColor = PdfColor.fromHex('#A8C9B8');
    final darkColor = PdfColor.fromHex('#2D5F4D');
    final lightBg = PdfColor.fromHex('#E8F3ED');
    final highlightColor = PdfColor.fromHex('#D4E8DD');
    final borderColor = PdfColor.fromHex('#7FB5A0');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(0),
        build: (pw.Context context) {
          return pw.Container(
            color: lightBg,
            child: pw.Padding(
              padding: pw.EdgeInsets.all(35),
              child: pw.Container(
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  borderRadius: pw.BorderRadius.circular(24),
                  border: pw.Border.all(color: primaryColor, width: 2),
                ),
                padding: pw.EdgeInsets.symmetric(horizontal: 30, vertical: 28),
                child: pw.Column(
                  children: [
                    // Top Decorations - simple colored circles
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Container(
                          width: 28,
                          height: 28,
                          decoration: pw.BoxDecoration(
                            color: PdfColor.fromHex('#FFD700'),
                            shape: pw.BoxShape.circle,
                          ),
                        ),
                        pw.Container(
                          width: 28,
                          height: 28,
                          decoration: pw.BoxDecoration(
                            color: PdfColor.fromHex('#7FB5A0'),
                            shape: pw.BoxShape.circle,
                          ),
                        ),
                        pw.Container(
                          width: 28,
                          height: 28,
                          decoration: pw.BoxDecoration(
                            color: PdfColor.fromHex('#9DB5A8'),
                            shape: pw.BoxShape.circle,
                          ),
                        ),
                        pw.Container(
                          width: 28,
                          height: 28,
                          decoration: pw.BoxDecoration(
                            color: PdfColor.fromHex('#FFB6C1'),
                            shape: pw.BoxShape.circle,
                          ),
                        ),
                      ],
                    ),

                    pw.SizedBox(height: 18),

                    // Title with underline
                    pw.Column(
                      children: [
                        pw.Text(
                          "MY HAPPY 100 WORDS",
                          style: pw.TextStyle(
                            fontSize: 28,
                            fontWeight: pw.FontWeight.bold,
                            color: darkColor,
                            letterSpacing: 2,
                          ),
                        ),
                        pw.SizedBox(height: 6),
                        pw.Container(
                          width: 120,
                          height: 3,
                          decoration: pw.BoxDecoration(
                            color: borderColor,
                            borderRadius: pw.BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),

                    pw.SizedBox(height: 18),

                    // Name and Date with better styling
                    pw.Row(
                      children: [
                        pw.Expanded(
                          flex: 3,
                          child: pw.Container(
                            padding: pw.EdgeInsets.all(10),
                            decoration: pw.BoxDecoration(
                              color: PdfColor.fromHex('#F7F9F8'),
                              borderRadius: pw.BorderRadius.circular(8),
                              border: pw.Border.all(color: primaryColor, width: 1),
                            ),
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  "NAME:",
                                  style: pw.TextStyle(
                                    fontSize: 9,
                                    fontWeight: pw.FontWeight.bold,
                                    color: darkColor,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                pw.SizedBox(height: 4),
                                pw.Text(
                                  nameController.text.isEmpty ? "_______________" : nameController.text,
                                  style: pw.TextStyle(fontSize: 12, color: PdfColors.grey800),
                                ),
                              ],
                            ),
                          ),
                        ),
                        pw.SizedBox(width: 15),
                        pw.Expanded(
                          flex: 2,
                          child: pw.Container(
                            padding: pw.EdgeInsets.all(10),
                            decoration: pw.BoxDecoration(
                              color: PdfColor.fromHex('#F7F9F8'),
                              borderRadius: pw.BorderRadius.circular(8),
                              border: pw.Border.all(color: primaryColor, width: 1),
                            ),
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  "DATE:",
                                  style: pw.TextStyle(
                                    fontSize: 9,
                                    fontWeight: pw.FontWeight.bold,
                                    color: darkColor,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                pw.SizedBox(height: 4),
                                pw.Text(
                                  dateController.text.isEmpty ? "_________" : dateController.text,
                                  style: pw.TextStyle(fontSize: 12, color: PdfColors.grey800),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    pw.SizedBox(height: 14),

                    pw.Container(
                      padding: pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromHex('#FFF9E6'),
                        borderRadius: pw.BorderRadius.circular(20),
                      ),
                      child: pw.Text(
                        "Fill in 100 words that bring you joy!",
                        style: pw.TextStyle(
                          fontSize: 10,
                          color: PdfColor.fromHex('#8B7355'),
                          fontStyle: pw.FontStyle.italic,
                        ),
                      ),
                    ),

                    pw.SizedBox(height: 14),

                    // Grid with better spacing
                    pw.Expanded(
                      child: pw.GridView(
                        crossAxisCount: 10,
                        childAspectRatio: 1,
                        children: List.generate(100, (index) {
                          final isHighlighted = highlightedBoxes.contains(index);
                          final wordText = wordControllers[index].text;

                          return pw.Container(
                            margin: pw.EdgeInsets.all(1.5),
                            decoration: pw.BoxDecoration(
                              color: isHighlighted ? highlightColor : PdfColors.white,
                              border: pw.Border.all(
                                color: isHighlighted ? borderColor : primaryColor,
                                width: isHighlighted ? 1.5 : 1,
                              ),
                              borderRadius: pw.BorderRadius.circular(5),
                            ),
                            child: pw.Stack(
                              children: [
                                pw.Positioned(
                                  left: 2,
                                  top: 1,
                                  child: pw.Text(
                                    "${index + 1}",
                                    style: pw.TextStyle(
                                      fontSize: 5,
                                      color: PdfColors.grey400,
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                  ),
                                ),
                                if (wordText.isNotEmpty)
                                  pw.Center(
                                    child: pw.Padding(
                                      padding: pw.EdgeInsets.only(top: 8, left: 2, right: 2, bottom: 2),
                                      child: pw.Text(
                                        wordText,
                                        style: pw.TextStyle(
                                          fontSize: 7,
                                          color: PdfColors.grey900,
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
                      ),
                    ),

                    pw.SizedBox(height: 14),

                    // Bottom decorations - simple circles and squares
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                        pw.Container(
                          width: 20,
                          height: 20,
                          decoration: pw.BoxDecoration(
                            color: PdfColor.fromHex('#FFD700'),
                            shape: pw.BoxShape.circle,
                          ),
                        ),
                        pw.SizedBox(width: 12),
                        pw.Container(
                          width: 18,
                          height: 18,
                          decoration: pw.BoxDecoration(
                            color: darkColor,
                            borderRadius: pw.BorderRadius.circular(4),
                          ),
                        ),
                        pw.SizedBox(width: 12),
                        pw.Container(
                          width: 18,
                          height: 18,
                          decoration: pw.BoxDecoration(
                            color: PdfColors.grey800,
                            borderRadius: pw.BorderRadius.circular(4),
                          ),
                        ),
                        pw.SizedBox(width: 12),
                        pw.Container(
                          width: 20,
                          height: 20,
                          decoration: pw.BoxDecoration(
                            color: PdfColor.fromHex('#7FB5A0'),
                            shape: pw.BoxShape.circle,
                          ),
                        ),
                        pw.SizedBox(width: 12),
                        pw.Container(
                          width: 20,
                          height: 20,
                          decoration: pw.BoxDecoration(
                            color: PdfColor.fromHex('#FFD700'),
                            shape: pw.BoxShape.circle,
                          ),
                        ),
                        pw.SizedBox(width: 12),
                        pw.Container(
                          width: 20,
                          height: 20,
                          decoration: pw.BoxDecoration(
                            color: PdfColor.fromHex('#9DB5A8'),
                            shape: pw.BoxShape.circle,
                          ),
                        ),
                      ],
                    ),

                    pw.SizedBox(height: 10),

                    // Footer text
                    pw.Text(
                      "Created with love & joy",
                      style: pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.grey500,
                        fontStyle: pw.FontStyle.italic,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildPdfDecoCircle(PdfColor innerColor, PdfColor outerColor) {
    return pw.Container(
      width: 35,
      height: 35,
      decoration: pw.BoxDecoration(
        color: outerColor,
        shape: pw.BoxShape.circle,
      ),
      child: pw.Center(
        child: pw.Container(
          width: 20,
          height: 20,
          decoration: pw.BoxDecoration(
            color: innerColor,
            shape: pw.BoxShape.circle,
          ),
        ),
      ),
    );
  }

  pw.Widget _buildPdfBottomDeco(PdfColor innerColor, PdfColor outerColor) {
    return pw.Container(
      width: 28,
      height: 28,
      decoration: pw.BoxDecoration(
        color: outerColor,
        shape: pw.BoxShape.circle,
      ),
      child: pw.Center(
        child: pw.Container(
          width: 16,
          height: 16,
          decoration: pw.BoxDecoration(
            color: innerColor,
            shape: pw.BoxShape.circle,
          ),
        ),
      ),
    );
  }
}