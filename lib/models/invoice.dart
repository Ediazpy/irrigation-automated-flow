import 'quote_line_item.dart';

class Invoice {
  final int id;
  final int? quoteId;
  final int? inspectionId;
  final int propertyId;
  final int clientId;
  final List<QuoteLineItem> lineItems;
  final double laborCost;
  final double discount;
  final double tax;
  final String status; // draft, sent, viewed, paid, partial, overdue, void
  final String? sentAt;
  final String? paidAt;
  final String? dueDate;
  final double amountPaid;
  final String paymentMethod; // cash, check, credit_card, bank_transfer, other
  final String? paymentNotes;
  final String companyName;
  final String companyPhone;
  final String companyEmail;
  final String createdAt;
  final String? notes;

  Invoice({
    required this.id,
    this.quoteId,
    this.inspectionId,
    required this.propertyId,
    required this.clientId,
    required this.lineItems,
    this.laborCost = 0.0,
    this.discount = 0.0,
    this.tax = 0.0,
    required this.status,
    this.sentAt,
    this.paidAt,
    this.dueDate,
    this.amountPaid = 0.0,
    this.paymentMethod = '',
    this.paymentNotes,
    required this.companyName,
    required this.companyPhone,
    required this.companyEmail,
    required this.createdAt,
    this.notes,
  });

  double get materialsCost =>
      lineItems.fold(0.0, (sum, item) => sum + item.totalPrice);

  double get subtotal => materialsCost + laborCost;

  double get totalCost {
    final total = subtotal - discount + tax;
    return total < 0 ? 0.0 : total;
  }

  double get balanceDue => totalCost - amountPaid;

  bool get isFullyPaid => amountPaid >= totalCost && totalCost > 0;

  bool get isOverdue {
    if (dueDate == null || status == 'paid' || status == 'void') return false;
    final due = DateTime.tryParse(dueDate!);
    if (due == null) return false;
    return DateTime.now().isAfter(due);
  }

  int get daysPastDue {
    if (dueDate == null) return 0;
    final due = DateTime.tryParse(dueDate!);
    if (due == null) return 0;
    final diff = DateTime.now().difference(due).inDays;
    return diff > 0 ? diff : 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'quote_id': quoteId,
      'inspection_id': inspectionId,
      'property_id': propertyId,
      'client_id': clientId,
      'line_items': lineItems.map((item) => item.toJson()).toList(),
      'labor_cost': laborCost,
      'discount': discount,
      'tax': tax,
      'status': status,
      'sent_at': sentAt,
      'paid_at': paidAt,
      'due_date': dueDate,
      'amount_paid': amountPaid,
      'payment_method': paymentMethod,
      'payment_notes': paymentNotes,
      'company_name': companyName,
      'company_phone': companyPhone,
      'company_email': companyEmail,
      'created_at': createdAt,
      'notes': notes,
    };
  }

  factory Invoice.fromJson(int id, Map<String, dynamic> json) {
    return Invoice(
      id: id,
      quoteId: json['quote_id'],
      inspectionId: json['inspection_id'],
      propertyId: json['property_id'] ?? 0,
      clientId: json['client_id'] ?? 0,
      lineItems: (json['line_items'] as List<dynamic>?)
              ?.map((item) => QuoteLineItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      laborCost: (json['labor_cost'] ?? 0.0).toDouble(),
      discount: (json['discount'] ?? 0.0).toDouble(),
      tax: (json['tax'] ?? 0.0).toDouble(),
      status: json['status'] ?? 'draft',
      sentAt: json['sent_at'],
      paidAt: json['paid_at'],
      dueDate: json['due_date'],
      amountPaid: (json['amount_paid'] ?? 0.0).toDouble(),
      paymentMethod: json['payment_method'] ?? '',
      paymentNotes: json['payment_notes'],
      companyName: json['company_name'] ?? '',
      companyPhone: json['company_phone'] ?? '',
      companyEmail: json['company_email'] ?? '',
      createdAt: json['created_at'] ?? DateTime.now().toIso8601String(),
      notes: json['notes'],
    );
  }

  Invoice copyWith({
    int? id,
    int? quoteId,
    int? inspectionId,
    int? propertyId,
    int? clientId,
    List<QuoteLineItem>? lineItems,
    double? laborCost,
    double? discount,
    double? tax,
    String? status,
    String? sentAt,
    String? paidAt,
    String? dueDate,
    double? amountPaid,
    String? paymentMethod,
    String? paymentNotes,
    String? companyName,
    String? companyPhone,
    String? companyEmail,
    String? createdAt,
    String? notes,
  }) {
    return Invoice(
      id: id ?? this.id,
      quoteId: quoteId ?? this.quoteId,
      inspectionId: inspectionId ?? this.inspectionId,
      propertyId: propertyId ?? this.propertyId,
      clientId: clientId ?? this.clientId,
      lineItems: lineItems ?? this.lineItems,
      laborCost: laborCost ?? this.laborCost,
      discount: discount ?? this.discount,
      tax: tax ?? this.tax,
      status: status ?? this.status,
      sentAt: sentAt ?? this.sentAt,
      paidAt: paidAt ?? this.paidAt,
      dueDate: dueDate ?? this.dueDate,
      amountPaid: amountPaid ?? this.amountPaid,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentNotes: paymentNotes ?? this.paymentNotes,
      companyName: companyName ?? this.companyName,
      companyPhone: companyPhone ?? this.companyPhone,
      companyEmail: companyEmail ?? this.companyEmail,
      createdAt: createdAt ?? this.createdAt,
      notes: notes ?? this.notes,
    );
  }
}

class InvoiceStatus {
  static const String draft = 'draft';
  static const String sent = 'sent';
  static const String viewed = 'viewed';
  static const String paid = 'paid';
  static const String partial = 'partial';
  static const String overdue = 'overdue';
  static const String voided = 'void';

  static String getDisplayName(String status) {
    switch (status) {
      case draft: return 'Draft';
      case sent: return 'Sent';
      case viewed: return 'Viewed';
      case paid: return 'Paid';
      case partial: return 'Partial';
      case overdue: return 'Overdue';
      case voided: return 'Void';
      default: return status;
    }
  }
}
