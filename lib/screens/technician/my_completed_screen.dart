import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../models/inspection.dart';

class MyCompletedScreen extends StatelessWidget {
  final AuthService authService;

  const MyCompletedScreen({Key? key, required this.authService}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final storage = authService.storage;
    final myEmail = authService.currentUser?.email;

    // Get current month/year
    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;

    // Get all inspections I completed this month
    // Include 'completed' and 'quote_sent' but display as "Completed" to tech
    final completedInspections = storage.inspections.values
        .where((i) {
          if (i.technician != myEmail) return false;
          // Only show completed or quote_sent (both mean work is done from tech perspective)
          if (i.status != 'completed' && i.status != 'quote_sent') return false;

          // Filter to current month
          try {
            final inspDate = DateTime.parse(i.date);
            return inspDate.month == currentMonth && inspDate.year == currentYear;
          } catch (e) {
            return false;
          }
        })
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date)); // Most recent first

    return Scaffold(
      appBar: AppBar(
        title: Text('My Completed - ${DateFormat('MMMM yyyy').format(now)}'),
      ),
      body: completedInspections.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment_turned_in, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No completed inspections this month',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: completedInspections.length,
              itemBuilder: (context, index) {
                final insp = completedInspections[index];
                final prop = storage.properties[insp.propertyId];

                // Parse completion date for display
                String completionDateStr = insp.date;
                try {
                  final date = DateTime.parse(insp.date);
                  completionDateStr = DateFormat('MMM d, yyyy').format(date);
                } catch (e) {
                  // Keep original string if parsing fails
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.green,
                      child: Icon(Icons.check, color: Colors.white),
                    ),
                    title: Text(
                      prop?.address ?? 'Unknown Property',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Completed: $completionDateStr'),
                        Text(
                          '${insp.repairs.length + insp.otherRepairs.length} repairs documented',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        ),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showInspectionDetails(context, insp, prop?.address ?? 'Unknown'),
                  ),
                );
              },
            ),
    );
  }

  void _showInspectionDetails(BuildContext context, Inspection insp, String address) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(address, style: const TextStyle(fontSize: 16)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Date: ${insp.date}', style: const TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 12),
              if (insp.repairs.isNotEmpty) ...[
                const Text('Zone Repairs:', style: TextStyle(fontWeight: FontWeight.bold)),
                ...insp.repairs.map((r) => Padding(
                  padding: const EdgeInsets.only(left: 8, top: 4),
                  child: Text('• Z${r.zoneNumber}: ${r.itemName.replaceAll('_', ' ')} x${r.quantity}'),
                )),
                const SizedBox(height: 8),
              ],
              if (insp.otherRepairs.isNotEmpty) ...[
                const Text('Other Repairs:', style: TextStyle(fontWeight: FontWeight.bold)),
                ...insp.otherRepairs.map((r) => Padding(
                  padding: const EdgeInsets.only(left: 8, top: 4),
                  child: Text('• ${r.itemName.replaceAll('_', ' ')} x${r.quantity}'),
                )),
                const SizedBox(height: 8),
              ],
              if (insp.otherNotes.isNotEmpty) ...[
                const Text('Notes:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(insp.otherNotes),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
