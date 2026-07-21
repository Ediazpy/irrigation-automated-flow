import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../models/quote.dart';
import '../../models/property.dart';
import '../../models/repair.dart';
import '../../models/repair_task.dart';
import '../../constants/status_constants.dart';

class ScheduleRepairScreen extends StatefulWidget {
  final AuthService authService;
  final Quote quote;
  final Property property;

  const ScheduleRepairScreen({
    Key? key,
    required this.authService,
    required this.quote,
    required this.property,
  }) : super(key: key);

  @override
  State<ScheduleRepairScreen> createState() => _ScheduleRepairScreenState();
}

class _ScheduleRepairScreenState extends State<ScheduleRepairScreen> {
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  List<String> _selectedTechnicians = [];
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  // Any active employee can be assigned, not just technicians
  List<Map<String, dynamic>> get _availableTechnicians {
    return widget.authService.storage.users.values
        .where((user) => !user.isArchived)
        .map((user) => {'email': user.email, 'name': user.name})
        .toList();
  }

  /// A repair that already has an open task must not be scheduled twice.
  RepairTask? get _existingTask {
    try {
      return widget.authService.storage.repairTasks.values.firstWhere(
        (t) =>
            t.quoteId == widget.quote.id &&
            t.status != RepairTaskStatus.cancelled &&
            t.status != RepairTaskStatus.completed,
      );
    } catch (_) {
      return null;
    }
  }

  void _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _createTask() {
    if (_existingTask != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'These repairs are already scheduled for ${_existingTask!.scheduledDate}.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    if (_selectedTechnicians.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please assign at least one team member'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final storage = widget.authService.storage;

    // Convert quote line items to repairs
    final repairs = widget.quote.lineItems.map((item) {
      return Repair(
        zoneNumber: item.zoneNumber ?? 0,
        itemName: item.description,
        quantity: item.quantity,
        price: item.unitPrice,
        notes: item.notes ?? '',
      );
    }).toList();

    // Create the repair task
    final task = RepairTask(
      id: storage.nextRepairTaskId,
      quoteId: widget.quote.id,
      propertyId: widget.property.id,
      repairs: repairs,
      assignedTechnicians: _selectedTechnicians,
      scheduledDate: DateFormat('MM/dd/yyyy').format(_selectedDate),
      status: RepairTaskStatus.assigned,
      technicianNotes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      createdAt: DateTime.now().toIso8601String(),
    );

    storage.repairTasks[task.id] = task;
    storage.nextRepairTaskId++;
    storage.saveData();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Repair task created successfully'),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final existing = _existingTask;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule Repairs'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Property Info Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.receipt_long, color: Theme.of(context).primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        'Quote #${widget.quote.id}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 18, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(child: Text(widget.property.address)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.build, size: 18, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text('${widget.quote.lineItems.length} repair items'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Already scheduled? Make it impossible to miss.
          if (existing != null) ...[
            Card(
              color: Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.event_busy, color: Colors.orange.shade800),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Already scheduled for ${existing.scheduledDate}. '
                        'Cancel or complete that task before scheduling again.',
                        style: TextStyle(color: Colors.orange.shade900),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Schedule Date
          const Text(
            'Schedule Date',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: _selectDate,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month),
                  const SizedBox(width: 12),
                  Text(
                    DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate),
                    style: const TextStyle(fontSize: 16),
                  ),
                  const Spacer(),
                  const Icon(Icons.edit, size: 18, color: Colors.grey),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Assign Team Members
          const Text(
            'Assign Team Members',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (_availableTechnicians.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange.shade700),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text('No team members available. Add users in User Management.'),
                    ),
                  ],
                ),
              ),
            )
          else
            ..._availableTechnicians.map((tech) {
              final isSelected = _selectedTechnicians.contains(tech['email']);
              return CheckboxListTile(
                value: isSelected,
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      _selectedTechnicians.add(tech['email']!);
                    } else {
                      _selectedTechnicians.remove(tech['email']);
                    }
                  });
                },
                title: Text(tech['name']!),
                subtitle: Text(tech['email']!),
                secondary: CircleAvatar(
                  backgroundColor: isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.grey.shade200,
                  child: Icon(
                    Icons.person,
                    color: isSelected ? Colors.white : Colors.grey,
                  ),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              );
            }),
          const SizedBox(height: 24),

          // Notes for Technician
          const Text(
            'Notes for Technician',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _notesController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Gate code, special instructions, etc.',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 32),

          // Create Task Button
          ElevatedButton.icon(
            onPressed: existing != null ? null : _createTask,
            icon: const Icon(Icons.check),
            label: Text(existing != null ? 'Already Scheduled' : 'Create Repair Task'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
