import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/quote_service.dart';
import '../../models/invoice.dart';
import '../../models/quote.dart';

class InvoicesScreen extends StatefulWidget {
  final AuthService authService;
  final int? filterClientId;

  const InvoicesScreen({
    Key? key,
    required this.authService,
    this.filterClientId,
  }) : super(key: key);

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  List<Invoice> _getInvoices(String? statusFilter) {
    final storage = widget.authService.storage;
    List<Invoice> all;
    if (widget.filterClientId != null) {
      all = storage.getInvoicesForClient(widget.filterClientId!);
    } else {
      all = storage.invoices.values.toList();
    }

    if (statusFilter == 'unpaid') {
      all = all.where((i) =>
          i.status != 'paid' && i.status != 'void').toList();
    } else if (statusFilter == 'paid') {
      all = all.where((i) => i.status == 'paid').toList();
    } else if (statusFilter == 'overdue') {
      all = all.where((i) => i.isOverdue && i.status != 'paid' && i.status != 'void').toList();
    }

    all.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return all;
  }

  @override
  Widget build(BuildContext context) {
    final clientName = widget.filterClientId != null
        ? widget.authService.storage.clients[widget.filterClientId]?.fullName
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(clientName != null ? '$clientName Invoices' : 'Invoices'),
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Unpaid'),
            Tab(text: 'Overdue'),
            Tab(text: 'Paid'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createInvoiceFromQuote(),
        tooltip: 'Create Invoice from Quote',
        child: const Icon(Icons.add),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _InvoiceList(invoices: _getInvoices(null), screen: this),
          _InvoiceList(invoices: _getInvoices('unpaid'), screen: this),
          _InvoiceList(invoices: _getInvoices('overdue'), screen: this),
          _InvoiceList(invoices: _getInvoices('paid'), screen: this),
        ],
      ),
    );
  }

  void _createInvoiceFromQuote() {
    final storage = widget.authService.storage;
    // Get approved quotes that don't have invoices yet
    final invoicedQuoteIds = storage.invoices.values.map((i) => i.quoteId).toSet();
    final eligibleQuotes = storage.quotes.values
        .where((q) =>
            q.status == 'approved' && !invoicedQuoteIds.contains(q.id))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (eligibleQuotes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No approved quotes without invoices'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (ctx, scroll) => Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Create Invoice from Approved Quote',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const Divider(height: 0),
            Expanded(
              child: ListView.builder(
                controller: scroll,
                itemCount: eligibleQuotes.length,
                itemBuilder: (ctx, i) {
                  final q = eligibleQuotes[i];
                  final prop = storage.properties[q.propertyId];
                  return ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFE8F5E9),
                      child: Icon(Icons.check_circle, color: Colors.green),
                    ),
                    title: Text('Quote #${q.id} - \$${q.totalCost.toStringAsFixed(2)}'),
                    subtitle: Text(prop?.address ?? 'Unknown property'),
                    trailing: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _generateInvoice(q);
                      },
                      child: const Text('Create'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _generateInvoice(Quote quote) {
    final storage = widget.authService.storage;
    final settings = storage.companySettings;
    final property = storage.properties[quote.propertyId];

    // Find or create clientId
    int clientId = property?.clientId ?? 0;

    final invoice = Invoice(
      id: storage.nextInvoiceId,
      quoteId: quote.id,
      inspectionId: quote.inspectionId,
      propertyId: quote.propertyId,
      clientId: clientId,
      lineItems: List.from(quote.lineItems),
      laborCost: quote.laborCost,
      discount: quote.discount,
      tax: quote.tax,
      status: InvoiceStatus.draft,
      dueDate: DateTime.now().add(const Duration(days: 30)).toIso8601String(),
      companyName: settings?.companyName ?? quote.companyName,
      companyPhone: settings?.companyPhone ?? quote.companyPhone,
      companyEmail: settings?.companyEmail ?? quote.companyEmail,
      createdAt: DateTime.now().toIso8601String(),
    );

    storage.invoices[invoice.id] = invoice;
    storage.nextInvoiceId++;
    storage.saveData();

    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Invoice INV-${invoice.id} created (\$${invoice.totalCost.toStringAsFixed(2)})'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showInvoiceDetail(Invoice invoice) {
    final storage = widget.authService.storage;
    final property = storage.properties[invoice.propertyId];
    final client = storage.clients[invoice.clientId];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (ctx, scroll) => Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  Text('INV-${invoice.id}',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  _StatusChip(invoice.status),
                ],
              ),
            ),
            const Divider(height: 20),
            Expanded(
              child: ListView(
                controller: scroll,
                padding: const EdgeInsets.all(16),
                children: [
                  if (client != null)
                    _DetailRow('Client', client.fullName),
                  _DetailRow('Property', property?.address ?? 'Unknown'),
                  _DetailRow('Created',
                      QuoteService.formatDateTime(invoice.createdAt)),
                  if (invoice.sentAt != null)
                    _DetailRow('Sent',
                        QuoteService.formatDateTime(invoice.sentAt)),
                  if (invoice.dueDate != null)
                    _DetailRow('Due',
                        QuoteService.formatDateTime(invoice.dueDate)),
                  if (invoice.paidAt != null)
                    _DetailRow('Paid',
                        QuoteService.formatDateTime(invoice.paidAt)),
                  const SizedBox(height: 16),
                  const Text('Line Items',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 8),
                  ...invoice.lineItems.map((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            Expanded(
                                child: Text(
                                    '${item.quantity}x ${item.displayDescription}'
                                    '${item.zoneNumber != null ? ' (Z${item.zoneNumber})' : ''}')),
                            Text('\$${item.totalPrice.toStringAsFixed(2)}'),
                          ],
                        ),
                      )),
                  const Divider(height: 20),
                  _TotalRow('Subtotal', invoice.materialsCost),
                  if (invoice.laborCost > 0)
                    _TotalRow('Labor', invoice.laborCost),
                  if (invoice.discount > 0)
                    _TotalRow('Discount', -invoice.discount),
                  if (invoice.tax > 0)
                    _TotalRow('Tax', invoice.tax),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('TOTAL',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('\$${invoice.totalCost.toStringAsFixed(2)}',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Theme.of(ctx).primaryColor)),
                    ],
                  ),
                  if (invoice.amountPaid > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Paid',
                            style: TextStyle(color: Colors.green.shade700)),
                        Text('-\$${invoice.amountPaid.toStringAsFixed(2)}',
                            style: TextStyle(color: Colors.green.shade700)),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('BALANCE DUE',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14)),
                        Text(
                            '\$${invoice.balanceDue.toStringAsFixed(2)}',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: invoice.balanceDue > 0
                                    ? Colors.orange
                                    : Colors.green)),
                      ],
                    ),
                  ],
                  if (invoice.paymentMethod.isNotEmpty)
                    _DetailRow('Payment Method', invoice.paymentMethod),
                  if (invoice.paymentNotes?.isNotEmpty == true)
                    _DetailRow('Payment Notes', invoice.paymentNotes!),
                  if (invoice.notes?.isNotEmpty == true) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(invoice.notes!),
                    ),
                  ],
                  const SizedBox(height: 20),

                  // Actions
                  if (invoice.status != 'paid' &&
                      invoice.status != 'void') ...[
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _recordPayment(invoice);
                      },
                      icon: const Icon(Icons.payments),
                      label: const Text('Record Payment'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(14)),
                    ),
                    const SizedBox(height: 8),
                    if (invoice.status == 'draft')
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _markSent(invoice);
                        },
                        icon: const Icon(Icons.send),
                        label: const Text('Mark as Sent'),
                        style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.blue,
                            padding: const EdgeInsets.all(14)),
                      ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _voidInvoice(invoice);
                      },
                      icon: const Icon(Icons.block),
                      label: const Text('Void Invoice'),
                      style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.all(14)),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _markSent(Invoice invoice) {
    final storage = widget.authService.storage;
    storage.invoices[invoice.id] = invoice.copyWith(
      status: InvoiceStatus.sent,
      sentAt: DateTime.now().toIso8601String(),
    );
    storage.saveData();
    setState(() {});
  }

  void _voidInvoice(Invoice invoice) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Void Invoice'),
        content: Text('Void INV-${invoice.id}? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              final storage = widget.authService.storage;
              storage.invoices[invoice.id] =
                  invoice.copyWith(status: InvoiceStatus.voided);
              storage.saveData();
              setState(() {});
            },
            child: const Text('Void'),
          ),
        ],
      ),
    );
  }

  void _recordPayment(Invoice invoice) {
    final amountCtrl =
        TextEditingController(text: invoice.balanceDue.toStringAsFixed(2));
    String method = 'cash';
    final notesCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Record Payment — INV-${invoice.id}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Balance: \$${invoice.balanceDue.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 16),
                TextFormField(
                  controller: amountCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: method,
                  decoration:
                      const InputDecoration(labelText: 'Payment Method'),
                  items: const [
                    DropdownMenuItem(value: 'cash', child: Text('Cash')),
                    DropdownMenuItem(value: 'check', child: Text('Check')),
                    DropdownMenuItem(
                        value: 'credit_card', child: Text('Credit Card')),
                    DropdownMenuItem(
                        value: 'bank_transfer',
                        child: Text('Bank Transfer')),
                    DropdownMenuItem(value: 'other', child: Text('Other')),
                  ],
                  onChanged: (v) =>
                      setDialogState(() => method = v ?? 'cash'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: notesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    hintText: 'Check #, reference, etc.',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton.icon(
              icon: const Icon(Icons.check),
              label: const Text('Record'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white),
              onPressed: () {
                final amount =
                    double.tryParse(amountCtrl.text) ?? 0.0;
                if (amount <= 0) return;

                Navigator.pop(ctx);
                final storage = widget.authService.storage;
                final newPaid = invoice.amountPaid + amount;
                final isFullyPaid = newPaid >= invoice.totalCost;

                storage.invoices[invoice.id] = invoice.copyWith(
                  amountPaid: newPaid,
                  paymentMethod: method,
                  paymentNotes: notesCtrl.text.trim().isEmpty
                      ? invoice.paymentNotes
                      : notesCtrl.text.trim(),
                  status: isFullyPaid
                      ? InvoiceStatus.paid
                      : InvoiceStatus.partial,
                  paidAt: isFullyPaid
                      ? DateTime.now().toIso8601String()
                      : invoice.paidAt,
                );
                storage.saveData();
                setState(() {});

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isFullyPaid
                        ? 'Invoice marked as fully paid!'
                        : 'Partial payment of \$${amount.toStringAsFixed(2)} recorded'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ───── Shared Widgets ─────

class _InvoiceList extends StatelessWidget {
  final List<Invoice> invoices;
  final _InvoicesScreenState screen;
  const _InvoiceList({required this.invoices, required this.screen});

  @override
  Widget build(BuildContext context) {
    if (invoices.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text('No invoices',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: invoices.length,
      itemBuilder: (ctx, i) {
        final inv = invoices[i];
        final storage = screen.widget.authService.storage;
        final client = storage.clients[inv.clientId];
        final property = storage.properties[inv.propertyId];
        final isPaid = inv.status == 'paid';
        final isVoid = inv.status == 'void';
        final color = isPaid
            ? Colors.green
            : isVoid
                ? Colors.grey
                : (inv.isOverdue ? Colors.red : Colors.blue);

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => screen._showInvoiceDetail(inv),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: color.withValues(alpha: 0.15),
                    child: Icon(
                      isPaid
                          ? Icons.check_circle
                          : isVoid
                              ? Icons.block
                              : Icons.receipt,
                      color: color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('INV-${inv.id}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(width: 8),
                            _StatusChip(inv.status),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          client?.fullName ?? property?.clientName ?? '',
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 13),
                        ),
                        Text(
                          property?.address ?? '',
                          style: TextStyle(
                              color: Colors.grey.shade500, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('\$${inv.totalCost.toStringAsFixed(2)}',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(ctx).primaryColor)),
                      if (!isPaid && !isVoid && inv.balanceDue > 0)
                        Text('Due: \$${inv.balanceDue.toStringAsFixed(2)}',
                            style: TextStyle(
                                color: inv.isOverdue
                                    ? Colors.red
                                    : Colors.orange,
                                fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip(this.status);

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'paid':
        color = Colors.green;
        break;
      case 'sent':
        color = Colors.blue;
        break;
      case 'overdue':
        color = Colors.red;
        break;
      case 'partial':
        color = Colors.orange;
        break;
      case 'void':
        color = Colors.grey;
        break;
      default:
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        InvoiceStatus.getDisplayName(status),
        style:
            TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Flexible(
              child: Text(value,
                  textAlign: TextAlign.end,
                  style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final double value;
  const _TotalRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Text(
            '${value < 0 ? '-' : ''}\$${value.abs().toStringAsFixed(2)}',
            style: TextStyle(color: value < 0 ? Colors.green : null),
          ),
        ],
      ),
    );
  }
}
