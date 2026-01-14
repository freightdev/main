import 'dart:async';
import '../models/driver.dart';

enum DriverStatus { available, onLoad, offDuty, maintenance }

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
        name: 'John Smith',
        phone: '(555) 123-4567',
        email: 'john.smith@email.com',
        licenseNumber: 'DL-123456',
        licenseExpiry: DateTime.now().add(const Duration(days: 180)),
        status: 'On Load',
        currentLoad: 'LD-2024-001',
        totalLoads: 145,
        rating: 4.8,
      ),
      Driver(
        id: '${_idCounter++}',
        name: 'Sarah Johnson',
        phone: '(555) 234-5678',
        email: 'sarah.johnson@email.com',
        licenseNumber: 'DL-234567',
        licenseExpiry: DateTime.now().add(const Duration(days: 240)),
        status: 'On Load',
        currentLoad: 'LD-2024-002',
        totalLoads: 198,
        rating: 4.9,
      ),
      Driver(
        id: '${_idCounter++}',
        name: 'Mike Davis',
        phone: '(555) 345-6789',
        email: 'mike.davis@email.com',
        licenseNumber: 'DL-345678',
        licenseExpiry: DateTime.now().add(const Duration(days: 90)),
        status: 'Available',
        totalLoads: 87,
        rating: 4.6,
      ),
      Driver(
        id: '${_idCounter++}',
        name: 'Emily Brown',
        phone: '(555) 456-7890',
        email: 'emily.brown@email.com',
        licenseNumber: 'DL-456789',
        licenseExpiry: DateTime.now().add(const Duration(days: 365)),
        status: 'On Load',
        currentLoad: 'LD-2024-005',
        totalLoads: 132,
        rating: 4.7,
      ),
      Driver(
        id: '${_idCounter++}',
        name: 'Robert Wilson',
        phone: '(555) 567-8901',
        email: 'robert.wilson@email.com',
        licenseNumber: 'DL-567890',
        licenseExpiry: DateTime.now().add(const Duration(days: 120)),
        status: 'Available',
        totalLoads: 156,
        rating: 4.5,
      ),
      Driver(
        id: '${_idCounter++}',
        name: 'Lisa Anderson',
        phone: '(555) 678-9012',
        email: 'lisa.anderson@email.com',
        licenseNumber: 'DL-678901',
        licenseExpiry: DateTime.now().add(const Duration(days: 200)),
        status: 'Off Duty',
        totalLoads: 203,
        rating: 4.9,
      ),
      Driver(
        id: '${_idCounter++}',
        name: 'David Martinez',
        phone: '(555) 789-0123',
        email: 'david.martinez@email.com',
        licenseNumber: 'DL-789012',
        licenseExpiry: DateTime.now().add(const Duration(days: 150)),
        status: 'Available',
        totalLoads: 78,
        rating: 4.4,
      ),
      Driver(
        id: '${_idCounter++}',
        name: 'Jennifer Taylor',
        phone: '(555) 890-1234',
        email: 'jennifer.taylor@email.com',
        licenseNumber: 'DL-890123',
        licenseExpiry: DateTime.now().add(const Duration(days: 300)),
        status: 'Available',
        totalLoads: 165,
        rating: 4.8,
      ),
    ]);
  }

  Future<List<Driver>> getDrivers({
    String? search,
    String? status,
    int page = 1,
    int limit = 50,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    var filtered = List<Driver>.from(_drivers);
    
    if (search != null && search.isNotEmpty) {
      filtered = filtered.where((driver) {
        return driver.name.toLowerCase().contains(search.toLowerCase()) ||
            driver.phone.contains(search) ||
            driver.email.toLowerCase().contains(search.toLowerCase()) ||
            driver.licenseNumber.toLowerCase().contains(search.toLowerCase());
      }).toList();
    }
    
    if (status != null && status.isNotEmpty) {
      filtered = filtered.where((driver) => 
        driver.status.toLowerCase() == status.toLowerCase()
      ).toList();
    }
    
    // Sort by name
    filtered.sort((a, b) => a.name.compareTo(b.name));
    
    return filtered;
  }

  Future<Driver> getDriver(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _drivers.firstWhere((driver) => driver.id == id);
  }

  Future<Driver> createDriver(Driver driver) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final newDriver = Driver(
      id: '${_idCounter++}',
      name: driver.name,
      phone: driver.phone,
      email: driver.email,
      licenseNumber: driver.licenseNumber,
      licenseExpiry: driver.licenseExpiry,
      status: driver.status,
      currentLoad: driver.currentLoad,
      totalLoads: driver.totalLoads,
      rating: driver.rating,
    );
    _drivers.insert(0, newDriver);
    return newDriver;
  }

  Future<Driver> updateDriver(String id, Driver driver) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _drivers.indexWhere((d) => d.id == id);
    if (index != -1) {
      _drivers[index] = driver;
      return driver;
    }
    throw Exception('Driver not found');
  }

  Future<void> deleteDriver(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _drivers.removeWhere((driver) => driver.id == id);
  }

  Future<Map<String, dynamic>> getDriverStats() async {
    await Future.delayed(const Duration(milliseconds: 200));
    
    final totalDrivers = _drivers.length;
    final availableDrivers = _drivers.where((d) => d.status == 'Available').length;
    final onLoadDrivers = _drivers.where((d) => d.status == 'On Load').length;
    final offDutyDrivers = _drivers.where((d) => d.status == 'Off Duty').length;
    
    final avgRating = _drivers.isEmpty ? 0.0 : 
      _drivers.fold<double>(0, (sum, d) => sum + (d.rating ?? 0)) / _drivers.length;
    
    return {
      'totalDrivers': totalDrivers,
      'availableDrivers': availableDrivers,
      'onLoadDrivers': onLoadDrivers,
      'offDutyDrivers': offDutyDrivers,
      'avgRating': avgRating,
    };
  }

  Future<List<Driver>> getAvailableDrivers() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _drivers.where((d) => d.status == 'Available').toList();
  }
}