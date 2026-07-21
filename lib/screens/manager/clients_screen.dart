import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../models/client.dart';
import 'client_detail_screen.dart';
import 'edit_client_screen.dart';

class ClientsScreen extends StatefulWidget {
  final AuthService authService;
  final bool embedded;
  const ClientsScreen({Key? key, required this.authService, this.embedded = false}) : super(key: key);

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  String _search = '';
  bool _showArchived = false;

  List<Client> get _filteredClients {
    final all = _showArchived
        ? widget.authService.storage.getArchivedClients()
        : widget.authService.storage.getActiveClients();
    if (_search.isEmpty) return all;
    final q = _search.toLowerCase();
    return all.where((c) =>
        c.fullName.toLowerCase().contains(q) ||
        c.email.toLowerCase().contains(q) ||
        c.phone.contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final clients = _filteredClients;
    final storage = widget.authService.storage;

    final body = Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search clients...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.grey.shade100,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
            onChanged: (v) => setState(() => _search = v),
          ),
        ),
        if (_showArchived)
          Container(
            width: double.infinity,
            color: Colors.orange.shade50,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
            child: const Text('Showing archived clients',
                style: TextStyle(color: Colors.orange, fontSize: 13)),
          ),
        Expanded(
          child: clients.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.people_outline, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text(
                        _showArchived ? 'No archived clients' : 'No clients yet',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
                      ),
                      if (!_showArchived) ...[
                        const SizedBox(height: 8),
                        const Text('Tap + to add your first client',
                            style: TextStyle(color: Colors.grey, fontSize: 13)),
                      ],
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  itemCount: clients.length,
                  itemBuilder: (context, index) {
                    final client = clients[index];
                    final propCount = storage.getPropertiesForClient(client.id).length;
                    final invoiceCount = storage.getInvoicesForClient(client.id).length;
                    final unpaid = storage.getInvoicesForClient(client.id)
                        .where((i) => i.status != 'paid' && i.status != 'void')
                        .fold(0.0, (sum, i) => sum + i.balanceDue);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ClientDetailScreen(
                                authService: widget.authService,
                                clientId: client.id,
                              ),
                            ),
                          );
                          setState(() {});
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: Theme.of(context)
                                    .primaryColor
                                    .withValues(alpha: 0.15),
                                child: Text(
                                  client.initials.isNotEmpty ? client.initials : '?',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      client.fullName.isNotEmpty
                                          ? client.fullName
                                          : client.email,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600, fontSize: 15),
                                    ),
                                    const SizedBox(height: 2),
                                    if (client.email.isNotEmpty)
                                      Text(client.email,
                                          style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 13)),
                                    Row(
                                      children: [
                                        Text('$propCount properties',
                                            style: TextStyle(
                                                color: Colors.grey.shade500,
                                                fontSize: 12)),
                                        if (invoiceCount > 0) ...[
                                          const Text(' \u00b7 ',
                                              style: TextStyle(color: Colors.grey)),
                                          Text('$invoiceCount invoices',
                                              style: TextStyle(
                                                  color: Colors.grey.shade500,
                                                  fontSize: 12)),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              if (unpaid > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '\$${unpaid.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                        color: Colors.orange,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13),
                                  ),
                                ),
                              const Icon(Icons.chevron_right, color: Colors.grey),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );

    if (widget.embedded) return body;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clients'),
        actions: [
          IconButton(
            icon: Icon(_showArchived ? Icons.archive : Icons.archive_outlined),
            tooltip: _showArchived ? 'Show Active' : 'Show Archived',
            onPressed: () => setState(() => _showArchived = !_showArchived),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EditClientScreen(authService: widget.authService),
            ),
          );
          if (result == true) setState(() {});
        },
        child: const Icon(Icons.person_add),
      ),
      body: body,
    );
  }
}
