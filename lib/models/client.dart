class Client {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String address;
  final String city;
  final String state;
  final String zip;
  final String notes;
  final String createdAt;
  final bool isArchived;

  Client({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.email = '',
    this.phone = '',
    this.address = '',
    this.city = '',
    this.state = '',
    this.zip = '',
    this.notes = '',
    required this.createdAt,
    this.isArchived = false,
  });

  String get fullName => '$firstName $lastName'.trim();

  String get initials {
    final f = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final l = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    return '$f$l';
  }

  String get fullAddress {
    final parts = <String>[];
    if (address.isNotEmpty) parts.add(address);
    final cityState = <String>[];
    if (city.isNotEmpty) cityState.add(city);
    if (state.isNotEmpty) cityState.add(state);
    if (cityState.isNotEmpty) parts.add(cityState.join(', '));
    if (zip.isNotEmpty) parts.add(zip);
    return parts.join(', ');
  }

  Map<String, dynamic> toJson() {
    return {
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone': phone,
      'address': address,
      'city': city,
      'state': state,
      'zip': zip,
      'notes': notes,
      'created_at': createdAt,
      'is_archived': isArchived,
    };
  }

  factory Client.fromJson(int id, Map<String, dynamic> json) {
    return Client(
      id: id,
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      zip: json['zip'] ?? '',
      notes: json['notes'] ?? '',
      createdAt: json['created_at'] ?? DateTime.now().toIso8601String(),
      isArchived: json['is_archived'] ?? false,
    );
  }

  Client copyWith({
    int? id,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? address,
    String? city,
    String? state,
    String? zip,
    String? notes,
    String? createdAt,
    bool? isArchived,
  }) {
    return Client(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      zip: zip ?? this.zip,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      isArchived: isArchived ?? this.isArchived,
    );
  }
}
