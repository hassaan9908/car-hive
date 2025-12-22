import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart' as intl;
import '../models/inspection_model.dart';
import 'package:flutter/services.dart' show rootBundle;

class PdfService {
  // Generate PDF report with a safety fallback to avoid TooManyPagesException
  Future<File> generateInspectionReport(InspectionModel inspection) async {
    try {
      return await _buildAndSaveReport(inspection);
    } catch (e) {
      // If the report grows too large (TooManyPagesException), fall back to a compact summary
      if (e.toString().contains('TooManyPagesException')) {
        final fallbackPdf = pw.Document();
        final dateFormat = intl.DateFormat('MMM dd, yyyy - hh:mm a');

        fallbackPdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (context) => pw.Padding(
              padding: const pw.EdgeInsets.all(24),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Inspection Summary (Compact)',
                      style: pw.TextStyle(
                          fontSize: 20, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 12),
                  pw.Text('Vehicle: ${inspection.carTitle}'),
                  pw.Text('Date: ${dateFormat.format(inspection.updatedAt)}'),
                  pw.SizedBox(height: 12),
                  pw.Text(
                      'Overall Score: ${inspection.overallScore.toStringAsFixed(0)}/100'),
                  pw.Text('Status: ${inspection.scoreText}'),
                  pw.SizedBox(height: 12),
                  pw.Text(
                      'Items Reviewed: ${inspection.completedItems}/${inspection.totalItems}'),
                  pw.Text(
                      'Completion: ${(inspection.progress * 100).toStringAsFixed(0)}%'),
                  pw.SizedBox(height: 16),
                  pw.Text('Sections:',
                      style: pw.TextStyle(
                          fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 8),
                  ...inspection.sections.map((section) => pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                              '- ${section.name}: ${section.sectionScore.toStringAsFixed(0)}/100'),
                        ],
                      )),
                  if (inspection.recommendations.isNotEmpty) ...[
                    pw.SizedBox(height: 16),
                    pw.Text('Recommendations:',
                        style: pw.TextStyle(
                            fontSize: 14, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 6),
                    ...inspection.recommendations.take(10).map(
                          (rec) => pw.Text('• ${rec.replaceAll('⚠️ ', '')}'),
                        ),
                  ]
                ],
              ),
            ),
          ),
        );

        return await _savePdfFile(fallbackPdf, inspection, suffix: 'compact');
      }

      rethrow;
    }
  }

  // Generate PDF as bytes (useful for web downloads)
  Future<Uint8List> generateInspectionReportBytes(
      InspectionModel inspection) async {
    try {
      final pdf = pw.Document();
      final dateFormat = intl.DateFormat('MMM dd, yyyy - hh:mm a');
      final logo = await _loadLogo();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (context) => [
            _buildHeader(inspection, dateFormat),
            pw.SizedBox(height: 16),
            _buildVehicleDetails(inspection),
            pw.SizedBox(height: 20),
            _buildOverallScore(inspection),
            pw.SizedBox(height: 16),
            ..._buildSectionBreakdown(inspection),
            pw.SizedBox(height: 16),
            if (inspection.recommendations.isNotEmpty)
              _buildRecommendations(inspection),
            pw.SizedBox(height: 16),
            ..._buildLowRatedSummary(inspection),
          ],
          footer: (context) => _buildPageFooter(context),
        ),
      );

      return await pdf.save();
    } catch (e) {
      // Fallback to compact summary
      final fallbackPdf = pw.Document();
      final dateFormat = intl.DateFormat('MMM dd, yyyy - hh:mm a');

      fallbackPdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) => pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Inspection Summary (Compact)',
                    style: pw.TextStyle(
                        fontSize: 20, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 12),
                pw.Text('Vehicle: ${inspection.carTitle}'),
                pw.Text('Date: ${dateFormat.format(inspection.updatedAt)}'),
                pw.SizedBox(height: 12),
                pw.Text(
                    'Overall Score: ${inspection.overallScore.toStringAsFixed(0)}/100'),
                pw.Text('Status: ${inspection.scoreText}'),
                pw.SizedBox(height: 12),
                pw.Text(
                    'Items Reviewed: ${inspection.completedItems}/${inspection.totalItems}'),
                pw.Text(
                    'Completion: ${(inspection.progress * 100).toStringAsFixed(0)}%'),
              ],
            ),
          ),
        ),
      );

      return await fallbackPdf.save();
    }
  }

  Future<File> _buildAndSaveReport(InspectionModel inspection) async {
    final pdf = pw.Document();
    final dateFormat = intl.DateFormat('MMM dd, yyyy - hh:mm a');
    final logo = await _loadLogo();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          _buildHeader(inspection, dateFormat),
          pw.SizedBox(height: 12),
          _buildVehicleDetails(inspection),
          pw.SizedBox(height: 16),
          _buildOverallScore(inspection),
          pw.SizedBox(height: 16),
          ..._buildSectionBreakdown(inspection),
          pw.SizedBox(height: 10),
          if (inspection.recommendations.isNotEmpty)
            _buildRecommendations(inspection),
          pw.SizedBox(height: 16),
          ..._buildLowRatedSummary(inspection),
        ],
        footer: (context) => _buildPageFooter(context),
      ),
    );

    return _savePdfFile(pdf, inspection);
  }

  Future<File> _savePdfFile(pw.Document pdf, InspectionModel inspection,
      {String suffix = ''}) async {
    final output = await getApplicationDocumentsDirectory();
    final cleanTitle = inspection.carTitle.replaceAll(' ', '_');
    final ts = DateTime.now().millisecondsSinceEpoch;
    final fileName =
        'inspection_${cleanTitle}_${suffix.isEmpty ? ts : '${ts}_$suffix'}.pdf';
    final file = File('${output.path}/$fileName');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  pw.Widget _buildHeader(
      InspectionModel inspection, intl.DateFormat dateFormat) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Company Banner
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('CarHive',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromInt(0xFF1E88E5),
                )),
            pw.Text('Inspection Report',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromInt(0xFF424242),
                )),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Text('VEHICLE INSPECTION REPORT',
            style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.Divider(),
        pw.SizedBox(height: 8),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Vehicle',
                    style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromInt(0xFF757575))),
                pw.SizedBox(height: 4),
                pw.Text(inspection.carTitle,
                    style: const pw.TextStyle(fontSize: 14)),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('Report Date',
                    style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromInt(0xFF757575))),
                pw.SizedBox(height: 4),
                pw.Text(dateFormat.format(inspection.updatedAt),
                    style: const pw.TextStyle(fontSize: 14)),
              ],
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildVehicleDetails(InspectionModel inspection) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColor.fromInt(0xFFE0E0E0)),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _kvWrapped('Vehicle Title', inspection.carTitle),
          _kvWrapped('Vehicle ID', inspection.carId),
          _kvWrapped('Buyer ID', inspection.buyerId),
          _kvWrapped('Seller ID', inspection.sellerId),
        ],
      ),
    );
  }

  pw.Widget _buildOverallScore(InspectionModel inspection) {
    final score = inspection.overallScore;
    final scoreText = inspection.scoreText;
    final scoreColor = _getPdfScoreColor(score);

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: scoreColor),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('OVERALL CONDITION SCORE',
              style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromInt(0xFF616161))),
          pw.SizedBox(height: 12),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('${score.toStringAsFixed(0)}/100',
                      style: pw.TextStyle(
                          fontSize: 32,
                          fontWeight: pw.FontWeight.bold,
                          color: scoreColor)),
                  pw.SizedBox(height: 8),
                  pw.Text(scoreText.toUpperCase(),
                      style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: scoreColor)),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('Items Inspected',
                      style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromInt(0xFF616161))),
                  pw.SizedBox(height: 4),
                  pw.Text(
                      '${inspection.completedItems}/${inspection.totalItems}',
                      style: const pw.TextStyle(fontSize: 16)),
                  pw.SizedBox(height: 12),
                  pw.Text('Completion',
                      style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromInt(0xFF616161))),
                  pw.SizedBox(height: 4),
                  pw.Text('${(inspection.progress * 100).toStringAsFixed(0)}%',
                      style: const pw.TextStyle(fontSize: 16)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<pw.Widget> _buildSectionBreakdown(InspectionModel inspection) {
    final sectionWidgets = inspection.sections
        .where((section) => section.completedCount > 0)
        .map((section) {
      final score = section.sectionScore;
      return pw.Container(
        width: double.infinity,
        margin: const pw.EdgeInsets.only(bottom: 12),
        padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColor.fromInt(0xFFE0E0E0)),
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(section.name,
                    style: pw.TextStyle(
                        fontSize: 12, fontWeight: pw.FontWeight.bold)),
                pw.Text('${score.toStringAsFixed(0)}',
                    style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: _getPdfScoreColor(score))),
              ],
            ),
            pw.SizedBox(height: 4),
            pw.Container(
              height: 8,
              decoration: pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFE0E0E0),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Row(
                children: [
                  pw.Expanded(
                    flex: score.clamp(0, 100).round(),
                    child: pw.Container(
                      decoration: pw.BoxDecoration(
                        color: _getPdfScoreColor(score),
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  pw.Expanded(
                    flex: (100 - score.clamp(0, 100)).round(),
                    child: pw.Container(color: PdfColor.fromInt(0x00000000)),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Text(
                '${section.completedCount}/${section.totalCount} items reviewed',
                style: pw.TextStyle(
                    fontSize: 10, color: PdfColor.fromInt(0xFF9E9E9E))),
          ],
        ),
      );
    }).toList();

    return [
      pw.Text('SECTION BREAKDOWN',
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 6),
      ...sectionWidgets,
    ];
  }

  pw.Widget _buildRecommendations(InspectionModel inspection) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('RECOMMENDATIONS',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        ...inspection.recommendations.map((rec) {
          final text = rec.replaceAll('⚠️ ', '');
          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 8),
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColor.fromInt(0xFFFFC107)),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('⚠️', style: const pw.TextStyle(fontSize: 12)),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: pw.Text(
                    text,
                    style: const pw.TextStyle(fontSize: 11),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  PdfColor _getPdfScoreColor(double score) {
    if (score >= 85) return PdfColor.fromInt(0xFF4CAF50); // Green
    if (score >= 70) return PdfColor.fromInt(0xFF8BC34A); // Light Green
    if (score >= 50) return PdfColor.fromInt(0xFFFFC107); // Orange
    if (score >= 30) return PdfColor.fromInt(0xFFFF9800); // Deep Orange
    return PdfColor.fromInt(0xFFF44336); // Red
  }

  pw.Widget _buildFooter() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text('Generated by CarHive',
            style:
                pw.TextStyle(fontSize: 9, color: PdfColor.fromInt(0xFF9E9E9E))),
        pw.Text('www.carhive.app',
            style:
                pw.TextStyle(fontSize: 9, color: PdfColor.fromInt(0xFF9E9E9E))),
      ],
    );
  }

  pw.Widget _buildPageFooter(pw.Context context) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Generated by CarHive',
              style: pw.TextStyle(
                  fontSize: 9, color: PdfColor.fromInt(0xFF9E9E9E))),
          pw.Text('Page ${context.pageNumber} of ${context.pagesCount}',
              style: pw.TextStyle(
                  fontSize: 9, color: PdfColor.fromInt(0xFF9E9E9E))),
        ],
      ),
    );
  }

  pw.Widget _kv(String key, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        children: [
          pw.Container(
            width: 100,
            child: pw.Text(
              key,
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromInt(0xFF616161),
              ),
            ),
          ),
          pw.Text(value, style: const pw.TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  pw.Widget _kvWrapped(String key, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            key,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromInt(0xFF616161),
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            value,
            style: const pw.TextStyle(fontSize: 10),
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  List<pw.Widget> _buildLowRatedSummary(InspectionModel inspection) {
    final rows = <List<String>>[];
    for (final section in inspection.sections) {
      for (final item in section.items) {
        if (item.isCompleted && item.rating < 60) {
          rows.add([
            section.name,
            item.question,
            item.rating.toString(),
            item.notes.isNotEmpty ? item.notes : '-',
          ]);
        }
      }
    }

    if (rows.isEmpty) {
      return [];
    }

    return [
      pw.Text('LOW-RATED ITEMS SUMMARY',
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 6),
      pw.TableHelper.fromTextArray(
        border: pw.TableBorder.all(color: PdfColor.fromInt(0xFFE0E0E0)),
        headerDecoration: pw.BoxDecoration(color: PdfColor.fromInt(0xFFF5F5F5)),
        headers: const ['Section', 'Item', 'Rating', 'Notes'],
        data: rows,
        cellPadding: const pw.EdgeInsets.all(6),
        headerStyle: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
        cellStyle: const pw.TextStyle(fontSize: 10),
        columnWidths: {
          0: const pw.FlexColumnWidth(1),
          1: const pw.FlexColumnWidth(2),
          2: const pw.FlexColumnWidth(0.6),
          3: const pw.FlexColumnWidth(2),
        },
      ),
    ];
  }

  pw.Widget _tableHeaderCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(text,
          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
    );
  }

  pw.Widget _tableCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(text, style: const pw.TextStyle(fontSize: 10)),
    );
  }

  Future<pw.MemoryImage?> _loadLogo() async {
    try {
      final bytes = await rootBundle.load('assets/images/logo.png');
      return pw.MemoryImage(bytes.buffer.asUint8List());
    } catch (_) {
      return null;
    }
  }
}