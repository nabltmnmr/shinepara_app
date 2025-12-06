class User {
  final int id;
  final String email;
  final String fullName;
  final String? phone;
  final String? location;
  final DateTime? createdAt;

  User({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone,
    this.location,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] is String ? int.parse(json['id']) : json['id'] as int,
      email: json['email'] as String,
      fullName: json['full_name'] as String? ?? json['fullName'] as String? ?? '',
      phone: json['phone'] as String?,
      location: json['location'] as String?,
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'phone': phone,
      'location': location,
    };
  }

  User copyWith({
    int? id,
    String? email,
    String? fullName,
    String? phone,
    String? location,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
