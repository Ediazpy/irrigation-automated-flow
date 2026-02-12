import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/auth_service.dart';
import '../../services/quote_service.dart';
import '../../models/quote.dart';
import '../../models/quote_line_item.dart';
import '../../models/inspection.dart';
import '../../models/property.dart';
import '../../models/company_settings.dart';
import '../../constants/status_constants.dart';

class SendQuoteScreen extends StatefulWidget {
  final AuthService authService;
  final Inspection inspection;
  final Property property;

  const SendQuoteScreen({
    Key? key,
    required this.authService,
    required this.inspection,
    required this.property,
  }) : super(key: key);

  @override
  State<SendQuoteScreen> createState() => _SendQuoteScreenState();
}

class _SendQuoteScreenState extends State<SendQuoteScreen> {
  late Quote _quote;
  late List<QuoteLineItem> _lineItems;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeQuote();
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
      inspection: widget.inspection,
      property: widget.property,
      settings: settings,
    );

    _lineItems = List.from(_quote.lineItems);
  }

  @override
  void dispose() {
    super.dispose();
  }

  double get _subtotal {
    return _lineItems.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  // Use labor/discount from inspection (set in review screen)
  double get _laborCost => widget.inspection.laborCost;
  double get _discount => widget.inspection.discount;

  double get _total {
    return _subtotal + _laborCost - _discount;
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
                  Icon(Icons.settings_remote, size: 18, color: Colors.teal.shade700),
                  const SizedBox(width: 6),
                  Text(
                    'Controller ${controller.controllerNumber}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal.shade700,
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

  void _addLaborCharge() {
    final descController = TextEditingController();
    final priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Labor/Service Charge'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'e.g., Service Call, Diagnostic',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: priceController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixIcon: Icon(Icons.attach_money),
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
              final desc = descController.text.trim();
              final price = double.tryParse(priceController.text) ?? 0.0;

              if (desc.isNotEmpty && price > 0) {
                setState(() {
                  _lineItems.add(QuoteLineItem(
                    description: desc,
                    quantity: 1,
                    unitPrice: price,
                    category: 'labor',
                  ));
                });
              }
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
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

    // Validate client contact
    if (widget.property.clientEmail.isEmpty && widget.property.clientPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No client email or phone number on file'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Check for existing active quote on this inspection
    final storage = widget.authService.storage;
    final existingQuote = storage.quotes.values.where((q) =>
        q.inspectionId == widget.inspection.id &&
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

    setState(() => _isLoading = true);

    try {
      final storage = widget.authService.storage;

      // Create and save the quote
      final finalQuote = _quote.copyWith(
        lineItems: _lineItems,
        laborCost: _laborCost,
        discount: _discount,
        status: QuoteStatus.sent,
        sentAt: DateTime.now().toIso8601String(),
      );

      storage.quotes[finalQuote.id] = finalQuote;
      storage.nextQuoteId++;

      // Update inspection status
      final updatedInspection = widget.inspection.copyWith(
        status: 'quote_sent',
      );
      storage.inspections[widget.inspection.id] = updatedInspection;

      storage.saveData();

      // Generate message with full quote details
      final message = QuoteService.formatQuoteMessage(
        quote: finalQuote,
        property: widget.property,
        quoteUrl: '', // Not used - full details in message
      );

      // Show send options
      if (mounted) {
        _showSendOptions(finalQuote, message);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating quote: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSendOptions(Quote quote, String message) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Quote Created Successfully!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Quote #${quote.id} - \$${quote.totalCost.toStringAsFixed(2)}',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 4),
              Text(
                'Full quote details will be included in the message',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
              const SizedBox(height: 24),
              if (widget.property.clientEmail.isNotEmpty)
                ElevatedButton.icon(
                  onPressed: () => _sendViaEmail(message),
                  icon: const Icon(Icons.email),
                  label: Text('Email Quote to ${widget.property.clientEmail}'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              const SizedBox(height: 12),
              if (widget.property.clientPhone.isNotEmpty)
                ElevatedButton.icon(
                  onPressed: () => _sendViaSms(
                    QuoteService.formatSmsMessage(
                      quote: quote,
                      property: widget.property,
                      quoteUrl: '', // Not used anymore
                    ),
                  ),
                  icon: const Icon(Icons.sms),
                  label: Text('Text Quote to ${widget.property.clientPhone}'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              const SizedBox(height: 12),
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

  Future<void> _sendViaEmail(String message) async {
    final email = widget.property.clientEmail;
    final subject = Uri.encodeComponent('Quote #${_quote.id} from ${_quote.companyName}');
    final body = Uri.encodeComponent(message);
    final uri = Uri.parse('mailto:$email?subject=$subject&body=$body');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _sendViaSms(String message) async {
    final phone = widget.property.clientPhone.replaceAll(RegExp(r'[^\d]'), '');
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
        title: const Text('Create Quote'),
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
            label: const Text('Send Quote'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Property & Client Info Card
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
                        Text(widget.property.clientName),
                      ],
                    ),
                  ],
                  if (widget.property.clientEmail.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.email, size: 20, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(widget.property.clientEmail),
                      ],
                    ),
                  ],
                  if (widget.property.clientPhone.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.phone, size: 20, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(widget.property.clientPhone),
                      ],
                    ),
                  ],
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
                onPressed: _addLaborCharge,
                icon: const Icon(Icons.add),
                label: const Text('Add Labor'),
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
                      const Text('Materials:'),
                      Text('\$${_subtotal.toStringAsFixed(2)}'),
                    ],
                  ),
                  if (_laborCost > 0) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Labor:'),
                        Text('\$${_laborCost.toStringAsFixed(2)}'),
                      ],
                    ),
                  ],
                  if (_discount > 0) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Discount:', style: TextStyle(color: Colors.green)),
                        Text('-\$${_discount.toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.green)),
                      ],
                    ),
                  ],
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

          // Send Button
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _sendQuote,
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.send),
            label: const Text('Create & Send Quote'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
