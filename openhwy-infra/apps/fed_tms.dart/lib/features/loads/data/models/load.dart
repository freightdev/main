// Production-like in-memory Load model with manual JSON handling

enum LoadStatus { pending, booked, inTransit, delivered, cancelled }

class Load {
  final String id;
  final String reference;
  final String origin;
  final String destination;
  final LoadStatus status;
  final double rate;
  final String? driverName;
  final double? distance;
  final DateTime? pickupDate;
  final DateTime? deliveryDate;
  final String? notes;

  Load({
    required this.id,
    required this.reference,
    required this.origin,
    required this.destination,
    required this.status,
    required this.rate,
    this.driverName,
    this.distance,
    this.pickupDate,
    this.deliveryDate,
    this.notes,
  });

  String get statusLabel => status.toString().split('.').last;

  double get progress {
    switch (status) {
      case LoadStatus.pending:
        return 0.0;
      case LoadStatus.booked:
        return 0.25;
      case LoadStatus.inTransit:
        return 0.6;
      case LoadStatus.delivered:
        return 1.0;
      case LoadStatus.cancelled:
        return 0.0;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reference': reference,
      'origin': origin,
      'destination': destination,
      'status': statusLabel,
      'rate': rate,
      'driverName': driverName,
      'distance': distance,
      'pickupDate': pickupDate?.toIso8601String(),
      'deliveryDate': deliveryDate?.toIso8601String(),
      'notes': notes,
    };
  }

  factory Load.fromJson(Map<String, dynamic> json) {
    final s = (json['status'] ?? 'pending').toString();
    final LoadStatus st = _toStatus(s);
    return Load(
      id: json['id'] as String,
      reference: json['reference'] as String,
      origin: json['origin'] as String,
      destination: json['destination'] as String,
      status: st,
      rate: (json['rate'] as num).toDouble(),
      driverName: (json['driverName'] as String?),
      distance: json['distance'] != null
          ? (json['distance'] as num).toDouble()
          : null,
      pickupDate: json['pickupDate'] != null
          ? DateTime.parse(json['pickupDate'])
          : null,
      deliveryDate: json['deliveryDate'] != null
          ? DateTime.parse(json['deliveryDate'])
          : null,
      notes: json['notes'] as String?,
    );
  }
}

LoadStatus _toStatus(String v) {
  switch (v) {
    case 'pending':
    case 'LoadStatus.pending':
      return LoadStatus.pending;
    case 'booked':
    case 'LoadStatus.booked':
      return LoadStatus.booked;
    case 'inTransit':
    case 'LoadStatus.inTransit':
      return LoadStatus.inTransit;
    case 'delivered':
    case 'LoadStatus.delivered':
      return LoadStatus.delivered;
    case 'cancelled':
    case 'LoadStatus.cancelled':
      return LoadStatus.cancelled;
    default:
      return LoadStatus.pending;
  }
}
