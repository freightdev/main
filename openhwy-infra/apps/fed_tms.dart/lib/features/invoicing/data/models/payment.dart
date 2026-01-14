import 'package:json_annotation/json_annotation.dart';

part 'package:fed_tms/features/invoicing/data/models/payment.g.dart';

enum PaymentStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('paid')
  paid,
  @JsonValue('failed')
  failed,
}

@JsonSerializable()
class Payment {
  final String id;
  final String invoiceId;
  final double amount;
  final PaymentStatus status;
  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime dueDate;
  @JsonKey(fromJson: _dateTimeFromJsonNullable, toJson: _dateTimeToJsonNullable)
  final DateTime? paidDate;

  const Payment({
    required this.id,
    required this.invoiceId,
    required this.amount,
    required this.status,
    required this.dueDate,
    this.paidDate,
  });

  factory Payment.fromJson(Map<String, dynamic> json) =>
      _$PaymentFromJson(json);
  Map<String, dynamic> toJson() => _$PaymentToJson(this);

  static DateTime _dateTimeFromJson(dynamic json) {
    if (json == null) return DateTime.now();
    return json is String ? DateTime.parse(json) : json;
  }

  static DateTime? _dateTimeFromJsonNullable(dynamic json) {
    if (json == null) return null;
    return json is String ? DateTime.parse(json) : json;
  }

  static dynamic _dateTimeToJson(DateTime dateTime) =>
      dateTime.toIso8601String();
  static dynamic _dateTimeToJsonNullable(DateTime? dateTime) =>
      dateTime?.toIso8601String();
}
