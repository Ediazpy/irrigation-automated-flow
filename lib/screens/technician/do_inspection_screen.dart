import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../models/repair.dart';

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
    final inspection = storage.inspections[widget.inspectionId];
    final property = storage.properties[inspection?.propertyId];

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
                  Text('Repairs logged: ${inspection.repairs.length + inspection.otherRepairs.length}'),
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
                    subtitle: const Text('Add repairs to zones'),
                    trailing: const Icon(Icons.arrow_forward),
                    onTap: () => _walkZones(inspection, property),
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.list, color: Colors.green),
                    title: const Text('View Current Repairs'),
                    subtitle: Text('${inspection.repairs.length} repairs'),
                    trailing: const Icon(Icons.arrow_forward),
                    onTap: () => _viewRepairs(inspection),
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.history, color: Colors.orange),
                    title: const Text('Previous Month Repairs'),
                    subtitle: const Text('View repairs from last inspection'),
                    trailing: const Icon(Icons.arrow_forward),
                    onTap: () => _viewPreviousRepairs(inspection.propertyId),
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.check_circle, color: Colors.purple),
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

  void _walkZones(inspection, property) {
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

  void _viewRepairs(inspection) {
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
                    final isZoneRepair = repair.zoneNumber > 0;
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

    // Find the most recent completed inspection for this property (excluding current)
    final previousInspections = storage.inspections.values
        .where((insp) =>
            insp.propertyId == propertyId &&
            insp.id != widget.inspectionId &&
            insp.status == 'completed')
        .toList();

    // Sort by date descending to get most recent
    previousInspections.sort((a, b) {
      try {
        final dateA = DateFormat('MM/dd/yyyy').parse(a.date);
        final dateB = DateFormat('MM/dd/yyyy').parse(b.date);
        return dateB.compareTo(dateA);
      } catch (e) {
        return 0;
      }
    });

    final previousInspection =
        previousInspections.isNotEmpty ? previousInspections.first : null;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Previous Month Repairs'),
        content: SizedBox(
          width: double.maxFinite,
          child: previousInspection == null
              ? const Text('No previous inspection found for this property')
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
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text('Billing Month: ${previousInspection.billingMonth}'),
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
                      const Text('No zone repairs', style: TextStyle(color: Colors.grey))
                    else
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: previousInspection.repairs.length,
                          itemBuilder: (context, index) {
                            final repair = previousInspection.repairs[index];
                            return ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: Text(repair.itemName.replaceAll('_', ' ')),
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
                      const Text('No other repairs', style: TextStyle(color: Colors.grey))
                    else
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: previousInspection.otherRepairs.length,
                          itemBuilder: (context, index) {
                            final repair = previousInspection.otherRepairs[index];
                            return ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: Text(repair.itemName.replaceAll('_', ' ')),
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

  void _submitInspection(inspection) {
    final totalRepairs = inspection.repairs.length + inspection.otherRepairs.length;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submit Inspection'),
        content: Text(
          'This will complete and lock the inspection.\n\n'
          'Repairs: $totalRepairs\n\n'
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
              final totalCost = inspection.calculateTotalCost();

              storage.inspections[widget.inspectionId] = inspection.copyWith(
                status: 'review',
                totalCost: totalCost,
              );
              storage.saveData();

              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close inspection screen

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

// Define categories that are "other repairs" (not zone-specific)
const List<String> otherRepairCategories = [
  'backflow',
  'ball_valve',
  'controller',
  'pipe_mainline',
  'winterize',
  'wire',
  'sensor',
  'service',
];

// Define categories that are zone-specific repairs
const List<String> zoneRepairCategories = [
  'heads',
  'stems',
  'nozzles',
  'drip',
  'pipe_lateral',
  'valves',
];

// Walk Zones Screen
class WalkZonesScreen extends StatefulWidget {
  final AuthService authService;
  final int inspectionId;

  const WalkZonesScreen({
    Key? key,
    required this.authService,
    required this.inspectionId,
  }) : super(key: key);

  @override
  State<WalkZonesScreen> createState() => _WalkZonesScreenState();
}

class _WalkZonesScreenState extends State<WalkZonesScreen> {
  @override
  Widget build(BuildContext context) {
    final storage = widget.authService.storage;
    final inspection = storage.inspections[widget.inspectionId]!;
    final property = storage.properties[inspection.propertyId]!;

    return Scaffold(
      appBar: AppBar(title: const Text('Walk Zones')),
      body: ListView(
        children: [
          // Zone Repairs Section
          if (property.zones.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Zone Repairs',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ...property.zones.map((zone) {
              final zoneRepairs = inspection.repairs
                  .where((r) => r.zoneNumber == zone.zoneNumber)
                  .toList();

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ExpansionTile(
                  leading: CircleAvatar(child: Text('${zone.zoneNumber}')),
                  title: Text('Zone ${zone.zoneNumber}'),
                  subtitle: Text(zone.description),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Head Type: ${zone.headType}'),
                          if (zone.headCount != null)
                            Text('Head Count: ${zone.headCount}'),
                          const Divider(),
                          const Text(
                            'Repairs in this zone:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          if (zoneRepairs.isEmpty)
                            const Text('No repairs logged'),
                          ...zoneRepairs.asMap().entries.map((entry) {
                            final repair = entry.value;
                            return ListTile(
                              dense: true,
                              title: Text(repair.itemName.replaceAll('_', ' ')),
                              subtitle: repair.notes.isNotEmpty
                                  ? Text(repair.notes)
                                  : null,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('x${repair.quantity}'),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                    onPressed: () => _deleteRepair(repair, true),
                                  ),
                                ],
                              ),
                            );
                          }),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () => _addRepair(zone.zoneNumber),
                            icon: const Icon(Icons.add),
                            label: const Text('Add Repair'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],

          // Other Repairs Section
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text(
              'Other Repairs',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Backflow, Controller, Mainline, Winterize, Wire, etc.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
          Card(
            margin: const EdgeInsets.all(8),
            color: Colors.orange.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (inspection.otherRepairs.isEmpty)
                    const Text('No other repairs logged'),
                  ...inspection.otherRepairs.asMap().entries.map((entry) {
                    final repair = entry.value;
                    return ListTile(
                      dense: true,
                      title: Text(repair.itemName.replaceAll('_', ' ')),
                      subtitle: repair.notes.isNotEmpty
                          ? Text(repair.notes)
                          : null,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('x${repair.quantity}'),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                            onPressed: () => _deleteRepair(repair, false),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => _addOtherRepair(),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Other Repair'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Other Notes Section
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Other Notes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Card(
            margin: const EdgeInsets.all(8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    inspection.otherNotes.isEmpty
                        ? 'No notes added'
                        : inspection.otherNotes,
                    style: TextStyle(
                      color: inspection.otherNotes.isEmpty
                          ? Colors.grey
                          : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => _editOtherNotes(),
                    icon: Icon(inspection.otherNotes.isEmpty
                        ? Icons.add
                        : Icons.edit),
                    label: Text(inspection.otherNotes.isEmpty
                        ? 'Add Notes'
                        : 'Edit Notes'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _deleteRepair(Repair repair, bool isZoneRepair) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Repair'),
        content: Text('Delete ${repair.itemName.replaceAll('_', ' ')}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              final storage = widget.authService.storage;
              final inspection = storage.inspections[widget.inspectionId]!;

              if (isZoneRepair) {
                final updatedRepairs = List<Repair>.from(inspection.repairs)
                  ..remove(repair);
                storage.inspections[widget.inspectionId] =
                    inspection.copyWith(repairs: updatedRepairs);
              } else {
                final updatedOtherRepairs =
                    List<Repair>.from(inspection.otherRepairs)..remove(repair);
                storage.inspections[widget.inspectionId] =
                    inspection.copyWith(otherRepairs: updatedOtherRepairs);
              }
              storage.saveData();

              setState(() {});
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Repair deleted')),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _editOtherNotes() {
    final storage = widget.authService.storage;
    final inspection = storage.inspections[widget.inspectionId]!;
    final notesController = TextEditingController(text: inspection.otherNotes);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Other Notes'),
        content: TextField(
          controller: notesController,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Enter any additional notes...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              storage.inspections[widget.inspectionId] =
                  inspection.copyWith(otherNotes: notesController.text);
              storage.saveData();
              setState(() {});
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _addRepair(int zoneNumber) {
    final storage = widget.authService.storage;
    // Only show zone repair categories
    final categories = zoneRepairCategories
        .where((cat) => storage.getItemsByCategory(cat).isNotEmpty)
        .toList();

    String? selectedCategory;
    String? selectedItem;
    int quantity = 1;
    String notes = '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final categoryItems = selectedCategory != null
              ? storage.getItemsByCategory(selectedCategory!)
              : <dynamic>[];

          return AlertDialog(
            title: Text('Add Repair to Zone $zoneNumber'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Category dropdown
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: categories.map((cat) => DropdownMenuItem(
                          value: cat,
                          child: Text(cat.replaceAll('_', ' ')),
                        )).toList(),
                    onChanged: (val) {
                      setDialogState(() {
                        selectedCategory = val;
                        selectedItem = null;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  // Item dropdown
                  if (selectedCategory != null)
                    DropdownButtonFormField<String>(
                      value: selectedItem,
                      decoration: const InputDecoration(labelText: 'Repair Item'),
                      items: categoryItems.map((item) => DropdownMenuItem<String>(
                            value: item.name,
                            child: Text(item.name.replaceAll('_', ' ')),
                          )).toList(),
                      onChanged: (val) {
                        setDialogState(() {
                          selectedItem = val;
                        });
                      },
                    ),
                  const SizedBox(height: 12),
                  // Quantity
                  TextField(
                    decoration: const InputDecoration(labelText: 'Quantity'),
                    keyboardType: TextInputType.number,
                    onChanged: (val) => quantity = int.tryParse(val) ?? 1,
                  ),
                  const SizedBox(height: 12),
                  // Notes (if required)
                  if (selectedItem != null && storage.repairItems[selectedItem]?.requiresNotes == true)
                    TextField(
                      decoration: const InputDecoration(labelText: 'Notes'),
                      onChanged: (val) => notes = val,
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (selectedItem == null) return;

                  final item = storage.repairItems[selectedItem]!;
                  final repair = Repair(
                    zoneNumber: zoneNumber,
                    itemName: selectedItem!,
                    quantity: quantity,
                    price: item.price,
                    notes: notes,
                  );

                  final inspection = storage.inspections[widget.inspectionId]!;
                  final updatedRepairs = List<Repair>.from(inspection.repairs)..add(repair);
                  storage.inspections[widget.inspectionId] = inspection.copyWith(repairs: updatedRepairs);
                  storage.saveData();

                  setState(() {});
                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Repair added!')),
                  );
                },
                child: const Text('Add'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _addOtherRepair() {
    final storage = widget.authService.storage;
    // Only show other repair categories
    final categories = otherRepairCategories
        .where((cat) => storage.getItemsByCategory(cat).isNotEmpty)
        .toList();

    String? selectedCategory;
    String? selectedItem;
    int quantity = 1;
    String notes = '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final categoryItems = selectedCategory != null
              ? storage.getItemsByCategory(selectedCategory!)
              : <dynamic>[];

          return AlertDialog(
            title: const Text('Add Other Repair'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Category dropdown
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: categories.map((cat) => DropdownMenuItem(
                          value: cat,
                          child: Text(cat.replaceAll('_', ' ')),
                        )).toList(),
                    onChanged: (val) {
                      setDialogState(() {
                        selectedCategory = val;
                        selectedItem = null;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  // Item dropdown
                  if (selectedCategory != null)
                    DropdownButtonFormField<String>(
                      value: selectedItem,
                      decoration: const InputDecoration(labelText: 'Repair Item'),
                      items: categoryItems.map((item) => DropdownMenuItem<String>(
                            value: item.name,
                            child: Text(item.name.replaceAll('_', ' ')),
                          )).toList(),
                      onChanged: (val) {
                        setDialogState(() {
                          selectedItem = val;
                        });
                      },
                    ),
                  const SizedBox(height: 12),
                  // Quantity
                  TextField(
                    decoration: const InputDecoration(labelText: 'Quantity'),
                    keyboardType: TextInputType.number,
                    onChanged: (val) => quantity = int.tryParse(val) ?? 1,
                  ),
                  const SizedBox(height: 12),
                  // Notes (if required or optional for other repairs)
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      hintText: 'Optional details',
                    ),
                    onChanged: (val) => notes = val,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (selectedItem == null) return;

                  final item = storage.repairItems[selectedItem]!;
                  final repair = Repair(
                    zoneNumber: 0, // Other repairs don't belong to a zone
                    itemName: selectedItem!,
                    quantity: quantity,
                    price: item.price,
                    notes: notes,
                  );

                  final inspection = storage.inspections[widget.inspectionId]!;
                  final updatedOtherRepairs = List<Repair>.from(inspection.otherRepairs)..add(repair);
                  storage.inspections[widget.inspectionId] = inspection.copyWith(otherRepairs: updatedOtherRepairs);
                  storage.saveData();

                  setState(() {});
                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Repair added!')),
                  );
                },
                child: const Text('Add'),
              ),
            ],
          );
        },
      ),
    );
  }
}
