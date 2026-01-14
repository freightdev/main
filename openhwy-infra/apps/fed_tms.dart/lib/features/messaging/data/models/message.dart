import 'package:json_annotation/json_annotation.dart';

part 'package:fed_tms/features/messaging/data/models/message.g.dart';

enum MessageStatus {
  @JsonValue('sent')
  sent,
  @JsonValue('delivered')
  delivered,
  @JsonValue('read')
  read,
}

enum ConversationParticipant {
  @JsonValue('driver')
  driver,
  @JsonValue('dispatcher')
  dispatcher,
  @JsonValue('system')
  system,
}

@JsonSerializable()
class Message {
  final String id;
  final String content;
  final MessageStatus status;
  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime timestamp;
  final String? senderId;
  final String? recipientId;
  final String? conversationId;

  const Message({
    required this.id,
    required this.content,
    required this.status,
    required this.timestamp,
    this.senderId,
    this.recipientId,
    this.conversationId,
  });

  factory Message.fromJson(Map<String, dynamic> json) =>
      _$MessageFromJson(json);
  Map<String, dynamic> toJson() => _$MessageToJson(this);

  static DateTime _dateTimeFromJson(dynamic json) {
    if (json == null) return DateTime.now();
    return json is String ? DateTime.parse(json) : json;
  }

  static dynamic _dateTimeToJson(DateTime dateTime) =>
      dateTime.toIso8601String();

  bool get isRead => status == MessageStatus.read;
}
