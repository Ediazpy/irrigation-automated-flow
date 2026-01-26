class Zone {
  final int zoneNumber;
  final String description;
  final String headType;
  final int? headCount;

  Zone({
    required this.zoneNumber,
    required this.description,
    required this.headType,
    this.headCount,
  });

  Map<String, dynamic> toJson() {
    return {
      'zone_number': zoneNumber,
      'description': description,
      'head_type': headType,
      'head_count': headCount,
    };
  }

  factory Zone.fromJson(Map<String, dynamic> json) {
    return Zone(
      zoneNumber: json['zone_number'] ?? 0,
      description: json['description'] ?? '',
      headType: json['head_type'] ?? '',
      headCount: json['head_count'],
    );
  }

  Zone copyWith({
    int? zoneNumber,
    String? description,
    String? headType,
    int? headCount,
  }) {
    return Zone(
      zoneNumber: zoneNumber ?? this.zoneNumber,
      description: description ?? this.description,
      headType: headType ?? this.headType,
      headCount: headCount ?? this.headCount,
    );
  }
}
