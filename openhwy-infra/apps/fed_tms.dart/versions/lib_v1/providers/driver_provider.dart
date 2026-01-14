import 'dart:core';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/driver.dart';
import '../services/driver_service.dart';

// Driver Service Provider
final driverServiceProvider = Provider<DriverService>((ref) => DriverService());

// Driver List Provider with filters
final driversProvider =
    FutureProvider.family<List<Driver>, DriverFilters>((ref, filters) async {
  final service = ref.watch(driverServiceProvider);
  final drivers = await service.getAllDrivers();

  // Apply filters manually since service doesn't support them yet
  var filteredDrivers = drivers;
  if (filters.search?.isNotEmpty == true) {
    filteredDrivers = filteredDrivers
        .where(
            (d) => d.name.toLowerCase().contains(filters.search!.toLowerCase()))
        .toList();
  }
  if (filters.status?.isNotEmpty == true) {
    filteredDrivers = filteredDrivers
        .where((d) =>
            d.status.toString().toLowerCase() == filters.status!.toLowerCase())
        .toList();
  }

  return filteredDrivers;
});

// Single Driver Provider
final singleDriverProvider =
    FutureProvider.family<Driver, String>((ref, driverId) async {
  final service = ref.watch(driverServiceProvider);
  final drivers = await service.getAllDrivers();
  return drivers.firstWhere((d) => d.id == driverId);
});

// Available Drivers Provider
final availableDriversProvider = FutureProvider<List<Driver>>((ref) async {
  final service = ref.watch(driverServiceProvider);
  final allDrivers = await service.getAllDrivers();
  return allDrivers
      .where((d) =>
          d.status == DriverStatus.active || d.status == DriverStatus.onDuty)
      .toList();
});

// Driver Stats Provider
final driverStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final service = ref.watch(driverServiceProvider);
  return await service.getDriverStats();
});

// Driver Filters State
class DriverFilters {
  final String? search;
  final String? status;
  final int page;
  final int limit;

  const DriverFilters({
    this.search,
    this.status,
    this.page = 1,
    this.limit = 50,
  });
}
