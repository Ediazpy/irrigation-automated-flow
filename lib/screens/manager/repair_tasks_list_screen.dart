import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../models/repair_task.dart';
import '../../constants/status_constants.dart';
import '../../utils/map_launcher.dart';

class RepairTasksListScreen extends StatefulWidget {
  final AuthService authService;

  const RepairTasksListScreen({Key? key, required this.authService}) : super(key: key);

  @override
  State<RepairTasksListScreen> createState() => _RepairTasksListScreenState();
}

class _RepairTasksListScreenState extends State<RepairTasksListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<RepairTask> _getFilteredTasks(String? statusFilter) {
    var tasks = widget.authService.storage.repairTasks.values.toList();

    // Filter by status
    if (statusFilter != null) {
      tasks = tasks.where((t) => t.status == statusFilter).toList();
    }

    // Filter by search
    if (_searchQuery.isNotEmpty) {
      tasks = tasks.where((t) {
        final property = widget.authService.storage.properties[t.propertyId];
        final address = property?.address.toLowerCase() ?? '';
        final techs = t.assignedTechnicians.join(' ').toLowerCase();
        return address.contains(_searchQuery.toLowerCase()) ||
            techs.contains(_searchQuery.toLowerCase()) ||
            t.id.toString().contains(_searchQuery);
      }).toList();
    }

    // Sort by scheduled date (most recent first)
    tasks.sort((a, b) => b.scheduledDate.compareTo(a.scheduledDate));

    return tasks;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Repair Tasks'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Needs Reschedule'),
            Tab(text: 'Assigned'),
            Tab(text: 'In Progress'),
            Tab(text: 'Completed'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by address, technician, or task #',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                isDense: true,
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),

          // Task Lists
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTaskList(null),
                // Tasks a technician kept open for another day
                _buildTaskList(RepairTaskStatus.pending),
                _buildTaskList(RepairTaskStatus.assigned),
                _buildTaskList(RepairTaskStatus.inProgress),
                _buildTaskList(RepairTaskStatus.completed),
                _buildTaskList(RepairTaskStatus.cancelled),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList(String? statusFilter) {
    final tasks = _getFilteredTasks(statusFilter);

    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No repair tasks',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => setState(() {}),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: tasks.length,
        itemBuilder: (context, index) => _buildTaskCard(tasks[index]),
      ),
    );
  }

  Widget _buildTaskCard(RepairTask task) {
    final property = widget.authService.storage.properties[task.propertyId];
    final statusColor = RepairTaskStatus.getColor(task.status);
    final priorityColor = TaskPriority.getColor(task.priority);

    // Get technician names
    final techNames = task.assignedTechnicians.map((email) {
      final user = widget.authService.storage.users[email];
      return user?.name ?? email;
    }).join(', ');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showTaskDetails(task),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
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
                  const SizedBox(width: 8),
                  if (task.priority != TaskPriority.normal)
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
                  const Spacer(),
                  Text(
                    'Task #${task.id}',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Property Address
              Row(
                children: [
                  const Icon(Icons.location_on, size: 18, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      property?.address ?? 'Unknown Property',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  if (property != null && property.address.isNotEmpty)
                    OpenInMapsButton(address: property.address),
                ],
              ),
              const SizedBox(height: 4),

              // Scheduled Date
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(task.scheduledDate),
                ],
              ),
              const SizedBox(height: 4),

              // Assigned Technicians
              Row(
                children: [
                  const Icon(Icons.person, size: 18, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      techNames,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Footer
              Row(
                children: [
                  Icon(Icons.build, size: 16, color: Colors.grey.shade400),
                  const SizedBox(width: 4),
                  Text(
                    '${task.repairs.length} items',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                  const SizedBox(width: 16),
                  if (task.status == RepairTaskStatus.completed && task.completedAt != null) ...[
                    Icon(Icons.check_circle, size: 16, color: Colors.green.shade400),
                    const SizedBox(width: 4),
                    Text(
                      'Completed ${_formatCompletedDate(task.completedAt!)}',
                      style: TextStyle(color: Colors.green.shade600, fontSize: 12),
                    ),
                  ] else ...[
                    Icon(Icons.timer, size: 16, color: Colors.grey.shade400),
                    const SizedBox(width: 4),
                    Text(
                      '${task.estimatedHours}h estimated',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTaskDetails(RepairTask task) {
    final property = widget.authService.storage.properties[task.propertyId];
    final quote = widget.authService.storage.quotes[task.quoteId];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    'Task #${task.id}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: RepairTaskStatus.getColor(task.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      RepairTaskStatus.getDisplayName(task.status),
                      style: TextStyle(
                        color: RepairTaskStatus.getColor(task.status),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                children: [
                  _detailRow('Property', property?.address ?? 'Unknown'),
                  _detailRow('Scheduled', task.scheduledDate),
                  if (task.status == RepairTaskStatus.completed && task.completedAt != null)
                    _detailRow('Completed', _formatCompletedDate(task.completedAt!)),
                  _detailRow('Priority', task.priority.toUpperCase()),
                  _detailRow('Est. Hours', '${task.estimatedHours}h'),
                  if (quote != null)
                    _detailRow('Quote #', '${quote.id} (\$${quote.totalCost.toStringAsFixed(2)})'),

                  const SizedBox(height: 16),
                  const Text(
                    'Assigned Technicians',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  ...task.assignedTechnicians.map((email) {
                    final user = widget.authService.storage.users[email];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 16,
                            child: Icon(Icons.person, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user?.name ?? email),
                              Text(
                                email,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 16),
                  const Text(
                    'Repair Items',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  ...task.repairs.map((repair) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Text(
                              '${repair.quantity}x',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                repair.itemName.split('_').map((w) =>
                                    w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : ''
                                ).join(' ') +
                                    (repair.zoneNumber > 0 ? ' (Zone ${repair.zoneNumber})' : ''),
                              ),
                            ),
                          ],
                        ),
                      )),

                  if (task.technicianNotes?.isNotEmpty == true) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Notes',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(task.technicianNotes!),
                    ),
                  ],

                  if (task.completionNotes?.isNotEmpty == true) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Completion Notes',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(task.completionNotes!),
                    ),
                  ],

                  // Edit / Cancel actions
                  if (task.status != RepairTaskStatus.completed &&
                      task.status != RepairTaskStatus.cancelled) ...[
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _editTask(task);
                        },
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Edit Task'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0EA5E9),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _cancelTask(task);
                        },
                        icon: const Icon(Icons.cancel_outlined),
                        label: const Text('Cancel Task'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.all(14),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _editTask(RepairTask task) {
    DateTime selectedDate;
    try {
      selectedDate = DateFormat('yyyy-MM-dd').parse(task.scheduledDate);
    } catch (_) {
      selectedDate = DateTime.now().add(const Duration(days: 1));
    }

    // Any active employee can be assigned, not just technicians
    final availableTechs = widget.authService.storage.users.values
        .where((u) => !u.isArchived)
        .toList();
    final selectedTechs = List<String>.from(task.assignedTechnicians);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              left: 16, right: 16, top: 16,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Edit Task #${task.id}',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 8),

                  // Scheduled Date
                  const Text('Scheduled Date',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: selectedDate,
                        firstDate: DateTime.now().subtract(
                            const Duration(days: 365)),
                        lastDate: DateTime.now()
                            .add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setModalState(() => selectedDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 18),
                          const SizedBox(width: 8),
                          Text(DateFormat('MMM d, yyyy')
                              .format(selectedDate)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Technicians
                  const Text('Assigned Technicians',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  ...availableTechs.map((user) => CheckboxListTile(
                        title: Text(user.name),
                        subtitle: Text(user.email,
                            style: const TextStyle(fontSize: 12)),
                        value: selectedTechs.contains(user.email),
                        dense: true,
                        onChanged: (checked) {
                          setModalState(() {
                            if (checked == true) {
                              selectedTechs.add(user.email);
                            } else {
                              selectedTechs.remove(user.email);
                            }
                          });
                        },
                      )),
                  const SizedBox(height: 16),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: selectedTechs.isEmpty
                          ? null
                          : () {
                              final storage =
                                  widget.authService.storage;
                              final updated = task.copyWith(
                                scheduledDate: DateFormat('yyyy-MM-dd')
                                    .format(selectedDate),
                                assignedTechnicians: selectedTechs,
                                // A kept-open task goes back on the
                                // technician's list once rescheduled
                                status: task.status ==
                                        RepairTaskStatus.pending
                                    ? RepairTaskStatus.assigned
                                    : task.status,
                              );
                              storage.repairTasks[task.id] = updated;
                              storage.saveData();
                              Navigator.pop(ctx);
                              setState(() {});
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Task updated'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0EA5E9),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(14),
                      ),
                      child: const Text('Save Changes'),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _cancelTask(RepairTask task) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Task'),
        content: Text(
            'Cancel Task #${task.id}? This cannot be undone and the technician will no longer see this task.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Keep Task')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              final storage = widget.authService.storage;
              storage.repairTasks[task.id] =
                  task.copyWith(status: RepairTaskStatus.cancelled);
              storage.saveData();
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Task cancelled'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            child: const Text('Cancel Task'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  String _formatCompletedDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return '${date.month}/${date.day}/${date.year}';
    } catch (e) {
      return isoDate;
    }
  }
}
