import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meta/meta.dart';

@immutable
class UserModel {
  const UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    required this.districtId,
    this.schoolId,
    this.photoUrl,
    this.isActive = false,
    this.permissions = const [],
    required this.createdAt,
    this.updatedAt,
    this.lastLoginAt,
  });

  final String uid;
  final String email;
  final String displayName;
  final UserRole role;
  final String districtId;
  final String? schoolId;
  final String? photoUrl;
  final bool isActive;
  final List<String> permissions;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? lastLoginAt;

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    uid: json['uid'] as String,
    email: json['email'] as String,
    displayName: json['displayName'] as String,
    role: UserRole.values.firstWhere((e) => e.value == json['role']),
    districtId: json['districtId'] as String,
    schoolId: json['schoolId'] as String?,
    photoUrl: json['photoUrl'] as String?,
    isActive: json['isActive'] as bool? ?? false,
    permissions: List<String>.from(json['permissions'] as List? ?? []),
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
    lastLoginAt: json['lastLoginAt'] != null ? DateTime.parse(json['lastLoginAt'] as String) : null,
  );

  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data()!;
    return UserModel.fromJson({'uid': snapshot.id, ...data});
  }

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'email': email,
    'displayName': displayName,
    'role': role.value,
    'districtId': districtId,
    'schoolId': schoolId,
    'photoUrl': photoUrl,
    'isActive': isActive,
    'permissions': permissions,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
    'lastLoginAt': lastLoginAt?.toIso8601String(),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel &&
          runtimeType == other.runtimeType &&
          uid == other.uid &&
          email == other.email &&
          displayName == other.displayName &&
          role == other.role &&
          districtId == other.districtId &&
          schoolId == other.schoolId &&
          photoUrl == other.photoUrl &&
          isActive == other.isActive &&
          permissions == other.permissions &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt &&
          lastLoginAt == other.lastLoginAt;

  @override
  int get hashCode => Object.hash(
    uid,
    email,
    displayName,
    role,
    districtId,
    schoolId,
    photoUrl,
    isActive,
    permissions,
    createdAt,
    updatedAt,
    lastLoginAt,
  );
}

enum UserRole {
  // @JsonValue('super_admin')
  superAdmin,
  // @JsonValue('district_admin')
  districtAdmin,
  // @JsonValue('school_admin')
  schoolAdmin,
  // @JsonValue('teacher')
  teacher,
  // @JsonValue('viewer')
  viewer,
}

extension UserRoleExtension on UserRole {
  String get value => name;
  String get displayName {
    switch (this) {
      case UserRole.superAdmin:
        return 'Super Administrator';
      case UserRole.districtAdmin:
        return 'District Administrator';
      case UserRole.schoolAdmin:
        return 'School Administrator';
      case UserRole.teacher:
        return 'Teacher';
      case UserRole.viewer:
        return 'Viewer';
    }
  }

  List<String> get defaultPermissions {
    switch (this) {
      case UserRole.superAdmin:
        return ['*'];
      case UserRole.districtAdmin:
        return [
          'district:read',
          'district:write',
          'school:read',
          'school:write',
          'student:read',
          'student:write',
          'attendance:read',
          'attendance:write',
          'fees:read',
          'fees:write',
          'exams:read',
          'exams:write',
          'risk:read',
          'risk:write',
          'reports:read',
          'reports:write',
        ];
      case UserRole.schoolAdmin:
        return [
          'school:read',
          'school:write',
          'student:read',
          'student:write',
          'attendance:read',
          'attendance:write',
          'fees:read',
          'fees:write',
          'exams:read',
          'exams:write',
          'risk:read',
          'reports:read',
        ];
      case UserRole.teacher:
        return [
          'student:read',
          'attendance:read',
          'attendance:write',
          'fees:read',
          'exams:read',
          'risk:read',
        ];
      case UserRole.viewer:
        return [
          'student:read',
          'attendance:read',
          'fees:read',
          'exams:read',
          'risk:read',
          'reports:read',
        ];
    }
  }
}