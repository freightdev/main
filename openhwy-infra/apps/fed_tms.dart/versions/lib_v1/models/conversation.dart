import 'package:json_annotation/json_annotation.dart';
import '../models/message.dart';

part 'conversation.g.dart';

enum ConversationType {
  @JsonValue('individual')
  individual,
  @JsonValue('group')
  group,
  @JsonValue('dispatch')
  dispatch,
}

@JsonSerializable()
class Conversation {
  final String id;
  final String title;
  final ConversationType type;
  final List<Message> messages;
  final List<String> participants;
  final DateTime lastMessageAt;
  final bool isRead;
  final String? lastMessage;

  const Conversation({
    required this.id,
    required this.title,
    required this.type,
    required this.messages,
    required this.participants,
    required this.lastMessageAt,
    this.isRead = false,
    this.lastMessage,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) =>
      _$ConversationFromJson(json);
  Map<String, dynamic> toJson() => _$ConversationToJson(this);
}
