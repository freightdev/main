import 'package:json_annotation/json_annotation.dart';

part 'invoice.g.dart';

enum InvoiceStatus {
  @JsonValue('draft')
  draft,
  @JsonValue('pending')
  pending,
  @JsonValue('paid')
  paid,
  @JsonValue('overdue')
  overdue,
  @JsonValue('cancelled')
  cancelled,
}

@JsonSerializable()
class Invoice {
  final String id;
  final String invoiceNumber;
  final String customerName;
  final double total;
  final InvoiceStatus status;
  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime issuedDate;
  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime dueDate;
  @JsonKey(fromJson: _dateTimeFromJsonNullable, toJson: _dateTimeToJsonNullable)
  final DateTime? paidDate;

  const Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.customerName,
    required this.total,
    required this.status,
    required this.issuedDate,
    required this.dueDate,
    this.paidDate,
  });

  // Convenience getters for UI
  String get number => invoiceNumber;
  String get driverName => customerName;
  double get amount => total;
  double get paidAmount => status == InvoiceStatus.paid ? total : 0.0;
  double get remainingAmount => status == InvoiceStatus.paid ? 0.0 : total;

  factory Invoice.fromJson(Map<String, dynamic> json) =>
      _$InvoiceFromJson(json);
  Map<String, dynamic> toJson() => _$InvoiceToJson(this);

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
