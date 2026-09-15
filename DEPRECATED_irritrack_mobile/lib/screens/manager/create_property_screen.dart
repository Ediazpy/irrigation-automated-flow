import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../models/property.dart';
import '../../models/zone.dart';
import '../../models/controller.dart';

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

  // Notes controllers
  final _notesController = TextEditingController();
  final _initialRepairNotesController = TextEditingController();

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
    _notesController.dispose();
    _initialRepairNotesController.dispose();
    super.dispose();
  }

  void _addZone() {
    showDialog(
      context: context,
      builder: (context) {
        final descController = TextEditingController();
        final headTypeController = TextEditingController();
        final headCountController = TextEditingController(text: '0');
        final runTimeController = TextEditingController();
        String? selectedProgram;
        List<String> selectedDays = [];

        const List<String> programs = ['A', 'B', 'C', 'D'];
        const List<String> allDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Add Zone ${zones.length + 1}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: descController,
                      decoration: const InputDecoration(labelText: 'Description'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: headTypeController,
                      decoration: const InputDecoration(
                        labelText: 'Head Type',
                        hintText: 'spray, rotor, drip, etc.',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: headCountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Head Count'),
                    ),
                    const SizedBox(height: 16),
                    const Text('Scheduling (Optional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: runTimeController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Run Time (minutes)',
                        hintText: 'e.g., 15',
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedProgram,
                      decoration: const InputDecoration(labelText: 'Program'),
                      items: programs
                          .map((p) => DropdownMenuItem(value: p, child: Text('Program $p')))
                          .toList(),
                      onChanged: (val) => setDialogState(() => selectedProgram = val),
                    ),
                    const SizedBox(height: 8),
                    const Text('Days of Week:', style: TextStyle(fontSize: 12)),
                    Wrap(
                      spacing: 4,
                      children: allDays.map((day) {
                        final isSelected = selectedDays.contains(day);
                        return FilterChip(
                          label: Text(day, style: const TextStyle(fontSize: 11)),
                          selected: isSelected,
                          onSelected: (selected) {
                            setDialogState(() {
                              if (selected) {
                                selectedDays.add(day);
                              } else {
                                selectedDays.remove(day);
                              }
                            });
                          },
                        );
                      }).toList(),
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
                      zones.add(Zone(
                        zoneNumber: zones.length + 1,
                        description: descController.text,
                        headType: headTypeController.text,
                        headCount: int.tryParse(headCountController.text) ?? 0,
                        runTimeMinutes: int.tryParse(runTimeController.text),
                        program: selectedProgram,
                        daysOfWeek: selectedDays,
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
      },
    );
  }

  void _editZone(int index) {
    final zone = zones[index];
    showDialog(
      context: context,
      builder: (context) {
        final descController = TextEditingController(text: zone.description);
        final headTypeController = TextEditingController(text: zone.headType);
        final headCountController = TextEditingController(text: zone.headCount.toString());
        final runTimeController = TextEditingController(
            text: zone.runTimeMinutes?.toString() ?? '');
        String? selectedProgram = zone.program;
        List<String> selectedDays = List<String>.from(zone.daysOfWeek);

        const List<String> programs = ['A', 'B', 'C', 'D'];
        const List<String> allDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Edit Zone ${zone.zoneNumber}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: descController,
                      decoration: const InputDecoration(labelText: 'Description'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: headTypeController,
                      decoration: const InputDecoration(
                        labelText: 'Head Type',
                        hintText: 'spray, rotor, drip, etc.',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: headCountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Head Count'),
                    ),
                    const SizedBox(height: 16),
                    const Text('Scheduling (Optional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: runTimeController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Run Time (minutes)',
                        hintText: 'e.g., 15',
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedProgram,
                      decoration: const InputDecoration(labelText: 'Program'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('None')),
                        ...programs.map((p) => DropdownMenuItem(value: p, child: Text('Program $p'))),
                      ],
                      onChanged: (val) => setDialogState(() => selectedProgram = val),
                    ),
                    const SizedBox(height: 8),
                    const Text('Days of Week:', style: TextStyle(fontSize: 12)),
                    Wrap(
                      spacing: 4,
                      children: allDays.map((day) {
                        final isSelected = selectedDays.contains(day);
                        return FilterChip(
                          label: Text(day, style: const TextStyle(fontSize: 11)),
                          selected: isSelected,
                          onSelected: (selected) {
                            setDialogState(() {
                              if (selected) {
                                selectedDays.add(day);
                              } else {
                                selectedDays.remove(day);
                              }
                            });
                          },
                        );
                      }).toList(),
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
                      zones[index] = zone.copyWith(
                        description: descController.text,
                        headType: headTypeController.text,
                        headCount: int.tryParse(headCountController.text) ?? 0,
                        runTimeMinutes: int.tryParse(runTimeController.text),
                        program: selectedProgram,
                        daysOfWeek: selectedDays,
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
      },
    );
  }

  void _saveProperty() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final storage = widget.authService.storage;

    // Create a single controller with all zones
    // (users can add more controllers when editing)
    final numControllers = int.tryParse(_numControllersController.text) ?? 1;
    final List<Controller> controllers = [];

    // Create controllers based on numControllers
    for (int i = 0; i < numControllers; i++) {
      controllers.add(Controller(
        controllerNumber: i + 1,
        location: i == 0 ? _controllerLocationController.text : '',
        zones: i == 0
            ? zones.map((z) => z.copyWith(controllerNumber: 1)).toList()
            : [],
      ));
    }

    final newProperty = Property(
      id: storage.nextPropertyId,
      address: _addressController.text,
      meterLocation: _meterController.text,
      backflowLocation: _backflowLocationController.text,
      backflowSize: _backflowSizeController.text,
      backflowSerial: _backflowSerialController.text,
      numControllers: numControllers,
      controllerLocation: _controllerLocationController.text,
      zones: zones,
      controllers: controllers,
      clientName: _clientNameController.text.trim(),
      clientEmail: _clientEmailController.text.trim(),
      clientPhone: _clientPhoneController.text.trim(),
      notes: _notesController.text.trim(),
      initialRepairNotes: _initialRepairNotesController.text.trim(),
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
            const Text('Notes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Property Notes',
                hintText: 'Gate codes, special instructions, problem areas...',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _initialRepairNotesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Initial Repair Notes (Optional)',
                hintText: 'Known repairs needed, previous issues...',
                alignLabelWithHint: true,
              ),
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
            ...zones.asMap().entries.map((entry) {
              final index = entry.key;
              final zone = entry.value;
              final scheduleInfo = zone.scheduleDisplay;
              return Card(
                child: ListTile(
                  title: Text('Zone ${zone.zoneNumber}: ${zone.description}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${zone.headType} (${zone.headCount})'),
                      if (scheduleInfo.isNotEmpty)
                        Text(
                          scheduleInfo,
                          style: TextStyle(fontSize: 11, color: Colors.teal.shade700),
                        ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _editZone(index),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            zones.removeAt(index);
                            for (int i = 0; i < zones.length; i++) {
                              zones[i] = zones[i].copyWith(zoneNumber: i + 1);
                            }
                          });
                        },
                      ),
                    ],
                  ),
                ),
              );
            }),
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
