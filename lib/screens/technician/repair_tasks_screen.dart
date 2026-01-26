import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../models/repair_task.dart';
import '../../constants/status_constants.dart';
import 'do_repair_task_screen.dart';

/// Technician view of repair tasks
/// NOTE: This screen does NOT show pricing, client contact info, or signatures
/// Those are manager-only data
class RepairTasksScreen extends StatefulWidget {
  final AuthService authService;

  const RepairTasksScreen({Key? key, required this.authService}) : super(key: key);

  @override
  State<RepairTasksScreen> createState() => _RepairTasksScreenState();
}

class _RepairTasksScreenState extends State<RepairTasksScreen> {
  List<RepairTask> _getMyTasks() {
    final myEmail = widget.authService.currentUser?.email ?? '';
    return widget.authService.storage.repairTasks.values
        .where((t) =>
            t.assignedTechnicians.contains(myEmail) &&
            t.status != RepairTaskStatus.completed)
        .toList()
      ..sort((a, b) {
        // Sort by priority first, then by date
        final priorityOrder = {
          TaskPriority.urgent: 0,
          TaskPriority.high: 1,
          TaskPriority.normal: 2,
          TaskPriority.low: 3,
        };
        final priorityCompare =
            (priorityOrder[a.priority] ?? 2).compareTo(priorityOrder[b.priority] ?? 2);
        if (priorityCompare != 0) return priorityCompare;
        return a.scheduledDate.compareTo(b.scheduledDate);
      });
  }

  List<RepairTask> _getCompletedTasks() {
    final myEmail = widget.authService.currentUser?.email ?? '';
    return widget.authService.storage.repairTasks.values
        .where((t) =>
            t.assignedTechnicians.contains(myEmail) &&
            t.status == RepairTaskStatus.completed)
        .toList()
      ..sort((a, b) => b.completedAt?.compareTo(a.completedAt ?? '') ?? 0);
  }

  @override
  Widget build(BuildContext context) {
    final myTasks = _getMyTasks();
    final completedTasks = _getCompletedTasks();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Repair Tasks'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => setState(() {}),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Active Tasks Section
            if (myTasks.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.check_circle, size: 64, color: Colors.green.shade300),
                      const SizedBox(height: 16),
                      const Text(
                        'No pending repair tasks',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Great work! Check back later for new assignments.',
                        style: TextStyle(color: Colors.grey.shade600),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              Text(
                'Your Tasks (${myTasks.length})',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...myTasks.map((task) => _buildTaskCard(task)),
            ],

            // Completed Section
            if (completedTasks.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'Recently Completed (${completedTasks.length})',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 12),
              ...completedTasks.take(5).map((task) => _buildTaskCard(task, isCompleted: true)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCard(RepairTask task, {bool isCompleted = false}) {
    final property = widget.authService.storage.properties[task.propertyId];
    final statusColor = RepairTaskStatus.getColor(task.status);
    final priorityColor = TaskPriority.getColor(task.priority);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isCompleted ? Colors.grey.shade50 : null,
      child: InkWell(
        onTap: isCompleted ? null : () => _openTask(task),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with status and priority
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          RepairTaskStatus.getIcon(task.status),
                          size: 14,
                          color: statusColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          RepairTaskStatus.getDisplayName(task.status),
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isCompleted && task.priority != TaskPriority.normal) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: priorityColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            TaskPriority.getIcon(task.priority),
                            size: 14,
                            color: priorityColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            task.priority.toUpperCase(),
                            style: TextStyle(
                              color: priorityColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),

              // Property Address (NO client contact info - manager only)
              Row(
                children: [
                  Icon(Icons.location_on,
                      size: 20, color: isCompleted ? Colors.grey : Colors.grey.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      property?.address ?? 'Unknown Property',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: isCompleted ? Colors.grey : null,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Scheduled Date
              Row(
                children: [
                  Icon(Icons.calendar_today,
                      size: 18, color: isCompleted ? Colors.grey : Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Text(
                    task.scheduledDate,
                    style: TextStyle(
                      color: isCompleted ? Colors.grey : Colors.grey.shade700,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.timer,
                      size: 18, color: isCompleted ? Colors.grey : Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    '${task.estimatedHours}h',
                    style: TextStyle(
                      color: isCompleted ? Colors.grey : Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Repair count (NO pricing - manager only)
              Row(
                children: [
                  Icon(Icons.build,
                      size: 18, color: isCompleted ? Colors.grey : Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Text(
                    '${task.totalRepairItems} repair items',
                    style: TextStyle(
                      color: isCompleted ? Colors.grey : Colors.grey.shade700,
                    ),
                  ),
                ],
              ),

              // Notes
              if (task.technicianNotes?.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.note, size: 16, color: Colors.amber.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          task.technicianNotes!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.amber.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Action button for active tasks
              if (!isCompleted) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _openTask(task),
                    icon: Icon(
                      task.status == RepairTaskStatus.assigned
                          ? Icons.play_arrow
                          : Icons.build,
                    ),
                    label: Text(
                      task.status == RepairTaskStatus.assigned
                          ? 'Start Task'
                          : 'Continue Task',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _openTask(RepairTask task) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DoRepairTaskScreen(
          authService: widget.authService,
          task: task,
        ),
      ),
    );

    if (result == true) {
      setState(() {});
    }
  }
}
