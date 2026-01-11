import 'dart:convert';

class User {
  final String id;
  final String email;
  final String? name;
  final String? firstName;
  final String? lastName;
  final String? picture;
  final bool emailVerified;
  final Map<String, dynamic>? metadata;

  User({
    required this.id,
    required this.email,
    this.name,
    this.firstName,
    this.lastName,
    this.picture,
    this.emailVerified = false,
    this.metadata,
  });

  String get displayName {
    if (name != null && name!.isNotEmpty) return name!;
    if (firstName != null && lastName != null) {
      return '$firstName $lastName'.trim();
    }
    if (firstName != null) return firstName!;
    return email;
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['sub'] ?? json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'],
      firstName: json['given_name'],
      lastName: json['family_name'],
      picture: json['picture'],
      emailVerified: json['email_verified'] ?? false,
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sub': id,
      'email': email,
      'name': name,
      'given_name': firstName,
      'family_name': lastName,
      'picture': picture,
      'email_verified': emailVerified,
      'metadata': metadata,
    };
  }

  String toJsonString() => json.encode(toJson());

  factory User.fromJsonString(String jsonString) {
    return User.fromJson(json.decode(jsonString));
  }

  User copyWith({
    String? id,
    String? email,
    String? name,
    String? firstName,
    String? lastName,
    String? picture,
    bool? emailVerified,
    Map<String, dynamic>? metadata,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      picture: picture ?? this.picture,
      emailVerified: emailVerified ?? this.emailVerified,
      metadata: metadata ?? this.metadata,
    );
  }
}
