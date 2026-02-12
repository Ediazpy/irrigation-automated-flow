import 'package:flutter/material.dart';
import '../../models/quote.dart';
import '../../models/property.dart';
import '../../services/storage_service.dart';
import '../../widgets/signature_pad.dart';
import '../../constants/status_constants.dart';

/// Client-facing quote view and approval screen
/// This screen is accessed via a unique URL token - no login required
class ClientQuoteScreen extends StatefulWidget {
  final StorageService storage;
  final String accessToken;

  const ClientQuoteScreen({
    Key? key,
    required this.storage,
    required this.accessToken,
  }) : super(key: key);

  @override
  State<ClientQuoteScreen> createState() => _ClientQuoteScreenState();
}

class _ClientQuoteScreenState extends State<ClientQuoteScreen> {
  Quote? _quote;
  Property? _property;
  final _notesController = TextEditingController();
  bool _showSignaturePad = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadQuote();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _loadQuote() {
    _quote = widget.storage.getQuoteByAccessToken(widget.accessToken);
    if (_quote != null) {
      _property = widget.storage.properties[_quote!.propertyId];

      // Mark as viewed if first time
      if (_quote!.viewedAt == null) {
        _quote = _quote!.copyWith(viewedAt: DateTime.now().toIso8601String());
        widget.storage.quotes[_quote!.id] = _quote!;
        widget.storage.saveData();
      }
    }
    setState(() {});
  }

  void _showApprovalFlow() {
    if (_quote!.isExpired) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This quote has expired and can no longer be approved.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    setState(() => _showSignaturePad = true);
  }

  void _onSignatureComplete(String signature) {
    if (_quote!.isExpired) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This quote has expired and can no longer be approved.'),
          backgroundColor: Colors.orange,
        ),
      );
      setState(() => _showSignaturePad = false);
      return;
    }
    setState(() => _isProcessing = true);

    _quote = _quote!.copyWith(
      status: QuoteStatus.approved,
      clientSignature: signature,
      signedAt: DateTime.now().toIso8601String(),
      clientNotes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    widget.storage.quotes[_quote!.id] = _quote!;
    widget.storage.saveData();

    setState(() {
      _isProcessing = false;
      _showSignaturePad = false;
    });

    _showSuccessDialog();
  }

  void _rejectQuote() {
    if (_quote!.isExpired) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This quote has expired.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (context) {
        final reasonController = TextEditingController();
        return AlertDialog(
          title: const Text('Decline Quote'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Please let us know why you\'re declining this quote:'),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Reason for declining (optional)',
                  border: OutlineInputBorder(),
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
                _quote = _quote!.copyWith(
                  status: QuoteStatus.rejected,
                  clientNotes: reasonController.text.trim().isEmpty
                      ? 'Declined by client'
                      : reasonController.text.trim(),
                );
                widget.storage.quotes[_quote!.id] = _quote!;
                widget.storage.saveData();

                Navigator.pop(context);
                setState(() {});

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Quote has been declined'),
                    backgroundColor: Colors.red,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Decline Quote'),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade600, size: 32),
            const SizedBox(width: 12),
            const Text('Quote Approved!'),
          ],
        ),
        content: const Text(
          'Thank you for approving this quote. We will contact you shortly to schedule the repair work.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_quote == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quote')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              const Text(
                'Quote not found',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'This quote may have expired or been removed.',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    final isExpired = _quote!.isExpired;
    final isActionable = _quote!.status == QuoteStatus.sent ||
        _quote!.status == QuoteStatus.viewed;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: Column(
          children: [
            // Company Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              color: Theme.of(context).primaryColor,
              child: Column(
                children: [
                  const Icon(Icons.water_drop, size: 40, color: Colors.white),
                  const SizedBox(height: 8),
                  Text(
                    _quote!.companyName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Quote #${_quote!.id}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

            // Status Banner
            if (!isActionable || isExpired)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                color: isExpired
                    ? Colors.orange.shade100
                    : QuoteStatus.getColor(_quote!.status).withOpacity(0.1),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isExpired ? Icons.timer_off : QuoteStatus.getIcon(_quote!.status),
                      color: isExpired ? Colors.orange : QuoteStatus.getColor(_quote!.status),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isExpired
                          ? 'This quote has expired'
                          : 'Quote ${QuoteStatus.getDisplayName(_quote!.status)}',
                      style: TextStyle(
                        color: isExpired ? Colors.orange.shade900 : QuoteStatus.getColor(_quote!.status),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

            // Quote Content
            Expanded(
              child: _showSignaturePad
                  ? _buildSignatureSection()
                  : _buildQuoteContent(isActionable && !isExpired),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuoteContent(bool showActions) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Property Info
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Service Location',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _property?.address ?? 'Unknown',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Line Items
        Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Services & Materials',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(height: 1),
              ..._quote!.lineItems.map((item) => ListTile(
                    dense: true,
                    title: Text(item.displayDescription),
                    subtitle: item.zoneNumber != null
                        ? Text('Zone ${item.zoneNumber}')
                        : null,
                    trailing: Text(
                      '\$${item.totalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    leading: CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.grey.shade200,
                      child: Text(
                        '${item.quantity}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  )),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _totalRow('Subtotal', _quote!.materialsCost),
                    if (_quote!.laborCost > 0)
                      _totalRow('Labor', _quote!.laborCost),
                    if (_quote!.discount > 0)
                      _totalRow('Discount', -_quote!.discount),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'TOTAL',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '\$${_quote!.totalCost.toStringAsFixed(2)}',
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
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Expiration Notice
        if (_quote!.expiresAt != null && showActions)
          Card(
            color: _quote!.daysUntilExpiry <= 3
                ? Colors.orange.shade50
                : Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    Icons.timer,
                    color: _quote!.daysUntilExpiry <= 3
                        ? Colors.orange
                        : Colors.blue,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Quote valid for ${_quote!.daysUntilExpiry} more days',
                    style: TextStyle(
                      color: _quote!.daysUntilExpiry <= 3
                          ? Colors.orange.shade900
                          : Colors.blue.shade900,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Terms and Conditions
        ExpansionTile(
          title: const Text('Terms and Conditions'),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _quote!.termsAndConditions,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Contact Info
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Questions?',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (_quote!.companyPhone.isNotEmpty)
                  Row(
                    children: [
                      const Icon(Icons.phone, size: 18, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(_quote!.companyPhone),
                    ],
                  ),
                if (_quote!.companyEmail.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.email, size: 18, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(_quote!.companyEmail),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Action Buttons
        if (showActions) ...[
          ElevatedButton.icon(
            onPressed: _showApprovalFlow,
            icon: const Icon(Icons.check_circle),
            label: const Text('Approve & Sign Quote'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _rejectQuote,
            icon: const Icon(Icons.cancel),
            label: const Text('Decline Quote'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              foregroundColor: Colors.red,
            ),
          ),
        ],

        // Signature display for approved quotes
        if (_quote!.status == QuoteStatus.approved &&
            _quote!.clientSignature != null) ...[
          const SizedBox(height: 16),
          Card(
            color: Colors.green.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.verified, color: Colors.green.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Approved & Signed',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Center(
                      child: Text(
                        'Signature on file',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],

        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildSignatureSection() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Approve Quote',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Total: \$${_quote!.totalCost.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 24,
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'By signing below, you agree to the terms and conditions and authorize the work to be performed.',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Optional notes
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Additional Notes (Optional)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText: 'Any special requests or notes...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Signature Pad
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Signature',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                SignaturePad(
                  onSignatureComplete: _onSignatureComplete,
                  height: 200,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Back button
        TextButton.icon(
          onPressed: () => setState(() => _showSignaturePad = false),
          icon: const Icon(Icons.arrow_back),
          label: const Text('Back to Quote'),
        ),
      ],
    );
  }

  Widget _totalRow(String label, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Text(value < 0
              ? '-\$${(-value).toStringAsFixed(2)}'
              : '\$${value.toStringAsFixed(2)}'),
        ],
      ),
    );
  }
}
