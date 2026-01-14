import 'package:json_annotation/json_annotation.dart';
import 'dart:core';

part 'user.g.dart';

enum UserRole {
  admin,
  dispatcher,
  driver,
  manager,
}

@JsonSerializable()
class User {
  final String id;
  final String firstName;
  final String lastName;
  final String? avatar;
  final UserRole? role;
  final String? email;
  final String? phone;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const User({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.avatar,
    this.role,
    this.email,
    this.phone,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  String? get fullName => (firstName.isNotEmpty && lastName.isNotEmpty)
      ? '$firstName $lastName'
      : null;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);
}
