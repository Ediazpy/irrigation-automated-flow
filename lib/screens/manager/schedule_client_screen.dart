import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../models/property.dart';
import '../../models/inspection.dart';
import '../../constants/status_constants.dart';
import '../../widgets/address_autocomplete_field.dart';

class ScheduleClientScreen extends StatefulWidget {
  final AuthService authService;

  const ScheduleClientScreen({Key? key, required this.authService})
      : super(key: key);

  @override
  State<ScheduleClientScreen> createState() => _ScheduleClientScreenState();
}

class _ScheduleClientScreenState extends State<ScheduleClientScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  String _inspectionFrequency = InspectionFrequency.monthly;
  final _clientNameController = TextEditingController();
  final _clientEmailController = TextEditingController();
  final _clientPhoneController = TextEditingController();
  final _notesController = TextEditingController();

  List<String> _selectedTechnicians = [];
  DateTime? _selectedDate;

  @override
  void dispose() {
    _addressController.dispose();
    _clientNameController.dispose();
    _clientEmailController.dispose();
    _clientPhoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _schedule() {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedTechnicians.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please assign at least one technician'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a date'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final storage = widget.authService.storage;

    // Create property with basic info (tech fills in details on-site)
    final property = Property(
      id: storage.nextPropertyId,
      address: _addressController.text.trim(),
      meterLocation: '',
      backflowLocation: '',
      backflowSize: '',
      backflowSerial: '',
      numControllers: 0,
      controllerLocation: '',
      zones: [],
      inspectionFrequency: _inspectionFrequency,
      // The first inspection is being scheduled right now — the scheduler
      // starts counting the recurrence from this month
      lastScheduledMonth: DateFormat('yyyy-MM').format(_selectedDate!),
      clientName: _clientNameController.text.trim(),
      clientEmail: _clientEmailController.text.trim(),
      clientPhone: _clientPhoneController.text.trim(),
      notes: _notesController.text.trim(),
    );

    storage.properties[storage.nextPropertyId] = property;
    final propId = storage.nextPropertyId;
    storage.nextPropertyId++;

    // Create inspection assigned to selected tech(s)
    final dateStr = DateFormat('MM/dd/yyyy').format(_selectedDate!);
    final billingMonth = DateFormat('yyyy-MM').format(_selectedDate!);

    final inspection = Inspection(
      id: storage.nextInspectionId,
      propertyId: propId,
      technicians: _selectedTechnicians,
      date: dateStr,
      status: 'assigned',
      repairs: [],
      totalCost: 0.0,
      billingMonth: billingMonth,
    );

    storage.inspections[storage.nextInspectionId] = inspection;
    storage.nextInspectionId++;

    storage.saveData();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Scheduled ${_clientNameController.text.trim().isNotEmpty ? _clientNameController.text.trim() : _addressController.text.trim()} for ${DateFormat('MMM d').format(_selectedDate!)}'),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final storage = widget.authService.storage;
    // Any active employee can be assigned, not just technicians
    final technicians = storage.users.entries
        .where((e) => !e.value.isArchived)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule New Client'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Client Info Section
            _buildSectionHeader('Client Info', Icons.person_outline),
            const SizedBox(height: 12),
            TextFormField(
              controller: _clientNameController,
              decoration: const InputDecoration(
                labelText: 'Client Name',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _clientEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _clientPhoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),

            const SizedBox(height: 24),

            // Property Address
            _buildSectionHeader('Property', Icons.location_on_outlined),
            const SizedBox(height: 12),
            AddressAutocompleteField(
              controller: _addressController,
              labelText: 'Property Address',
              prefixIcon: const Icon(Icons.home_outlined),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Address is required' : null,
            ),
            const SizedBox(height: 16),
            // Recurrence: recurring properties are auto-added to the
            // "To Schedule" list when their next inspection is due
            DropdownButtonFormField<String>(
              value: _inspectionFrequency,
              decoration: const InputDecoration(
                labelText: 'Inspection Schedule',
                prefixIcon: Icon(Icons.event_repeat),
              ),
              items: InspectionFrequency.all
                  .map((f) => DropdownMenuItem(
                        value: f,
                        child: Text(InspectionFrequency.getDisplayName(f)),
                      ))
                  .toList(),
              onChanged: (v) => setState(
                  () => _inspectionFrequency = v ?? _inspectionFrequency),
            ),

            const SizedBox(height: 24),

            // Notes / Instructions
            _buildSectionHeader('Notes for Technician', Icons.note_outlined),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText:
                    'Gate codes, special instructions, problem areas, etc.',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 24),

            // Assign Technician
            _buildSectionHeader('Assign Technician', Icons.engineering),
            const SizedBox(height: 12),
            if (technicians.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('No technicians found. Add users in Settings.',
                      style: TextStyle(color: Colors.grey.shade600)),
                ),
              )
            else
              Card(
                child: Column(
                  children: technicians.map((entry) {
                    final email = entry.key;
                    final user = entry.value;
                    final isSelected =
                        _selectedTechnicians.contains(email);
                    return CheckboxListTile(
                      value: isSelected,
                      onChanged: (checked) {
                        setState(() {
                          if (checked == true) {
                            _selectedTechnicians.add(email);
                          } else {
                            _selectedTechnicians.remove(email);
                          }
                        });
                      },
                      title: Text(user.name),
                      subtitle: Text(email,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600)),
                      secondary: CircleAvatar(
                        backgroundColor: isSelected
                            ? const Color(0xFF0EA5E9)
                            : Colors.grey.shade300,
                        child: Icon(Icons.person,
                            color: isSelected ? Colors.white : Colors.grey),
                      ),
                    );
                  }).toList(),
                ),
              ),

            const SizedBox(height: 24),

            // Schedule Date
            _buildSectionHeader('Schedule Date', Icons.calendar_today),
            const SizedBox(height: 12),
            InkWell(
              onTap: _selectDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.calendar_month),
                  border: OutlineInputBorder(),
                ),
                child: Text(
                  _selectedDate != null
                      ? DateFormat('EEEE, MMM d, yyyy').format(_selectedDate!)
                      : 'Tap to select date',
                  style: TextStyle(
                    color: _selectedDate != null
                        ? Colors.black
                        : Colors.grey.shade500,
                    fontSize: 16,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Schedule Button
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _schedule,
                icon: const Icon(Icons.schedule_send),
                label: const Text('Schedule Visit',
                    style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0EA5E9),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF0EA5E9)),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3)),
      ],
    );
  }
}
