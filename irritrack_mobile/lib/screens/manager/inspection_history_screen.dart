import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../models/inspection.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/photo_image.dart';

class InspectionHistoryScreen extends StatelessWidget {
  final AuthService authService;

  const InspectionHistoryScreen({Key? key, required this.authService}) : super(key: key);

  String _formatDate(String dateStr) {
    return DateFormatter.formatInspectionDate(dateStr);
  }

  void _viewDetails(BuildContext context, int inspectionId, Inspection inspection) {
    final storage = authService.storage;
    final property = storage.properties[inspection.propertyId];
    final tech = storage.users[inspection.technician];

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: inspection.status == 'completed'
                      ? Colors.green
                      : inspection.status == 'in_progress'
                          ? Colors.blue
                          : Colors.orange,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Inspection #${inspection.id}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            property?.address ?? 'Unknown Property',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
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
                      // Info section
                      _buildInfoRow('Technician', tech?.name ?? 'Unknown'),
                      _buildInfoRow('Date', inspection.date),
                      _buildInfoRow('Status', inspection.status.toUpperCase()),
                      const Divider(height: 32),

                      // Zone Repairs
                      if (inspection.repairs.isNotEmpty) ...[
                        const Text(
                          'Zone Repairs',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...inspection.repairs.map((repair) {
                          final item = storage.repairItems[repair.itemName];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          repair.itemName.replaceAll('_', ' ').toUpperCase(),
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      Text(
                                        '\$${repair.totalCost.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text('Zone: ${repair.zoneNumber}'),
                                  Text('Quantity: ${repair.quantity}'),
                                  if (item != null)
                                    Text('Unit Price: \$${item.price.toStringAsFixed(2)}'),
                                  if (repair.notes.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Notes: ${repair.notes}',
                                      style: const TextStyle(fontStyle: FontStyle.italic),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                        const Divider(height: 32),
                      ],

                      // Other Repairs
                      if (inspection.otherRepairs.isNotEmpty) ...[
                        const Text(
                          'Other Repairs',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...inspection.otherRepairs.map((repair) {
                          final item = storage.repairItems[repair.itemName];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            color: Colors.orange.shade50,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          repair.itemName.replaceAll('_', ' ').toUpperCase(),
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      Text(
                                        '\$${repair.totalCost.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text('Quantity: ${repair.quantity}'),
                                  if (item != null)
                                    Text('Unit Price: \$${item.price.toStringAsFixed(2)}'),
                                  if (repair.notes.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Notes: ${repair.notes}',
                                      style: const TextStyle(fontStyle: FontStyle.italic),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                        const Divider(height: 32),
                      ],

                      // Other Notes
                      if (inspection.otherNotes.isNotEmpty) ...[
                        const Text(
                          'Other Notes',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Text(inspection.otherNotes),
                        ),
                        const Divider(height: 32),
                      ],

                      // Photos
                      if (inspection.photos.isNotEmpty) ...[
                        Text(
                          'Repair Photos (${inspection.photos.length})',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 100,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: inspection.photos.length,
                            itemBuilder: (ctx, i) {
                              return GestureDetector(
                                onTap: () {
                                  showDialog(
                                    context: ctx,
                                    builder: (_) => Dialog(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          AppBar(
                                            title: Text('Photo ${i + 1}'),
                                            leading: IconButton(
                                              icon: const Icon(Icons.close),
                                              onPressed: () => Navigator.pop(ctx),
                                            ),
                                          ),
                                          InteractiveViewer(
                                            child: PhotoImage(
                                              photoData: inspection.photos[i],
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  width: 100,
                                  margin: const EdgeInsets.only(right: 8),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: PhotoImage(
                                      photoData: inspection.photos[i],
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const Divider(height: 32),
                      ],

                      // No repairs message
                      if (inspection.repairs.isEmpty && inspection.otherRepairs.isEmpty) ...[
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Text(
                              'No repairs logged for this inspection',
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      ],

                      // Total
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total Cost',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '\$${inspection.totalCost.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Close button
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final storage = authService.storage;
    final allInspections = storage.inspections.entries.toList();

    // Group by date
    final Map<String, List<MapEntry<int, Inspection>>> groupedByDate = {};
    for (var entry in allInspections) {
      final date = entry.value.date;
      if (!groupedByDate.containsKey(date)) {
        groupedByDate[date] = [];
      }
      groupedByDate[date]!.add(entry);
    }

    // Sort dates descending (newest first)
    final sortedDates = groupedByDate.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inspection History'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '${allInspections.length} total',
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ),
        ],
      ),
      body: allInspections.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No inspections found',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: sortedDates.length,
              itemBuilder: (context, index) {
                final date = sortedDates[index];
                final inspections = groupedByDate[date]!;

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ExpansionTile(
                    initiallyExpanded: index == 0, // First date expanded
                    title: Text(
                      _formatDate(date),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('${inspections.length} inspection(s)'),
                    children: inspections.map((entry) {
                      final inspection = entry.value;
                      final property = storage.properties[inspection.propertyId];
                      final tech = storage.users[inspection.technician];

                      return ListTile(
                        leading: Icon(
                          inspection.status == 'completed'
                              ? Icons.check_circle
                              : inspection.status == 'in_progress'
                                  ? Icons.pending
                                  : Icons.assignment,
                          color: inspection.status == 'completed'
                              ? Colors.green
                              : inspection.status == 'in_progress'
                                  ? Colors.blue
                                  : Colors.orange,
                        ),
                        title: Text(property?.address ?? 'Unknown Property'),
                        subtitle: Text(
                          '${tech?.name ?? "Unknown"} • ${inspection.status}',
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '\$${inspection.totalCost.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'ID: ${entry.key}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        onTap: () => _viewDetails(context, entry.key, inspection),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
    );
  }
}
