import 'repair.dart';

class Inspection {
  final int id;
  final int propertyId;
  final List<String> technicians; // Changed to list for multi-tech support
  final String date;
  final String status; // 'assigned', 'in_progress', 'review', 'completed'
  final List<Repair> repairs;
  final List<Repair> otherRepairs;
  final String otherNotes;
  final double totalCost;
  final String billingMonth; // Format: "2025-01" for January 2025
  final double laborCost; // Additional labor charges
  final double discount; // Discount amount
  final Map<int, List<String>> zonePhotos; // Zone number -> list of base64 photos (0 = general)

  Inspection({
    required this.id,
    required this.propertyId,
    required this.technicians,
    required this.date,
    required this.status,
    required this.repairs,
    List<Repair>? otherRepairs,
    this.otherNotes = '',
    required this.totalCost,
    this.billingMonth = '',
    this.laborCost = 0.0,
    this.discount = 0.0,
    Map<int, List<String>>? zonePhotos,
  })  : otherRepairs = otherRepairs ?? [],
        zonePhotos = zonePhotos ?? {};

  // Legacy getter for backwards compatibility with old photos field
  List<String> get photos {
    final all = <String>[];
    for (var photoList in zonePhotos.values) {
      all.addAll(photoList);
    }
    return all;
  }

  // Get photos for a specific zone
  List<String> getZonePhotos(int zoneNumber) {
    return zonePhotos[zoneNumber] ?? [];
  }

  // Get total photo count
  int get totalPhotoCount {
    return zonePhotos.values.fold(0, (sum, list) => sum + list.length);
  }

  // Legacy getter for backwards compatibility
  String get technician => technicians.isNotEmpty ? technicians.first : '';

  Map<String, dynamic> toJson() {
    return {
      'property_id': propertyId,
      'technicians': technicians,
      'date': date,
      'status': status,
      'repairs': repairs.map((r) => r.toJson()).toList(),
      'other_repairs': otherRepairs.map((r) => r.toJson()).toList(),
      'other_notes': otherNotes,
      'total_cost': totalCost,
      'billing_month': billingMonth,
      'labor_cost': laborCost,
      'discount': discount,
      'zone_photos': zonePhotos.map((key, value) => MapEntry(key.toString(), value)),
    };
  }

  factory Inspection.fromJson(int id, Map<String, dynamic> json) {
    List<Repair> repairsList = [];
    if (json['repairs'] != null) {
      repairsList = (json['repairs'] as List)
          .map((r) => Repair.fromJson(r as Map<String, dynamic>))
          .toList();
    }

    List<Repair> otherRepairsList = [];
    if (json['other_repairs'] != null) {
      otherRepairsList = (json['other_repairs'] as List)
          .map((r) => Repair.fromJson(r as Map<String, dynamic>))
          .toList();
    }

    // Handle both old single technician and new multi-tech format
    List<String> techList = [];
    if (json['technicians'] != null) {
      techList = List<String>.from(json['technicians']);
    } else if (json['technician'] != null) {
      // Backwards compatibility with old format
      techList = [json['technician'] as String];
    }

    return Inspection(
      id: id,
      propertyId: json['property_id'] ?? 0,
      technicians: techList,
      date: json['date'] ?? '',
      status: json['status'] ?? 'assigned',
      repairs: repairsList,
      otherRepairs: otherRepairsList,
      otherNotes: json['other_notes'] ?? '',
      totalCost: (json['total_cost'] ?? 0.0).toDouble(),
      billingMonth: json['billing_month'] ?? '',
      laborCost: (json['labor_cost'] ?? 0.0).toDouble(),
      discount: (json['discount'] ?? 0.0).toDouble(),
      zonePhotos: _parseZonePhotos(json),
    );
  }

  static Map<int, List<String>> _parseZonePhotos(Map<String, dynamic> json) {
    final result = <int, List<String>>{};

    // Handle new zone_photos format
    if (json['zone_photos'] != null) {
      (json['zone_photos'] as Map<String, dynamic>).forEach((key, value) {
        result[int.parse(key)] = List<String>.from(value);
      });
    }
    // Backwards compatibility: migrate old photos list to zone 0
    else if (json['photos'] != null && (json['photos'] as List).isNotEmpty) {
      result[0] = List<String>.from(json['photos']);
    }

    return result;
  }

  double calculateTotalCost() {
    double total = repairs.fold(0.0, (sum, repair) => sum + repair.totalCost);
    total += otherRepairs.fold(0.0, (sum, repair) => sum + repair.totalCost);
    return total;
  }

  Inspection copyWith({
    int? id,
    int? propertyId,
    List<String>? technicians,
    String? date,
    String? status,
    List<Repair>? repairs,
    List<Repair>? otherRepairs,
    String? otherNotes,
    double? totalCost,
    String? billingMonth,
    double? laborCost,
    double? discount,
    Map<int, List<String>>? zonePhotos,
  }) {
    return Inspection(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      technicians: technicians ?? this.technicians,
      date: date ?? this.date,
      status: status ?? this.status,
      repairs: repairs ?? this.repairs,
      otherRepairs: otherRepairs ?? this.otherRepairs,
      otherNotes: otherNotes ?? this.otherNotes,
      totalCost: totalCost ?? this.totalCost,
      billingMonth: billingMonth ?? this.billingMonth,
      laborCost: laborCost ?? this.laborCost,
      discount: discount ?? this.discount,
      zonePhotos: zonePhotos ?? this.zonePhotos,
    );
  }

  /// Add a photo to a specific zone
  Inspection addPhotoToZone(int zoneNumber, String base64Photo) {
    final updatedPhotos = Map<int, List<String>>.from(zonePhotos);
    if (!updatedPhotos.containsKey(zoneNumber)) {
      updatedPhotos[zoneNumber] = [];
    }
    updatedPhotos[zoneNumber] = [...updatedPhotos[zoneNumber]!, base64Photo];
    return copyWith(zonePhotos: updatedPhotos);
  }

  /// Remove a photo from a specific zone
  Inspection removePhotoFromZone(int zoneNumber, int photoIndex) {
    final updatedPhotos = Map<int, List<String>>.from(zonePhotos);
    if (updatedPhotos.containsKey(zoneNumber)) {
      final photos = List<String>.from(updatedPhotos[zoneNumber]!);
      if (photoIndex >= 0 && photoIndex < photos.length) {
        photos.removeAt(photoIndex);
        updatedPhotos[zoneNumber] = photos;
      }
    }
    return copyWith(zonePhotos: updatedPhotos);
  }
}
