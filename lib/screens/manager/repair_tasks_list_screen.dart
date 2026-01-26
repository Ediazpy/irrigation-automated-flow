import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../models/repair_task.dart';
import '../../constants/status_constants.dart';

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
    _tabController = TabController(length: 4, vsync: this);
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
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Assigned'),
            Tab(text: 'In Progress'),
            Tab(text: 'Completed'),
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
                _buildTaskList(RepairTaskStatus.assigned),
                _buildTaskList(RepairTaskStatus.inProgress),
                _buildTaskList(RepairTaskStatus.completed),
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
                  Icon(Icons.timer, size: 16, color: Colors.grey.shade400),
                  const SizedBox(width: 4),
                  Text(
                    '${task.estimatedHours}h estimated',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
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
                ],
              ),
            ),
          ],
        ),
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
}
