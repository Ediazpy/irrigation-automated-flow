import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../models/inspection.dart';
import '../../models/property.dart';
import 'package:intl/intl.dart';
import '../../utils/date_formatter.dart';

class CompletedInspectionsScreen extends StatefulWidget {
  final AuthService authService;

  const CompletedInspectionsScreen({Key? key, required this.authService})
      : super(key: key);

  @override
  State<CompletedInspectionsScreen> createState() =>
      _CompletedInspectionsScreenState();
}

class _CompletedInspectionsScreenState
    extends State<CompletedInspectionsScreen> {
  @override
  Widget build(BuildContext context) {
    final storage = widget.authService.storage;
    final completedInspections = storage.inspections.entries
        .where((e) => e.value.status == 'completed')
        .toList();

    // Group by date
    final Map<String, List<MapEntry<int, Inspection>>> groupedByDate = {};
    for (var entry in completedInspections) {
      final date = entry.value.date;
      if (!groupedByDate.containsKey(date)) {
        groupedByDate[date] = [];
      }
      groupedByDate[date]!.add(entry);
    }

    // Sort dates in descending order (newest first)
    final sortedDates = groupedByDate.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return Scaffold(
      appBar: AppBar(title: const Text('Completed Inspections')),
      body: completedInspections.isEmpty
          ? const Center(child: Text('No completed inspections'))
          : ListView.builder(
              itemCount: sortedDates.length,
              itemBuilder: (context, index) {
                final date = sortedDates[index];
                final inspections = groupedByDate[date]!;

                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ExpansionTile(
                    initiallyExpanded: index == 0, // Expand today's by default
                    leading: CircleAvatar(
                      child: Text('${inspections.length}'),
                    ),
                    title: Text(
                      _formatDate(date),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('${inspections.length} inspections'),
                    children: inspections.map((entry) {
                      final inspection = entry.value;
                      final prop = storage.properties[inspection.propertyId];

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 4,
                        ),
                        leading: const Icon(Icons.check_circle, color: Colors.green),
                        title: Text(prop?.address ?? 'Unknown Property'),
                        subtitle: Text(
                          'Tech: ${storage.users[inspection.technician]?.name ?? "Unknown"}\n'
                          'Total: \$${inspection.totalCost.toStringAsFixed(2)}',
                        ),
                        trailing: const Icon(Icons.arrow_forward),
                        onTap: () => _viewDetails(context, entry.key, inspection),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
    );
  }

  String _formatDate(String dateStr) {
    return DateFormatter.formatInspectionDate(dateStr);
  }

  void _viewDetails(BuildContext context, int inspectionId, Inspection inspection) {
    final storage = widget.authService.storage;
    final property = storage.properties[inspection.propertyId];

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade700,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.white),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            property?.address ?? 'Unknown Property',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Date: ${inspection.date}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    Text(
                      'Technician: ${storage.users[inspection.technician]?.name ?? "Unknown"}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Zone Repairs
                      if (inspection.repairs.isNotEmpty) ...[
                        const Text(
                          'Zone Repairs',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Divider(),
                        ...inspection.repairs.map((repair) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 40,
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade100,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Z${repair.zoneNumber}',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        repair.itemName.replaceAll('_', ' '),
                                        style: const TextStyle(fontWeight: FontWeight.w500),
                                      ),
                                      Text(
                                        'Qty: ${repair.quantity} × \$${repair.price.toStringAsFixed(2)} = \$${repair.totalCost.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                      if (repair.notes.isNotEmpty)
                                        Text(
                                          'Notes: ${repair.notes}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 16),
                      ],

                      // Other Repairs
                      if (inspection.otherRepairs.isNotEmpty) ...[
                        const Text(
                          'Other Repairs',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Divider(),
                        ...inspection.otherRepairs.map((repair) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.build, size: 20, color: Colors.orange),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        repair.itemName.replaceAll('_', ' '),
                                        style: const TextStyle(fontWeight: FontWeight.w500),
                                      ),
                                      Text(
                                        'Qty: ${repair.quantity} × \$${repair.price.toStringAsFixed(2)} = \$${repair.totalCost.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                      if (repair.notes.isNotEmpty)
                                        Text(
                                          'Notes: ${repair.notes}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 16),
                      ],

                      // Other Notes
                      if (inspection.otherNotes.isNotEmpty) ...[
                        const Text(
                          'Additional Notes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Divider(),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(inspection.otherNotes),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Total
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total Cost',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '\$${inspection.totalCost.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Actions
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _moveToInProgress(inspectionId, inspection);
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Move to In-Progress'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.orange,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        label: const Text('Close'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _moveToInProgress(int inspectionId, Inspection inspection) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Move to In-Progress'),
        content: const Text(
          'This will reopen the inspection and allow the technician to make changes.\n\n'
          'Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final storage = widget.authService.storage;
              storage.inspections[inspectionId] =
                  inspection.copyWith(status: 'in_progress');
              storage.saveData();

              Navigator.pop(context); // Close dialog
              setState(() {}); // Refresh list

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Inspection moved to in-progress'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            child: const Text('Move'),
          ),
        ],
      ),
    );
  }
}
