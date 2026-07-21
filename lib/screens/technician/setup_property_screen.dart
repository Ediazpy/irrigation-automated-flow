import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../models/property.dart';
import '../../models/zone.dart';
import '../../models/controller.dart' as ctrl;
import '../../utils/map_launcher.dart';

/// On-site property setup screen for technicians.
/// Lets the tech fill in meter, backflow, controller, and zone details
/// for a property that was scheduled by the manager.
class SetupPropertyScreen extends StatefulWidget {
  final AuthService authService;
  final int propertyId;

  const SetupPropertyScreen({
    Key? key,
    required this.authService,
    required this.propertyId,
  }) : super(key: key);

  @override
  State<SetupPropertyScreen> createState() => _SetupPropertyScreenState();
}

class _SetupPropertyScreenState extends State<SetupPropertyScreen> {
  final _formKey = GlobalKey<FormState>();
  late final Property _property;

  late final TextEditingController _meterController;
  late final TextEditingController _backflowLocationController;
  late final TextEditingController _backflowSizeController;
  late final TextEditingController _backflowSerialController;
  late final TextEditingController _notesController;

  int _numControllers = 1;
  List<_ControllerSetup> _controllers = [];

  @override
  void initState() {
    super.initState();
    _property = widget.authService.storage.properties[widget.propertyId]!;

    _meterController = TextEditingController(text: _property.meterLocation);
    _backflowLocationController =
        TextEditingController(text: _property.backflowLocation);
    _backflowSizeController =
        TextEditingController(text: _property.backflowSize);
    _backflowSerialController =
        TextEditingController(text: _property.backflowSerial);
    _notesController = TextEditingController(text: _property.notes);

    // Load existing controllers or start fresh
    if (_property.controllers.isNotEmpty) {
      _numControllers = _property.controllers.length;
      _controllers = _property.controllers.map((c) {
        return _ControllerSetup(
          locationController: TextEditingController(text: c.location),
          modelController: TextEditingController(text: c.model),
          zones: List.from(c.zones),
        );
      }).toList();
    } else {
      _numControllers = _property.numControllers > 0 ? _property.numControllers : 1;
      _controllers = List.generate(
        _numControllers,
        (_) => _ControllerSetup(
          locationController: TextEditingController(),
          modelController: TextEditingController(),
          zones: [],
        ),
      );
      // If property had legacy zones, assign them to controller 1
      if (_property.zones.isNotEmpty && _controllers.isNotEmpty) {
        _controllers[0].zones = List.from(_property.zones);
      }
    }
  }

  @override
  void dispose() {
    _meterController.dispose();
    _backflowLocationController.dispose();
    _backflowSizeController.dispose();
    _backflowSerialController.dispose();
    _notesController.dispose();
    for (var c in _controllers) {
      c.locationController.dispose();
      c.modelController.dispose();
    }
    super.dispose();
  }

  void _updateControllerCount(int count) {
    setState(() {
      if (count > _numControllers) {
        for (var i = _numControllers; i < count; i++) {
          _controllers.add(_ControllerSetup(
            locationController: TextEditingController(),
            modelController: TextEditingController(),
            zones: [],
          ));
        }
      } else if (count < _numControllers) {
        for (var i = _numControllers - 1; i >= count; i--) {
          _controllers[i].locationController.dispose();
          _controllers[i].modelController.dispose();
          _controllers.removeAt(i);
        }
      }
      _numControllers = count;
    });
  }

  void _addZone(int controllerIndex) {
    final controllerSetup = _controllers[controllerIndex];
    final nextZoneNum = controllerSetup.zones.isEmpty
        ? 1
        : controllerSetup.zones.last.zoneNumber + 1;

    final descController = TextEditingController();
    final headTypeController = TextEditingController();
    final headCountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Zone $nextZoneNum'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: descController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'e.g., Front lawn, Back garden',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: headTypeController,
                decoration: const InputDecoration(
                  labelText: 'Head Type',
                  hintText: 'e.g., Rotor, Spray, Drip',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: headCountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Head Count',
                ),
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
              setState(() {
                controllerSetup.zones.add(Zone(
                  zoneNumber: nextZoneNum,
                  description: descController.text.trim(),
                  headType: headTypeController.text.trim(),
                  headCount: int.tryParse(headCountController.text),
                  controllerNumber: controllerIndex + 1,
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

  void _removeZone(int controllerIndex, int zoneIndex) {
    setState(() {
      _controllers[controllerIndex].zones.removeAt(zoneIndex);
    });
  }

  void _saveProperty() {
    if (!_formKey.currentState!.validate()) return;

    // Build controller list
    final controllers = <ctrl.Controller>[];
    final allZones = <Zone>[];
    for (var i = 0; i < _controllers.length; i++) {
      final setup = _controllers[i];
      controllers.add(ctrl.Controller(
        controllerNumber: i + 1,
        location: setup.locationController.text.trim(),
        model: setup.modelController.text.trim(),
        zones: setup.zones,
      ));
      allZones.addAll(setup.zones);
    }

    final updated = _property.copyWith(
      meterLocation: _meterController.text.trim(),
      backflowLocation: _backflowLocationController.text.trim(),
      backflowSize: _backflowSizeController.text.trim(),
      backflowSerial: _backflowSerialController.text.trim(),
      numControllers: _numControllers,
      controllers: controllers,
      zones: allZones,
      notes: _notesController.text.trim(),
    );

    final storage = widget.authService.storage;
    storage.properties[widget.propertyId] = updated;
    storage.saveData();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Property details saved'),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup Property Details'),
        actions: [
          TextButton.icon(
            onPressed: _saveProperty,
            icon: const Icon(Icons.save),
            label: const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Property address (read-only context)
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.blue.shade700),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_property.address,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 15)),
                          if (_property.clientName.isNotEmpty)
                            Text(_property.clientName,
                                style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 13)),
                        ],
                      ),
                    ),
                    OpenInMapsButton(address: _property.address),
                  ],
                ),
              ),
            ),

            // Manager notes (if any)
            if (_property.notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Card(
                color: Colors.amber.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.note, color: Colors.amber.shade700, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Manager Notes',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                    color: Colors.amber.shade900)),
                            const SizedBox(height: 4),
                            Text(_property.notes,
                                style: const TextStyle(fontSize: 14)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Meter
            _buildSectionHeader('Meter', Icons.speed),
            const SizedBox(height: 10),
            TextFormField(
              controller: _meterController,
              decoration: const InputDecoration(
                labelText: 'Meter Location',
                hintText: 'e.g., Front left of house near sidewalk',
                prefixIcon: Icon(Icons.location_searching),
              ),
            ),

            const SizedBox(height: 24),

            // Backflow
            _buildSectionHeader('Backflow', Icons.water_outlined),
            const SizedBox(height: 10),
            TextFormField(
              controller: _backflowLocationController,
              decoration: const InputDecoration(
                labelText: 'Backflow Location',
                prefixIcon: Icon(Icons.location_searching),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _backflowSizeController,
                    decoration: const InputDecoration(
                      labelText: 'Size',
                      hintText: 'e.g., 1"',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _backflowSerialController,
                    decoration: const InputDecoration(
                      labelText: 'Serial Number',
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Controllers & Zones
            Row(
              children: [
                ..._buildSectionHeaderWidgets('Controllers & Zones', Icons.settings_remote),
                const Spacer(),
                // Controller count stepper
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: _numControllers > 1
                          ? () => _updateControllerCount(_numControllers - 1)
                          : null,
                      iconSize: 22,
                    ),
                    Text('$_numControllers',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: _numControllers < 8
                          ? () => _updateControllerCount(_numControllers + 1)
                          : null,
                      iconSize: 22,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Each controller
            ...List.generate(_numControllers, (i) {
              final setup = _controllers[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.settings_remote,
                              size: 18, color: const Color(0xFF0EA5E9)),
                          const SizedBox(width: 6),
                          Text('Controller ${i + 1}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: setup.locationController,
                              decoration: const InputDecoration(
                                labelText: 'Location',
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: setup.modelController,
                              decoration: const InputDecoration(
                                labelText: 'Model',
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Zones (${setup.zones.length})',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w500, fontSize: 13)),
                          TextButton.icon(
                            onPressed: () => _addZone(i),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add Zone'),
                          ),
                        ],
                      ),
                      if (setup.zones.isNotEmpty)
                        ...setup.zones.asMap().entries.map((entry) {
                          final zone = entry.value;
                          return ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              radius: 16,
                              backgroundColor:
                                  const Color(0xFF0EA5E9).withOpacity(0.15),
                              child: Text('${zone.zoneNumber}',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0EA5E9))),
                            ),
                            title: Text(zone.description.isNotEmpty
                                ? zone.description
                                : 'Zone ${zone.zoneNumber}'),
                            subtitle: Text(
                              [
                                if (zone.headType.isNotEmpty) zone.headType,
                                if (zone.headCount != null)
                                  '${zone.headCount} heads',
                              ].join(' - '),
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade600),
                            ),
                            trailing: IconButton(
                              icon: Icon(Icons.close,
                                  size: 18, color: Colors.red.shade300),
                              onPressed: () => _removeZone(i, entry.key),
                            ),
                          );
                        }),
                      if (setup.zones.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text('No zones added yet',
                              style: TextStyle(
                                  color: Colors.grey.shade500, fontSize: 13)),
                        ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 16),

            // Additional notes
            _buildSectionHeader('Additional Notes', Icons.edit_note),
            const SizedBox(height: 10),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Any additional notes about the property...',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 28),

            // Save button
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _saveProperty,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Save Property Details',
                    style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(children: _buildSectionHeaderWidgets(title, icon));
  }

  List<Widget> _buildSectionHeaderWidgets(String title, IconData icon) {
    return [
      Icon(icon, size: 20, color: const Color(0xFF0EA5E9)),
      const SizedBox(width: 8),
      Text(title,
          style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3)),
    ];
  }
}

class _ControllerSetup {
  final TextEditingController locationController;
  final TextEditingController modelController;
  List<Zone> zones;

  _ControllerSetup({
    required this.locationController,
    required this.modelController,
    required this.zones,
  });
}
