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
  }) : otherRepairs = otherRepairs ?? [];

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
    );
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
    );
  }
}
