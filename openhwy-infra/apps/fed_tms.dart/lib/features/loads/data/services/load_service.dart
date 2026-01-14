import 'dart:async';

import 'package:fed_tms/features/loads/data/models/load.dart';


class LoadService {
  final List<Load> _loads = [];
  int _idCounter = 1;
  
  LoadService() {
    _initializeMockData();
  }

  void _initializeMockData() {
    _loads.addAll([
      Load(
        id: '${_idCounter++}',
        reference: 'LD-2024-001',
        origin: 'Los Angeles, CA',
        destination: 'Phoenix, AZ',
        status: LoadStatus.booked,
        rate: 1250.00,
        driverName: 'John Smith',
        distance: 373.5,
        pickupDate: DateTime.now().add(const Duration(days: 1)),
        deliveryDate: DateTime.now().add(const Duration(days: 2)),
        notes: 'Fragile items - handle with care',
      ),
      Load(
        id: '${_idCounter++}',
        reference: 'LD-2024-002',
        origin: 'Dallas, TX',
        destination: 'Houston, TX',
        status: LoadStatus.inTransit,
        rate: 450.00,
        driverName: 'Sarah Johnson',
        distance: 239.8,
        pickupDate: DateTime.now().subtract(const Duration(hours: 4)),
        deliveryDate: DateTime.now().add(const Duration(hours: 2)),
        notes: 'Time-sensitive delivery',
      ),
      Load(
        id: '${_idCounter++}',
        reference: 'LD-2024-003',
        origin: 'Chicago, IL',
        destination: 'New York, NY',
        status: LoadStatus.pending,
        rate: 1800.00,
        distance: 790.3,
        pickupDate: DateTime.now().add(const Duration(days: 3)),
        deliveryDate: DateTime.now().add(const Duration(days: 5)),
        notes: 'Requires refrigeration',
      ),
      Load(
        id: '${_idCounter++}',
        reference: 'LD-2024-004',
        origin: 'Seattle, WA',
        destination: 'Portland, OR',
        status: LoadStatus.delivered,
        rate: 350.00,
        driverName: 'Mike Davis',
        distance: 173.2,
        pickupDate: DateTime.now().subtract(const Duration(days: 2)),
        deliveryDate: DateTime.now().subtract(const Duration(days: 1)),
        notes: 'Successfully delivered on time',
      ),
      Load(
        id: '${_idCounter++}',
        reference: 'LD-2024-005',
        origin: 'Miami, FL',
        destination: 'Atlanta, GA',
        status: LoadStatus.booked,
        rate: 650.00,
        driverName: 'Emily Brown',
        distance: 662.5,
        pickupDate: DateTime.now().add(const Duration(days: 2)),
        deliveryDate: DateTime.now().add(const Duration(days: 3)),
        notes: 'Standard delivery',
      ),
      Load(
        id: '${_idCounter++}',
        reference: 'LD-2024-006',
        origin: 'Denver, CO',
        destination: 'Las Vegas, NV',
        status: LoadStatus.pending,
        rate: 890.00,
        distance: 748.1,
        pickupDate: DateTime.now().add(const Duration(days: 4)),
        deliveryDate: DateTime.now().add(const Duration(days: 6)),
        notes: 'High-value load',
      ),
    ]);
  }

  Future<List<Load>> getLoads({
    String? search,
    LoadStatus? status,
    int page = 1,
    int limit = 50,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    var filtered = List<Load>.from(_loads);
    
    if (search != null && search.isNotEmpty) {
      filtered = filtered.where((load) {
        return load.reference.toLowerCase().contains(search.toLowerCase()) ||
            load.origin.toLowerCase().contains(search.toLowerCase()) ||
            load.destination.toLowerCase().contains(search.toLowerCase()) ||
            (load.driverName?.toLowerCase().contains(search.toLowerCase()) ?? false);
      }).toList();
    }
    
    if (status != null) {
      filtered = filtered.where((load) => load.status == status).toList();
    }
    
    // Sort by pickupDate descending (most recent first)
    filtered.sort((a, b) {
      if (a.pickupDate == null && b.pickupDate == null) return 0;
      if (a.pickupDate == null) return 1;
      if (b.pickupDate == null) return -1;
      return b.pickupDate!.compareTo(a.pickupDate!);
    });
    
    return filtered;
  }

  Future<Load> getLoad(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _loads.firstWhere((load) => load.id == id);
  }

  Future<Load> createLoad(Load load) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final newLoad = Load(
      id: '${_idCounter++}',
      reference: load.reference.isEmpty ? 'LD-2024-${_idCounter.toString().padLeft(3, '0')}' : load.reference,
      origin: load.origin,
      destination: load.destination,
      status: load.status,
      rate: load.rate,
      driverName: load.driverName,
      distance: load.distance,
      pickupDate: load.pickupDate,
      deliveryDate: load.deliveryDate,
      notes: load.notes,
    );
    _loads.insert(0, newLoad);
    return newLoad;
  }

  Future<Load> updateLoad(String id, Load load) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _loads.indexWhere((l) => l.id == id);
    if (index != -1) {
      _loads[index] = load;
      return load;
    }
    throw Exception('Load not found');
  }

  Future<void> deleteLoad(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _loads.removeWhere((load) => load.id == id);
  }

  Future<Map<String, dynamic>> getLoadStats() async {
    await Future.delayed(const Duration(milliseconds: 200));
    
    final totalLoads = _loads.length;
    final activeLoads = _loads.where((l) => 
      l.status == LoadStatus.booked || l.status == LoadStatus.inTransit
    ).length;
    final pendingLoads = _loads.where((l) => l.status == LoadStatus.pending).length;
    final deliveredLoads = _loads.where((l) => l.status == LoadStatus.delivered).length;
    
    final totalRevenue = _loads.fold<double>(
      0, 
      (sum, load) => sum + (load.status == LoadStatus.delivered ? load.rate : 0)
    );
    
    final todayRevenue = _loads.where((load) {
      return load.status == LoadStatus.delivered &&
          load.deliveryDate != null &&
          load.deliveryDate!.day == DateTime.now().day &&
          load.deliveryDate!.month == DateTime.now().month &&
          load.deliveryDate!.year == DateTime.now().year;
    }).fold<double>(0, (sum, load) => sum + load.rate);
    
    return {
      'totalLoads': totalLoads,
      'activeLoads': activeLoads,
      'pendingLoads': pendingLoads,
      'deliveredLoads': deliveredLoads,
      'totalRevenue': totalRevenue,
      'todayRevenue': todayRevenue,
    };
  }
}