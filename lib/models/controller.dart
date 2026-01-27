import 'zone.dart';

class Controller {
  final int controllerNumber;
  final String location;
  final String model;
  final String notes;
  final List<Zone> zones;

  Controller({
    required this.controllerNumber,
    this.location = '',
    this.model = '',
    this.notes = '',
    required this.zones,
  });

  Map<String, dynamic> toJson() {
    return {
      'controller_number': controllerNumber,
      'location': location,
      'model': model,
      'notes': notes,
      'zones': zones.map((z) => z.toJson()).toList(),
    };
  }

  factory Controller.fromJson(Map<String, dynamic> json) {
    List<Zone> zonesList = [];
    if (json['zones'] != null) {
      zonesList = (json['zones'] as List)
          .map((z) => Zone.fromJson(z as Map<String, dynamic>))
          .toList();
    }

    return Controller(
      controllerNumber: json['controller_number'] ?? 1,
      location: json['location'] ?? '',
      model: json['model'] ?? '',
      notes: json['notes'] ?? '',
      zones: zonesList,
    );
  }

  Controller copyWith({
    int? controllerNumber,
    String? location,
    String? model,
    String? notes,
    List<Zone>? zones,
  }) {
    return Controller(
      controllerNumber: controllerNumber ?? this.controllerNumber,
      location: location ?? this.location,
      model: model ?? this.model,
      notes: notes ?? this.notes,
      zones: zones ?? this.zones,
    );
  }
}
