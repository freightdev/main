// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'document.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Document _$DocumentFromJson(Map<String, dynamic> json) => Document(
      id: json['id'] as String,
      driverId: json['driverId'] as String,
      driverName: json['driverName'] as String,
      loadId: json['loadId'] as String,
      fileUrl: json['fileUrl'] as String,
      fileSize: (json['fileSize'] as num).toDouble(),
      uploadedAt: Document._dateTimeFromJson(json['uploadedAt']),
      expiresAt: Document._dateTimeFromJsonNullable(json['expiresAt']),
      createdAt: Document._dateTimeFromJson(json['createdAt']),
      updatedAt: Document._dateTimeFromJson(json['updatedAt']),
      type: $enumDecode(_$DocumentTypeEnumMap, json['type']),
      status: $enumDecode(_$DocumentStatusEnumMap, json['status']),
    );

Map<String, dynamic> _$DocumentToJson(Document instance) => <String, dynamic>{
      'id': instance.id,
      'driverId': instance.driverId,
      'driverName': instance.driverName,
      'loadId': instance.loadId,
      'fileUrl': instance.fileUrl,
      'fileSize': instance.fileSize,
      'uploadedAt': Document._dateTimeToJson(instance.uploadedAt),
      'expiresAt': Document._dateTimeToJsonNullable(instance.expiresAt),
      'createdAt': Document._dateTimeToJson(instance.createdAt),
      'updatedAt': Document._dateTimeToJson(instance.updatedAt),
      'type': _$DocumentTypeEnumMap[instance.type]!,
      'status': _$DocumentStatusEnumMap[instance.status]!,
    };

const _$DocumentTypeEnumMap = {
  DocumentType.license: 'license',
  DocumentType.insurance: 'insurance',
  DocumentType.bill: 'bill',
  DocumentType.inspection: 'inspection',
  DocumentType.hazmat: 'hazmat',
  DocumentType.delivery: 'delivery',
  DocumentType.rateConfirmation: 'rateConfirmation',
  DocumentType.pod: 'pod',
  DocumentType.bol: 'bol',
  DocumentType.other: 'other',
};

const _$DocumentStatusEnumMap = {
  DocumentStatus.verified: 'verified',
  DocumentStatus.pending: 'pending',
  DocumentStatus.expired: 'expired',
  DocumentStatus.rejected: 'rejected',
};
