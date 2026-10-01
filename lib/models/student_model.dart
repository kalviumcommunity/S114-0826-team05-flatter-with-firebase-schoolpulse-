import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

@immutable
class StudentModel {
  const StudentModel({
    required this.id,
    required this.districtId,
    required this.schoolId,
    required this.studentNumber,
    required this.firstName,
    required this.lastName,
    required this.gradeLevel,
    required this.section,
    required this.dateOfBirth,
    required this.gender,
    required this.parentPhone,
    required this.parentEmail,
    this.address,
    this.photoUrl,
    this.status = StudentStatus.active,
    this.attendanceScore = 0,
    this.feeBalance = 0.0,
    this.examAverage = 0.0,
    this.riskLevel = RiskLevel.low,
    required this.enrolledAt,
    this.withdrawnAt,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String districtId;
  final String schoolId;
  final String studentNumber;
  final String firstName;
  final String lastName;
  final String gradeLevel;
  final String section;
  final DateTime dateOfBirth;
  final Gender gender;
  final String parentPhone;
  final String parentEmail;
  final String? address;
  final String? photoUrl;
  final StudentStatus status;
  final int attendanceScore;
  final double feeBalance;
  final double examAverage;
  final RiskLevel riskLevel;
  final DateTime enrolledAt;
  final DateTime? withdrawnAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory StudentModel.fromJson(Map<String, dynamic> json) => StudentModel(
    id: json['id'] as String,
    districtId: json['districtId'] as String,
    schoolId: json['schoolId'] as String,
    studentNumber: json['studentNumber'] as String,
    firstName: json['firstName'] as String,
    lastName: json['lastName'] as String,
    gradeLevel: json['gradeLevel'] as String,
    section: json['section'] as String,
    dateOfBirth: DateTime.parse(json['dateOfBirth'] as String),
    gender: Gender.values.firstWhere((e) => e.value == json['gender']),
    parentPhone: json['parentPhone'] as String,
    parentEmail: json['parentEmail'] as String,
    address: json['address'] as String?,
    photoUrl: json['photoUrl'] as String?,
    status: StudentStatus.values.firstWhere((e) => e.value == json['status']),
    attendanceScore: (json['attendanceScore'] as num?)?.toInt() ?? 0,
    feeBalance: (json['feeBalance'] as num?)?.toDouble() ?? 0.0,
    examAverage: (json['examAverage'] as num?)?.toDouble() ?? 0.0,
    riskLevel: RiskLevel.values.firstWhere((e) => e.value == json['riskLevel']),
    enrolledAt: DateTime.parse(json['enrolledAt'] as String),
    withdrawnAt: json['withdrawnAt'] != null ? DateTime.parse(json['withdrawnAt'] as String) : null,
    createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
    updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
  );

  factory StudentModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data()!;
    return StudentModel.fromJson({'id': snapshot.id, ...data});
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'districtId': districtId,
    'schoolId': schoolId,
    'studentNumber': studentNumber,
    'firstName': firstName,
    'lastName': lastName,
    'gradeLevel': gradeLevel,
    'section': section,
    'dateOfBirth': dateOfBirth.toIso8601String(),
    'gender': gender.value,
    'parentPhone': parentPhone,
    'parentEmail': parentEmail,
    'address': address,
    'photoUrl': photoUrl,
    'status': status.value,
    'attendanceScore': attendanceScore,
    'feeBalance': feeBalance,
    'examAverage': examAverage,
    'riskLevel': riskLevel.value,
    'enrolledAt': enrolledAt.toIso8601String(),
    'withdrawnAt': withdrawnAt?.toIso8601String(),
    'createdAt': createdAt?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
  };

  String get displayName => '$firstName $lastName';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudentModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          districtId == other.districtId &&
          schoolId == other.schoolId &&
          studentNumber == other.studentNumber &&
          firstName == other.firstName &&
          lastName == other.lastName &&
          gradeLevel == other.gradeLevel &&
          section == other.section &&
          dateOfBirth == other.dateOfBirth &&
          gender == other.gender &&
          parentPhone == other.parentPhone &&
          parentEmail == other.parentEmail &&
          address == other.address &&
          photoUrl == other.photoUrl &&
          status == other.status &&
          attendanceScore == other.attendanceScore &&
          feeBalance == other.feeBalance &&
          examAverage == other.examAverage &&
          riskLevel == other.riskLevel &&
          enrolledAt == other.enrolledAt &&
          withdrawnAt == other.withdrawnAt &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
    Object.hash(id, districtId, schoolId, studentNumber, firstName, lastName, gradeLevel, section),
    Object.hash(dateOfBirth, gender, parentPhone, parentEmail, address, photoUrl, status, attendanceScore),
    Object.hash(feeBalance, examAverage, riskLevel, enrolledAt, withdrawnAt, createdAt, updatedAt),
  );
}

enum Gender {
  // @JsonValue('male')
  male,
  // @JsonValue('female')
  female,
  // @JsonValue('other')
  other,
  // @JsonValue('prefer_not_to_say')
  preferNotToSay,
}

extension GenderExtension on Gender {
  String get value => name;
  String get displayName {
    switch (this) {
      case Gender.male:
        return 'Male';
      case Gender.female:
        return 'Female';
      case Gender.other:
        return 'Other';
      case Gender.preferNotToSay:
        return 'Prefer not to say';
    }
  }
}

enum StudentStatus {
  // @JsonValue('active')
  active,
  // @JsonValue('inactive')
  inactive,
  // @JsonValue('withdrawn')
  withdrawn,
  // @JsonValue('graduated')
  graduated,
  // @JsonValue('transferred')
  transferred;
}

extension StudentStatusExtension on StudentStatus {
  String get value => name;
  String get displayName {
    switch (this) {
      case StudentStatus.active:
        return 'Active';
      case StudentStatus.inactive:
        return 'Inactive';
      case StudentStatus.withdrawn:
        return 'Withdrawn';
      case StudentStatus.graduated:
        return 'Graduated';
      case StudentStatus.transferred:
        return 'Transferred';
    }
  }
}

enum RiskLevel {
  // @JsonValue('low')
  low,
  // @JsonValue('medium')
  medium,
  // @JsonValue('high')
  high,
  // @JsonValue('critical')
  critical,
}

extension RiskLevelExtension on RiskLevel {
  String get value => name;
  String get displayName {
    switch (this) {
      case RiskLevel.low:
        return 'Low Risk';
      case RiskLevel.medium:
        return 'Medium Risk';
      case RiskLevel.high:
        return 'High Risk';
      case RiskLevel.critical:
        return 'Critical Risk';
    }
  }

  Color get color {
    switch (this) {
      case RiskLevel.low:
        return const Color(0xFF10B981); // Green
      case RiskLevel.medium:
        return const Color(0xFFF59E0B); // Amber
      case RiskLevel.high:
        return const Color(0xFFF97316); // Orange
      case RiskLevel.critical:
        return const Color(0xFFEF4444); // Red
    }
  }

  int get priority {
    switch (this) {
      case RiskLevel.low:
        return 1;
      case RiskLevel.medium:
        return 2;
      case RiskLevel.high:
        return 3;
      case RiskLevel.critical:
        return 4;
    }
  }
}