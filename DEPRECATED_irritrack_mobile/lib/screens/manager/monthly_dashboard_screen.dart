import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../models/property.dart';
import '../../models/inspection.dart';
import 'assign_inspection_screen.dart';

class MonthlyDashboardScreen extends StatefulWidget {
  final AuthService authService;

  const MonthlyDashboardScreen({Key? key, required this.authService}) : super(key: key);

  @override
  State<MonthlyDashboardScreen> createState() => _MonthlyDashboardScreenState();
}

class _MonthlyDashboardScreenState extends State<MonthlyDashboardScreen> {
  late DateTime selectedMonth;

  @override
  void initState() {
    super.initState();
    selectedMonth = DateTime.now();
  }

  String _getBillingMonth(DateTime date) {
    return DateFormat('yyyy-MM').format(date);
  }

  void _previousMonth() {
    setState(() {
      selectedMonth = DateTime(selectedMonth.year, selectedMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      selectedMonth = DateTime(selectedMonth.year, selectedMonth.month + 1);
    });
  }

  Map<String, dynamic> _getPropertyStatus(Property property, String billingMonth) {
    final storage = widget.authService.storage;

    // Find inspections for this property in this billing month
    final inspections = storage.inspections.values
        .where((insp) =>
            insp.propertyId == property.id &&
            insp.billingMonth == billingMonth)
        .toList();

    if (inspections.isEmpty) {
      return {
        'status': 'not_assigned',
        'color': Colors.grey,
        'label': 'Not Assigned',
        'inspections': <Inspection>[],
      };
    }

    // Check statuses
    final hasReview = inspections.any((i) => i.status == 'review');
    final hasInProgress = inspections.any((i) => i.status == 'in_progress');
    final allCompleted = inspections.every((i) => i.status == 'completed');

    if (allCompleted) {
      return {
        'status': 'completed',
        'color': Colors.green,
        'label': 'Completed',
        'inspections': inspections,
      };
    } else if (hasReview) {
      return {
        'status': 'review',
        'color': Colors.orange,
        'label': 'Pending Review',
        'inspections': inspections,
      };
    } else if (hasInProgress) {
      return {
        'status': 'in_progress',
        'color': Colors.blue,
        'label': 'In Progress',
        'inspections': inspections,
      };
    } else {
      return {
        'status': 'assigned',
        'color': Colors.amber,
        'label': 'Assigned',
        'inspections': inspections,
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    final storage = widget.authService.storage;
    final properties = storage.properties.values.toList();
    final billingMonth = _getBillingMonth(selectedMonth);

    // Calculate statistics
    int notAssigned = 0;
    int assigned = 0;
    int inProgress = 0;
    int review = 0;
    int completed = 0;

    for (final property in properties) {
      final status = _getPropertyStatus(property, billingMonth);
      switch (status['status']) {
        case 'not_assigned':
          notAssigned++;
          break;
        case 'assigned':
          assigned++;
          break;
        case 'in_progress':
          inProgress++;
          break;
        case 'review':
          review++;
          break;
        case 'completed':
          completed++;
          break;
      }
    }

    final total = properties.length;
    final completionPercentage = total > 0 ? (completed / total * 100).toStringAsFixed(0) : '0';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monthly Schedule'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AssignInspectionScreen(authService: widget.authService),
                ),
              ).then((_) => setState(() {}));
            },
            tooltip: 'Assign Inspection',
          ),
        ],
      ),
      body: Column(
        children: [
          // Month selector
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _previousMonth,
                ),
                Text(
                  DateFormat('MMMM yyyy').format(selectedMonth),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _nextMonth,
                ),
              ],
            ),
          ),

          // Statistics cards
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Progress bar
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$completionPercentage% Complete',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: total > 0 ? completed / total : 0,
                              minHeight: 12,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '$completed/$total',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Status chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _StatusChip(
                      label: 'Not Assigned',
                      count: notAssigned,
                      color: Colors.grey,
                    ),
                    _StatusChip(
                      label: 'Assigned',
                      count: assigned,
                      color: Colors.amber,
                    ),
                    _StatusChip(
                      label: 'In Progress',
                      count: inProgress,
                      color: Colors.blue,
                    ),
                    _StatusChip(
                      label: 'Review',
                      count: review,
                      color: Colors.orange,
                    ),
                    _StatusChip(
                      label: 'Completed',
                      count: completed,
                      color: Colors.green,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Property list
          Expanded(
            child: properties.isEmpty
                ? const Center(child: Text('No properties found'))
                : ListView.builder(
                    itemCount: properties.length,
                    itemBuilder: (context, index) {
                      final property = properties[index];
                      final statusInfo = _getPropertyStatus(property, billingMonth);
                      final inspections = statusInfo['inspections'] as List<Inspection>;

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: ExpansionTile(
                          leading: CircleAvatar(
                            backgroundColor: statusInfo['color'] as Color,
                            child: Icon(
                              _getStatusIcon(statusInfo['status'] as String),
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            property.address,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                statusInfo['label'] as String,
                                style: TextStyle(
                                  color: statusInfo['color'] as Color,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (property.clientName.isNotEmpty)
                                Text(
                                  property.clientName,
                                  style: const TextStyle(fontSize: 12),
                                ),
                            ],
                          ),
                          trailing: statusInfo['status'] == 'not_assigned'
                              ? IconButton(
                                  icon: const Icon(Icons.add_circle, color: Colors.green),
                                  onPressed: () => _assignProperty(property),
                                  tooltip: 'Assign',
                                )
                              : null,
                          children: [
                            if (inspections.isEmpty)
                              ListTile(
                                title: const Text('No inspections scheduled'),
                                trailing: ElevatedButton.icon(
                                  icon: const Icon(Icons.add, size: 16),
                                  label: const Text('Assign'),
                                  onPressed: () => _assignProperty(property),
                                ),
                              )
                            else
                              ...inspections.map((insp) => _buildInspectionTile(insp)),
                            if (property.notes.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.notes, size: 16, color: Colors.blue),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        property.notes,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: null,
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'not_assigned':
        return Icons.schedule;
      case 'assigned':
        return Icons.assignment;
      case 'in_progress':
        return Icons.play_circle;
      case 'review':
        return Icons.rate_review;
      case 'completed':
        return Icons.check_circle;
      default:
        return Icons.help;
    }
  }

  Widget _buildInspectionTile(Inspection inspection) {
    final storage = widget.authService.storage;
    final techNames = inspection.technicians
        .map((email) => storage.users[email]?.name ?? email)
        .join(', ');

    Color statusColor;
    switch (inspection.status) {
      case 'completed':
        statusColor = Colors.green;
        break;
      case 'review':
        statusColor = Colors.orange;
        break;
      case 'in_progress':
        statusColor = Colors.blue;
        break;
      default:
        statusColor = Colors.amber;
    }

    return ListTile(
      leading: Icon(Icons.person, color: statusColor),
      title: Text(techNames),
      subtitle: Text('${inspection.date} - ${inspection.status}'),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          inspection.status.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            color: statusColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _assignProperty(Property property) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AssignInspectionScreen(authService: widget.authService),
      ),
    ).then((_) => setState(() {}));
  }

}

class _StatusChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatusChip({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

