class User {
  final String email;
  final String password;
  final String role; // 'manager' or 'technician'
  final String name;
  final bool isArchived;

  User({
    required this.email,
    required this.password,
    required this.role,
    required this.name,
    this.isArchived = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'password': password,
      'role': role,
      'name': name,
      'is_archived': isArchived,
    };
  }

  factory User.fromJson(String email, Map<String, dynamic> json) {
    return User(
      email: email,
      password: json['password'] ?? '',
      role: json['role'] ?? 'technician',
      name: json['name'] ?? '',
      isArchived: json['is_archived'] ?? false,
    );
  }

  User copyWith({
    String? email,
    String? password,
    String? role,
    String? name,
    bool? isArchived,
  }) {
    return User(
      email: email ?? this.email,
      password: password ?? this.password,
      role: role ?? this.role,
      name: name ?? this.name,
      isArchived: isArchived ?? this.isArchived,
    );
  }
}
