class RepairItem {
  final String name;
  final double price;
  final String category;
  final bool requiresNotes;

  RepairItem({
    required this.name,
    required this.price,
    required this.category,
    required this.requiresNotes,
  });

  Map<String, dynamic> toJson() {
    return {
      'price': price,
      'category': category,
      'requires_notes': requiresNotes,
    };
  }

  factory RepairItem.fromJson(String name, Map<String, dynamic> json) {
    return RepairItem(
      name: name,
      price: (json['price'] ?? 0.0).toDouble(),
      category: json['category'] ?? '',
      requiresNotes: json['requires_notes'] ?? false,
    );
  }

  RepairItem copyWith({
    String? name,
    double? price,
    String? category,
    bool? requiresNotes,
  }) {
    return RepairItem(
      name: name ?? this.name,
      price: price ?? this.price,
      category: category ?? this.category,
      requiresNotes: requiresNotes ?? this.requiresNotes,
    );
  }
}
