import 'quote_line_item.dart';

class Quote {
  final int id;
  final int inspectionId;
  final int propertyId;
  final List<QuoteLineItem> lineItems;
  final double laborCost;
  final double discount;
  final String status;
  final String? clientSignature; // Base64 encoded signature image
  final String? signedAt;
  final String? sentAt;
  final String? expiresAt;
  final String? viewedAt;
  final String? clientNotes;
  final String accessToken;
  final String termsAndConditions;
  final String companyName;
  final String companyPhone;
  final String companyEmail;
  final String createdAt;

  Quote({
    required this.id,
    required this.inspectionId,
    required this.propertyId,
    required this.lineItems,
    this.laborCost = 0.0,
    this.discount = 0.0,
    required this.status,
    this.clientSignature,
    this.signedAt,
    this.sentAt,
    this.expiresAt,
    this.viewedAt,
    this.clientNotes,
    required this.accessToken,
    required this.termsAndConditions,
    required this.companyName,
    required this.companyPhone,
    required this.companyEmail,
    required this.createdAt,
  });

  double get materialsCost {
    return lineItems.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  double get subtotal => materialsCost + laborCost;

  double get totalCost => subtotal - discount;

  bool get isExpired {
    if (expiresAt == null) return false;
    final expiry = DateTime.tryParse(expiresAt!);
    if (expiry == null) return false;
    return DateTime.now().isAfter(expiry);
  }

  int get daysUntilExpiry {
    if (expiresAt == null) return -1;
    final expiry = DateTime.tryParse(expiresAt!);
    if (expiry == null) return -1;
    return expiry.difference(DateTime.now()).inDays;
  }

  Map<String, dynamic> toJson() {
    return {
      'inspection_id': inspectionId,
      'property_id': propertyId,
      'line_items': lineItems.map((item) => item.toJson()).toList(),
      'labor_cost': laborCost,
      'discount': discount,
      'status': status,
      'client_signature': clientSignature,
      'signed_at': signedAt,
      'sent_at': sentAt,
      'expires_at': expiresAt,
      'viewed_at': viewedAt,
      'client_notes': clientNotes,
      'access_token': accessToken,
      'terms_and_conditions': termsAndConditions,
      'company_name': companyName,
      'company_phone': companyPhone,
      'company_email': companyEmail,
      'created_at': createdAt,
    };
  }

  factory Quote.fromJson(int id, Map<String, dynamic> json) {
    return Quote(
      id: id,
      inspectionId: json['inspection_id'] ?? 0,
      propertyId: json['property_id'] ?? 0,
      lineItems: (json['line_items'] as List<dynamic>?)
              ?.map((item) => QuoteLineItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      laborCost: (json['labor_cost'] ?? 0.0).toDouble(),
      discount: (json['discount'] ?? 0.0).toDouble(),
      status: json['status'] ?? 'draft',
      clientSignature: json['client_signature'],
      signedAt: json['signed_at'],
      sentAt: json['sent_at'],
      expiresAt: json['expires_at'],
      viewedAt: json['viewed_at'],
      clientNotes: json['client_notes'],
      accessToken: json['access_token'] ?? '',
      termsAndConditions: json['terms_and_conditions'] ?? '',
      companyName: json['company_name'] ?? '',
      companyPhone: json['company_phone'] ?? '',
      companyEmail: json['company_email'] ?? '',
      createdAt: json['created_at'] ?? DateTime.now().toIso8601String(),
    );
  }

  Quote copyWith({
    int? id,
    int? inspectionId,
    int? propertyId,
    List<QuoteLineItem>? lineItems,
    double? laborCost,
    double? discount,
    String? status,
    String? clientSignature,
    String? signedAt,
    String? sentAt,
    String? expiresAt,
    String? viewedAt,
    String? clientNotes,
    String? accessToken,
    String? termsAndConditions,
    String? companyName,
    String? companyPhone,
    String? companyEmail,
    String? createdAt,
  }) {
    return Quote(
      id: id ?? this.id,
      inspectionId: inspectionId ?? this.inspectionId,
      propertyId: propertyId ?? this.propertyId,
      lineItems: lineItems ?? this.lineItems,
      laborCost: laborCost ?? this.laborCost,
      discount: discount ?? this.discount,
      status: status ?? this.status,
      clientSignature: clientSignature ?? this.clientSignature,
      signedAt: signedAt ?? this.signedAt,
      sentAt: sentAt ?? this.sentAt,
      expiresAt: expiresAt ?? this.expiresAt,
      viewedAt: viewedAt ?? this.viewedAt,
      clientNotes: clientNotes ?? this.clientNotes,
      accessToken: accessToken ?? this.accessToken,
      termsAndConditions: termsAndConditions ?? this.termsAndConditions,
      companyName: companyName ?? this.companyName,
      companyPhone: companyPhone ?? this.companyPhone,
      companyEmail: companyEmail ?? this.companyEmail,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
