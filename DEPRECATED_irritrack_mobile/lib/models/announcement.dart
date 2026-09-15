class Announcement {
  final String id;
  final String title;
  final String message;
  final String createdAt;
  final String? expiresAt;
  final String priority; // 'info', 'warning', 'urgent'
  final bool dismissible;

  Announcement({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    this.expiresAt,
    this.priority = 'info',
    this.dismissible = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'created_at': createdAt,
      'expires_at': expiresAt,
      'priority': priority,
      'dismissible': dismissible,
    };
  }

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      createdAt: json['created_at'] ?? '',
      expiresAt: json['expires_at'],
      priority: json['priority'] ?? 'info',
      dismissible: json['dismissible'] ?? true,
    );
  }

  bool get isExpired {
    if (expiresAt == null) return false;
    try {
      final expiry = DateTime.parse(expiresAt!);
      return DateTime.now().isAfter(expiry);
    } catch (e) {
      return false;
    }
  }
}
