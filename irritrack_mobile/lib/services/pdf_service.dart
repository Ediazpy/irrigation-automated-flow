import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/inspection.dart';
import '../models/property.dart';
import '../models/company_settings.dart';
import 'storage_service.dart';

class PdfService {
  /// Generate a monthly report PDF
  static Future<Uint8List> generateMonthlyReport({
    required StorageService storage,
    required DateTime selectedMonth,
    required Map<String, dynamic> reportData,
  }) async {
    final pdf = pw.Document();
    final companyName = storage.companySettings?.companyName ?? 'IrriTrack';
    final companyPhone = storage.companySettings?.companyPhone ?? '';
    final companyEmail = storage.companySettings?.companyEmail ?? '';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildHeader(
          companyName: companyName,
          companyPhone: companyPhone,
          companyEmail: companyEmail,
        ),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          _buildTitle(selectedMonth),
          pw.SizedBox(height: 20),
          _buildSummarySection(reportData),
          pw.SizedBox(height: 20),
          _buildRevenueSection(reportData),
          pw.SizedBox(height: 20),
          _buildRepairsByCategorySection(reportData),
          pw.SizedBox(height: 20),
          _buildInspectionDetailsSection(storage, reportData),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader({
    required String companyName,
    required String companyPhone,
    required String companyEmail,
  }) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 20),
      padding: const pw.EdgeInsets.only(bottom: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 1)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                companyName,
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.teal700,
                ),
              ),
              if (companyPhone.isNotEmpty)
                pw.Text(companyPhone, style: const pw.TextStyle(fontSize: 10)),
              if (companyEmail.isNotEmpty)
                pw.Text(companyEmail, style: const pw.TextStyle(fontSize: 10)),
            ],
          ),
          pw.Text(
            'Monthly Report',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey600,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 10),
      padding: const pw.EdgeInsets.only(top: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 1)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Generated: ${DateFormat('MM/dd/yyyy HH:mm').format(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTitle(DateTime selectedMonth) {
    return pw.Center(
      child: pw.Text(
        'Report for ${DateFormat('MMMM yyyy').format(selectedMonth)}',
        style: pw.TextStyle(
          fontSize: 18,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  static pw.Widget _buildSummarySection(Map<String, dynamic> reportData) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Summary',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryItem('Total Inspections', '${reportData['totalInspections']}'),
              _buildSummaryItem('Completed', '${reportData['completedInspections']}', color: PdfColors.green700),
              _buildSummaryItem('Pending Review', '${reportData['pendingReview']}', color: PdfColors.orange700),
              _buildSummaryItem('In Progress', '${reportData['inProgress']}', color: PdfColors.blue700),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSummaryItem(String label, String value, {PdfColor? color}) {
    return pw.Column(
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
            color: color ?? PdfColors.black,
          ),
        ),
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
        ),
      ],
    );
  }

  static pw.Widget _buildRevenueSection(Map<String, dynamic> reportData) {
    final totalRevenue = reportData['totalRevenue'] as double;
    final revenueByProperty = reportData['revenueByProperty'] as Map<String, double>;

    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.green50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.green200),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Total Revenue',
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(
                '\$${totalRevenue.toStringAsFixed(2)}',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.green700,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            'Zone Repairs: ${reportData['totalZoneRepairs']} | Other Repairs: ${reportData['totalOtherRepairs']}',
            style: const pw.TextStyle(fontSize: 10),
          ),
          if (revenueByProperty.isNotEmpty) ...[
            pw.SizedBox(height: 15),
            pw.Text(
              'Revenue by Property:',
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 5),
            ...revenueByProperty.entries.map((entry) => pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 2),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                    child: pw.Text(entry.key, style: const pw.TextStyle(fontSize: 9)),
                  ),
                  pw.Text(
                    '\$${entry.value.toStringAsFixed(2)}',
                    style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }

  static pw.Widget _buildRepairsByCategorySection(Map<String, dynamic> reportData) {
    final repairsByCategory = reportData['repairsByCategory'] as Map<String, int>;

    if (repairsByCategory.isEmpty) {
      return pw.Container();
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Repairs by Category',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          pw.Wrap(
            spacing: 20,
            runSpacing: 5,
            children: repairsByCategory.entries.map((entry) => pw.Container(
              width: 120,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    entry.key.replaceAll('_', ' '),
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                  pw.Text(
                    '${entry.value}',
                    style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildInspectionDetailsSection(
    StorageService storage,
    Map<String, dynamic> reportData,
  ) {
    final inspections = reportData['inspections'] as List<Inspection>;

    if (inspections.isEmpty) {
      return pw.Container();
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Inspection Details',
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          columnWidths: {
            0: const pw.FlexColumnWidth(3),
            1: const pw.FlexColumnWidth(1.5),
            2: const pw.FlexColumnWidth(2),
            3: const pw.FlexColumnWidth(1.5),
            4: const pw.FlexColumnWidth(1),
            5: const pw.FlexColumnWidth(1.5),
          },
          children: [
            // Header row
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _tableCell('Property', isHeader: true),
                _tableCell('Date', isHeader: true),
                _tableCell('Technician(s)', isHeader: true),
                _tableCell('Status', isHeader: true),
                _tableCell('Repairs', isHeader: true),
                _tableCell('Total', isHeader: true),
              ],
            ),
            // Data rows
            ...inspections.map((inspection) {
              final property = storage.properties[inspection.propertyId];
              final propertyName = property?.address ?? 'Unknown';
              final techNames = inspection.technicians
                  .map((e) => storage.users[e]?.name ?? e)
                  .join(', ');
              final total = inspection.calculateTotalCost();
              final repairCount = inspection.repairs.length + inspection.otherRepairs.length;

              return pw.TableRow(
                children: [
                  _tableCell(propertyName),
                  _tableCell(inspection.date),
                  _tableCell(techNames),
                  _tableCell(inspection.status),
                  _tableCell('$repairCount'),
                  _tableCell('\$${total.toStringAsFixed(2)}'),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }

  static pw.Widget _tableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 9 : 8,
          fontWeight: isHeader ? pw.FontWeight.bold : null,
        ),
      ),
    );
  }

  /// Show PDF preview and print dialog
  static Future<void> previewAndPrint(Uint8List pdfBytes, String title) async {
    await Printing.layoutPdf(
      onLayout: (format) => pdfBytes,
      name: title,
    );
  }

  /// Share/save PDF
  static Future<void> sharePdf(Uint8List pdfBytes, String filename) async {
    await Printing.sharePdf(bytes: pdfBytes, filename: filename);
  }
}
