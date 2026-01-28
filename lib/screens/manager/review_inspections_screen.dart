import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../models/inspection.dart';
import '../../models/repair.dart';
import '../../utils/date_formatter.dart';
import 'send_quote_screen.dart';

class ReviewInspectionsScreen extends StatefulWidget {
  final AuthService authService;

  const ReviewInspectionsScreen({Key? key, required this.authService})
      : super(key: key);

  @override
  State<ReviewInspectionsScreen> createState() =>
      _ReviewInspectionsScreenState();
}

class _ReviewInspectionsScreenState extends State<ReviewInspectionsScreen> {
  String _formatDate(String dateStr) {
    return DateFormatter.formatInspectionDate(dateStr);
  }

  void _viewAndEditInspection(
      BuildContext context, int inspectionId, Inspection inspection) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReviewInspectionDetailScreen(
          authService: widget.authService,
          inspectionId: inspectionId,
          inspection: inspection,
        ),
      ),
    ).then((_) => setState(() {})); // Refresh when returning
  }

  @override
  Widget build(BuildContext context) {
    final storage = widget.authService.storage;
    final reviewInspections = storage.inspections.entries
        .where((e) => e.value.status == 'review')
        .toList();

    // Group by date
    final Map<String, List<MapEntry<int, Inspection>>> groupedByDate = {};
    for (var entry in reviewInspections) {
      final date = entry.value.date;
      if (!groupedByDate.containsKey(date)) {
        groupedByDate[date] = [];
      }
      groupedByDate[date]!.add(entry);
    }

    // Sort dates descending (newest first)
    final sortedDates = groupedByDate.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Inspections'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Chip(
                label: Text(
                  '${reviewInspections.length} pending',
                  style: const TextStyle(color: Colors.white),
                ),
                backgroundColor: Colors.orange,
              ),
            ),
          ),
        ],
      ),
      body: reviewInspections.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline,
                      size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No inspections pending review',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: sortedDates.length,
              itemBuilder: (context, index) {
                final date = sortedDates[index];
                final inspections = groupedByDate[date]!;

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ExpansionTile(
                    initiallyExpanded: index == 0,
                    title: Text(
                      _formatDate(date),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('${inspections.length} inspection(s)'),
                    children: inspections.map((entry) {
                      final inspection = entry.value;
                      final property =
                          storage.properties[inspection.propertyId];
                      final tech = storage.users[inspection.technician];

                      return ListTile(
                        leading: const Icon(
                          Icons.rate_review,
                          color: Colors.orange,
                          size: 32,
                        ),
                        title: Text(property?.address ?? 'Unknown Property'),
                        subtitle: Text(
                          '${tech?.name ?? "Unknown"} • ${inspection.repairs.length + inspection.otherRepairs.length} repairs',
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '\$${inspection.totalCost.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const Text(
                              'Tap to review',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                        onTap: () => _viewAndEditInspection(
                            context, entry.key, inspection),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
    );
  }
}

// Detail screen for reviewing and editing an inspection
class ReviewInspectionDetailScreen extends StatefulWidget {
  final AuthService authService;
  final int inspectionId;
  final Inspection inspection;

  const ReviewInspectionDetailScreen({
    Key? key,
    required this.authService,
    required this.inspectionId,
    required this.inspection,
  }) : super(key: key);

  @override
  State<ReviewInspectionDetailScreen> createState() =>
      _ReviewInspectionDetailScreenState();
}

class _ReviewInspectionDetailScreenState
    extends State<ReviewInspectionDetailScreen> {
  late List<Repair> zoneRepairs;
  late List<Repair> otherRepairs;
  late String otherNotes;
  final _laborCostController = TextEditingController(text: '0.00');
  final _discountController = TextEditingController(text: '0.00');

  @override
  void initState() {
    super.initState();
    zoneRepairs = List.from(widget.inspection.repairs);
    otherRepairs = List.from(widget.inspection.otherRepairs);
    otherNotes = widget.inspection.otherNotes;
    // Initialize labor and discount from inspection if available
    _laborCostController.text = widget.inspection.laborCost.toStringAsFixed(2);
    _discountController.text = widget.inspection.discount.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _laborCostController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  double get _laborCost {
    return double.tryParse(_laborCostController.text) ?? 0.0;
  }

  double get _discount {
    return double.tryParse(_discountController.text) ?? 0.0;
  }

  void _saveChanges() {
    final storage = widget.authService.storage;
    final totalCost = _calculateTotalCost();

    storage.inspections[widget.inspectionId] = widget.inspection.copyWith(
      repairs: zoneRepairs,
      otherRepairs: otherRepairs,
      otherNotes: otherNotes,
      totalCost: totalCost,
      laborCost: _laborCost,
      discount: _discount,
    );
    storage.saveData();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Changes saved'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  double _calculateMaterialsCost() {
    double total = 0.0;
    for (var repair in zoneRepairs) {
      total += repair.totalCost;
    }
    for (var repair in otherRepairs) {
      total += repair.totalCost;
    }
    return total;
  }

  double _calculateTotalCost() {
    return _calculateMaterialsCost() + _laborCost - _discount;
  }

  void _deleteZoneRepair(int index) {
    setState(() {
      zoneRepairs.removeAt(index);
    });
    _saveChanges();
  }

  void _deleteOtherRepair(int index) {
    setState(() {
      otherRepairs.removeAt(index);
    });
    _saveChanges();
  }

  void _editRepair(Repair repair, bool isZoneRepair) {
    final quantityController =
        TextEditingController(text: repair.quantity.toString());
    final priceController =
        TextEditingController(text: repair.price.toStringAsFixed(2));
    final notesController = TextEditingController(text: repair.notes);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${repair.itemName.replaceAll('_', ' ')}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                  prefixIcon: Icon(Icons.numbers),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: priceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Price (per item)',
                  prefixIcon: Icon(Icons.attach_money),
                  prefixText: '\$',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 3,
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
              final newQuantity = int.tryParse(quantityController.text) ?? 1;
              final newPrice = double.tryParse(priceController.text) ?? 0.0;

              final updatedRepair = Repair(
                itemName: repair.itemName,
                quantity: newQuantity,
                price: newPrice,
                notes: notesController.text,
                zoneNumber: repair.zoneNumber,
              );

              setState(() {
                if (isZoneRepair) {
                  final index = zoneRepairs.indexOf(repair);
                  if (index != -1) zoneRepairs[index] = updatedRepair;
                } else {
                  final index = otherRepairs.indexOf(repair);
                  if (index != -1) otherRepairs[index] = updatedRepair;
                }
              });

              _saveChanges();
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _addNewRepair(bool isZoneRepair) {
    final storage = widget.authService.storage;
    final property = storage.properties[widget.inspection.propertyId];

    // Get available repair items based on type
    final availableItems = storage.repairItems.values.where((item) {
      if (isZoneRepair) {
        return ['heads', 'stems', 'nozzles', 'drip', 'pipe_lateral', 'pipe_mainline', 'valves'].contains(item.category);
      } else {
        return ['sensor', 'winterize', 'controller', 'ball_valve', 'wire', 'backflow', 'service'].contains(item.category);
      }
    }).toList();

    String? selectedItem;
    final quantityController = TextEditingController(text: '1');
    final priceController = TextEditingController();
    final notesController = TextEditingController();
    int? selectedZone;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text('Add ${isZoneRepair ? "Zone" : "Other"} Repair'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Item Dropdown
                  DropdownButtonFormField<String>(
                    value: selectedItem,
                    decoration: const InputDecoration(
                      labelText: 'Repair Item',
                      prefixIcon: Icon(Icons.build),
                    ),
                    items: availableItems.map((item) {
                      return DropdownMenuItem(
                        value: item.name,
                        child: Text(item.name.replaceAll('_', ' ').toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedItem = value;
                        final item = storage.repairItems[value];
                        if (item != null) {
                          priceController.text = item.price.toStringAsFixed(2);
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  // Zone selector (only for zone repairs)
                  if (isZoneRepair && property != null) ...[
                    DropdownButtonFormField<int>(
                      value: selectedZone,
                      decoration: const InputDecoration(
                        labelText: 'Zone',
                        prefixIcon: Icon(Icons.location_on),
                      ),
                      items: property.zones.map((zone) {
                        return DropdownMenuItem(
                          value: zone.zoneNumber,
                          child: Text('Zone ${zone.zoneNumber}: ${zone.description}'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedZone = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                  // Quantity
                  TextField(
                    controller: quantityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Quantity',
                      prefixIcon: Icon(Icons.numbers),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Price
                  TextField(
                    controller: priceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Price (per item)',
                      prefixIcon: Icon(Icons.attach_money),
                      prefixText: '\$',
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Notes
                  TextField(
                    controller: notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      prefixIcon: Icon(Icons.note),
                    ),
                    maxLines: 3,
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
                  if (selectedItem == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please select a repair item')),
                    );
                    return;
                  }
                  if (isZoneRepair && selectedZone == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please select a zone')),
                    );
                    return;
                  }

                  final newQuantity = int.tryParse(quantityController.text) ?? 1;
                  final newPrice = double.tryParse(priceController.text) ?? 0.0;

                  final newRepair = Repair(
                    itemName: selectedItem!,
                    quantity: newQuantity,
                    price: newPrice,
                    notes: notesController.text,
                    zoneNumber: isZoneRepair ? (selectedZone ?? 0) : 0,
                  );

                  setState(() {
                    if (isZoneRepair) {
                      zoneRepairs.add(newRepair);
                    } else {
                      otherRepairs.add(newRepair);
                    }
                  });

                  _saveChanges();
                  Navigator.pop(context);
                },
                child: const Text('Add'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _approveAndSendQuote() {
    final storage = widget.authService.storage;
    final property = storage.properties[widget.inspection.propertyId];

    if (property == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Property not found'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Save current changes first
    _saveChanges();

    // Get the latest inspection with saved changes
    final updatedInspection = storage.inspections[widget.inspectionId]!;

    // Navigate to SendQuoteScreen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SendQuoteScreen(
          authService: widget.authService,
          inspection: updatedInspection,
          property: property,
        ),
      ),
    ).then((result) {
      if (result == true) {
        // Quote was sent successfully, go back to review list
        Navigator.pop(context);
      }
    });
  }

  void _moveBackToInProgress() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Move Back to In Progress'),
        content: const Text(
          'This will move the inspection back to in-progress status so the technician can make changes.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final storage = widget.authService.storage;
              storage.inspections[widget.inspectionId] =
                  widget.inspection.copyWith(
                status: 'in_progress',
                repairs: zoneRepairs,
                otherRepairs: otherRepairs,
                otherNotes: otherNotes,
              );
              storage.saveData();

              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to review list

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Moved back to in-progress'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            child: const Text('Move Back'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final storage = widget.authService.storage;
    final property = storage.properties[widget.inspection.propertyId];
    final tech = storage.users[widget.inspection.technician];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Inspection'),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            tooltip: 'Move to In-Progress',
            onPressed: _moveBackToInProgress,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Property Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      property?.address ?? 'Unknown Property',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Technician: ${tech?.name ?? "Unknown"}'),
                    Text('Date: ${widget.inspection.date}'),
                    Text('Status: PENDING REVIEW',
                        style: const TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        )),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Zone Repairs
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Zone Repairs',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: () => _addNewRepair(true),
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Add Repair'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (zoneRepairs.isNotEmpty) ...[
              ...zoneRepairs.asMap().entries.map((entry) {
                final index = entry.key;
                final repair = entry.value;
                final item = storage.repairItems[repair.itemName];

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(
                      repair.itemName.replaceAll('_', ' ').toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Zone: ${repair.zoneNumber}'),
                        Text('Quantity: ${repair.quantity}'),
                        if (item != null)
                          Text(
                              'Unit Price: \$${item.price.toStringAsFixed(2)}'),
                        if (repair.notes.isNotEmpty) Text('Notes: ${repair.notes}'),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '\$${repair.totalCost.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        PopupMenuButton<String>(
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, size: 18),
                                  SizedBox(width: 8),
                                  Text('Edit'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, size: 18, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Delete', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                          onSelected: (value) {
                            if (value == 'edit') {
                              _editRepair(repair, true);
                            } else if (value == 'delete') {
                              _deleteZoneRepair(index);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
              const SizedBox(height: 16),
            ],

            // Other Repairs
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Other Repairs',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: () => _addNewRepair(false),
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Add Repair'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (otherRepairs.isNotEmpty) ...[
              ...otherRepairs.asMap().entries.map((entry) {
                final index = entry.key;
                final repair = entry.value;
                final item = storage.repairItems[repair.itemName];

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: Colors.orange.shade50,
                  child: ListTile(
                    title: Text(
                      repair.itemName.replaceAll('_', ' ').toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Quantity: ${repair.quantity}'),
                        if (item != null)
                          Text(
                              'Unit Price: \$${item.price.toStringAsFixed(2)}'),
                        if (repair.notes.isNotEmpty) Text('Notes: ${repair.notes}'),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '\$${repair.totalCost.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        PopupMenuButton<String>(
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, size: 18),
                                  SizedBox(width: 8),
                                  Text('Edit'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, size: 18, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Delete', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                          onSelected: (value) {
                            if (value == 'edit') {
                              _editRepair(repair, false);
                            } else if (value == 'delete') {
                              _deleteOtherRepair(index);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
              const SizedBox(height: 16),
            ],

            // Other Notes
            if (otherNotes.isNotEmpty) ...[
              const Text(
                'Other Notes',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(otherNotes),
              ),
              const SizedBox(height: 16),
            ],

            // Photos Section
            if (widget.inspection.photos.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Repair Photos (${widget.inspection.photos.length})',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.inspection.photos.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => Dialog(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AppBar(
                                  title: Text('Photo ${index + 1}'),
                                  leading: IconButton(
                                    icon: const Icon(Icons.close),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                ),
                                InteractiveViewer(
                                  child: Image.memory(
                                    base64Decode(widget.inspection.photos[index]),
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      child: Container(
                        width: 120,
                        margin: const EdgeInsets.only(right: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            base64Decode(widget.inspection.photos[index]),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Labor & Discount Section
            const Text(
              'Labor & Discount',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _laborCostController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Labor Cost',
                      prefixIcon: Icon(Icons.engineering),
                      prefixText: '\$',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _discountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Discount',
                      prefixIcon: Icon(Icons.discount),
                      prefixText: '-\$',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Cost Summary
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Materials:'),
                        Text('\$${_calculateMaterialsCost().toStringAsFixed(2)}'),
                      ],
                    ),
                    if (_laborCost > 0) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Labor:'),
                          Text('\$${_laborCost.toStringAsFixed(2)}'),
                        ],
                      ),
                    ],
                    if (_discount > 0) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Discount:', style: TextStyle(color: Colors.green)),
                          Text('-\$${_discount.toStringAsFixed(2)}',
                              style: const TextStyle(color: Colors.green)),
                        ],
                      ),
                    ],
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '\$${_calculateTotalCost().toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Action Buttons
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _approveAndSendQuote,
                icon: const Icon(Icons.send),
                label: const Text('Approve & Send Quote to Client'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
