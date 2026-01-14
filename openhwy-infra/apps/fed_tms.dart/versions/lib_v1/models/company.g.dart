// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'company.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Company _$CompanyFromJson(Map<String, dynamic> json) => Company(
      id: json['id'] as String,
      name: json['name'] as String,
      legalName: json['legalName'] as String?,
      ein: json['ein'] as String?,
      mcNumber: json['mcNumber'] as String?,
      dotNumber: json['dotNumber'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      zipCode: json['zipCode'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      website: json['website'] as String?,
      logo: json['logo'] as String?,
      createdAt: Company._dateTimeFromJson(json['createdAt']),
      updatedAt: Company._dateTimeFromJson(json['updatedAt']),
    );

Map<String, dynamic> _$CompanyToJson(Company instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'legalName': instance.legalName,
      'ein': instance.ein,
      'mcNumber': instance.mcNumber,
      'dotNumber': instance.dotNumber,
      'address': instance.address,
      'city': instance.city,
      'state': instance.state,
      'zipCode': instance.zipCode,
      'phone': instance.phone,
      'email': instance.email,
      'website': instance.website,
      'logo': instance.logo,
      'createdAt': Company._dateTimeToJson(instance.createdAt),
      'updatedAt': Company._dateTimeToJson(instance.updatedAt),
    };
