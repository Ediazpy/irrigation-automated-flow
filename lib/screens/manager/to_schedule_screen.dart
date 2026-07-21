import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../models/inspection.dart';
import '../../constants/status_constants.dart';

/// Inspections the scheduler has marked "due" — recurring properties whose
/// interval has elapsed. The manager picks a date and team members here,
/// which moves the inspection onto the assigned schedule.
class ToScheduleScreen extends StatefulWidget {
  final AuthService authService;

  const ToScheduleScreen({Key? key, required this.authService}) : super(key: key);

  @override
  State<ToScheduleScreen> createState() => _ToScheduleScreenState();
}

class _ToScheduleScreenState extends State<ToScheduleScreen> {
  List<Inspection> get _dueInspections {
    final due = widget.authService.storage.inspections.values
        .where((i) => i.status == InspectionStatus.due)
        .toList();
    due.sort((a, b) => a.billingMonth.compareTo(b.billingMonth));
    return due;
  }

  @override
  Widget build(BuildContext context) {
    final due = _dueInspections;
    final storage = widget.authService.storage;

    return Scaffold(
      appBar: AppBar(title: const Text('To Schedule')),
      body: due.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_available, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'All caught up!',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Recurring inspections appear here when they come due.',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: due.length,
              itemBuilder: (context, index) {
                final inspection = due[index];
                final property = storage.properties[inspection.propertyId];

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.deepOrange.shade50,
                      child: Icon(Icons.event_available,
                          color: Colors.deepOrange.shade700),
                    ),
                    title: Text(property?.address ?? 'Unknown Property'),
                    subtitle: Text(
                      'Due for ${inspection.billingMonth}'
                      '${property != null ? ' • ${InspectionFrequency.getDisplayName(property.inspectionFrequency)}' : ''}',
                    ),
                    trailing: ElevatedButton(
                      onPressed: () => _scheduleDialog(inspection),
                      child: const Text('Schedule'),
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _scheduleDialog(Inspection inspection) {
    final storage = widget.authService.storage;
    final property = storage.properties[inspection.propertyId];
    // Any active employee can be assigned
    final availableUsers =
        storage.users.values.where((u) => !u.isArchived).toList();
    final selected = <String>{};
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                property?.address ?? 'Schedule Inspection',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text('Date', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) setModalState(() => selectedDate = picked);
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month, size: 20),
                      const SizedBox(width: 10),
                      Text(DateFormat('EEEE, MMMM d, yyyy').format(selectedDate)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Assign Team Members',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              ...availableUsers.map((user) => CheckboxListTile(
                    dense: true,
                    title: Text(user.name),
                    subtitle: Text(user.email, style: const TextStyle(fontSize: 12)),
                    value: selected.contains(user.email),
                    onChanged: (checked) {
                      setModalState(() {
                        if (checked == true) {
                          selected.add(user.email);
                        } else {
                          selected.remove(user.email);
                        }
                      });
                    },
                  )),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  if (selected.isEmpty) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(
                        content: Text('Select at least one team member'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }
                  storage.inspections[inspection.id] = inspection.copyWith(
                    status: InspectionStatus.assigned,
                    technicians: selected.toList(),
                    date: DateFormat('yyyy-MM-dd').format(selectedDate),
                  );
                  storage.saveData();
                  Navigator.pop(ctx);
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Inspection scheduled'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(14),
                ),
                child: const Text('Schedule Inspection'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
