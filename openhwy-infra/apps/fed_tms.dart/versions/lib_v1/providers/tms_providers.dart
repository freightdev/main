import 'package:riverpod/riverpod.dart';

import '../models/load.dart';
import '../models/driver.dart';

class LoadsNotifier extends StateNotifier<List<Load>> {
  LoadsNotifier() : super(_seedLoads);
  static final List<Load> _seedLoads = [
    Load(
        id: 'L1',
        reference: 'L-1001',
        origin: 'A',
        destination: 'B',
        status: LoadStatus.booked,
        rate: 1200.0,
        driverName: 'Alex',
        distance: 320.0,
        pickupDate: DateTime.now(),
        deliveryDate: DateTime.now().add(Duration(days: 1)))
  ];
  void addLoad(Load l) => state = [...state, l];
  void updateLoad(Load l) => state = [
        for (var x in state)
          if (x.id == l.id) l else x
      ];
  void removeLoad(String id) => state = state.where((l) => l.id != id).toList();
}

class DriversNotifier extends StateNotifier<List<Driver>> {
  DriversNotifier() : super(_seedDrivers);
  static final List<Driver> _seedDrivers = [
    Driver(
        id: 'd1',
        firstName: 'Alex',
        lastName: 'C',
        email: 'a@example.com',
        phone: '111',
        licenseNumber: 'L1',
        status: DriverStatus.active,
        activeLoads: 1,
        totalLoads: 5,
        rating: 4.7)
  ];
  void addDriver(Driver d) => state = [...state, d];
  void updateDriver(Driver d) => state = [
        for (var x in state)
          if (x.id == d.id) d else x
      ];
  void removeDriver(String id) =>
      state = state.where((d) => d.id != id).toList();
}

final loadsProvider =
    StateNotifierProvider<LoadsNotifier, List<Load>>((ref) => LoadsNotifier());
final driversProvider = StateNotifierProvider<DriversNotifier, List<Driver>>(
    (ref) => DriversNotifier());
