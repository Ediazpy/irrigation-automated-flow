import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../models/repair_item.dart';

class RepairItemsScreen extends StatefulWidget {
  final AuthService authService;

  const RepairItemsScreen({Key? key, required this.authService}) : super(key: key);

  @override
  State<RepairItemsScreen> createState() => _RepairItemsScreenState();
}

class _RepairItemsScreenState extends State<RepairItemsScreen> {
  @override
  Widget build(BuildContext context) {
    final storage = widget.authService.storage;
    final items = storage.repairItems.values.toList()
      ..sort((a, b) => a.category.compareTo(b.category));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Repair Items'),
      ),
      body: ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return ListTile(
            leading: CircleAvatar(
              child: Text(item.category[0].toUpperCase()),
            ),
            title: Text(item.name.replaceAll('_', ' ')),
            subtitle: Text(item.category),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '\$${item.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _editPrice(item),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewItem,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _editPrice(RepairItem item) {
    final controller = TextEditingController(text: item.price.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Price: ${item.name}'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Price',
            prefixText: '\$',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newPrice = double.tryParse(controller.text) ?? item.price;
              setState(() {
                widget.authService.storage.repairItems[item.name] =
                    item.copyWith(price: newPrice);
              });
              widget.authService.storage.saveData();
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _addNewItem() {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final categoryController = TextEditingController();
    bool requiresNotes = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add New Repair Item'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Item Name',
                    hintText: 'e.g., new_sprinkler',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Price',
                    prefixText: '\$',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: categoryController,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    hintText: 'e.g., heads, valves',
                  ),
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  title: const Text('Requires Notes'),
                  value: requiresNotes,
                  onChanged: (value) {
                    setDialogState(() {
                      requiresNotes = value ?? false;
                    });
                  },
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
                final name = nameController.text.trim();
                final price = double.tryParse(priceController.text) ?? 0.0;
                final category = categoryController.text.trim();

                if (name.isEmpty || category.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Name and category are required')),
                  );
                  return;
                }

                setState(() {
                  widget.authService.storage.repairItems[name] = RepairItem(
                    name: name,
                    price: price,
                    category: category,
                    requiresNotes: requiresNotes,
                  );
                });
                widget.authService.storage.saveData();
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}
