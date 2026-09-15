import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/quote_service.dart';
import '../../models/quote.dart';
import '../../models/quote_line_item.dart';
import '../../models/inspection.dart';
import '../../models/property.dart';
import '../../models/company_settings.dart';
import '../../constants/status_constants.dart';

class SendQuoteScreen extends StatefulWidget {
  final AuthService authService;
  final Inspection? inspection;
  final Property property;
  final Quote? existingQuote;

  const SendQuoteScreen({
    Key? key,
    required this.authService,
    this.inspection,
    required this.property,
    this.existingQuote,
  }) : super(key: key);

  @override
  State<SendQuoteScreen> createState() => _SendQuoteScreenState();
}

class _SendQuoteScreenState extends State<SendQuoteScreen> {
  late Quote _quote;
  late List<QuoteLineItem> _lineItems;
  bool _isLoading = false;
  bool get _isEditing => widget.existingQuote != null;

  // Editable cost fields
  late double _laborCost;
  late double _discount;
  late double _tax;

  // Editable contact fields — default to what's on file
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.property.clientEmail);
    _phoneController = TextEditingController(text: widget.property.clientPhone);
    if (_isEditing) {
      _loadExistingQuote();
    } else {
      _initializeQuote();
    }
  }

  void _loadExistingQuote() {
    final existing = widget.existingQuote!;
    _quote = existing;
    _lineItems = List.from(existing.lineItems);
    _laborCost = existing.laborCost;
    _discount = existing.discount;
    _tax = existing.tax;
  }

  void _initializeQuote() {
    final storage = widget.authService.storage;

    // Get or create company settings
    var settings = storage.companySettings;
    if (settings == null) {
      settings = CompanySettings(companyName: 'Your Company Name');
      storage.companySettings = settings;
    }

    // Create quote from inspection
    _quote = QuoteService.createFromInspection(
      quoteId: storage.nextQuoteId,
      inspection: widget.inspection!,
      property: widget.property,
      settings: settings,
    );

    _lineItems = List.from(_quote.lineItems);
    _laborCost = widget.inspection!.laborCost;
    _discount = widget.inspection!.discount;
    _tax = widget.inspection!.tax;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  double get _subtotal {
    return _lineItems.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  double get _total {
    return _subtotal + _laborCost - _discount + _tax;
  }

  List<Widget> _buildLineItemWidgets() {
    final widgets = <Widget>[];
    final hasMultipleControllers = widget.property.controllers.length > 1;

    if (hasMultipleControllers) {
      // Group line items by controller
      for (var controller in widget.property.controllers) {
        final controllerZoneNumbers = controller.zones.map((z) => z.zoneNumber).toSet();
        final controllerItems = _lineItems
            .where((item) => item.zoneNumber != null && controllerZoneNumbers.contains(item.zoneNumber))
            .toList();

        if (controllerItems.isNotEmpty) {
          widgets.add(
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4, left: 4),
              child: Row(
                children: [
                  Icon(Icons.settings_remote, size: 18, color: const Color(0xFF0EA5E9)),
                  const SizedBox(width: 6),
                  Text(
                    'Controller ${controller.controllerNumber}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0EA5E9),
                    ),
                  ),
                  if (controller.location.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Text(
                      '(${controller.location})',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ],
              ),
            ),
          );
          for (var item in controllerItems) {
            widgets.add(_buildLineItemCard(_lineItems.indexOf(item), item));
          }
        }
      }

      // Items without zone (labor, general)
      final noZoneItems = _lineItems.where((item) => item.zoneNumber == null).toList();
      for (var item in noZoneItems) {
        widgets.add(_buildLineItemCard(_lineItems.indexOf(item), item));
      }
    } else {
      // Single controller or legacy - flat list
      for (var entry in _lineItems.asMap().entries) {
        widgets.add(_buildLineItemCard(entry.key, entry.value));
      }
    }

    return widgets;
  }

  Widget _buildLineItemCard(int index, item) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: item.category == 'labor'
              ? Colors.orange.shade100
              : Colors.blue.shade100,
          child: Icon(
            item.category == 'labor' ? Icons.engineering : Icons.build,
            color: item.category == 'labor' ? Colors.orange : Colors.blue,
            size: 20,
          ),
        ),
        title: Text(
          item.displayDescription,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          '${item.quantity} × \$${item.unitPrice.toStringAsFixed(2)}' +
              (item.zoneNumber != null ? ' (Zone ${item.zoneNumber})' : ''),
        ),
        trailing: Text(
          '\$${item.totalPrice.toStringAsFixed(2)}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        onTap: () => _editLineItem(index),
      ),
    );
  }

  void _editLineItem(int index) {
    final item = _lineItems[index];
    final qtyController = TextEditingController(text: item.quantity.toString());
    final priceController = TextEditingController(text: item.unitPrice.toStringAsFixed(2));
    final notesController = TextEditingController(text: item.notes ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit: ${item.displayDescription}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: qtyController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                  prefixIcon: Icon(Icons.numbers),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: priceController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Unit Price',
                  prefixIcon: Icon(Icons.attach_money),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  prefixIcon: Icon(Icons.note),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _lineItems.removeAt(index);
              });
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
          ElevatedButton(
            onPressed: () {
              final newQty = int.tryParse(qtyController.text) ?? item.quantity;
              final newPrice = double.tryParse(priceController.text) ?? item.unitPrice;

              setState(() {
                _lineItems[index] = item.copyWith(
                  quantity: newQty,
                  unitPrice: newPrice,
                  notes: notesController.text.isEmpty ? null : notesController.text,
                );
              });
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _editableCostRow({
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
    bool isDiscount = false,
    bool isAddition = false,
  }) {
    return InkWell(
      onTap: () {
        final controller = TextEditingController(text: value > 0 ? value.toStringAsFixed(2) : '');
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('Edit $label'),
            content: TextFormField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: InputDecoration(
                labelText: label.replaceAll(':', ''),
                prefixIcon: const Icon(Icons.attach_money),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  final v = double.tryParse(controller.text) ?? 0.0;
                  onChanged(v < 0 ? 0 : v);
                  Navigator.pop(ctx);
                },
                child: const Text('Save'),
              ),
            ],
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(label, style: isDiscount ? const TextStyle(color: Colors.green) : null),
                const SizedBox(width: 4),
                Icon(Icons.edit, size: 14, color: Colors.grey.shade400),
              ],
            ),
            Text(
              '${isDiscount ? '-' : isAddition ? '+' : ''}\$${value.toStringAsFixed(2)}',
              style: isDiscount ? const TextStyle(color: Colors.green) : null,
            ),
          ],
        ),
      ),
    );
  }

  void _addNewLineItem() {
    final descController = TextEditingController();
    final qtyController = TextEditingController(text: '1');
    final priceController = TextEditingController();
    String category = 'materials';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Line Item'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'e.g., Sprinkler Head, PVC Pipe',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: qtyController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Qty'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: priceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Unit Price',
                          prefixIcon: Icon(Icons.attach_money),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: const [
                    DropdownMenuItem(value: 'materials', child: Text('Materials')),
                    DropdownMenuItem(value: 'labor', child: Text('Labor')),
                  ],
                  onChanged: (v) => setDialogState(() => category = v ?? 'materials'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final desc = descController.text.trim();
                final qty = int.tryParse(qtyController.text) ?? 1;
                final price = double.tryParse(priceController.text) ?? 0.0;
                if (desc.isNotEmpty && price > 0) {
                  setState(() {
                    _lineItems.add(QuoteLineItem(
                      description: desc,
                      quantity: qty,
                      unitPrice: price,
                      category: category,
                    ));
                  });
                }
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendQuote() async {
    // Validate company settings
    final settings = widget.authService.storage.companySettings;
    if (settings == null || settings.companyName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please configure company settings first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Validate client contact using the editable fields
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    if (email.isEmpty && phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a client email or phone number'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final storage = widget.authService.storage;

    // Only check for duplicates when creating new quote
    if (!_isEditing) {
      final existingQuote = storage.quotes.values.where((q) =>
          q.inspectionId == widget.inspection!.id &&
          (q.status == QuoteStatus.sent || q.status == QuoteStatus.viewed || q.status == QuoteStatus.approved));
      if (existingQuote.isNotEmpty) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Quote Already Exists'),
            content: Text(
              'A quote (#${existingQuote.first.id}) already exists for this inspection with status "${QuoteStatus.getDisplayName(existingQuote.first.status)}". Create another?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Create Anyway'),
              ),
            ],
          ),
        );
        if (confirmed != true) return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final finalQuote = _quote.copyWith(
        lineItems: _lineItems,
        laborCost: _laborCost,
        discount: _discount,
        tax: _tax,
        status: QuoteStatus.sent,
        sentAt: DateTime.now().toIso8601String(),
      );

      storage.quotes[finalQuote.id] = finalQuote;

      if (!_isEditing) {
        storage.nextQuoteId++;

        // Update inspection status only for new quotes
        final updatedInspection = widget.inspection!.copyWith(
          status: 'quote_sent',
        );
        storage.inspections[widget.inspection!.id] = updatedInspection;
      }

      storage.saveData();

      // Mirror the quote into public_quotes/{token} so the customer can view
      // and approve it without an account (the business collections are not
      // publicly readable)
      try {
        await FirestoreService().savePublicQuote(
          finalQuote,
          address: widget.property.address,
        );
      } catch (_) {}

      // Generate the client approval URL
      final quoteUrl = QuoteService.generateQuoteUrl(finalQuote.accessToken);

      // Generate message with full quote details + approval link
      final message = QuoteService.formatQuoteMessage(
        quote: finalQuote,
        property: widget.property,
        quoteUrl: quoteUrl,
      );

      // Show send options
      if (mounted) {
        _showSendOptions(finalQuote, message);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error ${_isEditing ? 'updating' : 'creating'} quote: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSendOptions(Quote quote, String message) {
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _isEditing ? 'Quote Updated & Resent!' : 'Quote Created Successfully!',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Quote #${quote.id} - \$${quote.totalCost.toStringAsFixed(2)}',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),
              if (email.isNotEmpty)
                ElevatedButton.icon(
                  onPressed: () async {
                    await _sendViaEmail(message, email);
                    if (!context.mounted) return;
                    Navigator.pop(context); // close the sheet
                    Navigator.pop(context, true); // back to the list
                  },
                  icon: const Icon(Icons.email),
                  label: Text('Email Quote to $email'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              if (email.isNotEmpty) const SizedBox(height: 12),
              if (phone.isNotEmpty)
                ElevatedButton.icon(
                  onPressed: () async {
                    await _sendViaSms(
                      QuoteService.formatSmsMessage(
                        quote: quote,
                        property: widget.property,
                        quoteUrl: QuoteService.generateQuoteUrl(quote.accessToken),
                      ),
                      phone,
                    );
                    if (!context.mounted) return;
                    Navigator.pop(context); // close the sheet
                    Navigator.pop(context, true); // back to the list
                  },
                  icon: const Icon(Icons.sms),
                  label: Text('Text Quote to $phone'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              if (phone.isNotEmpty) const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context, true);
                },
                icon: const Icon(Icons.check),
                label: const Text('Done'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendViaEmail(String message, String email) async {
    final subject = Uri.encodeComponent('Quote #${_quote.id} from ${_quote.companyName}');
    final body = Uri.encodeComponent(message);
    final uri = Uri.parse('mailto:$email?subject=$subject&body=$body');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _sendViaSms(String message, String phoneNumber) async {
    final phone = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    final body = Uri.encodeComponent(message);
    final uri = Uri.parse('sms:$phone?body=$body');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Quote #${_quote.id}' : 'Create Quote'),
        actions: [
          TextButton.icon(
            onPressed: _isLoading ? null : _sendQuote,
            icon: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
            label: Text(_isEditing ? 'Update & Send' : 'Send Quote'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Property Info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.location_on, color: Theme.of(context).primaryColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.property.address,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (widget.property.clientName.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.person, size: 20, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(widget.property.clientName,
                            style: const TextStyle(fontSize: 15)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Send To — editable contact fields
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Send To',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade500,
                          letterSpacing: 0.5)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Client Email',
                      prefixIcon: Icon(Icons.email_outlined),
                      hintText: 'Enter email address',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Client Phone',
                      prefixIcon: Icon(Icons.phone_outlined),
                      hintText: 'Enter phone number',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Line Items Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Line Items',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                onPressed: _addNewLineItem,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Item'),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Line Items List - grouped by controller when applicable
          ..._buildLineItemWidgets(),

          if (_lineItems.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.receipt_long, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 8),
                    Text(
                      'No items in quote',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 24),

          // Totals Section
          Card(
            color: Colors.grey.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Subtotal:'),
                      Text('\$${_subtotal.toStringAsFixed(2)}'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _editableCostRow(
                    label: 'Labor:',
                    value: _laborCost,
                    onChanged: (v) => setState(() => _laborCost = v),
                  ),
                  const SizedBox(height: 8),
                  _editableCostRow(
                    label: 'Discount:',
                    value: _discount,
                    onChanged: (v) => setState(() => _discount = v),
                    isDiscount: true,
                  ),
                  const SizedBox(height: 8),
                  _editableCostRow(
                    label: 'Tax:',
                    value: _tax,
                    onChanged: (v) => setState(() => _tax = v),
                    isAddition: true,
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'TOTAL:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '\$${_total.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
