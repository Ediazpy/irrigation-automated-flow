import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/property.dart';
import '../models/inspection.dart';
import '../models/repair_item.dart';
import '../models/quote.dart';
import '../models/repair_task.dart';
import '../models/company_settings.dart';
import 'firestore_service.dart';

// Conditional import for file operations (not available on web)
import 'storage_io.dart' if (dart.library.html) 'storage_web.dart' as storage_impl;

class StorageService {
  static const String _storageKey = 'irritrack_data';
  static const String _syncKey = 'irritrack_firestore_sync';

  Map<String, User> users = {};
  Map<int, Property> properties = {};
  Map<int, Inspection> inspections = {};
  Map<String, RepairItem> repairItems = {};
  Map<String, int> failedAttempts = {};
  Map<int, Quote> quotes = {};
  Map<int, RepairTask> repairTasks = {};
  CompanySettings? companySettings;

  int nextPropertyId = 1;
  int nextInspectionId = 1;
  int nextQuoteId = 1;
  int nextRepairTaskId = 1;

  // Firestore sync - enabled by default (auto-sync)
  bool _firestoreSyncEnabled = true; // Default to true for automatic sync
  final FirestoreService _firestoreService = FirestoreService();

  bool get firestoreSyncEnabled => _firestoreSyncEnabled;

  Future<void> enableFirestoreSync() async {
    _firestoreSyncEnabled = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_syncKey, true);
  }

  Future<void> disableFirestoreSync() async {
    _firestoreSyncEnabled = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_syncKey, false);
  }

  Future<void> _loadSyncSetting() async {
    final prefs = await SharedPreferences.getInstance();
    // Default to true if not explicitly set to false
    _firestoreSyncEnabled = prefs.getBool(_syncKey) ?? true;
  }

  StorageService() {
    _initializeRepairItems();
  }

  void _initializeRepairItems() {
    repairItems = {
      // Heads
      "4_inch_head": RepairItem(name: "4_inch_head", price: 0.00, category: "heads", requiresNotes: false),
      "6_inch_head": RepairItem(name: "6_inch_head", price: 0.00, category: "heads", requiresNotes: false),
      "12_inch_head": RepairItem(name: "12_inch_head", price: 0.00, category: "heads", requiresNotes: false),
      "rotor": RepairItem(name: "rotor", price: 0.00, category: "heads", requiresNotes: false),

      // Stems/Risers
      "4_inch_stem": RepairItem(name: "4_inch_stem", price: 0.00, category: "stems", requiresNotes: false),
      "6_inch_stem": RepairItem(name: "6_inch_stem", price: 0.00, category: "stems", requiresNotes: false),
      "12_inch_stem": RepairItem(name: "12_inch_stem", price: 0.00, category: "stems", requiresNotes: false),

      // Nozzles
      "fixed_nozzle": RepairItem(name: "fixed_nozzle", price: 0.00, category: "nozzles", requiresNotes: false),
      "adjustable_nozzle": RepairItem(name: "adjustable_nozzle", price: 0.00, category: "nozzles", requiresNotes: false),
      "mp_rotator": RepairItem(name: "mp_rotator", price: 0.00, category: "nozzles", requiresNotes: false),
      "rvan_nozzle": RepairItem(name: "rvan_nozzle", price: 0.00, category: "nozzles", requiresNotes: false),
      "bubbler": RepairItem(name: "bubbler", price: 0.00, category: "nozzles", requiresNotes: false),

      // Drip
      "drip_break": RepairItem(name: "drip_break", price: 0.00, category: "drip", requiresNotes: false),
      "drip_row_per_ft": RepairItem(name: "drip_row_per_ft", price: 0.00, category: "drip", requiresNotes: false),

      // Pipe - Lateral
      "lateral_1_inch_or_less": RepairItem(name: "lateral_1_inch_or_less", price: 0.00, category: "pipe_lateral", requiresNotes: false),
      "lateral_1.5_inch_or_greater": RepairItem(name: "lateral_1.5_inch_or_greater", price: 0.00, category: "pipe_lateral", requiresNotes: false),

      // Pipe - Mainline
      "mainline_1_inch_or_less": RepairItem(name: "mainline_1_inch_or_less", price: 0.00, category: "pipe_mainline", requiresNotes: false),
      "mainline_1.5_inch_or_greater": RepairItem(name: "mainline_1.5_inch_or_greater", price: 0.00, category: "pipe_mainline", requiresNotes: false),

      // Valves
      "valve_1_inch_repair": RepairItem(name: "valve_1_inch_repair", price: 0.00, category: "valves", requiresNotes: false),
      "valve_1_inch_replace": RepairItem(name: "valve_1_inch_replace", price: 0.00, category: "valves", requiresNotes: false),
      "valve_1.5_inch_repair": RepairItem(name: "valve_1.5_inch_repair", price: 0.00, category: "valves", requiresNotes: false),
      "valve_1.5_inch_replace": RepairItem(name: "valve_1.5_inch_replace", price: 0.00, category: "valves", requiresNotes: false),
      "valve_2_inch_repair": RepairItem(name: "valve_2_inch_repair", price: 0.00, category: "valves", requiresNotes: false),
      "valve_2_inch_replace": RepairItem(name: "valve_2_inch_replace", price: 0.00, category: "valves", requiresNotes: false),

      // Controller
      "controller_replacement": RepairItem(name: "controller_replacement", price: 0.00, category: "controller", requiresNotes: true),

      // Rain Sensor
      "rain_sensor": RepairItem(name: "rain_sensor", price: 0.00, category: "sensor", requiresNotes: false),

      // Service Items
      "troubleshoot": RepairItem(name: "troubleshoot", price: 0.00, category: "service", requiresNotes: false),
      "locate": RepairItem(name: "locate", price: 0.00, category: "service", requiresNotes: false),

      // Wire
      "wire_repair_minimal": RepairItem(name: "wire_repair_minimal", price: 0.00, category: "wire", requiresNotes: false),
      "wire_repair_manual": RepairItem(name: "wire_repair_manual", price: 0.00, category: "wire", requiresNotes: true),
      "wire_sprout_replacement": RepairItem(name: "wire_sprout_replacement", price: 0.00, category: "wire", requiresNotes: false),

      // Winterize
      "winterize_system": RepairItem(name: "winterize_system", price: 0.00, category: "winterize", requiresNotes: false),

      // Backflow
      "backflow_repair": RepairItem(name: "backflow_repair", price: 0.00, category: "backflow", requiresNotes: true),
      "backflow_replacement": RepairItem(name: "backflow_replacement", price: 0.00, category: "backflow", requiresNotes: true),

      // Ball Valve
      "ball_valve_replacement": RepairItem(name: "ball_valve_replacement", price: 0.00, category: "ball_valve", requiresNotes: false),
    };
  }

  Future<void> saveData() async {
    try {
      final data = {
        'users': users.map((key, value) => MapEntry(key, value.toJson())),
        'properties': properties.map((key, value) => MapEntry(key.toString(), value.toJson())),
        'inspections': inspections.map((key, value) => MapEntry(key.toString(), value.toJson())),
        'repair_items': repairItems.map((key, value) => MapEntry(key, value.toJson())),
        'failed_attempts': failedAttempts,
        'quotes': quotes.map((key, value) => MapEntry(key.toString(), value.toJson())),
        'repair_tasks': repairTasks.map((key, value) => MapEntry(key.toString(), value.toJson())),
        'company_settings': companySettings?.toJson(),
        'next_property_id': nextPropertyId,
        'next_inspection_id': nextInspectionId,
        'next_quote_id': nextQuoteId,
        'next_repair_task_id': nextRepairTaskId,
      };

      final jsonString = json.encode(data);

      if (kIsWeb) {
        // Use SharedPreferences for web
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_storageKey, jsonString);
      } else {
        // Use file system for mobile
        await storage_impl.saveToFile(jsonString);
      }

      // Sync to Firestore if enabled
      if (_firestoreSyncEnabled) {
        await _syncToFirestore();
      }
    } catch (e) {
      print('Error saving data: $e');
    }
  }

  Future<void> _syncToFirestore() async {
    try {
      await _firestoreService.uploadAllData(
        users: users,
        properties: properties,
        inspections: inspections,
        quotes: quotes,
        repairTasks: repairTasks,
        companySettings: companySettings,
        nextPropertyId: nextPropertyId,
        nextInspectionId: nextInspectionId,
        nextQuoteId: nextQuoteId,
        nextRepairTaskId: nextRepairTaskId,
      );
    } catch (e) {
      print('Error syncing to Firestore: $e');
    }
  }

  /// Download all data from Firestore and replace local data
  Future<bool> downloadFromFirestore() async {
    try {
      final data = await _firestoreService.downloadAllData();

      users = data['users'] as Map<String, User>;
      properties = data['properties'] as Map<int, Property>;
      inspections = data['inspections'] as Map<int, Inspection>;
      quotes = data['quotes'] as Map<int, Quote>;
      repairTasks = data['repair_tasks'] as Map<int, RepairTask>;
      companySettings = data['company_settings'] as CompanySettings?;

      final metadata = data['metadata'] as Map<String, int>;
      nextPropertyId = metadata['next_property_id'] ?? 1;
      nextInspectionId = metadata['next_inspection_id'] ?? 1;
      nextQuoteId = metadata['next_quote_id'] ?? 1;
      nextRepairTaskId = metadata['next_repair_task_id'] ?? 1;

      // Save to local storage
      await saveData();
      return true;
    } catch (e) {
      print('Error downloading from Firestore: $e');
      return false;
    }
  }

  /// Upload all local data to Firestore
  Future<bool> uploadToFirestore() async {
    try {
      await _syncToFirestore();
      return true;
    } catch (e) {
      print('Error uploading to Firestore: $e');
      return false;
    }
  }

  Future<void> loadData() async {
    try {
      // Load sync setting first
      await _loadSyncSetting();

      String? contents;

      if (kIsWeb) {
        // Use SharedPreferences for web
        final prefs = await SharedPreferences.getInstance();
        contents = prefs.getString(_storageKey);
      } else {
        // Use file system for mobile
        contents = await storage_impl.loadFromFile();
      }

      if (contents == null || contents.isEmpty) {
        // No data yet, use defaults
        return;
      }

      final data = json.decode(contents) as Map<String, dynamic>;

      // Load users
      if (data['users'] != null) {
        users.clear();
        (data['users'] as Map<String, dynamic>).forEach((key, value) {
          users[key] = User.fromJson(key, value as Map<String, dynamic>);
        });
      }

      // Load properties
      if (data['properties'] != null) {
        properties.clear();
        (data['properties'] as Map<String, dynamic>).forEach((key, value) {
          properties[int.parse(key)] = Property.fromJson(int.parse(key), value as Map<String, dynamic>);
        });
      }

      // Load inspections
      if (data['inspections'] != null) {
        inspections.clear();
        (data['inspections'] as Map<String, dynamic>).forEach((key, value) {
          inspections[int.parse(key)] = Inspection.fromJson(int.parse(key), value as Map<String, dynamic>);
        });
      }

      // Load repair items
      if (data['repair_items'] != null) {
        repairItems.clear();
        (data['repair_items'] as Map<String, dynamic>).forEach((key, value) {
          repairItems[key] = RepairItem.fromJson(key, value as Map<String, dynamic>);
        });
      }

      // Load failed attempts
      if (data['failed_attempts'] != null) {
        failedAttempts.clear();
        (data['failed_attempts'] as Map<String, dynamic>).forEach((key, value) {
          failedAttempts[key] = value as int;
        });
      }

      // Load quotes
      if (data['quotes'] != null) {
        quotes.clear();
        (data['quotes'] as Map<String, dynamic>).forEach((key, value) {
          quotes[int.parse(key)] = Quote.fromJson(int.parse(key), value as Map<String, dynamic>);
        });
      }

      // Load repair tasks
      if (data['repair_tasks'] != null) {
        repairTasks.clear();
        (data['repair_tasks'] as Map<String, dynamic>).forEach((key, value) {
          repairTasks[int.parse(key)] = RepairTask.fromJson(int.parse(key), value as Map<String, dynamic>);
        });
      }

      // Load company settings
      if (data['company_settings'] != null) {
        companySettings = CompanySettings.fromJson(data['company_settings'] as Map<String, dynamic>);
      }

      // Load ID counters
      nextPropertyId = data['next_property_id'] ?? 1;
      nextInspectionId = data['next_inspection_id'] ?? 1;
      nextQuoteId = data['next_quote_id'] ?? 1;
      nextRepairTaskId = data['next_repair_task_id'] ?? 1;

    } catch (e) {
      print('Error loading data: $e');
      // On error, keep the defaults
    }
  }

  List<String> getCategories() {
    final categories = <String>{};
    for (var item in repairItems.values) {
      categories.add(item.category);
    }
    return categories.toList()..sort();
  }

  List<RepairItem> getItemsByCategory(String category) {
    return repairItems.values
        .where((item) => item.category == category)
        .toList();
  }

  // Quote helper methods
  Quote? getQuoteByAccessToken(String token) {
    try {
      return quotes.values.firstWhere((q) => q.accessToken == token);
    } catch (e) {
      return null;
    }
  }

  List<Quote> getQuotesByStatus(String status) {
    return quotes.values.where((q) => q.status == status).toList();
  }

  List<Quote> getQuotesByProperty(int propertyId) {
    return quotes.values.where((q) => q.propertyId == propertyId).toList();
  }

  List<Quote> getApprovedQuotesWithoutTasks() {
    final quotesWithTasks = repairTasks.values.map((t) => t.quoteId).toSet();
    return quotes.values
        .where((q) => q.status == 'approved' && !quotesWithTasks.contains(q.id))
        .toList();
  }

  // RepairTask helper methods
  List<RepairTask> getTasksByTechnician(String technicianEmail) {
    return repairTasks.values
        .where((t) => t.assignedTechnicians.contains(technicianEmail))
        .toList();
  }

  List<RepairTask> getTasksByStatus(String status) {
    return repairTasks.values.where((t) => t.status == status).toList();
  }

  List<RepairTask> getTasksByDate(String date) {
    return repairTasks.values.where((t) => t.scheduledDate == date).toList();
  }

  List<RepairTask> getPendingTasksForTechnician(String technicianEmail) {
    return repairTasks.values
        .where((t) =>
            t.assignedTechnicians.contains(technicianEmail) &&
            (t.status == 'assigned' || t.status == 'in_progress'))
        .toList();
  }

  /// Check if any repair item prices have been configured (non-zero)
  bool get hasPricesConfigured {
    return repairItems.values.any((item) => item.price > 0);
  }

  // Get all technicians (non-manager users)
  List<User> getTechnicians() {
    return users.values
        .where((u) => u.role == 'technician' && !u.isArchived)
        .toList();
  }
}
