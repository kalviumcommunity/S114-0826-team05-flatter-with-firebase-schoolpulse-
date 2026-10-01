import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meta/meta.dart';
import 'package:flutter/material.dart';

@immutable
class DistrictModel {
  const DistrictModel({
    required this.id,
    required this.name,
    required this.code,
    required this.address,
    required this.phone,
    required this.email,
    required this.superintendentName,
    this.isActive = true,
    this.settings = const {},
    required this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String code;
  final String address;
  final String phone;
  final String email;
  final String superintendentName;
  final bool isActive;
  final Map<String, dynamic> settings;
  final DateTime createdAt;
  final DateTime? updatedAt;

  factory DistrictModel.fromJson(Map<String, dynamic> json) => DistrictModel(
    id: json['id'] as String,
    name: json['name'] as String,
    code: json['code'] as String,
    address: json['address'] as String,
    phone: json['phone'] as String,
    email: json['email'] as String,
    superintendentName: json['superintendentName'] as String,
    isActive: json['isActive'] as bool? ?? true,
    settings: Map<String, dynamic>.from(json['settings'] as Map? ?? {}),
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
  );

  factory DistrictModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data()!;
    return DistrictModel.fromJson({'id': snapshot.id, ...data});
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'code': code,
    'address': address,
    'phone': phone,
    'email': email,
    'superintendentName': superintendentName,
    'isActive': isActive,
    'settings': settings,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DistrictModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          code == other.code &&
          address == other.address &&
          phone == other.phone &&
          email == other.email &&
          superintendentName == other.superintendentName &&
          isActive == other.isActive &&
          settings == other.settings &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    code,
    address,
    phone,
    email,
    superintendentName,
    isActive,
    settings,
    createdAt,
    updatedAt,
  );
}

@immutable
class SchoolModel {
  const SchoolModel({
    required this.id,
    required this.districtId,
    required this.name,
    required this.code,
    required this.type,
    required this.address,
    required this.phone,
    required this.email,
    required this.principalName,
    required this.principalPhone,
    required this.principalEmail,
    this.totalCapacity = 0,
    this.currentEnrollment = 0,
    this.gradeLevels = const [],
    this.isActive = true,
    this.settings = const {},
    required this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String districtId;
  final String name;
  final String code;
  final SchoolType type;
  final String address;
  final String phone;
  final String email;
  final String principalName;
  final String principalPhone;
  final String principalEmail;
  final int totalCapacity;
  final int currentEnrollment;
  final List<String> gradeLevels;
  final bool isActive;
  final Map<String, dynamic> settings;
  final DateTime createdAt;
  final DateTime? updatedAt;

  factory SchoolModel.fromJson(Map<String, dynamic> json) => SchoolModel(
    id: json['id'] as String,
    districtId: json['districtId'] as String,
    name: json['name'] as String,
    code: json['code'] as String,
    type: SchoolType.values.firstWhere((e) => e.value == json['type']),
    address: json['address'] as String,
    phone: json['phone'] as String,
    email: json['email'] as String,
    principalName: json['principalName'] as String,
    principalPhone: json['principalPhone'] as String,
    principalEmail: json['principalEmail'] as String,
    totalCapacity: (json['totalCapacity'] as num?)?.toInt() ?? 0,
    currentEnrollment: (json['currentEnrollment'] as num?)?.toInt() ?? 0,
    gradeLevels: List<String>.from(json['gradeLevels'] as List? ?? []),
    isActive: json['isActive'] as bool? ?? true,
    settings: Map<String, dynamic>.from(json['settings'] as Map? ?? {}),
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
  );

  factory SchoolModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data()!;
    return SchoolModel.fromJson({'id': snapshot.id, ...data});
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'districtId': districtId,
    'name': name,
    'code': code,
    'type': type.value,
    'address': address,
    'phone': phone,
    'email': email,
    'principalName': principalName,
    'principalPhone': principalPhone,
    'principalEmail': principalEmail,
    'totalCapacity': totalCapacity,
    'currentEnrollment': currentEnrollment,
    'gradeLevels': gradeLevels,
    'isActive': isActive,
    'settings': settings,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
  };

  double get utilizationRate => totalCapacity > 0 ? (currentEnrollment / totalCapacity) * 100 : 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SchoolModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          districtId == other.districtId &&
          name == other.name &&
          code == other.code &&
          type == other.type &&
          address == other.address &&
          phone == other.phone &&
          email == other.email &&
          principalName == other.principalName &&
          principalPhone == other.principalPhone &&
          principalEmail == other.principalEmail &&
          totalCapacity == other.totalCapacity &&
          currentEnrollment == other.currentEnrollment &&
          gradeLevels == other.gradeLevels &&
          isActive == other.isActive &&
          settings == other.settings &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
    id,
    districtId,
    name,
    code,
    type,
    address,
    phone,
    email,
    principalName,
    principalPhone,
    principalEmail,
    totalCapacity,
    currentEnrollment,
    gradeLevels,
    isActive,
    settings,
    createdAt,
    updatedAt,
  );
}

enum SchoolType {
  // @JsonValue('elementary')
  elementary,
  // @JsonValue('middle')
  middle,
  // @JsonValue('high')
  high,
  // @JsonValue('k12')
  k12,
  // @JsonValue('alternative')
  alternative,
  // @JsonValue('charter')
  charter,
}

extension SchoolTypeExtension on SchoolType {
  String get value => name;
  String get displayName {
    switch (this) {
      case SchoolType.elementary:
        return 'Elementary';
      case SchoolType.middle:
        return 'Middle School';
      case SchoolType.high:
        return 'High School';
      case SchoolType.k12:
        return 'K-12';
      case SchoolType.alternative:
        return 'Alternative';
      case SchoolType.charter:
        return 'Charter';
    }
  }
}