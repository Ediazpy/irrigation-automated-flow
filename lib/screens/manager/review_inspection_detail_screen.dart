import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../models/inspection.dart';
import '../../models/repair.dart';
import '../../widgets/photo_image.dart';
import 'send_quote_screen.dart';

/// Detail screen for managers to review a submitted inspection.
/// Allows editing repairs, adjusting pricing, and sending quotes.
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
    _laborCostController.text =
        widget.inspection.laborCost.toStringAsFixed(2);
    _discountController.text =
        widget.inspection.discount.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _laborCostController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  double get _laborCost =>
      double.tryParse(_laborCostController.text) ?? 0.0;

  double get _discount =>
      double.tryParse(_discountController.text) ?? 0.0;

  void _saveChanges() {
    final storage = widget.authService.storage;
    final double totalCost = _calculateTotalCost();

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
    for (Repair repair in zoneRepairs) {
      total += repair.totalCost;
    }
    for (Repair repair in otherRepairs) {
      total += repair.totalCost;
    }
    return total;
  }

  double _calculateTotalCost() {
    return _calculateMaterialsCost() + _laborCost - _discount;
  }

  Widget _buildRepairCard(Repair repair, int index, dynamic storage,
      {required bool isZone}) {
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
            if (isZone) Text('Zone: ${repair.zoneNumber}'),
            Text('Quantity: ${repair.quantity}'),
            if (item != null)
              Text('Unit Price: \$${item.price.toStringAsFixed(2)}'),
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
              onSelected: (String value) {
                if (value == 'edit') {
                  _editRepair(repair, isZone);
                } else if (value == 'delete') {
                  if (isZone) {
                    _deleteZoneRepair(index);
                  } else {
                    _deleteOtherRepair(index);
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
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
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
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
              final int newQuantity =
                  int.tryParse(quantityController.text) ?? 1;
              final double newPrice =
                  double.tryParse(priceController.text) ?? 0.0;

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

    final availableItems = storage.repairItems.values.where((item) {
      if (isZoneRepair) {
        return [
          'heads', 'stems', 'nozzles', 'drip', 'pipe_lateral',
          'pipe_mainline', 'valves'
        ].contains(item.category);
      } else {
        return [
          'sensor', 'winterize', 'controller', 'ball_valve', 'wire',
          'backflow', 'service'
        ].contains(item.category);
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
                  DropdownButtonFormField<String>(
                    value: selectedItem,
                    decoration: const InputDecoration(
                      labelText: 'Repair Item',
                      prefixIcon: Icon(Icons.build),
                    ),
                    items: availableItems.map((item) {
                      return DropdownMenuItem(
                        value: item.name,
                        child:
                            Text(item.name.replaceAll('_', ' ').toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (String? value) {
                      setDialogState(() {
                        selectedItem = value;
                        final item = storage.repairItems[value];
                        if (item != null) {
                          priceController.text =
                              item.price.toStringAsFixed(2);
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  if (isZoneRepair && property != null) ...[
                    DropdownButtonFormField<int>(
                      value: selectedZone,
                      decoration: const InputDecoration(
                        labelText: 'Zone',
                        prefixIcon: Icon(Icons.location_on),
                      ),
                      items: property.allZones.map((zone) {
                        return DropdownMenuItem(
                          value: zone.zoneNumber,
                          child: Text(zone.getDisplayName(
                              showController:
                                  property.hasMultipleControllers)),
                        );
                      }).toList(),
                      onChanged: (int? value) {
                        setDialogState(() {
                          selectedZone = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
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
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
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
                  if (selectedItem == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Please select a repair item')),
                    );
                    return;
                  }
                  if (isZoneRepair && selectedZone == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please select a zone')),
                    );
                    return;
                  }

                  final int newQuantity =
                      int.tryParse(quantityController.text) ?? 1;
                  final double newPrice =
                      double.tryParse(priceController.text) ?? 0.0;

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

    _saveChanges();
    final updatedInspection = storage.inspections[widget.inspectionId]!;

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
                    const Text('Status: PENDING REVIEW',
                        style: TextStyle(
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
              // Group repairs by controller when property has multiple
              if (property != null &&
                  property.controllers.length > 1) ...[
                ...property.controllers.map((controller) {
                  final controllerZoneNumbers =
                      controller.zones.map((z) => z.zoneNumber).toSet();
                  final controllerRepairs = zoneRepairs
                      .where((Repair r) =>
                          controllerZoneNumbers.contains(r.zoneNumber))
                      .toList();
                  if (controllerRepairs.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 4),
                        child: Row(
                          children: [
                            Icon(Icons.settings_remote,
                                size: 18, color: Colors.teal.shade700),
                            const SizedBox(width: 6),
                            Text(
                              'Controller ${controller.controllerNumber}',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal.shade700,
                              ),
                            ),
                            if (controller.location.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Text(
                                '(${controller.location})',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600),
                              ),
                            ],
                          ],
                        ),
                      ),
                      ...controllerRepairs.map((Repair repair) {
                        final index = zoneRepairs.indexOf(repair);
                        return _buildRepairCard(repair, index, storage,
                            isZone: true);
                      }),
                    ],
                  );
                }),
              ] else ...[
                ...zoneRepairs.asMap().entries.map((entry) {
                  return _buildRepairCard(entry.value, entry.key, storage,
                      isZone: true);
                }).toList(),
              ],
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
                return _buildRepairCard(entry.value, entry.key, storage,
                    isZone: false);
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
            if (widget.inspection.totalPhotoCount > 0) ...[
              Text(
                'Repair Photos (${widget.inspection.totalPhotoCount})',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...widget.inspection.zonePhotos.entries.map((entry) {
                final int zoneNumber = entry.key;
                final List<String> photos = entry.value;
                if (photos.isEmpty) return const SizedBox.shrink();

                final String zoneName =
                    zoneNumber == 0 ? 'General/Other' : 'Zone $zoneNumber';

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        '$zoneName (${photos.length})',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: photos.length,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () => _viewFullPhoto(
                                zoneName, photos[index], index),
                            child: Container(
                              width: 100,
                              margin: const EdgeInsets.only(right: 8),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: PhotoImage(
                                  photoData: photos[index],
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                );
              }).toList(),
              const SizedBox(height: 16),
            ],

            // Labor & Discount
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
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
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
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
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
                        Text(
                            '\$${_calculateMaterialsCost().toStringAsFixed(2)}'),
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
                          const Text('Discount:',
                              style: TextStyle(color: Colors.green)),
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
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
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

            // Approve & Send
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

  void _viewFullPhoto(String zoneName, String photoData, int index) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text('$zoneName - Photo ${index + 1}'),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            InteractiveViewer(
              child: PhotoImage(
                photoData: photoData,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
