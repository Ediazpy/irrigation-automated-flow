import 'repair.dart';

class RepairTask {
  final int id;
  final int quoteId;
  final int propertyId;
  final List<Repair> repairs;
  final List<String> assignedTechnicians;
  final String scheduledDate;
  final String status;
  final String? completedAt;
  final String? completionNotes;
  final double estimatedHours;
  final String priority;
  final String? technicianNotes;
  final String createdAt;

  RepairTask({
    required this.id,
    required this.quoteId,
    required this.propertyId,
    required this.repairs,
    required this.assignedTechnicians,
    required this.scheduledDate,
    required this.status,
    this.completedAt,
    this.completionNotes,
    this.estimatedHours = 1.0,
    this.priority = 'normal',
    this.technicianNotes,
    required this.createdAt,
  });

  int get totalRepairItems {
    return repairs.fold(0, (sum, repair) => sum + repair.quantity);
  }

  Map<String, dynamic> toJson() {
    return {
      'quote_id': quoteId,
      'property_id': propertyId,
      'repairs': repairs.map((r) => r.toJson()).toList(),
      'assigned_technicians': assignedTechnicians,
      'scheduled_date': scheduledDate,
      'status': status,
      'completed_at': completedAt,
      'completion_notes': completionNotes,
      'estimated_hours': estimatedHours,
      'priority': priority,
      'technician_notes': technicianNotes,
      'created_at': createdAt,
    };
  }

  factory RepairTask.fromJson(int id, Map<String, dynamic> json) {
    return RepairTask(
      id: id,
      quoteId: json['quote_id'] ?? 0,
      propertyId: json['property_id'] ?? 0,
      repairs: (json['repairs'] as List<dynamic>?)
              ?.map((r) => Repair.fromJson(r as Map<String, dynamic>))
              .toList() ??
          [],
      assignedTechnicians: (json['assigned_technicians'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      scheduledDate: json['scheduled_date'] ?? '',
      status: json['status'] ?? 'pending',
      completedAt: json['completed_at'],
      completionNotes: json['completion_notes'],
      estimatedHours: (json['estimated_hours'] ?? 1.0).toDouble(),
      priority: json['priority'] ?? 'normal',
      technicianNotes: json['technician_notes'],
      createdAt: json['created_at'] ?? DateTime.now().toIso8601String(),
    );
  }

  RepairTask copyWith({
    int? id,
    int? quoteId,
    int? propertyId,
    List<Repair>? repairs,
    List<String>? assignedTechnicians,
    String? scheduledDate,
    String? status,
    String? completedAt,
    String? completionNotes,
    double? estimatedHours,
    String? priority,
    String? technicianNotes,
    String? createdAt,
  }) {
    return RepairTask(
      id: id ?? this.id,
      quoteId: quoteId ?? this.quoteId,
      propertyId: propertyId ?? this.propertyId,
      repairs: repairs ?? this.repairs,
      assignedTechnicians: assignedTechnicians ?? this.assignedTechnicians,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      status: status ?? this.status,
      completedAt: completedAt ?? this.completedAt,
      completionNotes: completionNotes ?? this.completionNotes,
      estimatedHours: estimatedHours ?? this.estimatedHours,
      priority: priority ?? this.priority,
      technicianNotes: technicianNotes ?? this.technicianNotes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
