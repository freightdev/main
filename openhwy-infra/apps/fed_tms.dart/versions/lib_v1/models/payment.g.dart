// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Payment _$PaymentFromJson(Map<String, dynamic> json) => Payment(
      id: json['id'] as String,
      invoiceId: json['invoiceId'] as String,
      amount: (json['amount'] as num).toDouble(),
      status: $enumDecode(_$PaymentStatusEnumMap, json['status']),
      dueDate: Payment._dateTimeFromJson(json['dueDate']),
      paidDate: Payment._dateTimeFromJsonNullable(json['paidDate']),
    );

Map<String, dynamic> _$PaymentToJson(Payment instance) => <String, dynamic>{
      'id': instance.id,
      'invoiceId': instance.invoiceId,
      'amount': instance.amount,
      'status': _$PaymentStatusEnumMap[instance.status]!,
      'dueDate': Payment._dateTimeToJson(instance.dueDate),
      'paidDate': Payment._dateTimeToJsonNullable(instance.paidDate),
    };

const _$PaymentStatusEnumMap = {
  PaymentStatus.pending: 'pending',
  PaymentStatus.paid: 'paid',
  PaymentStatus.failed: 'failed',
};
