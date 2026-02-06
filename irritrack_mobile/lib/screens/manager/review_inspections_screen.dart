import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../models/inspection.dart';
import '../../utils/date_formatter.dart';
import 'review_inspection_detail_screen.dart';

/// List screen showing all inspections pending manager review.
/// Groups inspections by date and navigates to detail screen for editing.
class ReviewInspectionsScreen extends StatefulWidget {
  final AuthService authService;

  const ReviewInspectionsScreen({Key? key, required this.authService})
      : super(key: key);

  @override
  State<ReviewInspectionsScreen> createState() =>
      _ReviewInspectionsScreenState();
}

class _ReviewInspectionsScreenState extends State<ReviewInspectionsScreen> {
  String _formatDate(String dateStr) {
    return DateFormatter.formatInspectionDate(dateStr);
  }

  void _viewAndEditInspection(
      BuildContext context, int inspectionId, Inspection inspection) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReviewInspectionDetailScreen(
          authService: widget.authService,
          inspectionId: inspectionId,
          inspection: inspection,
        ),
      ),
    ).then((_) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final storage = widget.authService.storage;
    final reviewInspections = storage.inspections.entries
        .where((e) => e.value.status == 'review')
        .toList();

    // Group by date for organized display
    final Map<String, List<MapEntry<int, Inspection>>> groupedByDate = {};
    for (var entry in reviewInspections) {
      final date = entry.value.date;
      if (!groupedByDate.containsKey(date)) {
        groupedByDate[date] = [];
      }
      groupedByDate[date]!.add(entry);
    }

    final sortedDates = groupedByDate.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Inspections'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Chip(
                label: Text(
                  '${reviewInspections.length} pending',
                  style: const TextStyle(color: Colors.white),
                ),
                backgroundColor: Colors.orange,
              ),
            ),
          ),
        ],
      ),
      body: reviewInspections.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline,
                      size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No inspections pending review',
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
                    initiallyExpanded: index == 0,
                    title: Text(
                      _formatDate(date),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('${inspections.length} inspection(s)'),
                    children: inspections.map((entry) {
                      final Inspection inspection = entry.value;
                      final property =
                          storage.properties[inspection.propertyId];
                      final tech = storage.users[inspection.technician];

                      return ListTile(
                        leading: const Icon(
                          Icons.rate_review,
                          color: Colors.orange,
                          size: 32,
                        ),
                        title:
                            Text(property?.address ?? 'Unknown Property'),
                        subtitle: Text(
                          '${tech?.name ?? "Unknown"} • ${inspection.repairs.length + inspection.otherRepairs.length} repairs',
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
                            const Text(
                              'Tap to review',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                        onTap: () => _viewAndEditInspection(
                            context, entry.key, inspection),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
    );
  }
}
