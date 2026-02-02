import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/auth_service.dart';
import '../../services/photo_storage_service.dart';
import '../../widgets/photo_image.dart';
import '../../models/property.dart';
import '../../models/zone.dart';
import '../../models/inspection.dart';
import '../../models/repair.dart';
import '../../models/controller.dart';

/// Categories for non-zone repairs (backflow, controller, mainline, etc.)
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

/// Categories for zone-specific repairs (heads, nozzles, valves, etc.)
const List<String> zoneRepairCategories = [
  'heads',
  'stems',
  'nozzles',
  'drip',
  'pipe_lateral',
  'valves',
];

/// Screen for walking through zones during an inspection.
/// Technicians use this to add repairs, photos, and notes per zone.
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

  // -- Photo methods --

  Future<void> _takeZonePhoto(int zoneNumber) async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 50,
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

  /// Uploads photo to Firebase Storage (falls back to base64 if offline).
  Future<void> _saveZonePhoto(int zoneNumber, XFile image) async {
    final bytes = await image.readAsBytes();
    final storage = widget.authService.storage;
    final Inspection inspection = storage.inspections[widget.inspectionId]!;

    String photoRef;
    try {
      photoRef = await PhotoStorageService.uploadInspectionPhoto(
        inspectionId: widget.inspectionId,
        zoneNumber: zoneNumber,
        photoBytes: bytes,
      );
    } catch (e) {
      // Base64 fallback keeps the app working without internet in the field
      print('Firebase Storage upload failed, using base64 fallback: $e');
      photoRef = base64Encode(bytes);
    }

    storage.inspections[widget.inspectionId] =
        inspection.addPhotoToZone(zoneNumber, photoRef);
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
    final bool photosRequired = storage.companySettings?.photosRequired ?? false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final Inspection currentInspection =
              storage.inspections[widget.inspectionId]!;
          final List<String> currentPhotos =
              currentInspection.getZonePhotos(zoneNumber);

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
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
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
                                  child: const Icon(Icons.close,
                                      color: Colors.white, size: 14),
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
    final Inspection inspection = storage.inspections[widget.inspectionId]!;

    final List<String> photos = inspection.getZonePhotos(zoneNumber);
    if (photoIndex < photos.length &&
        PhotoStorageService.isStorageUrl(photos[photoIndex])) {
      PhotoStorageService.deletePhoto(photos[photoIndex]);
    }

    storage.inspections[widget.inspectionId] =
        inspection.removePhotoFromZone(zoneNumber, photoIndex);
    storage.saveData();
  }

  // -- Zone widget builders --

  /// Groups zones under "Controller N" headers when there are multiple controllers.
  /// Falls back to a flat list for legacy single-controller properties.
  List<Widget> _buildControllerZoneWidgets(
    Property property,
    Inspection inspection,
    bool photosRequired,
  ) {
    final widgets = <Widget>[];

    if (property.controllers.isNotEmpty) {
      for (Controller controller in property.controllers) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Row(
              children: [
                Icon(Icons.settings_remote,
                    color: Colors.teal.shade700, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Controller ${controller.controllerNumber}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal.shade700,
                  ),
                ),
                if (controller.location.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Text(
                    '(${controller.location})',
                    style:
                        TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ],
            ),
          ),
        );

        if (controller.zones.isEmpty) {
          widgets.add(
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text('No zones configured',
                  style: TextStyle(color: Colors.grey)),
            ),
          );
        } else {
          for (Zone zone in controller.zones) {
            widgets.add(_buildZoneCard(
              zone,
              inspection,
              photosRequired,
              showController: property.hasMultipleControllers,
            ));
          }
        }
      }
    } else if (property.zones.isNotEmpty) {
      widgets.add(
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Zone Repairs',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      );
      for (Zone zone in property.zones) {
        widgets.add(_buildZoneCard(zone, inspection, photosRequired,
            showController: false));
      }
    }

    return widgets;
  }

  /// Renders a single zone as an expandable card with photos, repairs, and add button.
  Widget _buildZoneCard(
    Zone zone,
    Inspection inspection,
    bool photosRequired, {
    bool showController = false,
  }) {
    final List<Repair> zoneRepairs = inspection.repairs
        .where((Repair r) => r.zoneNumber == zone.zoneNumber)
        .toList();
    final List<String> zonePhotos = inspection.getZonePhotos(zone.zoneNumber);
    final bool needsPhotos =
        photosRequired && zoneRepairs.isNotEmpty && zonePhotos.isEmpty;

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
                  child:
                      const Icon(Icons.warning, size: 8, color: Colors.white),
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
              Text(' ${zonePhotos.length}',
                  style:
                      TextStyle(fontSize: 12, color: Colors.grey.shade600)),
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

                // Photos row
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
                            child: Text('Required',
                                style: TextStyle(
                                    color: Colors.red, fontSize: 11)),
                          ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon:
                              const Icon(Icons.camera_alt, color: Colors.teal),
                          onPressed: () => _takeZonePhoto(zone.zoneNumber),
                          tooltip: 'Take Photo',
                        ),
                        IconButton(
                          icon: const Icon(Icons.photo_library,
                              color: Colors.teal),
                          onPressed: () =>
                              _pickZonePhotoFromGallery(zone.zoneNumber),
                          tooltip: 'Pick from Gallery',
                        ),
                        if (zonePhotos.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.visibility,
                                color: Colors.blue),
                            onPressed: () =>
                                _viewZonePhotos(zone.zoneNumber),
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
                if (zoneRepairs.isEmpty) const Text('No repairs logged'),
                ...zoneRepairs.asMap().entries.map((entry) {
                  final Repair repair = entry.value;
                  return ListTile(
                    dense: true,
                    title: Text(repair.itemName.replaceAll('_', ' ')),
                    subtitle:
                        repair.notes.isNotEmpty ? Text(repair.notes) : null,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('x${repair.quantity}'),
                        IconButton(
                          icon: const Icon(Icons.delete,
                              color: Colors.red, size: 20),
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
  }

  // -- Repair CRUD methods --

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
              final Inspection inspection =
                  storage.inspections[widget.inspectionId]!;

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
    final Inspection inspection = storage.inspections[widget.inspectionId]!;
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
    final categories = zoneRepairCategories
        .where((String cat) => storage.getItemsByCategory(cat).isNotEmpty)
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
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: categories
                        .map((String cat) => DropdownMenuItem(
                              value: cat,
                              child: Text(cat.replaceAll('_', ' ')),
                            ))
                        .toList(),
                    onChanged: (String? val) {
                      setDialogState(() {
                        selectedCategory = val;
                        selectedItem = null;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  if (selectedCategory != null)
                    DropdownButtonFormField<String>(
                      value: selectedItem,
                      decoration:
                          const InputDecoration(labelText: 'Repair Item'),
                      items: categoryItems
                          .map((item) => DropdownMenuItem<String>(
                                value: item.name,
                                child: Text(item.name.replaceAll('_', ' ')),
                              ))
                          .toList(),
                      onChanged: (String? val) {
                        setDialogState(() {
                          selectedItem = val;
                        });
                      },
                    ),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: const InputDecoration(labelText: 'Quantity'),
                    keyboardType: TextInputType.number,
                    onChanged: (String val) =>
                        quantity = int.tryParse(val) ?? 1,
                  ),
                  const SizedBox(height: 12),
                  if (selectedItem != null &&
                      storage.repairItems[selectedItem]?.requiresNotes == true)
                    TextField(
                      decoration: const InputDecoration(labelText: 'Notes'),
                      onChanged: (String val) => notes = val,
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

                  final Inspection inspection =
                      storage.inspections[widget.inspectionId]!;
                  final updatedRepairs =
                      List<Repair>.from(inspection.repairs)..add(repair);
                  storage.inspections[widget.inspectionId] =
                      inspection.copyWith(repairs: updatedRepairs);
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
    final categories = otherRepairCategories
        .where((String cat) => storage.getItemsByCategory(cat).isNotEmpty)
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
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: categories
                        .map((String cat) => DropdownMenuItem(
                              value: cat,
                              child: Text(cat.replaceAll('_', ' ')),
                            ))
                        .toList(),
                    onChanged: (String? val) {
                      setDialogState(() {
                        selectedCategory = val;
                        selectedItem = null;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  if (selectedCategory != null)
                    DropdownButtonFormField<String>(
                      value: selectedItem,
                      decoration:
                          const InputDecoration(labelText: 'Repair Item'),
                      items: categoryItems
                          .map((item) => DropdownMenuItem<String>(
                                value: item.name,
                                child: Text(item.name.replaceAll('_', ' ')),
                              ))
                          .toList(),
                      onChanged: (String? val) {
                        setDialogState(() {
                          selectedItem = val;
                        });
                      },
                    ),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: const InputDecoration(labelText: 'Quantity'),
                    keyboardType: TextInputType.number,
                    onChanged: (String val) =>
                        quantity = int.tryParse(val) ?? 1,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      hintText: 'Optional details',
                    ),
                    onChanged: (String val) => notes = val,
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
                    zoneNumber: 0,
                    itemName: selectedItem!,
                    quantity: quantity,
                    price: item.price,
                    notes: notes,
                  );

                  final Inspection inspection =
                      storage.inspections[widget.inspectionId]!;
                  final updatedOtherRepairs =
                      List<Repair>.from(inspection.otherRepairs)..add(repair);
                  storage.inspections[widget.inspectionId] =
                      inspection.copyWith(otherRepairs: updatedOtherRepairs);
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

  // -- Main build --

  @override
  Widget build(BuildContext context) {
    final storage = widget.authService.storage;
    final Inspection inspection = storage.inspections[widget.inspectionId]!;
    final Property property = storage.properties[inspection.propertyId]!;
    final bool photosRequired =
        storage.companySettings?.photosRequired ?? false;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) {
          storage.saveData(); // Auto-save when navigating back
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
                    label: Text('Photos Required',
                        style: TextStyle(fontSize: 11, color: Colors.white)),
                    backgroundColor: Colors.red,
                  ),
                ),
              ),
          ],
        ),
        body: ListView(
          children: [
            if (property.allZones.isNotEmpty)
              ..._buildControllerZoneWidgets(
                  property, inspection, photosRequired),

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
                      final Repair repair = entry.value;
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
                              icon: const Icon(Icons.delete,
                                  color: Colors.red, size: 20),
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
}
