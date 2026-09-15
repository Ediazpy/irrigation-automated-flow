import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../models/property.dart';
import '../../models/zone.dart';
import '../../models/inspection.dart';
import 'do_inspection_screen.dart';

class CreateWalkScreen extends StatefulWidget {
  final AuthService authService;

  const CreateWalkScreen({Key? key, required this.authService}) : super(key: key);

  @override
  State<CreateWalkScreen> createState() => _CreateWalkScreenState();
}

class _CreateWalkScreenState extends State<CreateWalkScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _meterController = TextEditingController();
  final _backflowLocationController = TextEditingController();
  final _backflowSizeController = TextEditingController();
  final _backflowSerialController = TextEditingController();
  final _numControllersController = TextEditingController(text: '1');
  final _controllerLocationController = TextEditingController();
  final _dateController = TextEditingController();

  List<Zone> zones = [];

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
                decoration: const InputDecoration(labelText: 'Head Type'),
              ),
              TextField(
                controller: headCountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Head Count'),
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

  void _createAndStart() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final storage = widget.authService.storage;

    // Create property
    final newProperty = Property(
      id: storage.nextPropertyId,
      address: _addressController.text,
      meterLocation: _meterController.text,
      backflowLocation: _backflowLocationController.text,
      backflowSize: _backflowSizeController.text,
      backflowSerial: _backflowSerialController.text,
      numControllers: int.tryParse(_numControllersController.text) ?? 1,
      controllerLocation: _controllerLocationController.text,
      zones: zones,
    );

    storage.properties[storage.nextPropertyId] = newProperty;
    final propId = storage.nextPropertyId;
    storage.nextPropertyId++;

    // Create inspection
    final date = _dateController.text.isEmpty
        ? DateTime.now()
        : (DateTime.tryParse(_dateController.text) ?? DateTime.now());
    final dateStr = DateFormat('MM/dd/yyyy').format(date);
    final billingMonth = DateFormat('yyyy-MM').format(date);

    final newInspection = Inspection(
      id: storage.nextInspectionId,
      propertyId: propId,
      technicians: [widget.authService.currentUser!.email],
      date: dateStr,
      status: 'in_progress',
      repairs: [],
      totalCost: 0.0,
      billingMonth: billingMonth,
    );

    storage.inspections[storage.nextInspectionId] = newInspection;
    final inspId = storage.nextInspectionId;
    storage.nextInspectionId++;

    storage.saveData();

    // Navigate to inspection screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => DoInspectionScreen(
          authService: widget.authService,
          inspectionId: inspId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Property Inspection')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: 'Address'),
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            TextFormField(
              controller: _meterController,
              decoration: const InputDecoration(labelText: 'Meter Location'),
            ),
            const Divider(height: 32),
            const Text('Backflow Info', style: TextStyle(fontWeight: FontWeight.bold)),
            TextFormField(
              controller: _backflowLocationController,
              decoration: const InputDecoration(labelText: 'Backflow Location'),
            ),
            TextFormField(
              controller: _backflowSizeController,
              decoration: const InputDecoration(labelText: 'Backflow Size'),
            ),
            TextFormField(
              controller: _backflowSerialController,
              decoration: const InputDecoration(labelText: 'Backflow Serial'),
            ),
            const Divider(height: 32),
            const Text('Controller Info', style: TextStyle(fontWeight: FontWeight.bold)),
            TextFormField(
              controller: _numControllersController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Number of Controllers'),
            ),
            TextFormField(
              controller: _controllerLocationController,
              decoration: const InputDecoration(labelText: 'Controller Location'),
            ),
            const Divider(height: 32),
            TextFormField(
              controller: _dateController,
              decoration: const InputDecoration(
                labelText: 'Inspection Date',
                hintText: '2025-01-15',
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Zones (${zones.length})', style: const TextStyle(fontWeight: FontWeight.bold)),
                ElevatedButton.icon(
                  onPressed: _addZone,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Zone'),
                ),
              ],
            ),
            ...zones.map((z) => ListTile(
                  title: Text('Zone ${z.zoneNumber}: ${z.description}'),
                  subtitle: Text('${z.headType}${z.headCount != null ? " (${z.headCount})" : ""}'),
                )),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _createAndStart,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
              child: const Text('Create & Start Inspection'),
            ),
          ],
        ),
      ),
    );
  }
}
