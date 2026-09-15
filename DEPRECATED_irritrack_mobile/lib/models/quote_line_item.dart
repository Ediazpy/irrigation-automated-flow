class QuoteLineItem {
  final String description;
  final int? zoneNumber;
  final int quantity;
  final double unitPrice;
  final String category;
  final String? notes;

  QuoteLineItem({
    required this.description,
    this.zoneNumber,
    required this.quantity,
    required this.unitPrice,
    required this.category,
    this.notes,
  });

  double get totalPrice => quantity * unitPrice;

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'zone_number': zoneNumber,
      'quantity': quantity,
      'unit_price': unitPrice,
      'category': category,
      'notes': notes,
    };
  }

  factory QuoteLineItem.fromJson(Map<String, dynamic> json) {
    return QuoteLineItem(
      description: json['description'] ?? '',
      zoneNumber: json['zone_number'],
      quantity: json['quantity'] ?? 0,
      unitPrice: (json['unit_price'] ?? 0.0).toDouble(),
      category: json['category'] ?? '',
      notes: json['notes'],
    );
  }

  QuoteLineItem copyWith({
    String? description,
    int? zoneNumber,
    int? quantity,
    double? unitPrice,
    String? category,
    String? notes,
  }) {
    return QuoteLineItem(
      description: description ?? this.description,
      zoneNumber: zoneNumber ?? this.zoneNumber,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      category: category ?? this.category,
      notes: notes ?? this.notes,
    );
  }

  /// Format description for display (convert snake_case to Title Case)
  String get displayDescription {
    return description
        .split('_')
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1)}'
            : '')
        .join(' ');
  }
}
