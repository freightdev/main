import 'package:json_annotation/json_annotation.dart';

part 'document.g.dart';

enum DocumentType {
  @JsonValue('license')
  license,
  @JsonValue('insurance')
  insurance,
  @JsonValue('bill')
  bill,
  @JsonValue('inspection')
  inspection,
  @JsonValue('hazmat')
  hazmat,
  @JsonValue('delivery')
  delivery,
  @JsonValue('rateConfirmation')
  rateConfirmation,
  @JsonValue('pod')
  pod,
  @JsonValue('bol')
  bol,
  @JsonValue('other')
  other,
}

enum DocumentStatus {
  @JsonValue('verified')
  verified,
  @JsonValue('pending')
  pending,
  @JsonValue('expired')
  expired,
  @JsonValue('rejected')
  rejected,
}

@JsonSerializable()
class Document {
  final String id;
  final String driverId;
  final String driverName;
  final String loadId;
  final String fileUrl;
  final double fileSize;
  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime uploadedAt;
  @JsonKey(fromJson: _dateTimeFromJsonNullable, toJson: _dateTimeToJsonNullable)
  final DateTime? expiresAt;
  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime createdAt;
  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime updatedAt;
  final DocumentType type;
  final DocumentStatus status;

  const Document({
    required this.id,
    required this.driverId,
    required this.driverName,
    required this.loadId,
    required this.fileUrl,
    required this.fileSize,
    required this.uploadedAt,
    this.expiresAt,
    required this.createdAt,
    required this.updatedAt,
    required this.type,
    required this.status,
  });

  // Convenience getters for UI
  String get name => fileUrl.split('/').last;
  String get category => type.toString().split('.').last;
  String get fileSizeFormatted {
    if (fileSize < 1024) {
      return '${fileSize.toInt()} B';
    }
    if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  factory Document.fromJson(Map<String, dynamic> json) =>
      _$DocumentFromJson(json);
  Map<String, dynamic> toJson() => _$DocumentToJson(this);

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
