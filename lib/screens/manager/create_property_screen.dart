import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../models/property.dart';
import '../../models/zone.dart';

class CreatePropertyScreen extends StatefulWidget {
  final AuthService authService;

  const CreatePropertyScreen({Key? key, required this.authService}) : super(key: key);

  @override
  State<CreatePropertyScreen> createState() => _CreatePropertyScreenState();
}

class _CreatePropertyScreenState extends State<CreatePropertyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _meterController = TextEditingController();
  final _backflowLocationController = TextEditingController();
  final _backflowSizeController = TextEditingController();
  final _backflowSerialController = TextEditingController();
  final _numControllersController = TextEditingController(text: '1');
  final _controllerLocationController = TextEditingController();

  // Client contact controllers
  final _clientNameController = TextEditingController();
  final _clientEmailController = TextEditingController();
  final _clientPhoneController = TextEditingController();

  List<Zone> zones = [];

  @override
  void dispose() {
    _addressController.dispose();
    _meterController.dispose();
    _backflowLocationController.dispose();
    _backflowSizeController.dispose();
    _backflowSerialController.dispose();
    _numControllersController.dispose();
    _controllerLocationController.dispose();
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
        final headCountController = TextEditingController(text: '0');

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
                setState(() {
                  zones.add(Zone(
                    zoneNumber: zones.length + 1,
                    description: descController.text,
                    headType: headTypeController.text,
                    headCount: int.tryParse(headCountController.text) ?? 0,
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

  void _saveProperty() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final storage = widget.authService.storage;
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
      clientName: _clientNameController.text.trim(),
      clientEmail: _clientEmailController.text.trim(),
      clientPhone: _clientPhoneController.text.trim(),
    );

    storage.properties[storage.nextPropertyId] = newProperty;
    storage.nextPropertyId++;
    storage.saveData();

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Property'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Basic Info', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: 'Address'),
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            TextFormField(
              controller: _meterController,
              decoration: const InputDecoration(labelText: 'Meter Location'),
            ),
            const SizedBox(height: 24),
            const Text('Client Contact', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextFormField(
              controller: _clientNameController,
              decoration: const InputDecoration(
                labelText: 'Contact Name',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            TextFormField(
              controller: _clientPhoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Contact Phone',
                prefixIcon: Icon(Icons.phone),
              ),
            ),
            TextFormField(
              controller: _clientEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Contact Email',
                prefixIcon: Icon(Icons.email),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Backflow Info', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
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
              decoration: const InputDecoration(labelText: 'Backflow Serial #'),
            ),
            const SizedBox(height: 24),
            const Text('Controller Info', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextFormField(
              controller: _numControllersController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Number of Controllers'),
            ),
            TextFormField(
              controller: _controllerLocationController,
              decoration: const InputDecoration(labelText: 'Controller Location'),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Zones', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ElevatedButton.icon(
                  onPressed: _addZone,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Zone'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...zones.map((zone) => Card(
                  child: ListTile(
                    title: Text('Zone ${zone.zoneNumber}: ${zone.description}'),
                    subtitle: Text('${zone.headType} (${zone.headCount})'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        setState(() {
                          zones.remove(zone);
                          // Renumber zones
                          for (int i = 0; i < zones.length; i++) {
                            zones[i] = zones[i].copyWith(zoneNumber: i + 1);
                          }
                        });
                      },
                    ),
                  ),
                )),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saveProperty,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
              child: const Text('Create Property'),
            ),
          ],
        ),
      ),
    );
  }
}
