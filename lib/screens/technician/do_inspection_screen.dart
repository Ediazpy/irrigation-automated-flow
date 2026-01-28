import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
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
                    leading: const Icon(Icons.camera_alt, color: Colors.teal),
                    title: const Text('Repair Photos'),
                    subtitle: Text('${inspection.photos.length} photo(s) taken'),
                    trailing: const Icon(Icons.arrow_forward),
                    onTap: () => _managePhotos(inspection),
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

  void _managePhotos(inspection) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _InspectionPhotosScreen(
          authService: widget.authService,
          inspectionId: widget.inspectionId,
        ),
      ),
    ).then((_) => setState(() {}));
  }

  void _submitInspection(inspection) {
    final storage = widget.authService.storage;
    final photosRequired = storage.companySettings?.photosRequired ?? false;

    // Check if photos are required and none taken
    if (photosRequired && inspection.photos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Photos are required before submitting. Please take at least one photo.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    final totalRepairs = inspection.repairs.length + inspection.otherRepairs.length;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submit Inspection'),
        content: Text(
          'This will complete and lock the inspection.\n\n'
          'Repairs: $totalRepairs\n'
          'Photos: ${inspection.photos.length}\n\n'
          'Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
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

// Photo management screen for inspection
class _InspectionPhotosScreen extends StatefulWidget {
  final AuthService authService;
  final int inspectionId;

  const _InspectionPhotosScreen({
    Key? key,
    required this.authService,
    required this.inspectionId,
  }) : super(key: key);

  @override
  State<_InspectionPhotosScreen> createState() => _InspectionPhotosScreenState();
}

class _InspectionPhotosScreenState extends State<_InspectionPhotosScreen> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _takePhoto() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 70,
    );
    if (image != null) {
      await _savePhoto(image);
    }
  }

  Future<void> _pickFromGallery() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 70,
    );
    if (image != null) {
      await _savePhoto(image);
    }
  }

  Future<void> _savePhoto(XFile image) async {
    final bytes = await image.readAsBytes();
    final base64Str = base64Encode(bytes);

    final storage = widget.authService.storage;
    final inspection = storage.inspections[widget.inspectionId]!;
    final updatedPhotos = List<String>.from(inspection.photos)..add(base64Str);

    storage.inspections[widget.inspectionId] = inspection.copyWith(photos: updatedPhotos);
    storage.saveData();

    setState(() {});

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo saved'), backgroundColor: Colors.green),
      );
    }
  }

  void _deletePhoto(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Photo'),
        content: const Text('Are you sure you want to delete this photo?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              final storage = widget.authService.storage;
              final inspection = storage.inspections[widget.inspectionId]!;
              final updatedPhotos = List<String>.from(inspection.photos)..removeAt(index);
              storage.inspections[widget.inspectionId] = inspection.copyWith(photos: updatedPhotos);
              storage.saveData();
              setState(() {});
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _viewPhoto(String base64Str) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('Photo'),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            InteractiveViewer(
              child: Image.memory(
                base64Decode(base64Str),
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final storage = widget.authService.storage;
    final inspection = storage.inspections[widget.inspectionId]!;
    final photosRequired = storage.companySettings?.photosRequired ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Repair Photos'),
        actions: [
          if (photosRequired)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: Chip(
                  label: Text('Required', style: TextStyle(color: Colors.white, fontSize: 12)),
                  backgroundColor: Colors.red,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          if (photosRequired && inspection.photos.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.red.shade50,
              child: const Row(
                children: [
                  Icon(Icons.warning, color: Colors.red),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'At least one photo is required before submitting this inspection.',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: inspection.photos.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.no_photography, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'No photos taken yet',
                          style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: inspection.photos.length,
                    itemBuilder: (context, index) {
                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          GestureDetector(
                            onTap: () => _viewPhoto(inspection.photos[index]),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.memory(
                                base64Decode(inspection.photos[index]),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => _deletePhoto(index),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close, color: Colors.white, size: 16),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _takePhoto,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Take Photo'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickFromGallery,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Gallery'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(14),
                    ),
                  ),
                ),
              ],
            ),
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
