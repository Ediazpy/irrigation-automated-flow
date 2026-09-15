import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../models/repair_task.dart';
import '../../constants/status_constants.dart';

/// Technician screen for completing a repair task
/// NOTE: This screen does NOT show pricing or client data - manager only
class DoRepairTaskScreen extends StatefulWidget {
  final AuthService authService;
  final RepairTask task;

  const DoRepairTaskScreen({
    Key? key,
    required this.authService,
    required this.task,
  }) : super(key: key);

  @override
  State<DoRepairTaskScreen> createState() => _DoRepairTaskScreenState();
}

class _DoRepairTaskScreenState extends State<DoRepairTaskScreen> {
  late RepairTask _task;
  final _notesController = TextEditingController();
  Set<int> _completedItems = {};

  @override
  void initState() {
    super.initState();
    _task = widget.task;

    // If task is assigned, mark it as in progress
    if (_task.status == RepairTaskStatus.assigned) {
      _updateTaskStatus(RepairTaskStatus.inProgress);
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _updateTaskStatus(String newStatus) {
    final storage = widget.authService.storage;
    _task = _task.copyWith(status: newStatus);
    storage.repairTasks[_task.id] = _task;
    storage.saveData();
    setState(() {});
  }

  void _toggleItem(int index) {
    setState(() {
      if (_completedItems.contains(index)) {
        _completedItems.remove(index);
      } else {
        _completedItems.add(index);
      }
    });
  }

  void _completeTask() {
    // Confirm all items are done
    if (_completedItems.length < _task.repairs.length) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Incomplete Items'),
          content: Text(
            '${_task.repairs.length - _completedItems.length} items are not marked complete. '
            'Are you sure you want to finish this task?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Go Back'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _finishTask();
              },
              child: const Text('Complete Anyway'),
            ),
          ],
        ),
      );
    } else {
      _finishTask();
    }
  }

  void _finishTask() {
    final storage = widget.authService.storage;

    _task = _task.copyWith(
      status: RepairTaskStatus.completed,
      completedAt: DateTime.now().toIso8601String(),
      completionNotes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    storage.repairTasks[_task.id] = _task;
    storage.saveData();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Task completed successfully!'),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final property = widget.authService.storage.properties[_task.propertyId];

    return Scaffold(
      appBar: AppBar(
        title: Text('Task #${_task.id}'),
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: RepairTaskStatus.getColor(_task.status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  RepairTaskStatus.getIcon(_task.status),
                  size: 16,
                  color: RepairTaskStatus.getColor(_task.status),
                ),
                const SizedBox(width: 4),
                Text(
                  RepairTaskStatus.getDisplayName(_task.status),
                  style: TextStyle(
                    color: RepairTaskStatus.getColor(_task.status),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Property Card (NO client contact - manager only)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.location_on, color: Theme.of(context).primaryColor),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                property?.address ?? 'Unknown Property',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text('Scheduled: ${_task.scheduledDate}'),
                          ],
                        ),
                        if (_task.technicianNotes?.isNotEmpty == true) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.note, color: Colors.amber.shade700, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _task.technicianNotes!,
                                    style: TextStyle(color: Colors.amber.shade900),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Progress indicator
                LinearProgressIndicator(
                  value: _completedItems.length / _task.repairs.length,
                  backgroundColor: Colors.grey.shade200,
                ),
                const SizedBox(height: 8),
                Text(
                  '${_completedItems.length} of ${_task.repairs.length} items completed',
                  style: TextStyle(color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Repair Items Checklist (NO pricing - manager only)
                const Text(
                  'Repair Checklist',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ..._task.repairs.asMap().entries.map((entry) {
                  final index = entry.key;
                  final repair = entry.value;
                  final isCompleted = _completedItems.contains(index);

                  return Card(
                    color: isCompleted ? Colors.green.shade50 : null,
                    child: CheckboxListTile(
                      value: isCompleted,
                      onChanged: (value) => _toggleItem(index),
                      title: Text(
                        _formatItemName(repair.itemName),
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          decoration: isCompleted ? TextDecoration.lineThrough : null,
                          color: isCompleted ? Colors.grey : null,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Quantity: ${repair.quantity}' +
                                (repair.zoneNumber > 0 ? ' | Zone ${repair.zoneNumber}' : ''),
                          ),
                          if (repair.notes.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                repair.notes,
                                style: TextStyle(
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      secondary: CircleAvatar(
                        backgroundColor:
                            isCompleted ? Colors.green : Colors.grey.shade200,
                        child: Icon(
                          isCompleted ? Icons.check : Icons.build,
                          color: isCompleted ? Colors.white : Colors.grey,
                        ),
                      ),
                      controlAffinity: ListTileControlAffinity.trailing,
                    ),
                  );
                }),

                const SizedBox(height: 24),

                // Completion Notes
                const Text(
                  'Completion Notes',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Add any notes about the repairs performed...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 100), // Space for bottom button
              ],
            ),
          ),

          // Bottom Complete Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _completeTask,
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Complete Task'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatItemName(String name) {
    return name
        .split('_')
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1)}'
            : '')
        .join(' ');
  }
}
