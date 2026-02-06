import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../models/inspection.dart';

class AssignInspectionScreen extends StatefulWidget {
  final AuthService authService;

  const AssignInspectionScreen({Key? key, required this.authService}) : super(key: key);

  @override
  State<AssignInspectionScreen> createState() => _AssignInspectionScreenState();
}

class _AssignInspectionScreenState extends State<AssignInspectionScreen> {
  int? selectedPropertyId;
  List<String> selectedTechnicians = [];
  DateTime? selectedDate;
  final _dateController = TextEditingController();

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        _dateController.text = DateFormat('MM/dd/yyyy').format(picked);
      });
    }
  }

  String _getBillingMonth(DateTime date) {
    return DateFormat('yyyy-MM').format(date);
  }

  bool _isPropertyAssignedThisMonth(int propertyId, String billingMonth) {
    final storage = widget.authService.storage;
    return storage.inspections.values.any((insp) =>
        insp.propertyId == propertyId && insp.billingMonth == billingMonth);
  }

  @override
  Widget build(BuildContext context) {
    final storage = widget.authService.storage;
    final properties = storage.properties.values.toList();
    final technicians = storage.users.entries
        .where((e) => e.value.role == 'technician' && !e.value.isArchived)
        .toList();

    // Get managers for self-assignment option
    final managers = storage.users.entries
        .where((e) => e.value.role == 'manager' && !e.value.isArchived)
        .toList();

    final currentBillingMonth = _getBillingMonth(selectedDate ?? DateTime.now());

    return Scaffold(
      appBar: AppBar(title: const Text('Assign Inspection')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Property Selection
            const Text('Select Property', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              isExpanded: true,
              value: selectedPropertyId,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Choose property',
              ),
              items: properties.map((p) {
                final isAssigned = _isPropertyAssignedThisMonth(p.id, currentBillingMonth);
                return DropdownMenuItem(
                  value: p.id,
                  child: Row(
                    children: [
                      Expanded(child: Text(p.address)),
                      if (isAssigned)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Assigned',
                            style: TextStyle(fontSize: 10, color: Colors.orange),
                          ),
                        ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (v) => setState(() => selectedPropertyId = v),
            ),

            // Show warning if already assigned
            if (selectedPropertyId != null &&
                _isPropertyAssignedThisMonth(selectedPropertyId!, currentBillingMonth))
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This property has already been assigned this month. '
                        'You can still assign it again if needed.',
                        style: TextStyle(color: Colors.orange.shade800, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),

            // Show property notes if available
            if (selectedPropertyId != null) ...[
              Builder(builder: (context) {
                final property = storage.properties[selectedPropertyId];
                if (property != null && property.notes.isNotEmpty) {
                  return Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.notes, size: 16, color: Colors.blue),
                            SizedBox(width: 4),
                            Text('Property Notes:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(property.notes, style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),
            ],

            const SizedBox(height: 24),

            // Technician Selection (Multi-select)
            const Text('Select Technician(s)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text(
              'Select one or more technicians for this walk',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 8),

            if (technicians.isEmpty && managers.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'No technicians available. Create technician accounts first.',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Managers section (for self-assignment)
                    if (managers.isNotEmpty) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        color: Colors.blue.shade50,
                        child: const Text(
                          'Managers (Self-Assign)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                      ...managers.map((m) {
                        final isSelected = selectedTechnicians.contains(m.key);
                        return CheckboxListTile(
                          title: Row(
                            children: [
                              Text(m.value.name),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Manager',
                                  style: TextStyle(fontSize: 10, color: Colors.blue),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Text(m.key, style: const TextStyle(fontSize: 12)),
                          value: isSelected,
                          onChanged: (checked) {
                            setState(() {
                              if (checked == true) {
                                selectedTechnicians.add(m.key);
                              } else {
                                selectedTechnicians.remove(m.key);
                              }
                            });
                          },
                        );
                      }),
                    ],
                    // Technicians section
                    if (technicians.isNotEmpty) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        color: Colors.green.shade50,
                        child: const Text(
                          'Technicians',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                      ...technicians.map((t) {
                        final isSelected = selectedTechnicians.contains(t.key);
                        return CheckboxListTile(
                          title: Text(t.value.name),
                          subtitle: Text(t.key, style: const TextStyle(fontSize: 12)),
                          value: isSelected,
                          onChanged: (checked) {
                            setState(() {
                              if (checked == true) {
                                selectedTechnicians.add(t.key);
                              } else {
                                selectedTechnicians.remove(t.key);
                              }
                            });
                          },
                        );
                      }),
                    ],
                  ],
                ),
              ),

            if (selectedTechnicians.length > 1)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.group, color: Colors.green, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Shared walk: ${selectedTechnicians.length} technicians will work together',
                      style: TextStyle(color: Colors.green.shade800, fontSize: 12),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // Date Selection
            TextField(
              controller: _dateController,
              readOnly: true,
              onTap: () => _selectDate(context),
              decoration: InputDecoration(
                labelText: 'Inspection Date',
                hintText: 'MM/DD/YYYY',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () => _selectDate(context),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Assign Button
            ElevatedButton(
              onPressed: selectedPropertyId != null && selectedTechnicians.isNotEmpty
                  ? _assignInspection
                  : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.green,
              ),
              child: Text(
                selectedTechnicians.length > 1
                    ? 'Assign Shared Walk'
                    : 'Assign Inspection',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _assignInspection() {
    if (selectedPropertyId == null || selectedTechnicians.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select property and at least one technician')),
      );
      return;
    }

    final storage = widget.authService.storage;
    final date = selectedDate ?? DateTime.now();
    final dateStr = DateFormat('MM/dd/yyyy').format(date);
    final billingMonth = _getBillingMonth(date);

    final inspection = Inspection(
      id: storage.nextInspectionId,
      propertyId: selectedPropertyId!,
      technicians: selectedTechnicians,
      date: dateStr,
      status: 'assigned',
      repairs: [],
      totalCost: 0.0,
      billingMonth: billingMonth,
    );

    storage.inspections[storage.nextInspectionId] = inspection;
    storage.nextInspectionId++;
    storage.saveData();

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          selectedTechnicians.length > 1
              ? 'Shared walk assigned to ${selectedTechnicians.length} technicians'
              : 'Inspection assigned successfully',
        ),
        backgroundColor: Colors.green,
      ),
    );
  }
}
