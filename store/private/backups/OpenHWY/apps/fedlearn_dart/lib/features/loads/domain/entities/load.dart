// Example Entity (Domain Layer)
// Entities are business objects with business rules

class Load {
  final String id;
  final String pickupLocation;
  final String deliveryLocation;
  final DateTime pickupDate;
  final DateTime deliveryDate;
  final double rate;
  final LoadStatus status;
  
  Load({
    required this.id,
    required this.pickupLocation,
    required this.deliveryLocation,
    required this.pickupDate,
    required this.deliveryDate,
    required this.rate,
    required this.status,
  });
  
  // Business logic methods
  bool isOverdue() {
    return DateTime.now().isAfter(deliveryDate) && 
           status != LoadStatus.delivered;
  }
  
  bool canBeAssigned() {
    return status == LoadStatus.pending || status == LoadStatus.available;
  }
}

enum LoadStatus {
  pending,
  available,
  assigned,
  inTransit,
  delivered,
  cancelled,
}
