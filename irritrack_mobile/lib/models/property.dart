import 'zone.dart';
import 'controller.dart';

class Property {
  final int id;
  final String address;
  final String meterLocation;
  final String backflowLocation;
  final String backflowSize;
  final String backflowSerial;
  final int numControllers;
  final String controllerLocation; // Legacy field - kept for backward compatibility
  final List<Zone> zones; // Legacy field - all zones combined
  final List<Controller> controllers; // New: separate controllers with their zones

  // New fields for workflow improvements
  final String notes; // Gate codes, special instructions, problem areas
  final int billingCycleDay; // Day of month billing cycle starts (1-28)
  final String clientName;
  final String clientEmail;
  final String clientPhone;
  final String initialRepairNotes; // Optional notes about known repairs needed

  Property({
    required this.id,
    required this.address,
    required this.meterLocation,
    required this.backflowLocation,
    required this.backflowSize,
    required this.backflowSerial,
    required this.numControllers,
    required this.controllerLocation,
    required this.zones,
    this.controllers = const [],
    this.notes = '',
    this.billingCycleDay = 1,
    this.clientName = '',
    this.clientEmail = '',
    this.clientPhone = '',
    this.initialRepairNotes = '',
  });

  /// Get all zones from all controllers (combined view)
  List<Zone> get allZones {
    if (controllers.isEmpty) {
      return zones; // Fallback to legacy zones
    }
    final allZonesList = <Zone>[];
    for (var controller in controllers) {
      allZonesList.addAll(controller.zones);
    }
    return allZonesList.isEmpty ? zones : allZonesList;
  }

  /// Check if property uses multi-controller setup
  bool get hasMultipleControllers => controllers.length > 1;

  /// Get zones for a specific controller number
  List<Zone> getZonesForController(int controllerNumber) {
    final controller = controllers.firstWhere(
      (c) => c.controllerNumber == controllerNumber,
      orElse: () => Controller(controllerNumber: controllerNumber, zones: []),
    );
    return controller.zones;
  }

  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'meter_location': meterLocation,
      'backflow_location': backflowLocation,
      'backflow_size': backflowSize,
      'backflow_serial': backflowSerial,
      'num_controllers': numControllers,
      'controller_location': controllerLocation,
      'zones': zones.map((z) => z.toJson()).toList(),
      'controllers': controllers.map((c) => c.toJson()).toList(),
      'notes': notes,
      'billing_cycle_day': billingCycleDay,
      'client_name': clientName,
      'client_email': clientEmail,
      'client_phone': clientPhone,
      'initial_repair_notes': initialRepairNotes,
    };
  }

  factory Property.fromJson(int id, Map<String, dynamic> json) {
    List<Zone> zonesList = [];
    if (json['zones'] != null) {
      zonesList = (json['zones'] as List)
          .map((z) => Zone.fromJson(z as Map<String, dynamic>))
          .toList();
    }

    List<Controller> controllersList = [];
    if (json['controllers'] != null) {
      controllersList = (json['controllers'] as List)
          .map((c) => Controller.fromJson(c as Map<String, dynamic>))
          .toList();
    }

    return Property(
      id: id,
      address: json['address'] ?? '',
      meterLocation: json['meter_location'] ?? '',
      backflowLocation: json['backflow_location'] ?? '',
      backflowSize: json['backflow_size'] ?? '',
      backflowSerial: json['backflow_serial'] ?? '',
      numControllers: json['num_controllers'] ?? 0,
      controllerLocation: json['controller_location'] ?? '',
      zones: zonesList,
      controllers: controllersList,
      notes: json['notes'] ?? '',
      billingCycleDay: json['billing_cycle_day'] ?? 1,
      clientName: json['client_name'] ?? '',
      clientEmail: json['client_email'] ?? '',
      clientPhone: json['client_phone'] ?? '',
      initialRepairNotes: json['initial_repair_notes'] ?? '',
    );
  }

  Property copyWith({
    int? id,
    String? address,
    String? meterLocation,
    String? backflowLocation,
    String? backflowSize,
    String? backflowSerial,
    int? numControllers,
    String? controllerLocation,
    List<Zone>? zones,
    List<Controller>? controllers,
    String? notes,
    int? billingCycleDay,
    String? clientName,
    String? clientEmail,
    String? clientPhone,
    String? initialRepairNotes,
  }) {
    return Property(
      id: id ?? this.id,
      address: address ?? this.address,
      meterLocation: meterLocation ?? this.meterLocation,
      backflowLocation: backflowLocation ?? this.backflowLocation,
      backflowSize: backflowSize ?? this.backflowSize,
      backflowSerial: backflowSerial ?? this.backflowSerial,
      numControllers: numControllers ?? this.numControllers,
      controllerLocation: controllerLocation ?? this.controllerLocation,
      zones: zones ?? this.zones,
      controllers: controllers ?? this.controllers,
      notes: notes ?? this.notes,
      billingCycleDay: billingCycleDay ?? this.billingCycleDay,
      clientName: clientName ?? this.clientName,
      clientEmail: clientEmail ?? this.clientEmail,
      clientPhone: clientPhone ?? this.clientPhone,
      initialRepairNotes: initialRepairNotes ?? this.initialRepairNotes,
    );
  }
}
