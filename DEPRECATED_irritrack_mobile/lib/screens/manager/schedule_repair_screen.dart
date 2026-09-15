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
  String _priority = TaskPriority.normal;
  double _estimatedHours = 2.0;
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _availableTechnicians {
    return widget.authService.storage.users.values
        .where((user) => user.role == 'technician' && !user.isArchived)
        .map((user) => {'email': user.email, 'name': user.name})
        .toList();
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
    if (_selectedTechnicians.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please assign at least one technician'),
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
      estimatedHours: _estimatedHours,
      priority: _priority,
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
          const SizedBox(height: 24),

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

          // Assign Technicians
          const Text(
            'Assign Technicians',
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
                      child: Text('No technicians available. Add technicians in User Management.'),
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

          // Priority
          const Text(
            'Priority',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _priorityChip(TaskPriority.low, 'Low', Colors.grey),
              _priorityChip(TaskPriority.normal, 'Normal', Colors.blue),
              _priorityChip(TaskPriority.high, 'High', Colors.orange),
              _priorityChip(TaskPriority.urgent, 'Urgent', Colors.red),
            ],
          ),
          const SizedBox(height: 24),

          // Estimated Hours
          const Text(
            'Estimated Hours',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: _estimatedHours > 0.5
                    ? () => setState(() => _estimatedHours -= 0.5)
                    : null,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_estimatedHours.toStringAsFixed(1)} hrs',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: _estimatedHours < 12
                    ? () => setState(() => _estimatedHours += 0.5)
                    : null,
              ),
            ],
          ),
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
            onPressed: _createTask,
            icon: const Icon(Icons.check),
            label: const Text('Create Repair Task'),
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

  Widget _priorityChip(String value, String label, Color color) {
    final isSelected = _priority == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _priority = value);
        }
      },
      selectedColor: color.withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? color : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      avatar: Icon(
        TaskPriority.getIcon(value),
        size: 18,
        color: isSelected ? color : Colors.grey,
      ),
    );
  }
}
