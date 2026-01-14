// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invoice.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Invoice _$InvoiceFromJson(Map<String, dynamic> json) => Invoice(
      id: json['id'] as String,
      invoiceNumber: json['invoiceNumber'] as String,
      customerName: json['customerName'] as String,
      total: (json['total'] as num).toDouble(),
      status: $enumDecode(_$InvoiceStatusEnumMap, json['status']),
      issuedDate: Invoice._dateTimeFromJson(json['issuedDate']),
      dueDate: Invoice._dateTimeFromJson(json['dueDate']),
      paidDate: Invoice._dateTimeFromJsonNullable(json['paidDate']),
    );

Map<String, dynamic> _$InvoiceToJson(Invoice instance) => <String, dynamic>{
      'id': instance.id,
      'invoiceNumber': instance.invoiceNumber,
      'customerName': instance.customerName,
      'total': instance.total,
      'status': _$InvoiceStatusEnumMap[instance.status]!,
      'issuedDate': Invoice._dateTimeToJson(instance.issuedDate),
      'dueDate': Invoice._dateTimeToJson(instance.dueDate),
      'paidDate': Invoice._dateTimeToJsonNullable(instance.paidDate),
    };

const _$InvoiceStatusEnumMap = {
  InvoiceStatus.draft: 'draft',
  InvoiceStatus.pending: 'pending',
  InvoiceStatus.paid: 'paid',
  InvoiceStatus.overdue: 'overdue',
  InvoiceStatus.cancelled: 'cancelled',
};
