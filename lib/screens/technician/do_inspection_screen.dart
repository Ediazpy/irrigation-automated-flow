import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/auth_service.dart';
import '../../services/photo_storage_service.dart';
import '../../widgets/photo_image.dart';
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
    final storage = widget.authService.storage;
    final photosRequired = storage.companySettings?.photosRequired ?? false;

    // Check if photos are required and none taken
    if (photosRequired && inspection.totalPhotoCount == 0) {
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

// Walk Zones Screen with auto-save and zone photos
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
  final ImagePicker _picker = ImagePicker();

  Future<void> _takeZonePhoto(int zoneNumber) async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 512,  // Smaller photos
      maxHeight: 512,
      imageQuality: 50,  // Lower quality = smaller file
    );
    if (image != null) {
      await _saveZonePhoto(zoneNumber, image);
    }
  }

  Future<void> _pickZonePhotoFromGallery(int zoneNumber) async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 50,
    );
    if (image != null) {
      await _saveZonePhoto(zoneNumber, image);
    }
  }

  Future<void> _saveZonePhoto(int zoneNumber, XFile image) async {
    final bytes = await image.readAsBytes();

    final storage = widget.authService.storage;
    final inspection = storage.inspections[widget.inspectionId]!;

    // Upload to Firebase Storage and store the download URL
    String photoRef;
    try {
      photoRef = await PhotoStorageService.uploadInspectionPhoto(
        inspectionId: widget.inspectionId,
        zoneNumber: zoneNumber,
        photoBytes: bytes,
      );
    } catch (e) {
      // Fallback to base64 if upload fails (e.g., no internet)
      print('Firebase Storage upload failed, using base64 fallback: $e');
      photoRef = base64Encode(bytes);
    }

    storage.inspections[widget.inspectionId] = inspection.addPhotoToZone(zoneNumber, photoRef);
    storage.saveData();

    setState(() {});

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Photo saved for Zone $zoneNumber'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _viewZonePhotos(int zoneNumber) {
    final storage = widget.authService.storage;
    final inspection = storage.inspections[widget.inspectionId]!;
    final photos = inspection.getZonePhotos(zoneNumber);
    final photosRequired = storage.companySettings?.photosRequired ?? false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          // Re-read photos in case they changed
          final currentInspection = storage.inspections[widget.inspectionId]!;
          final currentPhotos = currentInspection.getZonePhotos(zoneNumber);

          return AlertDialog(
            title: Row(
              children: [
                Text('Zone $zoneNumber Photos'),
                const Spacer(),
                if (photosRequired)
                  const Chip(
                    label: Text('Required', style: TextStyle(fontSize: 10)),
                    backgroundColor: Colors.red,
                    labelStyle: TextStyle(color: Colors.white),
                    padding: EdgeInsets.zero,
                  ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              height: 300,
              child: currentPhotos.isEmpty
                  ? const Center(child: Text('No photos for this zone'))
                  : GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: currentPhotos.length,
                      itemBuilder: (context, index) {
                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            GestureDetector(
                              onTap: () => _viewFullPhoto(currentPhotos[index]),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: PhotoImage(
                                  photoData: currentPhotos[index],
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () {
                                  _deleteZonePhoto(zoneNumber, index);
                                  setDialogState(() {});
                                  setState(() {});
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close, color: Colors.white, size: 14),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
            ),
            actions: [
              TextButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  await _takeZonePhoto(zoneNumber);
                },
                icon: const Icon(Icons.camera_alt),
                label: const Text('Camera'),
              ),
              TextButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  await _pickZonePhotoFromGallery(zoneNumber);
                },
                icon: const Icon(Icons.photo_library),
                label: const Text('Gallery'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _viewFullPhoto(String photoData) {
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
              child: PhotoImage(
                photoData: photoData,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteZonePhoto(int zoneNumber, int photoIndex) {
    final storage = widget.authService.storage;
    final inspection = storage.inspections[widget.inspectionId]!;

    // Delete from Firebase Storage if it's a URL
    final photos = inspection.getZonePhotos(zoneNumber);
    if (photoIndex < photos.length && PhotoStorageService.isStorageUrl(photos[photoIndex])) {
      PhotoStorageService.deletePhoto(photos[photoIndex]);
    }

    storage.inspections[widget.inspectionId] = inspection.removePhotoFromZone(zoneNumber, photoIndex);
    storage.saveData();
  }

  @override
  Widget build(BuildContext context) {
    final storage = widget.authService.storage;
    final inspection = storage.inspections[widget.inspectionId]!;
    final property = storage.properties[inspection.propertyId]!;
    final photosRequired = storage.companySettings?.photosRequired ?? false;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          storage.saveData(); // Auto-save on back
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Walk Zones'),
          actions: [
            if (photosRequired)
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Center(
                  child: Chip(
                    label: Text('Photos Required', style: TextStyle(fontSize: 11, color: Colors.white)),
                    backgroundColor: Colors.red,
                  ),
                ),
              ),
          ],
        ),
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
                final zonePhotos = inspection.getZonePhotos(zone.zoneNumber);
                final needsPhotos = photosRequired && zoneRepairs.isNotEmpty && zonePhotos.isEmpty;

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ExpansionTile(
                    leading: Stack(
                      children: [
                        CircleAvatar(child: Text('${zone.zoneNumber}')),
                        if (needsPhotos)
                          Positioned(
                            right: -2,
                            top: -2,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.warning, size: 8, color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                    title: Row(
                      children: [
                        Text('Zone ${zone.zoneNumber}'),
                        if (zonePhotos.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.camera_alt, size: 16, color: Colors.grey.shade600),
                          Text(' ${zonePhotos.length}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                        ],
                      ],
                    ),
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

                            // Photos section for this zone
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.camera_alt, size: 18),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Photos (${zonePhotos.length})',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    if (needsPhotos)
                                      const Padding(
                                        padding: EdgeInsets.only(left: 8),
                                        child: Text('Required', style: TextStyle(color: Colors.red, fontSize: 11)),
                                      ),
                                  ],
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.camera_alt, color: Colors.teal),
                                      onPressed: () => _takeZonePhoto(zone.zoneNumber),
                                      tooltip: 'Take Photo',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.photo_library, color: Colors.teal),
                                      onPressed: () => _pickZonePhotoFromGallery(zone.zoneNumber),
                                      tooltip: 'Pick from Gallery',
                                    ),
                                    if (zonePhotos.isNotEmpty)
                                      IconButton(
                                        icon: const Icon(Icons.visibility, color: Colors.blue),
                                        onPressed: () => _viewZonePhotos(zone.zoneNumber),
                                        tooltip: 'View Photos',
                                      ),
                                  ],
                                ),
                              ],
                            ),

                            // Photo thumbnails
                            if (zonePhotos.isNotEmpty)
                              SizedBox(
                                height: 60,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: zonePhotos.length,
                                  itemBuilder: (context, index) {
                                    return GestureDetector(
                                      onTap: () => _viewFullPhoto(zonePhotos[index]),
                                      child: Container(
                                        width: 60,
                                        height: 60,
                                        margin: const EdgeInsets.only(right: 8),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(8),
                                          image: DecorationImage(
                                            image: photoImageProvider(zonePhotos[index]),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),

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
