class Repair {
  final int zoneNumber;
  final String itemName;
  final int quantity;
  final double price;
  final String notes;

  Repair({
    required this.zoneNumber,
    required this.itemName,
    required this.quantity,
    required this.price,
    this.notes = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'zone_number': zoneNumber,
      'item_name': itemName,
      'quantity': quantity,
      'price': price,
      'notes': notes,
    };
  }

  factory Repair.fromJson(Map<String, dynamic> json) {
    return Repair(
      zoneNumber: json['zone_number'] ?? 0,
      itemName: json['item_name'] ?? '',
      quantity: json['quantity'] ?? 1,
      price: (json['price'] ?? 0.0).toDouble(),
      notes: json['notes'] ?? '',
    );
  }

  double get totalCost => quantity * price;

  Repair copyWith({
    int? zoneNumber,
    String? itemName,
    int? quantity,
    double? price,
    String? notes,
  }) {
    return Repair(
      zoneNumber: zoneNumber ?? this.zoneNumber,
      itemName: itemName ?? this.itemName,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      notes: notes ?? this.notes,
    );
  }
}
