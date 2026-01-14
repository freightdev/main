import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'company.g.dart';

@JsonSerializable()
class Company extends Equatable {
  final String id;
  final String name;
  final String? legalName;
  final String? ein;
  final String? mcNumber;
  final String? dotNumber;
  final String? address;
  final String? city;
  final String? state;
  final String? zipCode;
  final String? phone;
  final String? email;
  final String? website;
  final String? logo;
  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime createdAt;
  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime updatedAt;

  const Company({
    required this.id,
    required this.name,
    this.legalName,
    this.ein,
    this.mcNumber,
    this.dotNumber,
    this.address,
    this.city,
    this.state,
    this.zipCode,
    this.phone,
    this.email,
    this.website,
    this.logo,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Company.fromJson(Map<String, dynamic> json) =>
      _$CompanyFromJson(json);
  Map<String, dynamic> toJson() => _$CompanyToJson(this);

  static DateTime _dateTimeFromJson(dynamic json) {
    if (json == null) return DateTime.now();
    return json is String ? DateTime.parse(json) : json;
  }

  static dynamic _dateTimeToJson(DateTime dateTime) =>
      dateTime.toIso8601String();

  @override
  List<Object?> get props => [
        id,
        name,
        legalName,
        ein,
        mcNumber,
        dotNumber,
        address,
        city,
        state,
        zipCode,
        phone,
        email,
        website,
        logo,
        createdAt,
        updatedAt,
      ];

  Company copyWith({
    String? id,
    String? name,
    String? legalName,
    String? ein,
    String? mcNumber,
    String? dotNumber,
    String? address,
    String? city,
    String? state,
    String? zipCode,
    String? phone,
    String? email,
    String? website,
    String? logo,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Company(
      id: id ?? this.id,
      name: name ?? this.name,
      legalName: legalName ?? this.legalName,
      ein: ein ?? this.ein,
      mcNumber: mcNumber ?? this.mcNumber,
      dotNumber: dotNumber ?? this.dotNumber,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      zipCode: zipCode ?? this.zipCode,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      website: website ?? this.website,
      logo: logo ?? this.logo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
