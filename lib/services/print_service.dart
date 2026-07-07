import 'dart:async';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PrintDetail {
  const PrintDetail(this.label, this.value);

  final String label;
  final String value;
}

class PrintService {
  static void printRecord({
    required String title,
    required String module,
    required String reference,
    required String result,
    required List<PrintDetail> details,
  }) {
    unawaited(
      Printing.layoutPdf(
        name: '${_fallback(reference)} Record',
        onLayout: (_) => _buildRecordPdf(
          title: title,
          module: module,
          reference: reference,
          result: result,
          details: details,
        ),
      ),
    );
  }

  static Future<Uint8List> _buildRecordPdf({
    required String title,
    required String module,
    required String reference,
    required String result,
    required List<PrintDetail> details,
  }) async {
    final document = pw.Document();
    final generated = _formatDateTime(DateTime.now().toIso8601String());

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 18),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(
                  color: PdfColor.fromInt(0xff1d4ed8),
                  width: 3,
                ),
              ),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Barangay Information Management System',
                  style: pw.TextStyle(
                    color: const PdfColor.fromInt(0xff1d4ed8),
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  title,
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  'Generated on $generated',
                  style: const pw.TextStyle(
                    color: PdfColor.fromInt(0xff64748b),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 22),
          pw.Row(
            children: [
              _summaryBox('Reference', reference),
              pw.SizedBox(width: 12),
              _summaryBox('Module', module),
              pw.SizedBox(width: 12),
              _summaryBox('Result', result),
            ],
          ),
          pw.SizedBox(height: 24),
          pw.Text(
            'Record Details',
            style: pw.TextStyle(
              color: const PdfColor.fromInt(0xff1e293b),
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Table(
            border: pw.TableBorder.all(
              color: const PdfColor.fromInt(0xffcbd5e1),
            ),
            columnWidths: const {
              0: pw.FlexColumnWidth(1.1),
              1: pw.FlexColumnWidth(2.7),
            },
            children: details
                .map(
                  (item) => pw.TableRow(
                    children: [
                      _detailCell(item.label, isHeader: true),
                      _detailCell(_fallback(item.value)),
                    ],
                  ),
                )
                .toList(),
          ),
          pw.SizedBox(height: 56),
          pw.Row(
            children: [
              _signature('Prepared by'),
              pw.SizedBox(width: 48),
              _signature('Verified by'),
            ],
          ),
          pw.SizedBox(height: 28),
          pw.Container(
            padding: const pw.EdgeInsets.only(top: 12),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                top: pw.BorderSide(color: PdfColor.fromInt(0xffcbd5e1)),
              ),
            ),
            child: pw.Text(
              'This printed record was generated from the barangay admin transaction logs.',
              style: const pw.TextStyle(
                color: PdfColor.fromInt(0xff64748b),
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );

    return document.save();
  }

  static pw.Widget _summaryBox(String label, String value) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: const PdfColor.fromInt(0xffcbd5e1)),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              label.toUpperCase(),
              style: pw.TextStyle(
                color: const PdfColor.fromInt(0xff64748b),
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 5),
            pw.Text(
              _fallback(value),
              style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _detailCell(String value, {bool isHeader = false}) {
    return pw.Container(
      color: isHeader ? const PdfColor.fromInt(0xfff8fafc) : null,
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: pw.Text(
        _fallback(value),
        style: pw.TextStyle(
          color: PdfColor.fromInt(isHeader ? 0xff334155 : 0xff0f172a),
          fontSize: 12,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  static pw.Widget _signature(String label) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.only(top: 8),
        decoration: const pw.BoxDecoration(
          border: pw.Border(
            top: pw.BorderSide(color: PdfColor.fromInt(0xff334155)),
          ),
        ),
        child: pw.Center(
          child: pw.Text(
            label,
            style: const pw.TextStyle(
              color: PdfColor.fromInt(0xff475569),
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }

  static String _fallback(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? '-' : trimmed;
  }

  static String _formatDateTime(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return _fallback(value);
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final hour12 = parsed.hour % 12 == 0 ? 12 : parsed.hour % 12;
    final minute = parsed.minute.toString().padLeft(2, '0');
    final suffix = parsed.hour >= 12 ? 'PM' : 'AM';
    return '${months[parsed.month - 1]} ${parsed.day}, ${parsed.year}, $hour12:$minute $suffix';
  }
}
