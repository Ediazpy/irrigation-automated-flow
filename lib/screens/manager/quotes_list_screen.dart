import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/quote_service.dart';
import '../../models/quote.dart';
import '../../models/property.dart';
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
  StreamSubscription<Map<int, Quote>>? _quotesSubscription;
  Timer? _reconcileTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _subscribeToQuotes();
    // Customer approvals land in public_quotes — pull them into the quotes
    // collection now and every 30s while this screen is open, so approvals
    // show up without restarting the app.
    _reconcileApprovals();
    _reconcileTimer = Timer.periodic(
        const Duration(seconds: 30), (_) => _reconcileApprovals());
  }

  Future<void> _reconcileApprovals() async {
    try {
      final changed = await FirestoreService()
          .reconcilePublicQuotes(widget.authService.storage.quotes);
      if (changed.isNotEmpty && mounted) {
        widget.authService.storage.saveData();
        setState(() {});
      }
    } catch (_) {}
  }

  /// Listen to Firestore in real-time so the manager sees customer approvals
  /// the moment they happen — even on another device/browser.
  void _subscribeToQuotes() {
    if (!widget.authService.storage.firestoreSyncEnabled) return;
    _quotesSubscription = FirestoreService().watchQuotes().listen(
      (firestoreQuotes) {
        if (!mounted) return;
        // Merge Firestore quotes into local storage
        widget.authService.storage.quotes
          ..clear()
          ..addAll(firestoreQuotes);
        setState(() {});
      },
      onError: (_) {
        // Network unavailable — silently keep local data
      },
    );
  }

  @override
  void dispose() {
    _reconcileTimer?.cancel();
    _quotesSubscription?.cancel();
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
      onRefresh: () async {
        if (widget.authService.storage.firestoreSyncEnabled) {
          await widget.authService.storage.downloadFromFirestore();
        }
        setState(() {});
      },
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
    final isApproved = quote.status == QuoteStatus.approved;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      // Give approved cards a subtle green border to stand out
      shape: isApproved
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Colors.green, width: 1.5),
            )
          : null,
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
                  // Approved badge is filled solid; others are tinted
                  isApproved
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_circle, size: 16, color: Colors.white),
                              const SizedBox(width: 5),
                              const Text(
                                'APPROVED',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        )
                      : Container(
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

              // Resend Button for Sent Quotes
              if (quote.status == QuoteStatus.sent) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () => _resendQuote(quote),
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Resend Quote'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blue,
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
                  if (quote.tax > 0)
                    _totalRow('Tax', quote.tax),
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

                  // Resend for Sent quotes
                  if (quote.status == QuoteStatus.sent) ...[
                    const SizedBox(height: 24),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _resendQuote(quote);
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Resend Quote'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue,
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

  void _resendQuote(Quote quote) {
    final property = widget.authService.storage.properties[quote.propertyId];
    _showResendOptions(quote, property);
  }

  void _showResendOptions(Quote quote, Property? property) {
    // Generate quote URL and messages
    final quoteUrl = QuoteService.generateQuoteUrl(quote.accessToken);
    final emailMessage = property != null
        ? QuoteService.formatQuoteMessage(
            quote: quote, property: property, quoteUrl: quoteUrl)
        : 'View your quote: $quoteUrl';
    final smsMessage = property != null
        ? QuoteService.formatSmsMessage(
            quote: quote, property: property, quoteUrl: quoteUrl)
        : 'View your quote: $quoteUrl';

    final emailCtrl = TextEditingController(text: property?.clientEmail ?? '');
    final phoneCtrl = TextEditingController(text: property?.clientPhone ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 16, right: 16, top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Resend Quote',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Quote #${quote.id} - \$${quote.totalCost.toStringAsFixed(2)}',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Client Email',
                prefixIcon: Icon(Icons.email_outlined),
                hintText: 'Enter email address',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Client Phone',
                prefixIcon: Icon(Icons.phone_outlined),
                hintText: 'Enter phone number',
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                final email = emailCtrl.text.trim();
                if (email.isEmpty) return;
                Navigator.pop(context);
                final subject = Uri.encodeComponent(
                    'Quote #${quote.id} from ${quote.companyName}');
                final body = Uri.encodeComponent(emailMessage);
                final uri = Uri.parse('mailto:$email?subject=$subject&body=$body');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                }
              },
              icon: const Icon(Icons.email),
              label: const Text('Send via Email'),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(14)),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () async {
                final phone = phoneCtrl.text.trim();
                if (phone.isEmpty) return;
                Navigator.pop(context);
                final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
                final body = Uri.encodeComponent(smsMessage);
                final uri = Uri.parse('sms:$cleanPhone?body=$body');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                }
              },
              icon: const Icon(Icons.sms),
              label: const Text('Send via Text'),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(14)),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close),
              label: const Text('Cancel'),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(14)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendViaEmail(Quote quote, Property property, String message) async {
    final email = property.clientEmail;
    final subject = Uri.encodeComponent('Quote #${quote.id} from ${quote.companyName}');
    final body = Uri.encodeComponent(message);
    final uri = Uri.parse('mailto:$email?subject=$subject&body=$body');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email app opened'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open email app'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _sendViaSms(Property property, String message) async {
    final phone = property.clientPhone.replaceAll(RegExp(r'[^\d]'), '');
    final body = Uri.encodeComponent(message);
    final uri = Uri.parse('sms:$phone?body=$body');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('SMS app opened'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open SMS app'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
