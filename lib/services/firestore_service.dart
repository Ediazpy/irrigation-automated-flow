import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../models/user.dart';
import '../models/property.dart';
import '../models/inspection.dart';
import '../models/quote.dart';
import '../models/repair_task.dart';
import '../models/client.dart';
import '../models/invoice.dart';
import '../models/company_settings.dart';

/// Service for syncing data with Firebase Firestore.
///
/// All reads and writes are scoped to the caller's company. Identity comes
/// from the Firebase Auth ID token: `role` and `companyId` are custom claims
/// set server-side by Cloud Functions and cannot be forged by the client.
/// Every business document is stamped with `company_id`, `created_by`, and
/// `created_at`; the security rules require these on create and reject any
/// attempt to change them afterwards.
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection names
  static const String _usersCollection = 'users';
  static const String _propertiesCollection = 'properties';
  static const String _inspectionsCollection = 'inspections';
  static const String _quotesCollection = 'quotes';
  static const String _repairTasksCollection = 'repair_tasks';
  static const String _clientsCollection = 'clients';
  static const String _invoicesCollection = 'invoices';
  static const String _settingsCollection = 'settings';
  static const String _countersCollection = 'counters';
  static const String _metadataCollection = 'metadata';
  static const String _publicQuotesCollection = 'public_quotes';

  // Singleton pattern
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  // ============ IDENTITY (custom claims) ============

  String? _companyId;
  String? _role;

  /// Ownership stamps (created_by / created_at) per 'collection/docId'.
  /// Populated on download and persisted in the local cache so that full-doc
  /// overwrites during sync preserve the original ownership fields the
  /// security rules require to stay immutable.
  final Map<String, Map<String, dynamic>> stampCache = {};

  bool get isSignedIn => fb.FirebaseAuth.instance.currentUser != null;
  String? get _uid => fb.FirebaseAuth.instance.currentUser?.uid;
  String? get _email => fb.FirebaseAuth.instance.currentUser?.email;
  bool get isManager => _role == 'manager';
  String? get companyId => _companyId;

  /// Re-read role/companyId claims from the current ID token.
  /// Call after login and after any server-side claim change.
  Future<void> refreshClaims() async {
    final user = fb.FirebaseAuth.instance.currentUser;
    if (user == null) {
      clearClaims();
      return;
    }
    final token = await user.getIdTokenResult();
    _companyId = token.claims?['companyId'] as String?;
    _role = token.claims?['role'] as String?;
  }

  void clearClaims() {
    _companyId = null;
    _role = null;
    stampCache.clear();
  }

  String get _requireCompany {
    final c = _companyId;
    if (c == null || c.isEmpty) {
      throw StateError('Not signed in or company claim missing');
    }
    return c;
  }

  // Business docs are namespaced by company to avoid ID collisions between
  // tenants while keeping the app's internal integer IDs.
  String _docId(int id) => '${_requireCompany}_$id';

  int _parseDocId(String docId) {
    final sep = docId.lastIndexOf('_');
    return int.parse(sep >= 0 ? docId.substring(sep + 1) : docId);
  }

  /// Stamp a business document with company/ownership fields. Existing docs
  /// keep their original created_by/created_at (from the stamp cache);
  /// locally new docs are stamped as created by the current user now.
  Map<String, dynamic> _withStamp(String collection, String docId, Map<String, dynamic> data) {
    final key = '$collection/$docId';
    var stamp = stampCache[key];
    if (stamp == null) {
      stamp = {
        'created_by': _uid,
        'created_at': DateTime.now().toIso8601String(),
      };
      stampCache[key] = stamp;
    }
    data['company_id'] = _requireCompany;
    data['created_by'] = stamp['created_by'];
    data['created_at'] = stamp['created_at'];
    return data;
  }

  void _recordStamp(String collection, String docId, Map<String, dynamic> data) {
    if (data['created_by'] != null || data['created_at'] != null) {
      stampCache['$collection/$docId'] = {
        'created_by': data['created_by'],
        'created_at': data['created_at'],
      };
    }
  }

  Query<Map<String, dynamic>> _companyQuery(String collection) {
    return _firestore
        .collection(collection)
        .where('company_id', isEqualTo: _requireCompany);
  }

  // ============ USERS (profiles only — credentials live in Firebase Auth) ============

  Future<User?> getUserProfile(String uid) async {
    final doc = await _firestore.collection(_usersCollection).doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return User.fromFirestore(doc.id, doc.data()!);
  }

  /// Profile updates only. Role, company, and archived state are managed by
  /// Cloud Functions (they must stay in sync with Auth claims).
  Future<void> saveUser(User user) async {
    await _firestore
        .collection(_usersCollection)
        .doc(user.uid)
        .set(user.toFirestoreJson(), SetOptions(merge: true));
  }

  /// Managers see all company users; technicians only their own profile
  /// (rules restrict user docs to self-or-manager).
  Future<Map<String, User>> getAllUsers() async {
    final users = <String, User>{};
    if (isManager) {
      final snapshot = await _companyQuery(_usersCollection).get();
      for (var doc in snapshot.docs) {
        final user = User.fromFirestore(doc.id, doc.data());
        users[user.email] = user;
      }
    } else {
      final uid = _uid;
      if (uid != null) {
        final me = await getUserProfile(uid);
        if (me != null) users[me.email] = me;
      }
    }
    return users;
  }

  Stream<Map<String, User>> watchUsers() {
    return _companyQuery(_usersCollection).snapshots().map((snapshot) {
      final users = <String, User>{};
      for (var doc in snapshot.docs) {
        final user = User.fromFirestore(doc.id, doc.data());
        users[user.email] = user;
      }
      return users;
    });
  }

  // ============ GENERIC HELPERS ============

  Future<void> _saveDoc(String collection, int id, Map<String, dynamic> json) async {
    final docId = _docId(id);
    await _firestore
        .collection(collection)
        .doc(docId)
        .set(_withStamp(collection, docId, json));
  }

  Future<void> _deleteDoc(String collection, int id) async {
    final docId = _docId(id);
    await _firestore.collection(collection).doc(docId).delete();
    stampCache.remove('$collection/$docId');
  }

  Future<Map<int, T>> _getAll<T>(
      String collection, T Function(int id, Map<String, dynamic> json) fromJson) async {
    final snapshot = await _companyQuery(collection).get();
    final result = <int, T>{};
    for (var doc in snapshot.docs) {
      final id = _parseDocId(doc.id);
      _recordStamp(collection, doc.id, doc.data());
      result[id] = fromJson(id, doc.data());
    }
    return result;
  }

  Stream<Map<int, T>> _watchAll<T>(
      String collection, T Function(int id, Map<String, dynamic> json) fromJson) {
    return _companyQuery(collection).snapshots().map((snapshot) {
      final result = <int, T>{};
      for (var doc in snapshot.docs) {
        final id = _parseDocId(doc.id);
        _recordStamp(collection, doc.id, doc.data());
        result[id] = fromJson(id, doc.data());
      }
      return result;
    });
  }

  // ============ PROPERTIES ============

  Future<void> saveProperty(int id, Property property) =>
      _saveDoc(_propertiesCollection, id, property.toJson());

  Future<void> deleteProperty(int id) => _deleteDoc(_propertiesCollection, id);

  Future<Map<int, Property>> getAllProperties() =>
      _getAll(_propertiesCollection, Property.fromJson);

  Stream<Map<int, Property>> watchProperties() =>
      _watchAll(_propertiesCollection, Property.fromJson);

  // ============ INSPECTIONS ============

  Future<void> saveInspection(int id, Inspection inspection) =>
      _saveDoc(_inspectionsCollection, id, inspection.toJson());

  Future<void> deleteInspection(int id) => _deleteDoc(_inspectionsCollection, id);

  Future<Map<int, Inspection>> getAllInspections() =>
      _getAll(_inspectionsCollection, Inspection.fromJson);

  Stream<Map<int, Inspection>> watchInspections() =>
      _watchAll(_inspectionsCollection, Inspection.fromJson);

  // ============ QUOTES ============

  Future<void> saveQuote(int id, Quote quote) =>
      _saveDoc(_quotesCollection, id, quote.toJson());

  Future<void> deleteQuote(int id) => _deleteDoc(_quotesCollection, id);

  Future<Map<int, Quote>> getAllQuotes() => _getAll(_quotesCollection, Quote.fromJson);

  Stream<Map<int, Quote>> watchQuotes() => _watchAll(_quotesCollection, Quote.fromJson);

  // ============ REPAIR TASKS ============

  Future<void> saveRepairTask(int id, RepairTask task) =>
      _saveDoc(_repairTasksCollection, id, task.toJson());

  Future<void> deleteRepairTask(int id) => _deleteDoc(_repairTasksCollection, id);

  Future<Map<int, RepairTask>> getAllRepairTasks() =>
      _getAll(_repairTasksCollection, RepairTask.fromJson);

  Stream<Map<int, RepairTask>> watchRepairTasks() =>
      _watchAll(_repairTasksCollection, RepairTask.fromJson);

  // ============ CLIENTS ============

  Future<void> saveClient(int id, Client client) =>
      _saveDoc(_clientsCollection, id, client.toJson());

  Future<void> deleteClient(int id) => _deleteDoc(_clientsCollection, id);

  Future<Map<int, Client>> getAllClients() => _getAll(_clientsCollection, Client.fromJson);

  Stream<Map<int, Client>> watchClients() => _watchAll(_clientsCollection, Client.fromJson);

  // ============ INVOICES ============

  Future<void> saveInvoice(int id, Invoice invoice) =>
      _saveDoc(_invoicesCollection, id, invoice.toJson());

  // Invoices are never hard-deleted (void them instead); rules enforce this.

  Future<Map<int, Invoice>> getAllInvoices() =>
      _getAll(_invoicesCollection, Invoice.fromJson);

  Stream<Map<int, Invoice>> watchInvoices() =>
      _watchAll(_invoicesCollection, Invoice.fromJson);

  // ============ COMPANY SETTINGS (settings/{companyId}) ============

  Future<void> saveCompanySettings(CompanySettings settings) async {
    await _firestore
        .collection(_settingsCollection)
        .doc(_requireCompany)
        .set(settings.toFirestoreJson(), SetOptions(merge: true));
  }

  Future<CompanySettings?> getCompanySettings() async {
    final doc = await _firestore
        .collection(_settingsCollection)
        .doc(_requireCompany)
        .get();
    if (doc.exists && doc.data() != null) {
      return CompanySettings.fromJson(doc.data()!);
    }
    return null;
  }

  Stream<CompanySettings?> watchCompanySettings() {
    return _firestore
        .collection(_settingsCollection)
        .doc(_requireCompany)
        .snapshots()
        .map((doc) {
      if (doc.exists && doc.data() != null) {
        return CompanySettings.fromJson(doc.data()!);
      }
      return null;
    });
  }

  // ============ COUNTERS (per-company ID allocation) ============

  Future<void> saveCounters({
    required int nextPropertyId,
    required int nextInspectionId,
    required int nextQuoteId,
    required int nextRepairTaskId,
    required int nextClientId,
    required int nextInvoiceId,
  }) async {
    await _firestore.collection(_countersCollection).doc(_requireCompany).set({
      'company_id': _requireCompany,
      'next_property_id': nextPropertyId,
      'next_inspection_id': nextInspectionId,
      'next_quote_id': nextQuoteId,
      'next_repair_task_id': nextRepairTaskId,
      'next_client_id': nextClientId,
      'next_invoice_id': nextInvoiceId,
    });
  }

  Future<Map<String, int>> getCounters() async {
    final doc = await _firestore
        .collection(_countersCollection)
        .doc(_requireCompany)
        .get();
    final data = (doc.exists ? doc.data() : null) ?? {};
    return {
      'next_property_id': data['next_property_id'] ?? 1,
      'next_inspection_id': data['next_inspection_id'] ?? 1,
      'next_quote_id': data['next_quote_id'] ?? 1,
      'next_repair_task_id': data['next_repair_task_id'] ?? 1,
      'next_client_id': data['next_client_id'] ?? 1,
      'next_invoice_id': data['next_invoice_id'] ?? 1,
    };
  }

  // ============ PUBLIC QUOTES (customer approval by unguessable token) ============

  /// Mirror a quote into public_quotes/{accessToken} so the customer can view
  /// and approve it without an account. The token doc is get-only (no list)
  /// and only the approval fields are writable by the public — see rules.
  Future<void> savePublicQuote(Quote quote, {String address = ''}) async {
    await _firestore.collection(_publicQuotesCollection).doc(quote.accessToken).set({
      'company_id': _requireCompany,
      'quote_id': quote.id,
      'status': quote.status,
      'address': address,
      'quote': quote.toJson(),
      'viewed_at': quote.viewedAt,
      'client_signature': quote.clientSignature,
      'signed_at': quote.signedAt,
      'client_notes': quote.clientNotes,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> deletePublicQuote(String accessToken) async {
    await _firestore.collection(_publicQuotesCollection).doc(accessToken).delete();
  }

  /// Unauthenticated read for the customer-facing quote screen.
  Future<Map<String, dynamic>?> getPublicQuote(String accessToken) async {
    final doc =
        await _firestore.collection(_publicQuotesCollection).doc(accessToken).get();
    if (!doc.exists || doc.data() == null) return null;
    return doc.data();
  }

  /// Customer action on a public quote. Rules only allow these exact fields
  /// to change, and only while the quote is still actionable.
  Future<void> updatePublicQuote(String accessToken, Map<String, dynamic> fields) async {
    final allowed = <String, dynamic>{};
    for (final key in ['status', 'viewed_at', 'client_signature', 'signed_at', 'client_notes']) {
      if (fields.containsKey(key)) allowed[key] = fields[key];
    }
    allowed['updated_at'] = DateTime.now().toIso8601String();
    await _firestore
        .collection(_publicQuotesCollection)
        .doc(accessToken)
        .update(allowed);
  }

  /// Manager-side: pull customer decisions from public_quotes back into the
  /// company's quote documents. Returns the quotes that changed.
  Future<List<Quote>> reconcilePublicQuotes(Map<int, Quote> quotes) async {
    if (!isManager) return const [];
    final changed = <Quote>[];
    for (final entry in quotes.entries) {
      final quote = entry.value;
      if (quote.accessToken.isEmpty) continue;
      if (quote.status != 'sent' && quote.status != 'viewed') continue;
      try {
        final pub = await getPublicQuote(quote.accessToken);
        if (pub == null) continue;
        final pubStatus = pub['status'] as String? ?? quote.status;
        if (pubStatus == quote.status && pub['viewed_at'] == quote.viewedAt) continue;
        final updated = quote.copyWith(
          status: pubStatus,
          viewedAt: pub['viewed_at'] as String? ?? quote.viewedAt,
          clientSignature: pub['client_signature'] as String? ?? quote.clientSignature,
          signedAt: pub['signed_at'] as String? ?? quote.signedAt,
          clientNotes: pub['client_notes'] as String? ?? quote.clientNotes,
        );
        quotes[entry.key] = updated;
        await saveQuote(entry.key, updated);
        changed.add(updated);
      } catch (_) {}
    }
    return changed;
  }

  // ============ BULK SYNC ============

  /// Upload local data to Firestore. Writes are filtered by role so that
  /// every operation in the batch is allowed by the security rules:
  /// technicians only write collections and documents they may edit.
  Future<void> uploadAllData({
    required Map<String, User> users,
    required Map<int, Property> properties,
    required Map<int, Inspection> inspections,
    required Map<int, Quote> quotes,
    required Map<int, RepairTask> repairTasks,
    required Map<int, Client> clients,
    required Map<int, Invoice> invoices,
    required CompanySettings? companySettings,
    required int nextPropertyId,
    required int nextInspectionId,
    required int nextQuoteId,
    required int nextRepairTaskId,
    required int nextClientId,
    required int nextInvoiceId,
  }) async {
    if (!isSignedIn || _companyId == null) return;
    final myEmail = _email;
    final myUid = _uid;

    // collection -> docId -> data
    final writes = <String, Map<String, Map<String, dynamic>>>{};
    void add(String collection, int id, Map<String, dynamic> json) {
      final docId = _docId(id);
      writes.putIfAbsent(collection, () => {})[docId] =
          _withStamp(collection, docId, json);
    }

    for (var e in properties.entries) {
      add(_propertiesCollection, e.key, e.value.toJson());
    }
    for (var e in clients.entries) {
      add(_clientsCollection, e.key, e.value.toJson());
    }

    for (var e in inspections.entries) {
      final docId = _docId(e.key);
      final stamp = stampCache['$_inspectionsCollection/$docId'];
      final mine = stamp == null ||
          stamp['created_by'] == myUid ||
          (myEmail != null && e.value.technicians.contains(myEmail));
      if (isManager || mine) {
        add(_inspectionsCollection, e.key, e.value.toJson());
      }
    }

    for (var e in repairTasks.entries) {
      final docId = _docId(e.key);
      final stamp = stampCache['$_repairTasksCollection/$docId'];
      final mine = stamp == null ||
          stamp['created_by'] == myUid ||
          (myEmail != null && e.value.assignedTechnicians.contains(myEmail));
      if (isManager || mine) {
        add(_repairTasksCollection, e.key, e.value.toJson());
      }
    }

    if (isManager) {
      for (var e in quotes.entries) {
        add(_quotesCollection, e.key, e.value.toJson());
      }
      for (var e in invoices.entries) {
        add(_invoicesCollection, e.key, e.value.toJson());
      }
    }

    // Flatten into batches of 450 (Firestore limit is 500 ops per batch)
    final ops = <MapEntry<DocumentReference, Map<String, dynamic>>>[];
    writes.forEach((collection, docs) {
      docs.forEach((docId, data) {
        ops.add(MapEntry(_firestore.collection(collection).doc(docId), data));
      });
    });

    for (var i = 0; i < ops.length; i += 450) {
      final batch = _firestore.batch();
      final end = (i + 450 < ops.length) ? i + 450 : ops.length;
      for (var j = i; j < end; j++) {
        batch.set(ops[j].key, ops[j].value);
      }
      await batch.commit();
    }

    if (isManager && companySettings != null) {
      await saveCompanySettings(companySettings);
    }
    await saveCounters(
      nextPropertyId: nextPropertyId,
      nextInspectionId: nextInspectionId,
      nextQuoteId: nextQuoteId,
      nextRepairTaskId: nextRepairTaskId,
      nextClientId: nextClientId,
      nextInvoiceId: nextInvoiceId,
    );
  }

  /// Download all company data from Firestore.
  Future<Map<String, dynamic>> downloadAllData() async {
    final users = await getAllUsers();
    final properties = await getAllProperties();
    final inspections = await getAllInspections();
    final quotes = await getAllQuotes();
    final repairTasks = await getAllRepairTasks();
    final clients = await getAllClients();
    final invoices = isManager ? await getAllInvoices() : <int, Invoice>{};
    final companySettings = await getCompanySettings();
    final counters = await getCounters();

    // Pull in any customer quote decisions made since the last sync
    if (isManager) {
      await reconcilePublicQuotes(quotes);
    }

    return {
      'users': users,
      'properties': properties,
      'inspections': inspections,
      'quotes': quotes,
      'repair_tasks': repairTasks,
      'clients': clients,
      'invoices': invoices,
      'company_settings': companySettings,
      'metadata': counters,
    };
  }

  // ============ APP VERSION CHECK (metadata is read-only to clients) ============

  /// Latest app version, maintained via the deploy script / Admin SDK.
  Future<String?> getLatestAppVersion() async {
    try {
      final doc =
          await _firestore.collection(_metadataCollection).doc('app_version').get();
      if (doc.exists && doc.data() != null) {
        return doc.data()!['version'] as String?;
      }
    } catch (_) {
      // Not signed in yet or offline — version check is best-effort.
    }
    return null;
  }
}
