import 'package:flutter/material.dart';

enum DriverStatus { active, onDuty, offDuty, sleeping, inactive }

class Driver {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String licenseNumber;
  final DriverStatus status;
  final int? activeLoads;
  final int? totalLoads;
  final double? rating;

  Driver({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.licenseNumber,
    required this.status,
    this.activeLoads,
    this.totalLoads,
    this.rating,
  });

  String get fullName => '$firstName $lastName';

  Color get statusColor {
    switch (status) {
      case DriverStatus.active:
        return Colors.green;
      case DriverStatus.onDuty:
        return Colors.blue;
      case DriverStatus.offDuty:
        return Colors.orange;
      case DriverStatus.sleeping:
        return Colors.purple;
      case DriverStatus.inactive:
        return Colors.red;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'licenseNumber': licenseNumber,
      'status': status.toString().split('.').last,
      'activeLoads': activeLoads,
      'totalLoads': totalLoads,
      'rating': rating,
    };
  }

  factory Driver.fromJson(Map<String, dynamic> json) {
    String s = (json['status'] ?? 'active').toString();
    DriverStatus st;
    switch (s) {
      case 'active':
        st = DriverStatus.active;
        break;
      case 'onDuty':
        st = DriverStatus.onDuty;
        break;
      case 'offDuty':
        st = DriverStatus.offDuty;
        break;
      case 'sleeping':
        st = DriverStatus.sleeping;
        break;
      case 'inactive':
        st = DriverStatus.inactive;
        break;
      default:
        st = DriverStatus.active;
        break;
    }
    return Driver(
      id: json['id'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      licenseNumber: json['licenseNumber'] as String,
      status: st,
      activeLoads: json['activeLoads'] as int?,
      totalLoads: json['totalLoads'] as int?,
      rating: (json['rating'] as num?)?.toDouble(),
    );
  }
}
