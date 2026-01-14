import 'dart:async';

import 'package:fed_tms/features/drivers/data/models/driver.dart';


class DriverService {
  final List<Driver> _drivers = [];
  int _idCounter = 1;

  DriverService() {
    _initializeMockData();
  }

  void _initializeMockData() {
    _drivers.addAll([
      Driver(
        id: '${_idCounter++}',
        firstName: 'John',
        lastName: 'Smith',
        email: 'john.smith@email.com',
        phone: '(555) 123-4567',
        licenseNumber: 'DL-123456',
        status: DriverStatus.onDuty,
        activeLoads: 2,
        totalLoads: 145,
        rating: 4.8,
      ),
      Driver(
        id: '${_idCounter++}',
        firstName: 'Sarah',
        lastName: 'Johnson',
        email: 'sarah.johnson@email.com',
        phone: '(555) 234-5678',
        licenseNumber: 'DL-234567',
        status: DriverStatus.active,
        activeLoads: 1,
        totalLoads: 98,
        rating: 4.9,
      ),
      Driver(
        id: '${_idCounter++}',
        firstName: 'Mike',
        lastName: 'Davis',
        email: 'mike.davis@email.com',
        phone: '(555) 345-6789',
        licenseNumber: 'DL-345678',
        status: DriverStatus.offDuty,
        activeLoads: 0,
        totalLoads: 76,
        rating: 4.6,
      ),
      Driver(
        id: '${_idCounter++}',
        firstName: 'Emily',
        lastName: 'Brown',
        email: 'emily.brown@email.com',
        phone: '(555) 456-7890',
        licenseNumber: 'DL-456789',
        status: DriverStatus.sleeping,
        activeLoads: 1,
        totalLoads: 112,
        rating: 4.7,
      ),
      Driver(
        id: '${_idCounter++}',
        firstName: 'Robert',
        lastName: 'Wilson',
        email: 'robert.wilson@email.com',
        phone: '(555) 567-8901',
        licenseNumber: 'DL-567890',
        status: DriverStatus.active,
        activeLoads: 3,
        totalLoads: 189,
        rating: 4.8,
      ),
      Driver(
        id: '${_idCounter++}',
        firstName: 'Lisa',
        lastName: 'Anderson',
        email: 'lisa.anderson@email.com',
        phone: '(555) 678-9012',
        licenseNumber: 'DL-678901',
        status: DriverStatus.inactive,
        activeLoads: 0,
        totalLoads: 234,
        rating: 4.9,
      ),
      Driver(
        id: '${_idCounter++}',
        firstName: 'David',
        lastName: 'Martinez',
        email: 'david.martinez@email.com',
        phone: '(555) 789-0123',
        licenseNumber: 'DL-789012',
        status: DriverStatus.online,
        activeLoads: 1,
        totalLoads: 156,
        rating: 4.5,
      ),
      Driver(
        id: '${_idCounter++}',
        firstName: 'Jennifer',
        lastName: 'Taylor',
        email: 'jennifer.taylor@email.com',
        phone: '(555) 890-1234',
        licenseNumber: 'DL-890123',
        status: DriverStatus.active,
        activeLoads: 2,
        totalLoads: 201,
        rating: 4.7,
      ),
    ]);
  }

  Future<List<Driver>> getAllDrivers() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _drivers;
  }

  Future<Driver?> getDriverById(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      return _drivers.firstWhere((driver) => driver.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<List<Driver>> getDriversByStatus(String status) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final filtered = _drivers
        .where((driver) =>
            driver.status.toString().toLowerCase() == status.toLowerCase())
        .toList();

    // Sort by name for consistent ordering
    filtered.sort((a, b) => a.name.compareTo(b.name));
    return filtered;
  }

  Future<List<Driver>> searchDrivers(String query) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final filtered = _drivers
        .where((driver) =>
            driver.name.toLowerCase().contains(query.toLowerCase()) ||
            driver.email.toLowerCase().contains(query.toLowerCase()))
        .toList();

    filtered.sort((a, b) => a.name.compareTo(b.name));
    return filtered;
  }

  Future<void> updateDriver(
      String driverId, Map<String, dynamic> updates) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final index = _drivers.indexWhere((driver) => driver.id == driverId);
    if (index != -1) {
      final driver = _drivers[index];
      final updatedDriver = Driver(
        id: driver.id,
        firstName: updates['firstName'] ?? driver.firstName,
        lastName: updates['lastName'] ?? driver.lastName,
        email: updates['email'] ?? driver.email,
        phone: updates['phone'] ?? driver.phone,
        licenseNumber: updates['licenseNumber'] ?? driver.licenseNumber,
        status: updates['status'] ?? driver.status,
        activeLoads: updates['activeLoads'] ?? driver.activeLoads,
        totalLoads: updates['totalLoads'] ?? driver.totalLoads,
        rating: updates['rating'] ?? driver.rating,
      );
      _drivers[index] = updatedDriver;
    }
  }

  Future<void> deleteDriver(String driverId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _drivers.removeWhere((driver) => driver.id == driverId);
  }

  Stream<List<Driver>> getDriversStream() {
    return Stream.periodic(const Duration(seconds: 5), (_) {
      return _drivers;
    });
  }

  Map<String, dynamic> getDriverStats() {
    if (_drivers.isEmpty) {
      return {
        'totalDrivers': 0,
        'availableDrivers': 0,
        'onLoadDrivers': 0,
        'avgRating': 0.0,
        'deliveredLoads': 0,
      };
    }

    final ratings = _drivers.map((d) => d.rating ?? 0.0).toList();
    final avgRating = ratings.isEmpty
        ? 0.0
        : ratings.reduce((a, b) => a + b) / ratings.length;

    return {
      'totalDrivers': _drivers.length,
      'availableDrivers': _drivers
          .where((d) =>
              d.status == DriverStatus.active ||
              d.status == DriverStatus.online)
          .length,
      'onLoadDrivers': _drivers.where((d) => (d.activeLoads ?? 0) > 0).length,
      'avgRating': avgRating,
      'deliveredLoads':
          _drivers.map((d) => d.totalLoads ?? 0).reduce((a, b) => a + b),
    };
  }
}
