class Zone {
  final int zoneNumber;
  final String description;
  final String headType;
  final int? headCount;
  final int controllerNumber; // Which controller this zone belongs to

  // Scheduling fields
  final int? runTimeMinutes; // How long this zone runs in minutes
  final String? program; // Program letter (A, B, C, D, etc.)
  final List<String> daysOfWeek; // Days zone runs: ['Mon', 'Tue', 'Wed', etc.]

  Zone({
    required this.zoneNumber,
    required this.description,
    required this.headType,
    this.headCount,
    this.controllerNumber = 1, // Default to controller 1 for backward compatibility
    this.runTimeMinutes,
    this.program,
    this.daysOfWeek = const [],
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
      'run_time_minutes': runTimeMinutes,
      'program': program,
      'days_of_week': daysOfWeek,
    };
  }

  factory Zone.fromJson(Map<String, dynamic> json) {
    return Zone(
      zoneNumber: json['zone_number'] ?? 0,
      description: json['description'] ?? '',
      headType: json['head_type'] ?? '',
      headCount: json['head_count'],
      controllerNumber: json['controller_number'] ?? 1,
      runTimeMinutes: json['run_time_minutes'],
      program: json['program'],
      daysOfWeek: json['days_of_week'] != null
          ? List<String>.from(json['days_of_week'])
          : [],
    );
  }

  Zone copyWith({
    int? zoneNumber,
    String? description,
    String? headType,
    int? headCount,
    int? controllerNumber,
    int? runTimeMinutes,
    String? program,
    List<String>? daysOfWeek,
  }) {
    return Zone(
      zoneNumber: zoneNumber ?? this.zoneNumber,
      description: description ?? this.description,
      headType: headType ?? this.headType,
      headCount: headCount ?? this.headCount,
      controllerNumber: controllerNumber ?? this.controllerNumber,
      runTimeMinutes: runTimeMinutes ?? this.runTimeMinutes,
      program: program ?? this.program,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
    );
  }

  /// Get formatted run time display string
  String get runTimeDisplay {
    if (runTimeMinutes == null || runTimeMinutes == 0) return '';
    return '$runTimeMinutes min';
  }

  /// Get formatted schedule display string
  String get scheduleDisplay {
    final parts = <String>[];
    if (program != null && program!.isNotEmpty) {
      parts.add('Pgm $program');
    }
    if (daysOfWeek.isNotEmpty) {
      parts.add(daysOfWeek.join(', '));
    }
    if (runTimeMinutes != null && runTimeMinutes! > 0) {
      parts.add('$runTimeMinutes min');
    }
    return parts.isEmpty ? '' : parts.join(' • ');
  }
}
