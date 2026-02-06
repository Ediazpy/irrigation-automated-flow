import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../models/inspection.dart';

class _AssignmentGroup {
  Set<String> techEmails;
  Set<int> propertyIds;

  _AssignmentGroup({
    Set<String>? techEmails,
    Set<int>? propertyIds,
  })  : techEmails = techEmails ?? {},
        propertyIds = propertyIds ?? {};

  int get totalInspections => propertyIds.length * techEmails.length;
}

class BulkScheduleScreen extends StatefulWidget {
  final AuthService authService;

  const BulkScheduleScreen({Key? key, required this.authService}) : super(key: key);

  @override
  State<BulkScheduleScreen> createState() => _BulkScheduleScreenState();
}

class _BulkScheduleScreenState extends State<BulkScheduleScreen> {
  final List<_AssignmentGroup> groups = [];
  DateTime selectedDate = DateTime.now();

  int get _totalInspections =>
      groups.fold(0, (sum, g) => sum + g.totalInspections);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule Inspections'),
        actions: [
          if (_totalInspections > 0)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _confirmAndCreate,
              tooltip: 'Create All',
            ),
        ],
      ),
      body: Column(
        children: [
          // Date & Summary Card
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
                          'Groups',
                          groups.length.toString(),
                          Icons.group_work,
                        ),
                      ),
                      Expanded(
                        child: _buildSummaryItem(
                          'Total Inspections',
                          _totalInspections.toString(),
                          Icons.assignment,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
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

          // Assignment Groups List
          Expanded(
            child: groups.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.group_add, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'No assignment groups yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Add a group to assign properties to technicians',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: groups.length,
                    itemBuilder: (context, index) => _buildGroupCard(index),
                  ),
          ),

          // Add Group & Create Buttons
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
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _addGroup,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Assignment Group'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(14),
                    ),
                  ),
                ),
                if (_totalInspections > 0) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _confirmAndCreate,
                      icon: const Icon(Icons.schedule),
                      label: Text('Create $_totalInspections Inspection${_totalInspections != 1 ? 's' : ''}'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupCard(int index) {
    final group = groups[index];
    final storage = widget.authService.storage;

    final techNames = group.techEmails
        .map((e) => storage.users[e]?.name ?? e)
        .toList();
    final propAddresses = group.propertyIds
        .map((id) => storage.properties[id]?.address ?? 'Unknown')
        .toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  radius: 14,
                  child: Text('${index + 1}', style: const TextStyle(fontSize: 12)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Group ${index + 1}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Text(
                  '${group.totalInspections} inspection${group.totalInspections != 1 ? 's' : ''}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                  onPressed: () {
                    setState(() => groups.removeAt(index));
                  },
                ),
              ],
            ),
            const Divider(),
            // Technicians
            InkWell(
              onTap: () => _editGroupTechs(index),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.person, size: 18, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: techNames.isEmpty
                          ? Text(
                              'Tap to select technicians',
                              style: TextStyle(color: Colors.grey.shade500, fontStyle: FontStyle.italic),
                            )
                          : Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              children: techNames
                                  .map((n) => Chip(
                                        label: Text(n, style: const TextStyle(fontSize: 12)),
                                        visualDensity: VisualDensity.compact,
                                      ))
                                  .toList(),
                            ),
                    ),
                    const Icon(Icons.edit, size: 16, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            // Properties
            InkWell(
              onTap: () => _editGroupProperties(index),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.home_work, size: 18, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: propAddresses.isEmpty
                          ? Text(
                              'Tap to select properties',
                              style: TextStyle(color: Colors.grey.shade500, fontStyle: FontStyle.italic),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: propAddresses
                                  .map((a) => Padding(
                                        padding: const EdgeInsets.only(bottom: 2),
                                        child: Text('- $a', style: const TextStyle(fontSize: 13)),
                                      ))
                                  .toList(),
                            ),
                    ),
                    const Icon(Icons.edit, size: 16, color: Colors.grey),
                  ],
                ),
              ),
            ),
          ],
        ),
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
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  void _addGroup() {
    setState(() {
      groups.add(_AssignmentGroup());
    });
    // Immediately open tech selection for the new group
    _editGroupTechs(groups.length - 1);
  }

  void _editGroupTechs(int groupIndex) {
    final group = groups[groupIndex];
    final storage = widget.authService.storage;
    final technicians = storage.users.entries
        .where((e) => e.value.role == 'technician' && !e.value.isArchived)
        .toList();

    final tempSelected = Set<String>.from(group.techEmails);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.3,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) {
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Text(
                            'Select Technicians (Group ${groupIndex + 1})',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                group.techEmails = tempSelected;
                              });
                              Navigator.pop(context);
                            },
                            child: const Text('Done'),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 0),
                    Expanded(
                      child: technicians.isEmpty
                          ? const Center(child: Text('No technicians available'))
                          : ListView.builder(
                              controller: scrollController,
                              itemCount: technicians.length,
                              itemBuilder: (context, index) {
                                final tech = technicians[index];
                                final isSelected = tempSelected.contains(tech.key);
                                return CheckboxListTile(
                                  value: isSelected,
                                  onChanged: (value) {
                                    setSheetState(() {
                                      if (value == true) {
                                        tempSelected.add(tech.key);
                                      } else {
                                        tempSelected.remove(tech.key);
                                      }
                                    });
                                  },
                                  secondary: const Icon(Icons.person),
                                  title: Text(tech.value.name),
                                  subtitle: Text(tech.key),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    ).then((_) {
      // Ensure state is updated when sheet is dismissed
      setState(() {
        group.techEmails = tempSelected;
      });
    });
  }

  void _editGroupProperties(int groupIndex) {
    final group = groups[groupIndex];
    final storage = widget.authService.storage;
    final properties = storage.properties.values.toList();

    final tempSelected = Set<int>.from(group.propertyIds);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.3,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) {
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Text(
                            'Select Properties (Group ${groupIndex + 1})',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                group.propertyIds = tempSelected;
                              });
                              Navigator.pop(context);
                            },
                            child: const Text('Done'),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 0),
                    Expanded(
                      child: properties.isEmpty
                          ? const Center(child: Text('No properties available'))
                          : ListView.builder(
                              controller: scrollController,
                              itemCount: properties.length,
                              itemBuilder: (context, index) {
                                final prop = properties[index];
                                final isSelected = tempSelected.contains(prop.id);
                                return CheckboxListTile(
                                  value: isSelected,
                                  onChanged: (value) {
                                    setSheetState(() {
                                      if (value == true) {
                                        tempSelected.add(prop.id);
                                      } else {
                                        tempSelected.remove(prop.id);
                                      }
                                    });
                                  },
                                  secondary: const Icon(Icons.home_work),
                                  title: Text(prop.address),
                                  subtitle: Text('${prop.zones.length} zones'),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    ).then((_) {
      setState(() {
        group.propertyIds = tempSelected;
      });
    });
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

  void _confirmAndCreate() {
    // Validate all groups have both techs and properties
    final emptyGroups = groups.where((g) => g.techEmails.isEmpty || g.propertyIds.isEmpty).toList();
    if (emptyGroups.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All groups must have at least one technician and one property'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final storage = widget.authService.storage;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Schedule'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Date: ${DateFormat('MMM d, yyyy').format(selectedDate)}'),
              const SizedBox(height: 12),
              ...groups.asMap().entries.map((entry) {
                final i = entry.key;
                final g = entry.value;
                final techNames = g.techEmails
                    .map((e) => storage.users[e]?.name ?? e)
                    .join(', ');
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Group ${i + 1}: ${g.totalInspections} inspection${g.totalInspections != 1 ? 's' : ''}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('Techs: $techNames', style: const TextStyle(fontSize: 12)),
                      Text('Properties: ${g.propertyIds.length}', style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                );
              }),
              const Divider(),
              Text(
                'Total: $_totalInspections inspections',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
              Navigator.pop(context);
              _performSchedule();
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _performSchedule() {
    final storage = widget.authService.storage;
    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
    final billingMonth = DateFormat('yyyy-MM').format(selectedDate);
    int created = 0;
    int skipped = 0;

    for (final group in groups) {
      for (final propertyId in group.propertyIds) {
        for (final techEmail in group.techEmails) {
          // Check for existing incomplete inspection
          final existingIncomplete = storage.inspections.values.any((insp) =>
              insp.propertyId == propertyId &&
              insp.technicians.contains(techEmail) &&
              insp.date == dateStr &&
              insp.status != 'completed');

          if (existingIncomplete) {
            skipped++;
            continue;
          }

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
