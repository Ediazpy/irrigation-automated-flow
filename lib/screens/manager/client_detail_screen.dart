import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/auth_service.dart';
import '../../models/client.dart';
import '../../models/property.dart';
import '../../models/quote.dart';
import '../../models/invoice.dart';
import '../../constants/status_constants.dart';
import 'edit_client_screen.dart';
import 'edit_property_screen.dart';
import 'create_property_screen.dart';
import 'invoices_screen.dart';

class ClientDetailScreen extends StatefulWidget {
  final AuthService authService;
  final int clientId;

  const ClientDetailScreen({
    Key? key,
    required this.authService,
    required this.clientId,
  }) : super(key: key);

  @override
  State<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends State<ClientDetailScreen> {
  Client? get _client => widget.authService.storage.clients[widget.clientId];

  List<Property> get _properties =>
      widget.authService.storage.getPropertiesForClient(widget.clientId);

  List<Quote> get _quotes =>
      widget.authService.storage.getQuotesForClient(widget.clientId);

  List<Invoice> get _invoices =>
      widget.authService.storage.getInvoicesForClient(widget.clientId);

  @override
  Widget build(BuildContext context) {
    final client = _client;
    if (client == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Client')),
        body: const Center(child: Text('Client not found')),
      );
    }

    final properties = _properties;
    final quotes = _quotes..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final invoices = _invoices..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final unpaidBalance = invoices
        .where((i) => i.status != 'paid' && i.status != 'void')
        .fold(0.0, (sum, i) => sum + i.balanceDue);
    final totalRevenue = invoices
        .where((i) => i.status == 'paid')
        .fold(0.0, (sum, i) => sum + i.amountPaid);

    return Scaffold(
      appBar: AppBar(
        title: Text(client.fullName),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditClientScreen(
                    authService: widget.authService,
                    existingClient: client,
                  ),
                ),
              );
              if (result == true) setState(() {});
            },
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'archive') _toggleArchive(client);
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'archive',
                child: Text(client.isArchived ? 'Unarchive Client' : 'Archive Client'),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Contact card
          _ContactCard(client: client),
          const SizedBox(height: 16),

          // Financial summary
          if (invoices.isNotEmpty) ...[
            Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    label: 'Outstanding',
                    value: '\$${unpaidBalance.toStringAsFixed(2)}',
                    color: unpaidBalance > 0 ? Colors.orange : Colors.green,
                    icon: Icons.receipt_long,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SummaryCard(
                    label: 'Total Paid',
                    value: '\$${totalRevenue.toStringAsFixed(2)}',
                    color: Colors.green,
                    icon: Icons.payments,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // Properties section
          _SectionHeader(
            'Properties (${properties.length})',
            action: TextButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add'),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CreatePropertyScreen(
                      authService: widget.authService,
                    ),
                  ),
                );
                if (result == true) setState(() {});
              },
            ),
          ),
          if (properties.isEmpty)
            _EmptyState(icon: Icons.home_outlined, text: 'No properties yet')
          else
            ...properties.map((p) => _PropertyTile(
                  property: p,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditPropertyScreen(
                          authService: widget.authService,
                          property: p,
                        ),
                      ),
                    );
                    setState(() {});
                  },
                )),
          const SizedBox(height: 16),

          // Quotes section
          _SectionHeader('Quotes (${quotes.length})'),
          if (quotes.isEmpty)
            _EmptyState(icon: Icons.request_quote_outlined, text: 'No quotes yet')
          else
            ...quotes.take(5).map((q) {
              final prop = widget.authService.storage.properties[q.propertyId];
              return _QuoteTile(quote: q, propertyAddress: prop?.address ?? '');
            }),
          if (quotes.length > 5)
            Center(
              child: TextButton(
                onPressed: () {},
                child: Text('View all ${quotes.length} quotes'),
              ),
            ),
          const SizedBox(height: 16),

          // Invoices section
          _SectionHeader(
            'Invoices (${invoices.length})',
            action: TextButton.icon(
              icon: const Icon(Icons.list, size: 18),
              label: const Text('View All'),
              onPressed: invoices.isEmpty
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => InvoicesScreen(
                            authService: widget.authService,
                            filterClientId: widget.clientId,
                          ),
                        ),
                      );
                    },
            ),
          ),
          if (invoices.isEmpty)
            _EmptyState(icon: Icons.receipt_outlined, text: 'No invoices yet')
          else
            ...invoices.take(5).map((inv) {
              final prop = widget.authService.storage.properties[inv.propertyId];
              return _InvoiceTile(
                invoice: inv,
                propertyAddress: prop?.address ?? '',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => InvoicesScreen(
                        authService: widget.authService,
                        filterClientId: widget.clientId,
                      ),
                    ),
                  ).then((_) => setState(() {}));
                },
              );
            }),
        ],
      ),
    );
  }

  void _toggleArchive(Client client) {
    final storage = widget.authService.storage;
    storage.clients[client.id] = client.copyWith(isArchived: !client.isArchived);
    storage.saveData();
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(client.isArchived ? 'Client unarchived' : 'Client archived'),
      ),
    );
  }
}

// ───── Widgets ─────

class _ContactCard extends StatelessWidget {
  final Client client;
  const _ContactCard({required this.client});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor:
                      Theme.of(context).primaryColor.withValues(alpha: 0.15),
                  child: Text(client.initials,
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(client.fullName,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      if (client.fullAddress.isNotEmpty)
                        Text(client.fullAddress,
                            style: TextStyle(
                                color: Colors.grey.shade600, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            if (client.email.isNotEmpty)
              _ContactRow(
                icon: Icons.email,
                text: client.email,
                onTap: () => launchUrl(Uri.parse('mailto:${client.email}')),
              ),
            if (client.phone.isNotEmpty)
              _ContactRow(
                icon: Icons.phone,
                text: client.phone,
                onTap: () => launchUrl(Uri.parse(
                    'tel:${client.phone.replaceAll(RegExp(r'[^\d+]'), '')}')),
              ),
            if (client.notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.note, size: 16, color: Colors.amber.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(client.notes,
                            style: TextStyle(
                                fontSize: 13, color: Colors.amber.shade900))),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback? onTap;
  const _ContactRow({required this.icon, required this.text, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Colors.grey),
            const SizedBox(width: 10),
            Text(text, style: const TextStyle(fontSize: 14)),
            if (onTap != null)
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Icon(Icons.open_in_new, size: 14, color: Colors.grey.shade400),
              ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Widget? action;
  const _SectionHeader(this.title, {this.action});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const Spacer(),
        if (action != null) action!,
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String text;
  const _EmptyState({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade400),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  const _SummaryCard(
      {required this.label,
      required this.value,
      required this.color,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
                Text(label,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}

class _PropertyTile extends StatelessWidget {
  final Property property;
  final VoidCallback onTap;
  const _PropertyTile({required this.property, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFE8F5E9),
          child: Icon(Icons.home, color: Color(0xFF2E7D32)),
        ),
        title: Text(property.address,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
        subtitle: Text('${property.allZones.length} zones',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}

class _QuoteTile extends StatelessWidget {
  final Quote quote;
  final String propertyAddress;
  const _QuoteTile({required this.quote, required this.propertyAddress});

  @override
  Widget build(BuildContext context) {
    final color = QuoteStatus.getColor(quote.status);
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(QuoteStatus.getIcon(quote.status), color: color, size: 20),
        ),
        title: Text('Quote #${quote.id} - \$${quote.totalCost.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
        subtitle: Text(
          '${QuoteStatus.getDisplayName(quote.status)} \u00b7 ${propertyAddress}',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
      ),
    );
  }
}

class _InvoiceTile extends StatelessWidget {
  final Invoice invoice;
  final String propertyAddress;
  final VoidCallback? onTap;
  const _InvoiceTile(
      {required this.invoice, required this.propertyAddress, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isPaid = invoice.status == 'paid';
    final color = isPaid ? Colors.green : (invoice.isOverdue ? Colors.red : Colors.blue);
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(
            isPaid ? Icons.check_circle : Icons.receipt,
            color: color,
            size: 20,
          ),
        ),
        title: Text(
          'INV-${invoice.id} - \$${invoice.totalCost.toStringAsFixed(2)}',
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        ),
        subtitle: Text(
          '${isPaid ? 'Paid' : (invoice.isOverdue ? 'Overdue' : invoice.status.toUpperCase())} \u00b7 $propertyAddress',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
        trailing: !isPaid && invoice.balanceDue > 0
            ? Text('\$${invoice.balanceDue.toStringAsFixed(2)}',
                style: TextStyle(
                    color: invoice.isOverdue ? Colors.red : Colors.orange,
                    fontWeight: FontWeight.w600))
            : null,
        onTap: onTap,
      ),
    );
  }
}
