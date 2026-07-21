class User {
  final String uid;
  final String email;
  final String role; // 'manager' or 'technician'
  final String name;
  final bool isArchived;
  final String companyId;

  User({
    required this.uid,
    required this.email,
    required this.role,
    required this.name,
    this.isArchived = false,
    this.companyId = '',
  });

  /// Serialization for local cache. Credentials live in Firebase Auth —
  /// this is profile data only.
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'role': role,
      'name': name,
      'is_archived': isArchived,
      'company_id': companyId,
    };
  }

  /// Firestore profile document (doc ID is the Firebase Auth uid).
  Map<String, dynamic> toFirestoreJson() {
    return {
      'email': email,
      'role': role,
      'name': name,
      'is_archived': isArchived,
      'company_id': companyId,
    };
  }

  factory User.fromJson(String key, Map<String, dynamic> json) {
    return User(
      uid: json['uid'] ?? '',
      email: json['email'] ?? key,
      role: json['role'] ?? 'technician',
      name: json['name'] ?? '',
      isArchived: json['is_archived'] ?? false,
      companyId: json['company_id'] ?? '',
    );
  }

  /// From a Firestore users/{uid} document.
  factory User.fromFirestore(String uid, Map<String, dynamic> json) {
    return User(
      uid: uid,
      email: json['email'] ?? '',
      role: json['role'] ?? 'technician',
      name: json['name'] ?? '',
      isArchived: json['is_archived'] ?? false,
      companyId: json['company_id'] ?? '',
    );
  }

  User copyWith({
    String? uid,
    String? email,
    String? role,
    String? name,
    bool? isArchived,
    String? companyId,
  }) {
    return User(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      role: role ?? this.role,
      name: name ?? this.name,
      isArchived: isArchived ?? this.isArchived,
      companyId: companyId ?? this.companyId,
    );
  }
}
