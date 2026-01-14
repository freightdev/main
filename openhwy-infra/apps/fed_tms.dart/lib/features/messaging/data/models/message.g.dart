// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Message _$MessageFromJson(Map<String, dynamic> json) => Message(
      id: json['id'] as String,
      content: json['content'] as String,
      status: $enumDecode(_$MessageStatusEnumMap, json['status']),
      timestamp: Message._dateTimeFromJson(json['timestamp']),
      senderId: json['senderId'] as String?,
      recipientId: json['recipientId'] as String?,
      conversationId: json['conversationId'] as String?,
    );

Map<String, dynamic> _$MessageToJson(Message instance) => <String, dynamic>{
      'id': instance.id,
      'content': instance.content,
      'status': _$MessageStatusEnumMap[instance.status]!,
      'timestamp': Message._dateTimeToJson(instance.timestamp),
      'senderId': instance.senderId,
      'recipientId': instance.recipientId,
      'conversationId': instance.conversationId,
    };

const _$MessageStatusEnumMap = {
  MessageStatus.sent: 'sent',
  MessageStatus.delivered: 'delivered',
  MessageStatus.read: 'read',
};
