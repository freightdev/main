// Example Repository Interface (Domain Layer)
// Defines the contract for data operations

import '../entities/load.dart';

abstract class LoadRepository {
  Future<List<Load>> getLoads({
    LoadStatus? status,
    DateTime? startDate,
    DateTime? endDate,
  });
  
  Future<Load> getLoadById(String id);
  
  Future<Load> createLoad(Load load);
  
  Future<Load> updateLoad(Load load);
  
  Future<void> deleteLoad(String id);
  
  Future<Load> assignDriver(String loadId, String driverId);
}
