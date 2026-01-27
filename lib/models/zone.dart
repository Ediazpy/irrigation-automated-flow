class Zone {
  final int zoneNumber;
  final String description;
  final String headType;
  final int? headCount;
  final int controllerNumber; // Which controller this zone belongs to

  Zone({
    required this.zoneNumber,
    required this.description,
    required this.headType,
    this.headCount,
    this.controllerNumber = 1, // Default to controller 1 for backward compatibility
  });

  /// Display name showing controller number if multi-controller
  String getDisplayName({bool showController = false}) {
    if (showController && controllerNumber > 0) {
      return 'C$controllerNumber-Z$zoneNumber: $description';
    }
    return 'Zone $zoneNumber: $description';
  }

  Map<String, dynamic> toJson() {
    return {
      'zone_number': zoneNumber,
      'description': description,
      'head_type': headType,
      'head_count': headCount,
      'controller_number': controllerNumber,
    };
  }

  factory Zone.fromJson(Map<String, dynamic> json) {
    return Zone(
      zoneNumber: json['zone_number'] ?? 0,
      description: json['description'] ?? '',
      headType: json['head_type'] ?? '',
      headCount: json['head_count'],
      controllerNumber: json['controller_number'] ?? 1,
    );
  }

  Zone copyWith({
    int? zoneNumber,
    String? description,
    String? headType,
    int? headCount,
    int? controllerNumber,
  }) {
    return Zone(
      zoneNumber: zoneNumber ?? this.zoneNumber,
      description: description ?? this.description,
      headType: headType ?? this.headType,
      headCount: headCount ?? this.headCount,
      controllerNumber: controllerNumber ?? this.controllerNumber,
    );
  }
}
