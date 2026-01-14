import 'package:flutter/material.dart';

enum LoadStatus {
  pending('Pending'),
  booked('Booked'),
  inTransit('In Transit'),
  delivered('Delivered'),
  cancelled('Cancelled');

  final String displayName;
  const LoadStatus(this.displayName);

  @override
  String toString() => displayName;
}

class Load {
  final String id;
  final String reference;
  final String origin;
  final String destination;
  final LoadStatus status;
  final double? rate;
  final String? driverName;
  final String? distance;
  final String? pickupDate;
  final String? deliveryDate;
  final String? notes;

  Load({
    required this.id,
    required this.reference,
    required this.origin,
    required this.destination,
    required this.status,
    this.rate,
    this.driverName,
    this.distance,
    this.pickupDate,
    this.deliveryDate,
    this.notes,
  });

  String get statusText => status.toString();

  Color get statusColor {
    switch (status) {
      case LoadStatus.pending:
        return Colors.orange;
      case LoadStatus.booked:
        return Colors.blue;
      case LoadStatus.inTransit:
        return Colors.purple;
      case LoadStatus.delivered:
        return Colors.green;
      case LoadStatus.cancelled:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

enum DriverStatus {
  active('Active'),
  onDuty('On Duty'),
  offDuty('Off Duty'),
  sleeping('Sleeping'),
  inactive('Inactive');

  final String displayName;
  const DriverStatus(this.displayName);

  @override
  String toString() => displayName;
}

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
      default:
        return Colors.grey;
    }
  }
}
