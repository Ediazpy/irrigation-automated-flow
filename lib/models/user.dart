class User {
  final String email;
  final String password;
  final String role; // 'manager' or 'technician'
  final String name;
  final bool isArchived;
  // Security questions for password reset (manager only)
  final Map<String, String> securityAnswers; // questionId -> answer

  User({
    required this.email,
    required this.password,
    required this.role,
    required this.name,
    this.isArchived = false,
    this.securityAnswers = const {},
  });

  // Available security questions
  static const List<Map<String, String>> securityQuestions = [
    {'id': 'pet', 'question': 'What was the name of your first pet?'},
    {'id': 'city', 'question': 'What city did you grow up in?'},
    {'id': 'school', 'question': 'What was the name of your elementary school?'},
    {'id': 'car', 'question': 'What was your first car make and model?'},
    {'id': 'mother', 'question': "What is your mother's maiden name?"},
    {'id': 'street', 'question': 'What street did you live on as a child?'},
    {'id': 'friend', 'question': "What was your childhood best friend's name?"},
  ];

  /// Full serialization for local storage (includes all fields)
  Map<String, dynamic> toJson() {
    return {
      'password': password,
      'role': role,
      'name': name,
      'is_archived': isArchived,
      'security_answers': securityAnswers,
    };
  }

  /// Firestore-safe serialization — excludes security_answers
  /// (security answers are sensitive and only needed locally)
  Map<String, dynamic> toFirestoreJson() {
    return {
      'password': password,
      'role': role,
      'name': name,
      'is_archived': isArchived,
    };
  }

  factory User.fromJson(String email, Map<String, dynamic> json) {
    Map<String, String> answers = {};
    if (json['security_answers'] != null) {
      (json['security_answers'] as Map<String, dynamic>).forEach((key, value) {
        answers[key] = value.toString();
      });
    }

    return User(
      email: email,
      password: json['password'] ?? '',
      role: json['role'] ?? 'technician',
      name: json['name'] ?? '',
      isArchived: json['is_archived'] ?? false,
      securityAnswers: answers,
    );
  }

  User copyWith({
    String? email,
    String? password,
    String? role,
    String? name,
    bool? isArchived,
    Map<String, String>? securityAnswers,
  }) {
    return User(
      email: email ?? this.email,
      password: password ?? this.password,
      role: role ?? this.role,
      name: name ?? this.name,
      isArchived: isArchived ?? this.isArchived,
      securityAnswers: securityAnswers ?? this.securityAnswers,
    );
  }

  bool hasSecurityQuestions() {
    return securityAnswers.isNotEmpty && securityAnswers.length >= 3;
  }
}
