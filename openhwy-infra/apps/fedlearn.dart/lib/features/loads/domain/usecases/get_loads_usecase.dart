// Example Use Case (Domain Layer)
// Use cases contain application-specific business rules

import '../entities/load.dart';
import '../repositories/load_repository.dart';

class GetLoadsUseCase {
  final LoadRepository repository;
  
  GetLoadsUseCase(this.repository);
  
  Future<List<Load>> call({
    LoadStatus? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final loads = await repository.getLoads(
        status: status,
        startDate: startDate,
        endDate: endDate,
      );
      
      // Apply business logic/filtering if needed
      return loads;
    } catch (e) {
      throw Exception('Failed to fetch loads: $e');
    }
  }
}
