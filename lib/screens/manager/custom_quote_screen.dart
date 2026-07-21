import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/auth_service.dart';
import '../../services/quote_service.dart';
import '../../models/quote.dart';
import '../../models/quote_line_item.dart';
import '../../models/company_settings.dart';
import '../../constants/status_constants.dart';

/// Standalone quote builder for creating custom quotes
/// without requiring an inspection. Allows free-form line items,
/// title, description, discount, and tax.
class CustomQuoteScreen extends StatefulWidget {
  final AuthService authService;

  const CustomQuoteScreen({Key? key, required this.authService}) : super(key: key);

  @override
  State<CustomQuoteScreen> createState() => _CustomQuoteScreenState();
}

class _CustomQuoteScreenState extends State<CustomQuoteScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _clientNameController = TextEditingController();
  final _clientEmailController = TextEditingController();
  final _clientPhoneController = TextEditingController();
  final _discountController = TextEditingController(text: '0.00');
  final _taxController = TextEditingController(text: '0.00');
  final _discountPercentController = TextEditingController();
  final _taxPercentController = TextEditingController();

  List<QuoteLineItem> _lineItems = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _clientNameController.dispose();
    _clientEmailController.dispose();
    _clientPhoneController.dispose();
    _discountController.dispose();
    _taxController.dispose();
    _discountPercentController.dispose();
    _taxPercentController.dispose();
    super.dispose();
  }

  double get _subtotal {
    return _lineItems.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  double get _discount {
    return double.tryParse(_discountController.text) ?? 0.0;
  }

  double get _tax {
    return double.tryParse(_taxController.text) ?? 0.0;
  }

  double get _total {
    final t = _subtotal - _discount + _tax;
    return t < 0 ? 0.0 : t;
  }

  void _applyDiscountPercent() {
    final pct = double.tryParse(_discountPercentController.text) ?? 0.0;
    if (pct > 0) {
      final amount = _subtotal * (pct / 100.0);
      setState(() {
        _discountController.text = amount.toStringAsFixed(2);
      });
    }
  }

  void _applyTaxPercent() {
    final pct = double.tryParse(_taxPercentController.text) ?? 0.0;
    if (pct > 0) {
      final afterDiscount = _subtotal - _discount;
      final amount = afterDiscount * (pct / 100.0);
      setState(() {
        _taxController.text = amount.toStringAsFixed(2);
      });
    }
  }

  void _addLineItem() {
    final descController = TextEditingController();
    final qtyController = TextEditingController(text: '1');
    final priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Line Item'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: descController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'e.g., Sprinkler head replacement',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: qtyController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Unit Price',
                  prefixText: '\$',
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
          ElevatedButton(
            onPressed: () {
              final desc = descController.text.trim();
              final qty = int.tryParse(qtyController.text) ?? 1;
              final price = double.tryParse(priceController.text) ?? 0.0;

              if (desc.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Description is required')),
                );
                return;
              }

              setState(() {
                _lineItems.add(QuoteLineItem(
                  description: desc,
                  quantity: qty,
                  unitPrice: price,
                  category: 'custom',
                ));
              });
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _editLineItem(int index) {
    final item = _lineItems[index];
    final descController = TextEditingController(text: item.description);
    final qtyController = TextEditingController(text: item.quantity.toString());
    final priceController = TextEditingController(text: item.unitPrice.toStringAsFixed(2));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Line Item'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: qtyController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Quantity'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Unit Price',
                  prefixText: '\$',
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
              setState(() {
                _lineItems[index] = QuoteLineItem(
                  description: descController.text.trim(),
                  quantity: int.tryParse(qtyController.text) ?? 1,
                  unitPrice: double.tryParse(priceController.text) ?? 0.0,
                  category: 'custom',
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

  Future<void> _createAndSendQuote() async {
    if (_lineItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one line item'), backgroundColor: Colors.orange),
      );
      return;
    }

    final settings = widget.authService.storage.companySettings;
    if (settings == null || settings.companyName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please configure company settings first'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final storage = widget.authService.storage;
      final quoteId = storage.nextQuoteId;

      final quote = Quote(
        id: quoteId,
        inspectionId: 0, // No linked inspection
        propertyId: 0, // No linked property
        lineItems: _lineItems,
        laborCost: 0.0,
        discount: _discount,
        tax: _tax,
        status: QuoteStatus.sent,
        accessToken: QuoteService.generateAccessToken(),
        termsAndConditions: settings.defaultTermsAndConditions,
        companyName: settings.companyName,
        companyPhone: settings.companyPhone,
        companyEmail: settings.companyEmail,
        createdAt: DateTime.now().toIso8601String(),
        sentAt: DateTime.now().toIso8601String(),
      );

      storage.quotes[quoteId] = quote;
      storage.nextQuoteId++;
      storage.saveData();

      if (mounted) {
        _showSendOptions(quote);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSendOptions(Quote quote) {
    final clientEmail = _clientEmailController.text.trim();
    final clientPhone = _clientPhoneController.text.trim();
    final clientName = _clientNameController.text.trim();

    // Build the quote message
    final buffer = StringBuffer();
    buffer.writeln('${quote.companyName}');
    if (quote.companyPhone.isNotEmpty) buffer.writeln('Phone: ${quote.companyPhone}');
    if (quote.companyEmail.isNotEmpty) buffer.writeln('Email: ${quote.companyEmail}');
    buffer.writeln('');
    buffer.writeln('QUOTE #${quote.id}');
    if (_titleController.text.trim().isNotEmpty) {
      buffer.writeln(_titleController.text.trim());
    }
    buffer.writeln('Date: ${_formatDate(quote.createdAt)}');
    if (clientName.isNotEmpty) buffer.writeln('Client: $clientName');
    buffer.writeln('');

    if (_descriptionController.text.trim().isNotEmpty) {
      buffer.writeln(_descriptionController.text.trim());
      buffer.writeln('');
    }

    buffer.writeln('ITEMS');
    for (var item in _lineItems) {
      buffer.writeln('  ${item.description} (x${item.quantity})  \$${item.totalPrice.toStringAsFixed(2)}');
    }
    buffer.writeln('');
    buffer.writeln('SUMMARY');
    buffer.writeln('Subtotal: \$${_subtotal.toStringAsFixed(2)}');
    if (_discount > 0) buffer.writeln('Discount: -\$${_discount.toStringAsFixed(2)}');
    if (_tax > 0) buffer.writeln('Tax: +\$${_tax.toStringAsFixed(2)}');
    buffer.writeln('');
    buffer.writeln('TOTAL: \$${_total.toStringAsFixed(2)}');
    buffer.writeln('');
    final quoteUrl = QuoteService.generateQuoteUrl(quote.accessToken);
    buffer.writeln('VIEW & APPROVE YOUR QUOTE ONLINE:');
    buffer.writeln(quoteUrl);
    buffer.writeln('');
    if (quote.companyPhone.isNotEmpty) {
      buffer.writeln('Please contact us at ${quote.companyPhone} with any questions.');
    }
    buffer.writeln('');
    buffer.writeln('Thank you for your business!');
    buffer.writeln(quote.companyName);

    final message = buffer.toString();

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
                'Quote Created!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Quote #${quote.id} - \$${_total.toStringAsFixed(2)}',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),
              if (clientEmail.isNotEmpty)
                ElevatedButton.icon(
                  onPressed: () async {
                    final subject = Uri.encodeComponent(
                        'Quote #${quote.id} from ${quote.companyName}');
                    final body = Uri.encodeComponent(message);
                    final uri = Uri.parse('mailto:$clientEmail?subject=$subject&body=$body');
                    if (await canLaunchUrl(uri)) await launchUrl(uri);
                  },
                  icon: const Icon(Icons.email),
                  label: Text('Email to $clientEmail'),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                ),
              if (clientEmail.isNotEmpty) const SizedBox(height: 12),
              if (clientPhone.isNotEmpty)
                ElevatedButton.icon(
                  onPressed: () async {
                    final phone = clientPhone.replaceAll(RegExp(r'[^\d]'), '');
                    // Build short SMS
                    final sms = StringBuffer();
                    sms.write('${quote.companyName}\nQuote #${quote.id}\n');
                    if (_titleController.text.trim().isNotEmpty) {
                      sms.write('${_titleController.text.trim()}\n');
                    }
                    sms.write('\nTotal: \$${_total.toStringAsFixed(2)}\n');
                    sms.write('\nView & approve your quote:\n${QuoteService.generateQuoteUrl(quote.accessToken)}\n');
                    if (quote.companyPhone.isNotEmpty) {
                      sms.write('\nCall ${quote.companyPhone} with questions.');
                    }
                    final body = Uri.encodeComponent(sms.toString());
                    final uri = Uri.parse('sms:$phone?body=$body');
                    if (await canLaunchUrl(uri)) await launchUrl(uri);
                  },
                  icon: const Icon(Icons.sms),
                  label: Text('Text to $clientPhone'),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                ),
              if (clientPhone.isNotEmpty) const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context); // close bottom sheet
                  Navigator.pop(context); // go back
                },
                icon: const Icon(Icons.check),
                label: const Text('Done'),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null) return 'N/A';
    final date = DateTime.tryParse(isoDate);
    if (date == null) return 'N/A';
    return '${date.month}/${date.day}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom Quote'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Quote Info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Quote Details',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title (optional)',
                      hintText: 'e.g., Irrigation System Repair',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Description (optional)',
                      hintText: 'Brief description of work...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Client Info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Client Info',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _clientNameController,
                    decoration: const InputDecoration(
                      labelText: 'Client Name',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _clientEmailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Client Email',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _clientPhoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Client Phone',
                      prefixIcon: Icon(Icons.phone),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Line Items
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Line Items',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: _addLineItem,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Item'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_lineItems.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.receipt_long, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 8),
                    Text('No items added yet',
                        style: TextStyle(color: Colors.grey.shade600)),
                  ],
                ),
              ),
            )
          else
            ..._lineItems.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Card(
                child: ListTile(
                  title: Text(item.description,
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: Text('${item.quantity} x \$${item.unitPrice.toStringAsFixed(2)}'),
                  trailing: Text(
                    '\$${item.totalPrice.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  onTap: () => _editLineItem(index),
                ),
              );
            }),

          const SizedBox(height: 24),

          // Discount & Tax
          const Text('Discount & Tax',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 2,
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
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _discountPercentController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: '%',
                    suffixText: '%',
                    isDense: true,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.calculate, color: Colors.green),
                tooltip: 'Apply discount %',
                onPressed: _applyDiscountPercent,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _taxController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Tax',
                    prefixIcon: Icon(Icons.receipt_long),
                    prefixText: '+\$',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _taxPercentController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: '%',
                    suffixText: '%',
                    isDense: true,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.calculate, color: Colors.blue),
                tooltip: 'Apply tax %',
                onPressed: _applyTaxPercent,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Totals
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
                  if (_tax > 0) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Tax:'),
                        Text('+\$${_tax.toStringAsFixed(2)}'),
                      ],
                    ),
                  ],
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('TOTAL:',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
            onPressed: _isLoading ? null : _createAndSendQuote,
            icon: _isLoading
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.send),
            label: const Text('Create & Send Quote'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
