import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../models/inspection.dart';

class MonthlyReportScreen extends StatefulWidget {
  final AuthService authService;

  const MonthlyReportScreen({Key? key, required this.authService}) : super(key: key);

  @override
  State<MonthlyReportScreen> createState() => _MonthlyReportScreenState();
}

class _MonthlyReportScreenState extends State<MonthlyReportScreen> {
  late DateTime selectedMonth;

  @override
  void initState() {
    super.initState();
    selectedMonth = DateTime.now();
  }

  String _getBillingMonth(DateTime date) {
    return DateFormat('yyyy-MM').format(date);
  }

  void _previousMonth() {
    setState(() {
      selectedMonth = DateTime(selectedMonth.year, selectedMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      selectedMonth = DateTime(selectedMonth.year, selectedMonth.month + 1);
    });
  }

  Map<String, dynamic> _calculateReportData() {
    final storage = widget.authService.storage;
    final billingMonth = _getBillingMonth(selectedMonth);

    // Get all inspections for this billing month
    final inspections = storage.inspections.values
        .where((insp) => insp.billingMonth == billingMonth)
        .toList();

    final completedInspections =
        inspections.where((i) => i.status == 'completed').toList();

    // Calculate totals
    double totalRevenue = 0.0;
    int totalZoneRepairs = 0;
    int totalOtherRepairs = 0;
    Map<String, int> repairsByCategory = {};
    Map<String, double> revenueByProperty = {};

    for (final inspection in completedInspections) {
      final property = storage.properties[inspection.propertyId];
      final propertyName = property?.address ?? 'Unknown Property';

      double inspectionTotal = inspection.calculateTotalCost();
      totalRevenue += inspectionTotal;
      totalZoneRepairs += inspection.repairs.length;
      totalOtherRepairs += inspection.otherRepairs.length;

      revenueByProperty[propertyName] =
          (revenueByProperty[propertyName] ?? 0) + inspectionTotal;

      // Count repairs by category
      for (final repair in [...inspection.repairs, ...inspection.otherRepairs]) {
        final category = repair.itemName.split('_').first;
        repairsByCategory[category] =
            (repairsByCategory[category] ?? 0) + repair.quantity;
      }
    }

    return {
      'totalInspections': inspections.length,
      'completedInspections': completedInspections.length,
      'pendingReview': inspections.where((i) => i.status == 'review').length,
      'inProgress': inspections.where((i) => i.status == 'in_progress').length,
      'assigned': inspections.where((i) => i.status == 'assigned').length,
      'totalRevenue': totalRevenue,
      'totalZoneRepairs': totalZoneRepairs,
      'totalOtherRepairs': totalOtherRepairs,
      'repairsByCategory': repairsByCategory,
      'revenueByProperty': revenueByProperty,
      'inspections': inspections,
    };
  }

  String _generateCSVReport(Map<String, dynamic> reportData) {
    final storage = widget.authService.storage;
    final inspections = reportData['inspections'] as List<Inspection>;

    final buffer = StringBuffer();

    // Header
    buffer.writeln('IrriTrack Monthly Report');
    buffer.writeln('Billing Month: ${DateFormat('MMMM yyyy').format(selectedMonth)}');
    buffer.writeln('Generated: ${DateFormat('MM/dd/yyyy HH:mm').format(DateTime.now())}');
    buffer.writeln('');

    // Summary
    buffer.writeln('=== SUMMARY ===');
    buffer.writeln('Total Inspections,${reportData['totalInspections']}');
    buffer.writeln('Completed,${reportData['completedInspections']}');
    buffer.writeln('Pending Review,${reportData['pendingReview']}');
    buffer.writeln('In Progress,${reportData['inProgress']}');
    buffer.writeln('Assigned,${reportData['assigned']}');
    buffer.writeln('Total Revenue,\$${(reportData['totalRevenue'] as double).toStringAsFixed(2)}');
    buffer.writeln('Total Zone Repairs,${reportData['totalZoneRepairs']}');
    buffer.writeln('Total Other Repairs,${reportData['totalOtherRepairs']}');
    buffer.writeln('');

    // Revenue by Property
    buffer.writeln('=== REVENUE BY PROPERTY ===');
    buffer.writeln('Property,Revenue');
    final revenueByProperty = reportData['revenueByProperty'] as Map<String, double>;
    for (final entry in revenueByProperty.entries) {
      buffer.writeln('"${entry.key}",\$${entry.value.toStringAsFixed(2)}');
    }
    buffer.writeln('');

    // Repairs by Category
    buffer.writeln('=== REPAIRS BY CATEGORY ===');
    buffer.writeln('Category,Count');
    final repairsByCategory = reportData['repairsByCategory'] as Map<String, int>;
    for (final entry in repairsByCategory.entries) {
      buffer.writeln('${entry.key},${entry.value}');
    }
    buffer.writeln('');

    // Detailed Inspections
    buffer.writeln('=== INSPECTION DETAILS ===');
    buffer.writeln('Property,Date,Technician(s),Status,Zone Repairs,Other Repairs,Total');

    for (final inspection in inspections) {
      final property = storage.properties[inspection.propertyId];
      final propertyName = property?.address ?? 'Unknown';
      final techNames = inspection.technicians
          .map((e) => storage.users[e]?.name ?? e)
          .join('; ');
      final total = inspection.calculateTotalCost();

      buffer.writeln(
        '"$propertyName","${inspection.date}","$techNames","${inspection.status}",${inspection.repairs.length},${inspection.otherRepairs.length},\$${total.toStringAsFixed(2)}',
      );
    }

    return buffer.toString();
  }

  void _copyReport() {
    final reportData = _calculateReportData();
    final csvReport = _generateCSVReport(reportData);

    Clipboard.setData(ClipboardData(text: csvReport));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Report copied to clipboard!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reportData = _calculateReportData();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monthly Report'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: _copyReport,
            tooltip: 'Copy Report (CSV)',
          ),
        ],
      ),
      body: Column(
        children: [
          // Month selector
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _previousMonth,
                ),
                Text(
                  DateFormat('MMMM yyyy').format(selectedMonth),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _nextMonth,
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Summary Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Summary',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Divider(),
                        _buildSummaryRow(
                          'Total Inspections',
                          '${reportData['totalInspections']}',
                        ),
                        _buildSummaryRow(
                          'Completed',
                          '${reportData['completedInspections']}',
                          color: Colors.green,
                        ),
                        _buildSummaryRow(
                          'Pending Review',
                          '${reportData['pendingReview']}',
                          color: Colors.orange,
                        ),
                        _buildSummaryRow(
                          'In Progress',
                          '${reportData['inProgress']}',
                          color: Colors.blue,
                        ),
                        _buildSummaryRow(
                          'Assigned',
                          '${reportData['assigned']}',
                          color: Colors.amber,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Revenue Card
                Card(
                  color: Colors.green.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.attach_money, color: Colors.green),
                            const SizedBox(width: 8),
                            const Text(
                              'Total Revenue',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '\$${(reportData['totalRevenue'] as double).toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const Divider(),
                        Text('Zone Repairs: ${reportData['totalZoneRepairs']}'),
                        Text('Other Repairs: ${reportData['totalOtherRepairs']}'),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Revenue by Property
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Revenue by Property',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Divider(),
                        if ((reportData['revenueByProperty'] as Map).isEmpty)
                          const Text('No data for this period')
                        else
                          ...(reportData['revenueByProperty'] as Map<String, double>)
                              .entries
                              .map((entry) => Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            entry.key,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Text(
                                          '\$${entry.value.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ))
                              .toList(),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Repairs by Category
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Repairs by Category',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Divider(),
                        if ((reportData['repairsByCategory'] as Map).isEmpty)
                          const Text('No repairs for this period')
                        else
                          ...(reportData['repairsByCategory'] as Map<String, int>)
                              .entries
                              .map((entry) => Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(entry.key.replaceAll('_', ' ')),
                                        Text(
                                          '${entry.value}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ))
                              .toList(),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Export Button
                ElevatedButton.icon(
                  onPressed: _copyReport,
                  icon: const Icon(Icons.file_download),
                  label: const Text('Export Report (Copy to Clipboard)'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
