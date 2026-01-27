import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../models/property.dart';
import '../../models/zone.dart';
import '../../models/controller.dart';

class EditPropertyScreen extends StatefulWidget {
  final AuthService authService;
  final Property property;

  const EditPropertyScreen({
    Key? key,
    required this.authService,
    required this.property,
  }) : super(key: key);

  @override
  State<EditPropertyScreen> createState() => _EditPropertyScreenState();
}

class _EditPropertyScreenState extends State<EditPropertyScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _addressController;
  late TextEditingController _meterController;
  late TextEditingController _backflowLocationController;
  late TextEditingController _backflowSizeController;
  late TextEditingController _backflowSerialController;
  late TextEditingController _numControllersController;
  late TextEditingController _controllerLocationController;

  // New fields for workflow improvements
  late TextEditingController _notesController;
  late TextEditingController _billingCycleDayController;
  late TextEditingController _clientNameController;
  late TextEditingController _clientEmailController;
  late TextEditingController _clientPhoneController;

  late List<Zone> zones;
  late List<Controller> controllers;
  int _selectedControllerIndex = 0;

  @override
  void initState() {
    super.initState();
    // Initialize with existing property data
    _addressController = TextEditingController(text: widget.property.address);
    _meterController = TextEditingController(text: widget.property.meterLocation);
    _backflowLocationController = TextEditingController(text: widget.property.backflowLocation);
    _backflowSizeController = TextEditingController(text: widget.property.backflowSize);
    _backflowSerialController = TextEditingController(text: widget.property.backflowSerial);
    _numControllersController = TextEditingController(text: widget.property.numControllers.toString());
    _controllerLocationController = TextEditingController(text: widget.property.controllerLocation);

    // New fields
    _notesController = TextEditingController(text: widget.property.notes);
    _billingCycleDayController = TextEditingController(text: widget.property.billingCycleDay.toString());
    _clientNameController = TextEditingController(text: widget.property.clientName);
    _clientEmailController = TextEditingController(text: widget.property.clientEmail);
    _clientPhoneController = TextEditingController(text: widget.property.clientPhone);

    zones = List.from(widget.property.zones); // Create a copy for backward compatibility

    // Initialize controllers
    if (widget.property.controllers.isNotEmpty) {
      controllers = widget.property.controllers.map((c) => Controller(
        controllerNumber: c.controllerNumber,
        location: c.location,
        model: c.model,
        notes: c.notes,
        zones: List.from(c.zones),
      )).toList();
    } else if (widget.property.numControllers > 1) {
      // Legacy: multiple controllers but no controller data - create empty controllers
      controllers = List.generate(
        widget.property.numControllers,
        (i) => Controller(
          controllerNumber: i + 1,
          location: i == 0 ? widget.property.controllerLocation : '',
          zones: [],
        ),
      );
      // Put all existing zones in controller 1
      if (controllers.isNotEmpty && zones.isNotEmpty) {
        controllers[0] = controllers[0].copyWith(zones: List.from(zones));
      }
    } else {
      // Single controller - create one with all zones
      controllers = [
        Controller(
          controllerNumber: 1,
          location: widget.property.controllerLocation,
          zones: List.from(zones),
        ),
      ];
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _meterController.dispose();
    _backflowLocationController.dispose();
    _backflowSizeController.dispose();
    _backflowSerialController.dispose();
    _numControllersController.dispose();
    _controllerLocationController.dispose();
    _notesController.dispose();
    _billingCycleDayController.dispose();
    _clientNameController.dispose();
    _clientEmailController.dispose();
    _clientPhoneController.dispose();
    super.dispose();
  }

  void _addController() {
    final locationController = TextEditingController();
    final modelController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Controller ${controllers.length + 1}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: locationController,
              decoration: const InputDecoration(
                labelText: 'Location',
                hintText: 'e.g., Garage, Side of house',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: modelController,
              decoration: const InputDecoration(
                labelText: 'Model (optional)',
                hintText: 'e.g., Hunter Pro-C, Rainbird ESP',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                controllers.add(Controller(
                  controllerNumber: controllers.length + 1,
                  location: locationController.text,
                  model: modelController.text,
                  zones: [],
                ));
              });
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _editController(int index) {
    final controller = controllers[index];
    final locationController = TextEditingController(text: controller.location);
    final modelController = TextEditingController(text: controller.model);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Controller ${controller.controllerNumber}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: locationController,
              decoration: const InputDecoration(
                labelText: 'Location',
                hintText: 'e.g., Garage, Side of house',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: modelController,
              decoration: const InputDecoration(
                labelText: 'Model (optional)',
                hintText: 'e.g., Hunter Pro-C, Rainbird ESP',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          if (controllers.length > 1 && controller.zones.isEmpty)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteController(index);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                controllers[index] = controller.copyWith(
                  location: locationController.text,
                  model: modelController.text,
                );
              });
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _deleteController(int index) {
    if (controllers[index].zones.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot delete controller with zones. Remove zones first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Controller'),
        content: Text('Delete Controller ${controllers[index].controllerNumber}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              setState(() {
                controllers.removeAt(index);
                // Renumber controllers
                for (int i = 0; i < controllers.length; i++) {
                  controllers[i] = controllers[i].copyWith(controllerNumber: i + 1);
                  // Update zone controller numbers
                  final updatedZones = controllers[i].zones.map((z) =>
                    z.copyWith(controllerNumber: i + 1)
                  ).toList();
                  controllers[i] = controllers[i].copyWith(zones: updatedZones);
                }
                if (_selectedControllerIndex >= controllers.length) {
                  _selectedControllerIndex = controllers.length - 1;
                }
              });
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _addZone() {
    if (controllers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add a controller first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final currentController = controllers[_selectedControllerIndex];
    final descController = TextEditingController();
    final headTypeController = TextEditingController();
    final headCountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Zone to Controller ${currentController.controllerNumber}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              TextField(
                controller: headTypeController,
                decoration: const InputDecoration(
                  labelText: 'Head Type',
                  hintText: 'spray, rotor, drip, etc.',
                ),
              ),
              TextField(
                controller: headCountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Head Count (optional)',
                  hintText: 'Leave blank if unknown',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final headCountText = headCountController.text.trim();
                setState(() {
                  final newZoneNumber = currentController.zones.length + 1;
                  final newZones = List<Zone>.from(currentController.zones)
                    ..add(Zone(
                      zoneNumber: newZoneNumber,
                      description: descController.text,
                      headType: headTypeController.text,
                      headCount: headCountText.isEmpty ? null : int.tryParse(headCountText),
                      controllerNumber: currentController.controllerNumber,
                    ));
                  controllers[_selectedControllerIndex] = currentController.copyWith(
                    zones: newZones,
                  );
                  // Also update legacy zones list
                  _updateLegacyZones();
                });
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _updateLegacyZones() {
    // Update the legacy zones list with all zones from all controllers
    zones = [];
    for (var controller in controllers) {
      zones.addAll(controller.zones);
    }
  }

  void _editZoneInController(int controllerIndex, int zoneIndex) {
    final controller = controllers[controllerIndex];
    final zone = controller.zones[zoneIndex];
    final descController = TextEditingController(text: zone.description);
    final headTypeController = TextEditingController(text: zone.headType);
    final headCountController = TextEditingController(
      text: zone.headCount?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Zone ${zone.zoneNumber} (Controller ${controller.controllerNumber})'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              TextField(
                controller: headTypeController,
                decoration: const InputDecoration(
                  labelText: 'Head Type',
                  hintText: 'spray, rotor, drip, etc.',
                ),
              ),
              TextField(
                controller: headCountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Head Count (optional)',
                  hintText: 'Leave blank if unknown',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final headCountText = headCountController.text.trim();
                setState(() {
                  final updatedZones = List<Zone>.from(controller.zones);
                  updatedZones[zoneIndex] = Zone(
                    zoneNumber: zone.zoneNumber,
                    description: descController.text,
                    headType: headTypeController.text,
                    headCount: headCountText.isEmpty ? null : int.tryParse(headCountText),
                    controllerNumber: controller.controllerNumber,
                  );
                  controllers[controllerIndex] = controller.copyWith(zones: updatedZones);
                  _updateLegacyZones();
                });
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _deleteZoneFromController(int controllerIndex, int zoneIndex) {
    final controller = controllers[controllerIndex];
    final zone = controller.zones[zoneIndex];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Zone'),
        content: Text('Delete Zone ${zone.zoneNumber} from Controller ${controller.controllerNumber}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              setState(() {
                final updatedZones = List<Zone>.from(controller.zones);
                updatedZones.removeAt(zoneIndex);
                // Renumber remaining zones
                for (int i = 0; i < updatedZones.length; i++) {
                  updatedZones[i] = updatedZones[i].copyWith(zoneNumber: i + 1);
                }
                controllers[controllerIndex] = controller.copyWith(zones: updatedZones);
                _updateLegacyZones();
              });
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _saveProperty() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final storage = widget.authService.storage;

    // Validate billing cycle day
    int billingDay = int.tryParse(_billingCycleDayController.text) ?? 1;
    if (billingDay < 1) billingDay = 1;
    if (billingDay > 28) billingDay = 28;

    // Update legacy zones from controllers
    _updateLegacyZones();

    // Get controller location from first controller if available
    final controllerLocation = controllers.isNotEmpty
        ? controllers.first.location
        : _controllerLocationController.text;

    final updatedProperty = Property(
      id: widget.property.id, // Keep same ID
      address: _addressController.text,
      meterLocation: _meterController.text,
      backflowLocation: _backflowLocationController.text,
      backflowSize: _backflowSizeController.text,
      backflowSerial: _backflowSerialController.text,
      numControllers: controllers.length,
      controllerLocation: controllerLocation,
      zones: zones,
      controllers: controllers,
      notes: _notesController.text,
      billingCycleDay: billingDay,
      clientName: _clientNameController.text,
      clientEmail: _clientEmailController.text,
      clientPhone: _clientPhoneController.text,
    );

    storage.properties[widget.property.id] = updatedProperty;
    storage.saveData();

    Navigator.pop(context, true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Property updated successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Property'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveProperty,
            tooltip: 'Save',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Address',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _meterController,
              decoration: const InputDecoration(
                labelText: 'Meter Location',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 24),
            const Text(
              'Client Info',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _clientNameController,
              decoration: const InputDecoration(
                labelText: 'Client Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _clientEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Client Email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _clientPhoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Client Phone',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
            ),

            const SizedBox(height: 24),
            const Text(
              'Billing & Notes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _billingCycleDayController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Billing Cycle Day (1-28)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_today),
                helperText: 'Day of month when billing cycle starts',
              ),
              validator: (v) {
                if (v != null && v.isNotEmpty) {
                  final day = int.tryParse(v);
                  if (day == null || day < 1 || day > 28) {
                    return 'Enter a day between 1 and 28';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Property Notes',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.notes),
                alignLabelWithHint: true,
                helperText: 'Gate codes, special instructions, problem areas, etc.',
              ),
            ),

            const SizedBox(height: 24),
            const Text(
              'Backflow Info',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _backflowLocationController,
              decoration: const InputDecoration(
                labelText: 'Backflow Location',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _backflowSizeController,
              decoration: const InputDecoration(
                labelText: 'Backflow Size',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _backflowSerialController,
              decoration: const InputDecoration(
                labelText: 'Backflow Serial',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Controllers & Zones',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: _addController,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Controller'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (controllers.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.settings_input_component, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      const Text(
                        'No controllers added yet',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _addController,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Controller'),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...controllers.asMap().entries.map((controllerEntry) {
                final controllerIndex = controllerEntry.key;
                final controller = controllerEntry.value;
                final isSelected = controllerIndex == _selectedControllerIndex;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: isSelected ? 4 : 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: isSelected
                        ? BorderSide(color: Theme.of(context).primaryColor, width: 2)
                        : BorderSide.none,
                  ),
                  child: Column(
                    children: [
                      // Controller Header
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).primaryColor,
                          child: Text(
                            'C${controller.controllerNumber}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(
                          'Controller ${controller.controllerNumber}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          controller.location.isEmpty
                              ? 'No location set'
                              : '${controller.location}${controller.model.isNotEmpty ? " (${controller.model})" : ""}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _editController(controllerIndex),
                              tooltip: 'Edit Controller',
                            ),
                            if (isSelected)
                              IconButton(
                                icon: const Icon(Icons.add_circle, color: Colors.green),
                                onPressed: _addZone,
                                tooltip: 'Add Zone',
                              ),
                          ],
                        ),
                        onTap: () => setState(() => _selectedControllerIndex = controllerIndex),
                      ),

                      // Zones for this controller
                      if (controller.zones.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'No zones - tap + to add',
                            style: TextStyle(color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                          ),
                        )
                      else
                        ...controller.zones.asMap().entries.map((zoneEntry) {
                          final zoneIndex = zoneEntry.key;
                          final zone = zoneEntry.value;
                          return Container(
                            margin: const EdgeInsets.only(left: 24, right: 8, bottom: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ListTile(
                              dense: true,
                              leading: CircleAvatar(
                                radius: 16,
                                backgroundColor: Colors.blue.shade100,
                                child: Text(
                                  '${zone.zoneNumber}',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                              title: Text(zone.description),
                              subtitle: Text(
                                '${zone.headType}${zone.headCount != null ? " (${zone.headCount} heads)" : ""}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 20, color: Colors.blue),
                                    onPressed: () => _editZoneInController(controllerIndex, zoneIndex),
                                    tooltip: 'Edit Zone',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                                    onPressed: () => _deleteZoneFromController(controllerIndex, zoneIndex),
                                    tooltip: 'Delete Zone',
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      const SizedBox(height: 8),
                    ],
                  ),
                );
              }),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saveProperty,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.green,
              ),
              child: const Text(
                'Save Property',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
