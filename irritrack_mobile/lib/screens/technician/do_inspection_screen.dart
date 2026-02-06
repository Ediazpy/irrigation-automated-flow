import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../models/inspection.dart';
import '../../models/property.dart';
import 'walk_zones_screen.dart';

/// Entry screen for a technician performing an inspection.
/// Shows inspection summary and navigation to walk zones, view repairs, etc.
class DoInspectionScreen extends StatefulWidget {
  final AuthService authService;
  final int inspectionId;

  const DoInspectionScreen({
    Key? key,
    required this.authService,
    required this.inspectionId,
  }) : super(key: key);

  @override
  State<DoInspectionScreen> createState() => _DoInspectionScreenState();
}

class _DoInspectionScreenState extends State<DoInspectionScreen> {
  @override
  Widget build(BuildContext context) {
    final storage = widget.authService.storage;
    final Inspection? inspection = storage.inspections[widget.inspectionId];
    final Property? property = storage.properties[inspection?.propertyId];

    if (inspection == null || property == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Inspection')),
        body: const Center(child: Text('Inspection not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(property.address),
      ),
      body: Column(
        children: [
          // Inspection Info Card
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Inspection Details',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Divider(),
                  Text('Date: ${inspection.date}'),
                  Text('Status: ${inspection.status}'),
                  Text(
                      'Repairs logged: ${inspection.repairs.length + inspection.otherRepairs.length}'),
                  Text('Photos: ${inspection.totalPhotoCount}'),
                ],
              ),
            ),
          ),

          // Menu Options
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.route, color: Colors.blue),
                    title: const Text('Walk Zones'),
                    subtitle: const Text('Add repairs & photos to zones'),
                    trailing: const Icon(Icons.arrow_forward),
                    onTap: () => _walkZones(inspection, property),
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.list, color: Colors.green),
                    title: const Text('View Current Repairs'),
                    subtitle:
                        Text('${inspection.repairs.length} repairs'),
                    trailing: const Icon(Icons.arrow_forward),
                    onTap: () => _viewRepairs(inspection),
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.history, color: Colors.orange),
                    title: const Text('Previous Month Repairs'),
                    subtitle:
                        const Text('View repairs from last inspection'),
                    trailing: const Icon(Icons.arrow_forward),
                    onTap: () =>
                        _viewPreviousRepairs(inspection.propertyId),
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    leading:
                        const Icon(Icons.check_circle, color: Colors.purple),
                    title: const Text('Submit Inspection'),
                    subtitle: const Text('Complete and lock inspection'),
                    trailing: const Icon(Icons.arrow_forward),
                    onTap: () => _submitInspection(inspection),
                  ),
                ),
              ],
            ),
          ),

          // Bottom Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: () {
                widget.authService.storage.saveData();
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Save and Exit'),
            ),
          ),
        ],
      ),
    );
  }

  void _walkZones(Inspection inspection, Property property) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WalkZonesScreen(
          authService: widget.authService,
          inspectionId: widget.inspectionId,
        ),
      ),
    ).then((_) => setState(() {}));
  }

  void _viewRepairs(Inspection inspection) {
    final allRepairs = [...inspection.repairs, ...inspection.otherRepairs];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Current Repairs'),
        content: SizedBox(
          width: double.maxFinite,
          child: allRepairs.isEmpty
              ? const Text('No repairs logged yet')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: allRepairs.length,
                  itemBuilder: (context, index) {
                    final repair = allRepairs[index];
                    final bool isZoneRepair = repair.zoneNumber > 0;
                    return ListTile(
                      title: Text(repair.itemName.replaceAll('_', ' ')),
                      subtitle: Text(isZoneRepair
                          ? 'Zone ${repair.zoneNumber} - Qty: ${repair.quantity}'
                          : 'Qty: ${repair.quantity}'),
                    );
                  },
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

  void _viewPreviousRepairs(int propertyId) {
    final storage = widget.authService.storage;

    // Find the most recent completed inspection for this property
    final previousInspections = storage.inspections.values
        .where((Inspection insp) =>
            insp.propertyId == propertyId &&
            insp.id != widget.inspectionId &&
            insp.status == 'completed')
        .toList();

    previousInspections.sort((a, b) {
      try {
        final dateA = DateFormat('MM/dd/yyyy').parse(a.date);
        final dateB = DateFormat('MM/dd/yyyy').parse(b.date);
        return dateB.compareTo(dateA);
      } catch (e) {
        return 0;
      }
    });

    final Inspection? previousInspection =
        previousInspections.isNotEmpty ? previousInspections.first : null;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Previous Month Repairs'),
        content: SizedBox(
          width: double.maxFinite,
          child: previousInspection == null
              ? const Text(
                  'No previous inspection found for this property')
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Date: ${previousInspection.date}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold),
                          ),
                          Text(
                              'Billing Month: ${previousInspection.billingMonth}'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Zone Repairs:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    if (previousInspection.repairs.isEmpty)
                      const Text('No zone repairs',
                          style: TextStyle(color: Colors.grey))
                    else
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: previousInspection.repairs.length,
                          itemBuilder: (context, index) {
                            final repair =
                                previousInspection.repairs[index];
                            return ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: Text(repair.itemName
                                  .replaceAll('_', ' ')),
                              subtitle: Text(
                                'Zone ${repair.zoneNumber} - Qty: ${repair.quantity}${repair.notes.isNotEmpty ? '\n${repair.notes}' : ''}',
                              ),
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 12),
                    const Text(
                      'Other Repairs:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    if (previousInspection.otherRepairs.isEmpty)
                      const Text('No other repairs',
                          style: TextStyle(color: Colors.grey))
                    else
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount:
                              previousInspection.otherRepairs.length,
                          itemBuilder: (context, index) {
                            final repair =
                                previousInspection.otherRepairs[index];
                            return ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: Text(repair.itemName
                                  .replaceAll('_', ' ')),
                              subtitle: Text(
                                'Qty: ${repair.quantity}${repair.notes.isNotEmpty ? '\n${repair.notes}' : ''}',
                              ),
                            );
                          },
                        ),
                      ),
                    if (previousInspection.otherNotes.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Text(
                        'Notes:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(previousInspection.otherNotes),
                      ),
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

  void _submitInspection(Inspection inspection) {
    final storage = widget.authService.storage;
    final bool photosRequired =
        storage.companySettings?.photosRequired ?? false;

    if (photosRequired && inspection.totalPhotoCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Photos are required before submitting. Please take at least one photo.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    final int totalRepairs =
        inspection.repairs.length + inspection.otherRepairs.length;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submit Inspection'),
        content: Text(
          'This will complete and lock the inspection.\n\n'
          'Repairs: $totalRepairs\n'
          'Photos: ${inspection.totalPhotoCount}\n\n'
          'Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final double totalCost = inspection.calculateTotalCost();

              storage.inspections[widget.inspectionId] =
                  inspection.copyWith(
                status: 'review',
                totalCost: totalCost,
              );
              storage.saveData();

              Navigator.pop(context);
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Inspection submitted for review!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}
