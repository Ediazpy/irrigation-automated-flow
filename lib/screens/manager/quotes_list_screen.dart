import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/quote_service.dart';
import '../../models/quote.dart';
import '../../constants/status_constants.dart';
import 'schedule_repair_screen.dart';

class QuotesListScreen extends StatefulWidget {
  final AuthService authService;

  const QuotesListScreen({Key? key, required this.authService}) : super(key: key);

  @override
  State<QuotesListScreen> createState() => _QuotesListScreenState();
}

class _QuotesListScreenState extends State<QuotesListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Quote> _getFilteredQuotes(String? statusFilter) {
    var quotes = widget.authService.storage.quotes.values.toList();

    // Filter by status if specified
    if (statusFilter != null) {
      quotes = quotes.where((q) => q.status == statusFilter).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      quotes = quotes.where((q) {
        final property = widget.authService.storage.properties[q.propertyId];
        final address = property?.address.toLowerCase() ?? '';
        final clientName = property?.clientName.toLowerCase() ?? '';
        return address.contains(_searchQuery.toLowerCase()) ||
            clientName.contains(_searchQuery.toLowerCase()) ||
            q.id.toString().contains(_searchQuery);
      }).toList();
    }

    // Sort by created date (newest first)
    quotes.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return quotes;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quotes'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Sent'),
            Tab(text: 'Approved'),
            Tab(text: 'Rejected'),
            Tab(text: 'Expired'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by address, client, or quote #',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                isDense: true,
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),

          // Quote Lists
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildQuoteList(null),
                _buildQuoteList(QuoteStatus.sent),
                _buildQuoteList(QuoteStatus.approved),
                _buildQuoteList(QuoteStatus.rejected),
                _buildQuoteList(QuoteStatus.expired),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuoteList(String? statusFilter) {
    final quotes = _getFilteredQuotes(statusFilter);

    if (quotes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              statusFilter == null ? 'No quotes yet' : 'No ${statusFilter} quotes',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => setState(() {}),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: quotes.length,
        itemBuilder: (context, index) {
          final quote = quotes[index];
          return _buildQuoteCard(quote);
        },
      ),
    );
  }

  Widget _buildQuoteCard(Quote quote) {
    final property = widget.authService.storage.properties[quote.propertyId];
    final statusColor = QuoteStatus.getColor(quote.status);
    final statusIcon = QuoteStatus.getIcon(quote.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showQuoteDetails(quote),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 16, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          QuoteStatus.getDisplayName(quote.status),
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Quote #${quote.id}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Property Address
              Row(
                children: [
                  const Icon(Icons.location_on, size: 18, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      property?.address ?? 'Unknown Property',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),

              // Client Name
              if (property?.clientName.isNotEmpty == true) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.person, size: 18, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      property!.clientName,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 12),

              // Footer Row
              Row(
                children: [
                  // Total
                  Text(
                    '\$${quote.totalCost.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const Spacer(),

                  // Expiration
                  if (quote.status == QuoteStatus.sent) ...[
                    Icon(
                      Icons.timer,
                      size: 16,
                      color: quote.daysUntilExpiry <= 3 ? Colors.orange : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${quote.daysUntilExpiry} days left',
                      style: TextStyle(
                        color: quote.daysUntilExpiry <= 3 ? Colors.orange : Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],

                  // Signature indicator for approved
                  if (quote.status == QuoteStatus.approved && quote.clientSignature != null) ...[
                    const Icon(Icons.draw, size: 16, color: Colors.green),
                    const SizedBox(width: 4),
                    const Text(
                      'Signed',
                      style: TextStyle(color: Colors.green, fontSize: 12),
                    ),
                  ],
                ],
              ),

              // Action Button for Approved Quotes
              if (quote.status == QuoteStatus.approved) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _scheduleRepairs(quote),
                    icon: const Icon(Icons.calendar_month),
                    label: const Text('Schedule Repairs'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showQuoteDetails(Quote quote) {
    final property = widget.authService.storage.properties[quote.propertyId];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    'Quote #${quote.id}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: QuoteStatus.getColor(quote.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      QuoteStatus.getDisplayName(quote.status),
                      style: TextStyle(
                        color: QuoteStatus.getColor(quote.status),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Content
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                children: [
                  // Property Info
                  _detailRow('Property', property?.address ?? 'Unknown'),
                  if (property?.clientName.isNotEmpty == true)
                    _detailRow('Client', property!.clientName),

                  const SizedBox(height: 16),

                  // Dates
                  _detailRow('Created', QuoteService.formatDateTime(quote.createdAt)),
                  if (quote.sentAt != null)
                    _detailRow('Sent', QuoteService.formatDateTime(quote.sentAt)),
                  if (quote.viewedAt != null)
                    _detailRow('Viewed', QuoteService.formatDateTime(quote.viewedAt)),
                  if (quote.signedAt != null)
                    _detailRow('Signed', QuoteService.formatDateTime(quote.signedAt)),
                  _detailRow('Expires', QuoteService.formatDateTime(quote.expiresAt)),

                  const SizedBox(height: 16),

                  // Line Items
                  const Text(
                    'Items',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  ...quote.lineItems.map((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${item.quantity}x ${item.displayDescription}' +
                                    (item.zoneNumber != null ? ' (Z${item.zoneNumber})' : ''),
                              ),
                            ),
                            Text('\$${item.totalPrice.toStringAsFixed(2)}'),
                          ],
                        ),
                      )),

                  const Divider(height: 24),

                  // Totals
                  _totalRow('Subtotal', quote.materialsCost),
                  if (quote.laborCost > 0)
                    _totalRow('Labor', quote.laborCost),
                  if (quote.discount > 0)
                    _totalRow('Discount', -quote.discount),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'TOTAL',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      Text(
                        '\$${quote.totalCost.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),

                  // Client Notes
                  if (quote.clientNotes?.isNotEmpty == true) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Client Notes',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(quote.clientNotes!),
                    ),
                  ],

                  // Schedule Button for Approved
                  if (quote.status == QuoteStatus.approved) ...[
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _scheduleRepairs(quote);
                      },
                      icon: const Icon(Icons.calendar_month),
                      label: const Text('Schedule Repairs'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(16),
                      ),
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

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _totalRow(String label, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Text('\$${value.toStringAsFixed(2)}'),
        ],
      ),
    );
  }

  void _scheduleRepairs(Quote quote) {
    final property = widget.authService.storage.properties[quote.propertyId];
    if (property == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScheduleRepairScreen(
          authService: widget.authService,
          quote: quote,
          property: property,
        ),
      ),
    ).then((_) => setState(() {}));
  }
}
