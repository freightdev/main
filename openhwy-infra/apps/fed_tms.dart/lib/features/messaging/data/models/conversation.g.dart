// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Conversation _$ConversationFromJson(Map<String, dynamic> json) => Conversation(
      id: json['id'] as String,
      title: json['title'] as String,
      type: $enumDecode(_$ConversationTypeEnumMap, json['type']),
      messages: (json['messages'] as List<dynamic>)
          .map((e) => Message.fromJson(e as Map<String, dynamic>))
          .toList(),
      participants: (json['participants'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      lastMessageAt: DateTime.parse(json['lastMessageAt'] as String),
      isRead: json['isRead'] as bool? ?? false,
      lastMessage: json['lastMessage'] as String?,
    );

Map<String, dynamic> _$ConversationToJson(Conversation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'type': _$ConversationTypeEnumMap[instance.type]!,
      'messages': instance.messages,
      'participants': instance.participants,
      'lastMessageAt': instance.lastMessageAt.toIso8601String(),
      'isRead': instance.isRead,
      'lastMessage': instance.lastMessage,
    };

const _$ConversationTypeEnumMap = {
  ConversationType.individual: 'individual',
  ConversationType.group: 'group',
  ConversationType.dispatch: 'dispatch',
};
