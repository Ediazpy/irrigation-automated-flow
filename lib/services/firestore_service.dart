import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import '../models/property.dart';
import '../models/inspection.dart';
import '../models/quote.dart';
import '../models/repair_task.dart';
import '../models/company_settings.dart';
import '../utils/password_hash.dart';

/// Service for syncing data with Firebase Firestore
/// Works alongside StorageService for cloud backup and multi-device sync
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection names
  static const String _usersCollection = 'users';
  static const String _propertiesCollection = 'properties';
  static const String _inspectionsCollection = 'inspections';
  static const String _quotesCollection = 'quotes';
  static const String _repairTasksCollection = 'repair_tasks';
  static const String _settingsCollection = 'settings';
  static const String _metadataCollection = 'metadata';
  static const String _resetRequestsCollection = 'password_reset_requests';

  // Singleton pattern
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  // ============ USERS ============

  Future<void> saveUser(String email, User user) async {
    await _firestore
        .collection(_usersCollection)
        .doc(email)
        .set(user.toFirestoreJson()); // Excludes security_answers
  }

  Future<void> deleteUser(String email) async {
    await _firestore.collection(_usersCollection).doc(email).delete();
  }

  Future<Map<String, User>> getAllUsers() async {
    final snapshot = await _firestore.collection(_usersCollection).get();
    final users = <String, User>{};
    for (var doc in snapshot.docs) {
      users[doc.id] = User.fromJson(doc.id, doc.data());
    }
    return users;
  }

  Stream<Map<String, User>> watchUsers() {
    return _firestore.collection(_usersCollection).snapshots().map((snapshot) {
      final users = <String, User>{};
      for (var doc in snapshot.docs) {
        users[doc.id] = User.fromJson(doc.id, doc.data());
      }
      return users;
    });
  }

  // ============ PROPERTIES ============

  Future<void> saveProperty(int id, Property property) async {
    await _firestore
        .collection(_propertiesCollection)
        .doc(id.toString())
        .set(property.toJson());
  }

  Future<void> deleteProperty(int id) async {
    await _firestore.collection(_propertiesCollection).doc(id.toString()).delete();
  }

  Future<Map<int, Property>> getAllProperties() async {
    final snapshot = await _firestore.collection(_propertiesCollection).get();
    final properties = <int, Property>{};
    for (var doc in snapshot.docs) {
      final id = int.parse(doc.id);
      properties[id] = Property.fromJson(id, doc.data());
    }
    return properties;
  }

  Stream<Map<int, Property>> watchProperties() {
    return _firestore.collection(_propertiesCollection).snapshots().map((snapshot) {
      final properties = <int, Property>{};
      for (var doc in snapshot.docs) {
        final id = int.parse(doc.id);
        properties[id] = Property.fromJson(id, doc.data());
      }
      return properties;
    });
  }

  // ============ INSPECTIONS ============

  Future<void> saveInspection(int id, Inspection inspection) async {
    await _firestore
        .collection(_inspectionsCollection)
        .doc(id.toString())
        .set(inspection.toJson());
  }

  Future<void> deleteInspection(int id) async {
    await _firestore.collection(_inspectionsCollection).doc(id.toString()).delete();
  }

  Future<Map<int, Inspection>> getAllInspections() async {
    final snapshot = await _firestore.collection(_inspectionsCollection).get();
    final inspections = <int, Inspection>{};
    for (var doc in snapshot.docs) {
      final id = int.parse(doc.id);
      inspections[id] = Inspection.fromJson(id, doc.data());
    }
    return inspections;
  }

  Stream<Map<int, Inspection>> watchInspections() {
    return _firestore.collection(_inspectionsCollection).snapshots().map((snapshot) {
      final inspections = <int, Inspection>{};
      for (var doc in snapshot.docs) {
        final id = int.parse(doc.id);
        inspections[id] = Inspection.fromJson(id, doc.data());
      }
      return inspections;
    });
  }

  // ============ QUOTES ============

  Future<void> saveQuote(int id, Quote quote) async {
    await _firestore
        .collection(_quotesCollection)
        .doc(id.toString())
        .set(quote.toJson());
  }

  Future<void> deleteQuote(int id) async {
    await _firestore.collection(_quotesCollection).doc(id.toString()).delete();
  }

  Future<Map<int, Quote>> getAllQuotes() async {
    final snapshot = await _firestore.collection(_quotesCollection).get();
    final quotes = <int, Quote>{};
    for (var doc in snapshot.docs) {
      final id = int.parse(doc.id);
      quotes[id] = Quote.fromJson(id, doc.data());
    }
    return quotes;
  }

  Stream<Map<int, Quote>> watchQuotes() {
    return _firestore.collection(_quotesCollection).snapshots().map((snapshot) {
      final quotes = <int, Quote>{};
      for (var doc in snapshot.docs) {
        final id = int.parse(doc.id);
        quotes[id] = Quote.fromJson(id, doc.data());
      }
      return quotes;
    });
  }

  // ============ REPAIR TASKS ============

  Future<void> saveRepairTask(int id, RepairTask task) async {
    await _firestore
        .collection(_repairTasksCollection)
        .doc(id.toString())
        .set(task.toJson());
  }

  Future<void> deleteRepairTask(int id) async {
    await _firestore.collection(_repairTasksCollection).doc(id.toString()).delete();
  }

  Future<Map<int, RepairTask>> getAllRepairTasks() async {
    final snapshot = await _firestore.collection(_repairTasksCollection).get();
    final tasks = <int, RepairTask>{};
    for (var doc in snapshot.docs) {
      final id = int.parse(doc.id);
      tasks[id] = RepairTask.fromJson(id, doc.data());
    }
    return tasks;
  }

  Stream<Map<int, RepairTask>> watchRepairTasks() {
    return _firestore.collection(_repairTasksCollection).snapshots().map((snapshot) {
      final tasks = <int, RepairTask>{};
      for (var doc in snapshot.docs) {
        final id = int.parse(doc.id);
        tasks[id] = RepairTask.fromJson(id, doc.data());
      }
      return tasks;
    });
  }

  // ============ COMPANY SETTINGS ============

  Future<void> saveCompanySettings(CompanySettings settings) async {
    await _firestore
        .collection(_settingsCollection)
        .doc('company')
        .set(settings.toFirestoreJson()); // Excludes master_reset_code
  }

  Future<CompanySettings?> getCompanySettings() async {
    final doc = await _firestore.collection(_settingsCollection).doc('company').get();
    if (doc.exists && doc.data() != null) {
      return CompanySettings.fromJson(doc.data()!);
    }
    return null;
  }

  Stream<CompanySettings?> watchCompanySettings() {
    return _firestore
        .collection(_settingsCollection)
        .doc('company')
        .snapshots()
        .map((doc) {
      if (doc.exists && doc.data() != null) {
        return CompanySettings.fromJson(doc.data()!);
      }
      return null;
    });
  }

  // ============ METADATA (ID counters) ============

  Future<void> saveMetadata({
    required int nextPropertyId,
    required int nextInspectionId,
    required int nextQuoteId,
    required int nextRepairTaskId,
  }) async {
    await _firestore.collection(_metadataCollection).doc('counters').set({
      'next_property_id': nextPropertyId,
      'next_inspection_id': nextInspectionId,
      'next_quote_id': nextQuoteId,
      'next_repair_task_id': nextRepairTaskId,
    });
  }

  Future<Map<String, int>> getMetadata() async {
    final doc = await _firestore.collection(_metadataCollection).doc('counters').get();
    if (doc.exists && doc.data() != null) {
      final data = doc.data()!;
      return {
        'next_property_id': data['next_property_id'] ?? 1,
        'next_inspection_id': data['next_inspection_id'] ?? 1,
        'next_quote_id': data['next_quote_id'] ?? 1,
        'next_repair_task_id': data['next_repair_task_id'] ?? 1,
      };
    }
    return {
      'next_property_id': 1,
      'next_inspection_id': 1,
      'next_quote_id': 1,
      'next_repair_task_id': 1,
    };
  }

  // ============ BULK OPERATIONS ============

  /// Upload all local data to Firestore (for initial sync or backup)
  Future<void> uploadAllData({
    required Map<String, User> users,
    required Map<int, Property> properties,
    required Map<int, Inspection> inspections,
    required Map<int, Quote> quotes,
    required Map<int, RepairTask> repairTasks,
    required CompanySettings? companySettings,
    required int nextPropertyId,
    required int nextInspectionId,
    required int nextQuoteId,
    required int nextRepairTaskId,
  }) async {
    final batch = _firestore.batch();

    // Users (Firestore-safe: excludes security_answers)
    for (var entry in users.entries) {
      final ref = _firestore.collection(_usersCollection).doc(entry.key);
      batch.set(ref, entry.value.toFirestoreJson());
    }

    // Properties
    for (var entry in properties.entries) {
      final ref = _firestore.collection(_propertiesCollection).doc(entry.key.toString());
      batch.set(ref, entry.value.toJson());
    }

    // Inspections
    for (var entry in inspections.entries) {
      final ref = _firestore.collection(_inspectionsCollection).doc(entry.key.toString());
      batch.set(ref, entry.value.toJson());
    }

    // Quotes
    for (var entry in quotes.entries) {
      final ref = _firestore.collection(_quotesCollection).doc(entry.key.toString());
      batch.set(ref, entry.value.toJson());
    }

    // Repair Tasks
    for (var entry in repairTasks.entries) {
      final ref = _firestore.collection(_repairTasksCollection).doc(entry.key.toString());
      batch.set(ref, entry.value.toJson());
    }

    // Company Settings (Firestore-safe: excludes master_reset_code)
    if (companySettings != null) {
      final ref = _firestore.collection(_settingsCollection).doc('company');
      batch.set(ref, companySettings.toFirestoreJson());
    }

    // Metadata
    final metaRef = _firestore.collection(_metadataCollection).doc('counters');
    batch.set(metaRef, {
      'next_property_id': nextPropertyId,
      'next_inspection_id': nextInspectionId,
      'next_quote_id': nextQuoteId,
      'next_repair_task_id': nextRepairTaskId,
    });

    await batch.commit();
  }

  // ============ PASSWORD RESET REQUESTS ============

  /// Submit a password reset request (locked-out admin → dev team)
  Future<void> submitResetRequest(String email, String name) async {
    await _firestore.collection(_resetRequestsCollection).doc(email).set({
      'email': email,
      'name': name,
      'status': 'pending', // pending, approved, denied
      'requested_at': FieldValue.serverTimestamp(),
    });
  }

  /// Check if a reset request has been approved and get the new password
  Future<Map<String, dynamic>?> checkResetRequest(String email) async {
    final doc = await _firestore.collection(_resetRequestsCollection).doc(email).get();
    if (doc.exists && doc.data() != null) {
      return doc.data();
    }
    return null;
  }

  /// Delete a processed reset request
  Future<void> deleteResetRequest(String email) async {
    await _firestore.collection(_resetRequestsCollection).doc(email).delete();
  }

  /// Get all pending reset requests (for dev/admin tool)
  Future<List<Map<String, dynamic>>> getPendingResetRequests() async {
    final snapshot = await _firestore
        .collection(_resetRequestsCollection)
        .where('status', isEqualTo: 'pending')
        .get();
    return snapshot.docs.map((doc) => {'email': doc.id, ...doc.data()}).toList();
  }

  /// Approve a reset request with a new temporary password (dev/admin tool)
  /// The password is stored as a hash in Firestore
  Future<void> approveResetRequest(String email, String newPassword) async {
    await _firestore.collection(_resetRequestsCollection).doc(email).update({
      'status': 'approved',
      'new_password': PasswordHash.hashPassword(newPassword),
      'approved_at': FieldValue.serverTimestamp(),
    });
  }

  /// Download all data from Firestore
  Future<Map<String, dynamic>> downloadAllData() async {
    final users = await getAllUsers();
    final properties = await getAllProperties();
    final inspections = await getAllInspections();
    final quotes = await getAllQuotes();
    final repairTasks = await getAllRepairTasks();
    final companySettings = await getCompanySettings();
    final metadata = await getMetadata();

    return {
      'users': users,
      'properties': properties,
      'inspections': inspections,
      'quotes': quotes,
      'repair_tasks': repairTasks,
      'company_settings': companySettings,
      'metadata': metadata,
    };
  }
}
