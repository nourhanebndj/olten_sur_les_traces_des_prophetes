import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ProphetsPdfService {
  static const PdfColor green =
      PdfColor.fromInt(0xFF3F9463);

  static const PdfColor dark =
      PdfColor.fromInt(0xFF302C27);

  static const PdfColor text =
      PdfColor.fromInt(0xFF5F574E);

  static const PdfColor lightGreen =
      PdfColor.fromInt(0xFFF0F7F2);

  static const PdfColor lightCream =
      PdfColor.fromInt(0xFFFCF9F3);

  static const PdfColor lightYellow =
      PdfColor.fromInt(0xFFFFF7E7);

  static const PdfColor yellow =
      PdfColor.fromInt(0xFFB77C19);

  // ============================================================
  // GENERATE + DOWNLOAD
  // ============================================================

  static Future<void> generateAndDownload({
    required Map<String, dynamic> prophet,
    required List<Map<String, dynamic>> stories,
    required Map<int, List<String>> quranReferences,
    required Map<int, List<String>> lessons,
  }) async {
    final pdfBytes = await generatePdf(
      prophet: prophet,
      stories: stories,
      quranReferences: quranReferences,
      lessons: lessons,
    );

    final prophetName =
        prophet['name_fr']?.toString().trim().isNotEmpty == true
            ? prophet['name_fr'].toString().trim()
            : 'Prophete';

    final safeName = _sanitizeFileName(
      'Histoire_de_$prophetName',
    );

    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: '$safeName.pdf',
    );
  }

  // ============================================================
  // GENERATE PDF
  // ============================================================

  static Future<Uint8List> generatePdf({
    required Map<String, dynamic> prophet,
    required List<Map<String, dynamic>> stories,
    required Map<int, List<String>> quranReferences,
    required Map<int, List<String>> lessons,
  }) async {
    final pdf = pw.Document();

    // ----------------------------------------------------------
    // LOAD ARABIC / UNICODE FONTS
    // ----------------------------------------------------------

    final regularFontData = await rootBundle.load(
      'assets/fonts/NotoSansArabic-Regular.ttf',
    );

    final boldFontData = await rootBundle.load(
      'assets/fonts/NotoSansArabic-Bold.ttf',
    );

    final regularFont = pw.Font.ttf(
      regularFontData,
    );

    final boldFont = pw.Font.ttf(
      boldFontData,
    );

    final name =
        prophet['name_fr']?.toString().trim().isNotEmpty == true
            ? prophet['name_fr'].toString().trim()
            : 'Prophète';

    final summary =
        prophet['summary_fr']?.toString().trim() ?? '';

    final displayOrder =
        prophet['display_order']?.toString() ?? '';

    final generatedDate =
        _formatDate(DateTime.now());

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(
            40,
            45,
            40,
            45,
          ),
          theme: pw.ThemeData.withFont(
            base: regularFont,
            bold: boldFont,
          ),
        ),

        // ======================================================
        // HEADER
        // ======================================================

        header: (context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(
              bottom: 18,
            ),
            padding: const pw.EdgeInsets.only(
              bottom: 10,
            ),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(
                  color: green,
                  width: 1.2,
                ),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment:
                  pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Sur les traces des prophètes',
                  style: pw.TextStyle(
                    font: regularFont,
                    fontSize: 9,
                    color: PdfColors.grey600,
                  ),
                ),
                pw.Text(
                  name,
                  style: pw.TextStyle(
                    font: regularFont,
                    fontSize: 9,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
          );
        },

        // ======================================================
        // FOOTER
        // ======================================================

        footer: (context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(
              top: 18,
            ),
            padding: const pw.EdgeInsets.only(
              top: 8,
            ),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                top: pw.BorderSide(
                  color: PdfColor.fromInt(
                    0xFFEDE3D2,
                  ),
                  width: 0.8,
                ),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment:
                  pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Document éducatif',
                  style: pw.TextStyle(
                    font: regularFont,
                    fontSize: 8,
                    color: PdfColors.grey600,
                  ),
                ),
                pw.Text(
                  'Page ${context.pageNumber} / ${context.pagesCount}',
                  style: pw.TextStyle(
                    font: regularFont,
                    fontSize: 8,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
          );
        },

        // ======================================================
        // CONTENT
        // ======================================================

        build: (context) {
          final widgets = <pw.Widget>[];

          // ====================================================
          // TITLE
          // ====================================================

          widgets.add(
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 25,
                vertical: 28,
              ),
              decoration: pw.BoxDecoration(
                color: lightGreen,
                borderRadius:
                    pw.BorderRadius.circular(18),
                border: pw.Border.all(
                  color: PdfColor.fromInt(
                    0xFFD9EBDD,
                  ),
                  width: 1,
                ),
              ),
              child: pw.Column(
                crossAxisAlignment:
                    pw.CrossAxisAlignment.center,
                children: [
                  pw.Container(
                    width: 52,
                    height: 52,
                    decoration: pw.BoxDecoration(
                      color: green,
                      borderRadius:
                          pw.BorderRadius.circular(15),
                    ),
                    child: pw.Center(
                      child: pw.Text(
                        'PDF',
                        style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 14,
                          color: PdfColors.white,
                        ),
                      ),
                    ),
                  ),

                  pw.SizedBox(height: 14),

                  pw.Text(
                    displayOrder.isNotEmpty
                        ? 'PROPHÈTE $displayOrder'
                        : 'PROPHÈTE',
                    style: pw.TextStyle(
                      font: boldFont,
                      fontSize: 10,
                      color: green,
                    ),
                  ),

                  pw.SizedBox(height: 7),

                  pw.Text(
                    name,
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      font: boldFont,
                      fontSize: 25,
                      color: dark,
                    ),
                  ),

                  pw.SizedBox(height: 8),

                  pw.Text(
                    'Histoire, références et leçons',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      font: regularFont,
                      fontSize: 11,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
            ),
          );

          // ====================================================
          // SUMMARY
          // ====================================================

          if (summary.isNotEmpty) {
            widgets.add(
              pw.SizedBox(height: 22),
            );

            widgets.add(
              _sectionTitle(
                'À propos',
                regularFont,
                boldFont,
              ),
            );

            widgets.add(
              pw.SizedBox(height: 9),
            );

            widgets.add(
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  color: lightCream,
                  borderRadius:
                      pw.BorderRadius.circular(12),
                ),
                child: pw.Text(
                  summary,
                  style: pw.TextStyle(
                    font: regularFont,
                    fontSize: 10.5,
                    height: 1.6,
                    color: text,
                  ),
                ),
              ),
            );
          }

          // ====================================================
          // STORIES
          // ====================================================

          if (stories.isNotEmpty) {
            widgets.add(
              pw.SizedBox(height: 25),
            );

            widgets.add(
              _sectionTitle(
                'Histoires',
                regularFont,
                boldFont,
              ),
            );

            widgets.add(
              pw.SizedBox(height: 10),
            );

            for (int i = 0;
                i < stories.length;
                i++) {
              final story = stories[i];

              final storyId =
                  (story['id'] as num).toInt();

              final title =
                  story['title_fr']
                          ?.toString()
                          .trim() ??
                      'Histoire';

              final content =
                  story['content_fr']
                          ?.toString()
                          .trim() ??
                      '';

              final references =
                  quranReferences[storyId] ?? [];

              final storyLessons =
                  lessons[storyId] ?? [];

              widgets.add(
                _buildStory(
                  index: i + 1,
                  title: title,
                  content: content,
                  references: references,
                  lessons: storyLessons,
                  regularFont: regularFont,
                  boldFont: boldFont,
                ),
              );

              if (i < stories.length - 1) {
                widgets.add(
                  pw.SizedBox(height: 18),
                );
              }
            }
          } else {
            widgets.add(
              pw.SizedBox(height: 25),
            );

            widgets.add(
              pw.Container(
                width: double.infinity,
                padding:
                    const pw.EdgeInsets.all(18),
                decoration: pw.BoxDecoration(
                  color: lightCream,
                  borderRadius:
                      pw.BorderRadius.circular(12),
                ),
                child: pw.Text(
                  'Aucune histoire disponible.',
                  textAlign:
                      pw.TextAlign.center,
                  style: pw.TextStyle(
                    font: regularFont,
                    fontSize: 10,
                    color:
                        PdfColors.grey700,
                  ),
                ),
              ),
            );
          }

          // ====================================================
          // DATE
          // ====================================================

          widgets.add(
            pw.SizedBox(height: 25),
          );

          widgets.add(
            pw.Center(
              child: pw.Text(
                'Généré le $generatedDate',
                style: pw.TextStyle(
                  font: regularFont,
                  fontSize: 8,
                  color:
                      PdfColors.grey600,
                ),
              ),
            ),
          );

          return widgets;
        },
      ),
    );

    return pdf.save();
  }

  // ============================================================
  // STORY
  // ============================================================

  static pw.Widget _buildStory({
    required int index,
    required String title,
    required String content,
    required List<String> references,
    required List<String> lessons,
    required pw.Font regularFont,
    required pw.Font boldFont,
  }) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius:
            pw.BorderRadius.circular(14),
        border: pw.Border.all(
          color: PdfColor.fromInt(
            0xFFEDE3D2,
          ),
          width: 0.8,
        ),
      ),
      child: pw.Column(
        crossAxisAlignment:
            pw.CrossAxisAlignment.start,
        children: [
          // TITLE
          pw.Row(
            crossAxisAlignment:
                pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: 29,
                height: 29,
                decoration: pw.BoxDecoration(
                  color: lightGreen,
                  borderRadius:
                      pw.BorderRadius.circular(9),
                ),
                child: pw.Center(
                  child: pw.Text(
                    '$index',
                    style: pw.TextStyle(
                      font: boldFont,
                      fontSize: 9,
                      color: green,
                    ),
                  ),
                ),
              ),

              pw.SizedBox(width: 10),

              pw.Expanded(
                child: pw.Text(
                  title,
                  style: pw.TextStyle(
                    font: boldFont,
                    fontSize: 13,
                    color: dark,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),

          // CONTENT
          if (content.isNotEmpty) ...[
            pw.SizedBox(height: 12),

            pw.Container(
              width: double.infinity,
              padding:
                  const pw.EdgeInsets.all(13),
              decoration: pw.BoxDecoration(
                color: lightCream,
                borderRadius:
                    pw.BorderRadius.circular(10),
              ),
              child: pw.Text(
                content,
                style: pw.TextStyle(
                  font: regularFont,
                  fontSize: 10,
                  height: 1.65,
                  color: text,
                ),
              ),
            ),
          ],

          // REFERENCES
          if (references.isNotEmpty) ...[
            pw.SizedBox(height: 12),

            _buildReferences(
              references,
              regularFont,
              boldFont,
            ),
          ],

          // LESSONS
          if (lessons.isNotEmpty) ...[
            pw.SizedBox(height: 12),

            _buildLessons(
              lessons,
              regularFont,
              boldFont,
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // REFERENCES
  // ============================================================

  static pw.Widget _buildReferences(
    List<String> references,
    pw.Font regularFont,
    pw.Font boldFont,
  ) {
    return pw.Container(
      width: double.infinity,
      padding:
          const pw.EdgeInsets.all(13),
      decoration: pw.BoxDecoration(
        color: lightGreen,
        borderRadius:
            pw.BorderRadius.circular(10),
      ),
      child: pw.Column(
        crossAxisAlignment:
            pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Références coraniques',
            style: pw.TextStyle(
              font: boldFont,
              fontSize: 10,
              color: green,
            ),
          ),

          pw.SizedBox(height: 7),

          ...references.map(
            (reference) {
              return pw.Padding(
                padding:
                    const pw.EdgeInsets.only(
                  bottom: 5,
                ),
                child: pw.Row(
                  crossAxisAlignment:
                      pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      margin:
                          const pw.EdgeInsets.only(
                        top: 4,
                        right: 7,
                      ),
                      width: 4,
                      height: 4,
                      decoration:
                          const pw.BoxDecoration(
                        color: green,
                        shape:
                            pw.BoxShape.circle,
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Text(
                        reference,
                        style: pw.TextStyle(
                          font: regularFont,
                          fontSize: 9,
                          height: 1.4,
                          color: text,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LESSONS
  // ============================================================

  static pw.Widget _buildLessons(
    List<String> lessons,
    pw.Font regularFont,
    pw.Font boldFont,
  ) {
    return pw.Container(
      width: double.infinity,
      padding:
          const pw.EdgeInsets.all(13),
      decoration: pw.BoxDecoration(
        color: lightYellow,
        borderRadius:
            pw.BorderRadius.circular(10),
      ),
      child: pw.Column(
        crossAxisAlignment:
            pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Leçons à retenir',
            style: pw.TextStyle(
              font: boldFont,
              fontSize: 10,
              color: yellow,
            ),
          ),

          pw.SizedBox(height: 7),

          ...lessons.map(
            (lesson) {
              return pw.Padding(
                padding:
                    const pw.EdgeInsets.only(
                  bottom: 5,
                ),
                child: pw.Row(
                  crossAxisAlignment:
                      pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      margin:
                          const pw.EdgeInsets.only(
                        top: 3,
                        right: 7,
                      ),
                      width: 7,
                      height: 7,
                      decoration:
                          const pw.BoxDecoration(
                        color: yellow,
                        shape:
                            pw.BoxShape.circle,
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Text(
                        lesson,
                        style: pw.TextStyle(
                          font: regularFont,
                          fontSize: 9,
                          height: 1.45,
                          color:
                              PdfColor.fromInt(
                            0xFF705C38,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  static pw.Widget _sectionTitle(
    String title,
    pw.Font regularFont,
    pw.Font boldFont,
  ) {
    return pw.Row(
      children: [
        pw.Container(
          width: 27,
          height: 27,
          decoration: pw.BoxDecoration(
            color: green,
            borderRadius:
                pw.BorderRadius.circular(8),
          ),
          child: pw.Center(
            child: pw.Text(
              '•',
              style: pw.TextStyle(
                font: boldFont,
                color:
                    PdfColors.white,
                fontSize: 12,
              ),
            ),
          ),
        ),

        pw.SizedBox(width: 9),

        pw.Text(
          title,
          style: pw.TextStyle(
            font: boldFont,
            fontSize: 16,
            color: dark,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  static String _sanitizeFileName(
    String value,
  ) {
    return value
        .replaceAll(
          RegExp(r'[<>:"/\\|?*]'),
          '_',
        )
        .replaceAll(' ', '_');
  }

  static String _formatDate(
    DateTime date,
  ) {
    final day =
        date.day.toString().padLeft(2, '0');

    final month =
        date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }
}