import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../models/inspection.dart';

class BulkScheduleScreen extends StatefulWidget {
  final AuthService authService;

  const BulkScheduleScreen({Key? key, required this.authService}) : super(key: key);

  @override
  State<BulkScheduleScreen> createState() => _BulkScheduleScreenState();
}

class _BulkScheduleScreenState extends State<BulkScheduleScreen> {
  final Set<int> selectedPropertyIds = {};
  final Set<String> selectedTechEmails = {};
  DateTime selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final storage = widget.authService.storage;
    final properties = storage.properties.values.toList();
    final technicians = storage.users.entries
        .where((e) => e.value.role == 'technician' && !e.value.isArchived)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule Inspections'),
        actions: [
          if (selectedPropertyIds.isNotEmpty && selectedTechEmails.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _createSchedules,
              tooltip: 'Create Schedules',
            ),
        ],
      ),
      body: Column(
        children: [
          // Summary Card
          Card(
            margin: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Schedule Summary',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryItem(
                          'Properties',
                          selectedPropertyIds.length.toString(),
                          Icons.home_work,
                        ),
                      ),
                      Expanded(
                        child: _buildSummaryItem(
                          'Technicians',
                          selectedTechEmails.length.toString(),
                          Icons.person,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildSummaryItem(
                    'Total Inspections',
                    (selectedPropertyIds.length * selectedTechEmails.length).toString(),
                    Icons.assignment,
                  ),
                  const Divider(height: 24),
                  // Date Selector
                  const Text(
                    'Inspection Date',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _selectDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                        color: Colors.white,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            DateFormat('EEEE, MMM d, yyyy').format(selectedDate),
                            style: const TextStyle(fontSize: 16),
                          ),
                          const Icon(Icons.calendar_today, color: Colors.blue),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Tabs for Properties and Technicians
          Expanded(
            child: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  const TabBar(
                    tabs: [
                      Tab(icon: Icon(Icons.home_work), text: 'Properties'),
                      Tab(icon: Icon(Icons.person), text: 'Technicians'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        // Properties Tab
                        _buildPropertiesList(properties),
                        // Technicians Tab
                        _buildTechniciansList(technicians),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Create Button
          if (selectedPropertyIds.isNotEmpty && selectedTechEmails.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _createSchedules,
                  icon: const Icon(Icons.schedule),
                  label: Text(
                    'Create ${selectedPropertyIds.length * selectedTechEmails.length} Inspections',
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.blue),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPropertiesList(List properties) {
    if (properties.isEmpty) {
      return const Center(child: Text('No properties available'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: properties.length,
      itemBuilder: (context, index) {
        final prop = properties[index];
        final isSelected = selectedPropertyIds.contains(prop.id);

        return Card(
          child: CheckboxListTile(
            value: isSelected,
            onChanged: (bool? value) {
              setState(() {
                if (value == true) {
                  selectedPropertyIds.add(prop.id);
                } else {
                  selectedPropertyIds.remove(prop.id);
                }
              });
            },
            secondary: const Icon(Icons.home_work),
            title: Text(prop.address),
            subtitle: Text('${prop.zones.length} zones'),
          ),
        );
      },
    );
  }

  Widget _buildTechniciansList(List technicians) {
    if (technicians.isEmpty) {
      return const Center(child: Text('No technicians available'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: technicians.length,
      itemBuilder: (context, index) {
        final tech = technicians[index];
        final isSelected = selectedTechEmails.contains(tech.key);

        return Card(
          child: CheckboxListTile(
            value: isSelected,
            onChanged: (bool? value) {
              setState(() {
                if (value == true) {
                  selectedTechEmails.add(tech.key);
                } else {
                  selectedTechEmails.remove(tech.key);
                }
              });
            },
            secondary: const Icon(Icons.person),
            title: Text(tech.value.name),
            subtitle: Text(tech.key),
          ),
        );
      },
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  void _createSchedules() {
    if (selectedPropertyIds.isEmpty || selectedTechEmails.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one property and one technician'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Bulk Schedule'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Properties: ${selectedPropertyIds.length}'),
            Text('Technicians: ${selectedTechEmails.length}'),
            Text('Date: ${DateFormat('MMM d, yyyy').format(selectedDate)}'),
            const SizedBox(height: 16),
            Text(
              'Total: ${selectedPropertyIds.length * selectedTechEmails.length} inspections',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Each technician will be assigned to all selected properties.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
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
              _performBulkSchedule();
              Navigator.pop(context);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _performBulkSchedule() {
    final storage = widget.authService.storage;
    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
    int created = 0;
    int skipped = 0;

    for (final propertyId in selectedPropertyIds) {
      for (final techEmail in selectedTechEmails) {
        // Check if there's already an incomplete inspection for this property-tech-date combo
        final existingIncomplete = storage.inspections.values.any((insp) =>
            insp.propertyId == propertyId &&
            insp.technicians.contains(techEmail) &&
            insp.date == dateStr &&
            insp.status != 'completed');

        if (existingIncomplete) {
          skipped++;
          continue; // Skip creating duplicate
        }

        // Get billing month from date
        final billingMonth = DateFormat('yyyy-MM').format(selectedDate);

        final inspection = Inspection(
          id: storage.nextInspectionId,
          propertyId: propertyId,
          technicians: [techEmail],
          date: dateStr,
          status: 'assigned',
          repairs: [],
          totalCost: 0.0,
          billingMonth: billingMonth,
        );

        storage.inspections[storage.nextInspectionId] = inspection;
        storage.nextInspectionId++;
        created++;
      }
    }

    storage.saveData();

    Navigator.pop(context);

    String message = 'Successfully created $created inspection${created != 1 ? 's' : ''}';
    if (skipped > 0) {
      message += '\n$skipped skipped (already assigned)';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: created > 0 ? Colors.green : Colors.orange,
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
