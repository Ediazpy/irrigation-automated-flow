import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../models/property.dart';
import '../../models/zone.dart';

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

    zones = List.from(widget.property.zones); // Create a copy
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

  void _addZone() {
    showDialog(
      context: context,
      builder: (context) {
        final descController = TextEditingController();
        final headTypeController = TextEditingController();
        final headCountController = TextEditingController();

        return AlertDialog(
          title: Text('Add Zone ${zones.length + 1}'),
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
                  zones.add(Zone(
                    zoneNumber: zones.length + 1,
                    description: descController.text,
                    headType: headTypeController.text,
                    headCount: headCountText.isEmpty ? null : int.tryParse(headCountText),
                  ));
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

  void _editZone(int index) {
    final zone = zones[index];
    final descController = TextEditingController(text: zone.description);
    final headTypeController = TextEditingController(text: zone.headType);
    final headCountController = TextEditingController(
      text: zone.headCount?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Zone ${zone.zoneNumber}'),
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
                  zones[index] = Zone(
                    zoneNumber: zone.zoneNumber,
                    description: descController.text,
                    headType: headTypeController.text,
                    headCount: headCountText.isEmpty ? null : int.tryParse(headCountText),
                  );
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

  void _deleteZone(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Zone'),
        content: Text('Delete Zone ${zones[index].zoneNumber}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              setState(() {
                zones.removeAt(index);
                // Renumber remaining zones
                for (int i = 0; i < zones.length; i++) {
                  zones[i] = zones[i].copyWith(zoneNumber: i + 1);
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

  void _saveProperty() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final storage = widget.authService.storage;

    // Validate billing cycle day
    int billingDay = int.tryParse(_billingCycleDayController.text) ?? 1;
    if (billingDay < 1) billingDay = 1;
    if (billingDay > 28) billingDay = 28;

    final updatedProperty = Property(
      id: widget.property.id, // Keep same ID
      address: _addressController.text,
      meterLocation: _meterController.text,
      backflowLocation: _backflowLocationController.text,
      backflowSize: _backflowSizeController.text,
      backflowSerial: _backflowSerialController.text,
      numControllers: int.tryParse(_numControllersController.text) ?? 1,
      controllerLocation: _controllerLocationController.text,
      zones: zones,
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
            const Text(
              'Controller Info',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _numControllersController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Number of Controllers',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _controllerLocationController,
              decoration: const InputDecoration(
                labelText: 'Controller Location',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Zones',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: _addZone,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Zone'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (zones.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    'No zones added yet',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ...zones.asMap().entries.map((entry) {
                final index = entry.key;
                final zone = entry.value;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text('${zone.zoneNumber}'),
                    ),
                    title: Text(zone.description),
                    subtitle: Text(
                      '${zone.headType}${zone.headCount != null ? " (${zone.headCount})" : ""}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _editZone(index),
                          tooltip: 'Edit Zone',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteZone(index),
                          tooltip: 'Delete Zone',
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
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
