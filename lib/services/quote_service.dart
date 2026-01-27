import 'dart:math';
import '../models/quote.dart';
import '../models/quote_line_item.dart';
import '../models/inspection.dart';
import '../models/property.dart';
import '../models/company_settings.dart';
import '../constants/status_constants.dart';

class QuoteService {
  /// Generate a unique access token for client quote URL
  static String generateAccessToken() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return List.generate(32, (index) => chars[random.nextInt(chars.length)]).join();
  }

  /// Create a quote from an inspection
  static Quote createFromInspection({
    required int quoteId,
    required Inspection inspection,
    required Property property,
    required CompanySettings settings,
  }) {
    // Convert inspection repairs to quote line items
    final lineItems = <QuoteLineItem>[];

    // Add zone repairs
    for (var repair in inspection.repairs) {
      lineItems.add(QuoteLineItem(
        description: repair.itemName,
        zoneNumber: repair.zoneNumber,
        quantity: repair.quantity,
        unitPrice: repair.price,
        category: 'materials',
        notes: repair.notes,
      ));
    }

    // Add other repairs
    for (var repair in inspection.otherRepairs) {
      lineItems.add(QuoteLineItem(
        description: repair.itemName,
        zoneNumber: null,
        quantity: repair.quantity,
        unitPrice: repair.price,
        category: 'materials',
        notes: repair.notes,
      ));
    }

    // Calculate expiration date
    final expiresAt = DateTime.now()
        .add(Duration(days: settings.quoteExpirationDays))
        .toIso8601String();

    return Quote(
      id: quoteId,
      inspectionId: inspection.id,
      propertyId: property.id,
      lineItems: lineItems,
      laborCost: inspection.laborCost,
      discount: inspection.discount,
      status: QuoteStatus.draft,
      accessToken: generateAccessToken(),
      termsAndConditions: settings.defaultTermsAndConditions,
      companyName: settings.companyName,
      companyPhone: settings.companyPhone,
      companyEmail: settings.companyEmail,
      createdAt: DateTime.now().toIso8601String(),
      expiresAt: expiresAt,
    );
  }

  /// Format quote for email/SMS message
  static String formatQuoteMessage({
    required Quote quote,
    required Property property,
    required String quoteUrl,
  }) {
    final buffer = StringBuffer();

    buffer.writeln('${quote.companyName}');
    buffer.writeln('');
    buffer.writeln('QUOTE #${quote.id}');
    buffer.writeln('Property: ${property.address}');
    buffer.writeln('');
    buffer.writeln('Total: \$${quote.totalCost.toStringAsFixed(2)}');
    buffer.writeln('');
    buffer.writeln('View and approve your quote:');
    buffer.writeln(quoteUrl);
    buffer.writeln('');
    buffer.writeln('This quote expires on ${_formatDate(quote.expiresAt)}');
    buffer.writeln('');
    buffer.writeln('Questions? Contact us:');
    if (quote.companyPhone.isNotEmpty) {
      buffer.writeln('Phone: ${quote.companyPhone}');
    }
    if (quote.companyEmail.isNotEmpty) {
      buffer.writeln('Email: ${quote.companyEmail}');
    }

    return buffer.toString();
  }

  /// Format short SMS message
  static String formatSmsMessage({
    required Quote quote,
    required Property property,
    required String quoteUrl,
  }) {
    return '${quote.companyName}: Quote #${quote.id} for ${property.address} - \$${quote.totalCost.toStringAsFixed(2)}. View & approve: $quoteUrl';
  }

  /// Generate a shareable quote URL
  /// In production, this would be a web URL. For now, we use a deep link format.
  static String generateQuoteUrl(String accessToken) {
    // In production, replace with actual web URL
    return 'irrigationflow://quote/$accessToken';
  }

  /// Check if quote is expired
  static bool isExpired(Quote quote) {
    if (quote.expiresAt == null) return false;
    final expiry = DateTime.tryParse(quote.expiresAt!);
    if (expiry == null) return false;
    return DateTime.now().isAfter(expiry);
  }

  /// Get days until expiry
  static int daysUntilExpiry(Quote quote) {
    if (quote.expiresAt == null) return -1;
    final expiry = DateTime.tryParse(quote.expiresAt!);
    if (expiry == null) return -1;
    final diff = expiry.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  /// Format date for display
  static String _formatDate(String? isoDate) {
    if (isoDate == null) return 'N/A';
    final date = DateTime.tryParse(isoDate);
    if (date == null) return 'N/A';
    return '${date.month}/${date.day}/${date.year}';
  }

  /// Format date/time for display
  static String formatDateTime(String? isoDate) {
    if (isoDate == null) return 'N/A';
    final date = DateTime.tryParse(isoDate);
    if (date == null) return 'N/A';
    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final amPm = date.hour >= 12 ? 'PM' : 'AM';
    return '${date.month}/${date.day}/${date.year} $hour:${date.minute.toString().padLeft(2, '0')} $amPm';
  }

  /// Get quote status display info
  static Map<String, dynamic> getStatusInfo(String status) {
    return {
      'color': QuoteStatus.getColor(status),
      'icon': QuoteStatus.getIcon(status),
      'name': QuoteStatus.getDisplayName(status),
    };
  }
}
