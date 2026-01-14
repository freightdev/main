import 'package:equatable/equatable.dart';
import 'package:playground/core/models/load.dart';

class LoadCardData extends Equatable {
  final String id;
  final String reference;
  final String origin;
  final String destination;
  final LoadStatus status;
  final double? rate;

  const LoadCardData({
    required this.id,
    required this.reference,
    required this.origin,
    required this.destination,
    required this.status,
    this.rate,
  });

  @override
  List<Object?> get props => [
        id,
        reference,
        origin,
        destination,
        status,
        rate,
      ];
}
