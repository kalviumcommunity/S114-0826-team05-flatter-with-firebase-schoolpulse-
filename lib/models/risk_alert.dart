import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'student_model.dart';
import 'package:meta/meta.dart';

@immutable
class RiskAlert {
  const RiskAlert({
    required this.id,
    required this.districtId,
    required this.schoolId,
    this.studentId,
    required this.category,
    required this.level,
    required this.title,
    required this.description,
    required this.metrics,
    required this.affectedEntities,
    this.isResolved = false,
    this.resolvedBy,
    this.resolvedAt,
    this.resolutionNotes,
    required this.triggeredAt,
    this.acknowledgedAt,
    this.acknowledgedBy,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String districtId;
  final String schoolId;
  final String? studentId;
  final RiskCategory category;
  final RiskLevel level;
  final String title;
  final String description;
  final Map<String, dynamic> metrics;
  final List<String> affectedEntities;
  final bool isResolved;
  final String? resolvedBy;
  final DateTime? resolvedAt;
  final String? resolutionNotes;
  final DateTime triggeredAt;
  final DateTime? acknowledgedAt;
  final String? acknowledgedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory RiskAlert.fromJson(Map<String, dynamic> json) => RiskAlert(
    id: json['id'] as String,
    districtId: json['districtId'] as String,
    schoolId: json['schoolId'] as String,
    studentId: json['studentId'] as String?,
    category: RiskCategory.values.firstWhere((e) => e.value == json['category']),
    level: RiskLevel.values.firstWhere((e) => e.value == json['level']),
    title: json['title'] as String,
    description: json['description'] as String,
    metrics: Map<String, dynamic>.from(json['metrics'] as Map),
    affectedEntities: List<String>.from(json['affectedEntities'] as List),
    isResolved: json['isResolved'] as bool? ?? false,
    resolvedBy: json['resolvedBy'] as String?,
    resolvedAt: json['resolvedAt'] != null ? DateTime.parse(json['resolvedAt'] as String) : null,
    resolutionNotes: json['resolutionNotes'] as String?,
    triggeredAt: DateTime.parse(json['triggeredAt'] as String),
    acknowledgedAt: json['acknowledgedAt'] != null ? DateTime.parse(json['acknowledgedAt'] as String) : null,
    acknowledgedBy: json['acknowledgedBy'] as String?,
    createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
    updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
  );

  factory RiskAlert.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data()!;
    return RiskAlert.fromJson({'id': snapshot.id, ...data});
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'districtId': districtId,
    'schoolId': schoolId,
    'studentId': studentId,
    'category': category.value,
    'level': level.value,
    'title': title,
    'description': description,
    'metrics': metrics,
    'affectedEntities': affectedEntities,
    'isResolved': isResolved,
    'resolvedBy': resolvedBy,
    'resolvedAt': resolvedAt?.toIso8601String(),
    'resolutionNotes': resolutionNotes,
    'triggeredAt': triggeredAt.toIso8601String(),
    'acknowledgedAt': acknowledgedAt?.toIso8601String(),
    'acknowledgedBy': acknowledgedBy,
    'createdAt': createdAt?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
  };

  RiskAlert copyWith({
    String? id,
    String? districtId,
    String? schoolId,
    String? studentId,
    RiskCategory? category,
    RiskLevel? level,
    String? title,
    String? description,
    Map<String, dynamic>? metrics,
    List<String>? affectedEntities,
    bool? isResolved,
    String? resolvedBy,
    DateTime? resolvedAt,
    String? resolutionNotes,
    DateTime? triggeredAt,
    DateTime? acknowledgedAt,
    String? acknowledgedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RiskAlert(
      id: id ?? this.id,
      districtId: districtId ?? this.districtId,
      schoolId: schoolId ?? this.schoolId,
      studentId: studentId ?? this.studentId,
      category: category ?? this.category,
      level: level ?? this.level,
      title: title ?? this.title,
      description: description ?? this.description,
      metrics: metrics ?? this.metrics,
      affectedEntities: affectedEntities ?? this.affectedEntities,
      isResolved: isResolved ?? this.isResolved,
      resolvedBy: resolvedBy ?? this.resolvedBy,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolutionNotes: resolutionNotes ?? this.resolutionNotes,
      triggeredAt: triggeredAt ?? this.triggeredAt,
      acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
      acknowledgedBy: acknowledgedBy ?? this.acknowledgedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RiskAlert &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          districtId == other.districtId &&
          schoolId == other.schoolId &&
          studentId == other.studentId &&
          category == other.category &&
          level == other.level &&
          title == other.title &&
          description == other.description &&
          metrics == other.metrics &&
          affectedEntities == other.affectedEntities &&
          isResolved == other.isResolved &&
          resolvedBy == other.resolvedBy &&
          resolvedAt == other.resolvedAt &&
          resolutionNotes == other.resolutionNotes &&
          triggeredAt == other.triggeredAt &&
          acknowledgedAt == other.acknowledgedAt &&
          acknowledgedBy == other.acknowledgedBy &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
    id,
    districtId,
    schoolId,
    studentId,
    category,
    level,
    title,
    description,
    metrics,
    affectedEntities,
    isResolved,
    resolvedBy,
    resolvedAt,
    resolutionNotes,
    triggeredAt,
    acknowledgedAt,
    acknowledgedBy,
    createdAt,
    updatedAt,
  );
}

enum RiskCategory {
  // @JsonValue('attendance')
  attendance,
  // @JsonValue('fees')
  fees,
  // @JsonValue('academic')
  academic,
  // @JsonValue('enrollment')
  enrollment,
  // @JsonValue('operational')
  operational,
  // @JsonValue('composite')
  composite,
}

extension RiskCategoryExtension on RiskCategory {
  String get value => name;
  String get displayName {
    switch (this) {
      case RiskCategory.attendance:
        return 'Attendance Risk';
      case RiskCategory.fees:
        return 'Fee Collection Risk';
      case RiskCategory.academic:
        return 'Academic Performance Risk';
      case RiskCategory.enrollment:
        return 'Enrollment Risk';
      case RiskCategory.operational:
        return 'Operational Risk';
      case RiskCategory.composite:
        return 'Composite Risk';
    }
  }

  IconData get icon {
    switch (this) {
      case RiskCategory.attendance:
        return Icons.assignment_ind;
      case RiskCategory.fees:
        return Icons.account_balance_wallet;
      case RiskCategory.academic:
        return Icons.school;
      case RiskCategory.enrollment:
        return Icons.people;
      case RiskCategory.operational:
        return Icons.warning;
      case RiskCategory.composite:
        return Icons.analytics;
    }
  }
}

@immutable
class SchoolRiskProfile {
  const SchoolRiskProfile({
    required this.schoolId,
    required this.schoolName,
    required this.districtId,
    required this.totalStudents,
    required this.attendanceRate,
    required this.feeCollectionRate,
    required this.examPassRate,
    required this.enrollmentTrend,
    required this.overallRiskLevel,
    required this.compositeScore,
    required this.categoryRisks,
    required this.activeAlerts,
    required this.calculatedAt,
  });

  final String schoolId;
  final String schoolName;
  final String districtId;
  final int totalStudents;
  final double attendanceRate;
  final double feeCollectionRate;
  final double examPassRate;
  final double enrollmentTrend;
  final RiskLevel overallRiskLevel;
  final double compositeScore;
  final Map<RiskCategory, RiskLevel> categoryRisks;
  final List<RiskAlert> activeAlerts;
  final DateTime calculatedAt;

  factory SchoolRiskProfile.fromJson(Map<String, dynamic> json) => SchoolRiskProfile(
    schoolId: json['schoolId'] as String,
    schoolName: json['schoolName'] as String,
    districtId: json['districtId'] as String,
    totalStudents: (json['totalStudents'] as num).toInt(),
    attendanceRate: (json['attendanceRate'] as num).toDouble(),
    feeCollectionRate: (json['feeCollectionRate'] as num).toDouble(),
    examPassRate: (json['examPassRate'] as num).toDouble(),
    enrollmentTrend: (json['enrollmentTrend'] as num).toDouble(),
    overallRiskLevel: RiskLevel.values.firstWhere((e) => e.value == json['overallRiskLevel']),
    compositeScore: (json['compositeScore'] as num).toDouble(),
    categoryRisks: (json['categoryRisks'] as Map).map(
      (k, v) => MapEntry(
        RiskCategory.values.firstWhere((e) => e.value == k),
        RiskLevel.values.firstWhere((e) => e.value == v),
      ),
    ),
    activeAlerts: (json['activeAlerts'] as List)
        .map((e) => RiskAlert.fromJson(e as Map<String, dynamic>))
        .toList(),
    calculatedAt: DateTime.parse(json['calculatedAt'] as String),
  );

  Map<String, dynamic> toJson() => {
    'schoolId': schoolId,
    'schoolName': schoolName,
    'districtId': districtId,
    'totalStudents': totalStudents,
    'attendanceRate': attendanceRate,
    'feeCollectionRate': feeCollectionRate,
    'examPassRate': examPassRate,
    'enrollmentTrend': enrollmentTrend,
    'overallRiskLevel': overallRiskLevel.value,
    'compositeScore': compositeScore,
    'categoryRisks': categoryRisks.map((k, v) => MapEntry(k.value, v.value)),
    'activeAlerts': activeAlerts.map((e) => e.toJson()).toList(),
    'calculatedAt': calculatedAt.toIso8601String(),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SchoolRiskProfile &&
          runtimeType == other.runtimeType &&
          schoolId == other.schoolId &&
          schoolName == other.schoolName &&
          districtId == other.districtId &&
          totalStudents == other.totalStudents &&
          attendanceRate == other.attendanceRate &&
          feeCollectionRate == other.feeCollectionRate &&
          examPassRate == other.examPassRate &&
          enrollmentTrend == other.enrollmentTrend &&
          overallRiskLevel == other.overallRiskLevel &&
          compositeScore == other.compositeScore &&
          categoryRisks == other.categoryRisks &&
          activeAlerts == other.activeAlerts &&
          calculatedAt == other.calculatedAt;

  @override
  int get hashCode => Object.hash(
    schoolId,
    schoolName,
    districtId,
    totalStudents,
    attendanceRate,
    feeCollectionRate,
    examPassRate,
    enrollmentTrend,
    overallRiskLevel,
    compositeScore,
    categoryRisks,
    activeAlerts,
    calculatedAt,
  );
}

@immutable
class DistrictRiskSummary {
  const DistrictRiskSummary({
    required this.districtId,
    required this.districtName,
    required this.totalSchools,
    required this.totalStudents,
    required this.overallAttendanceRate,
    required this.overallFeeCollectionRate,
    required this.overallExamPassRate,
    required this.schoolsByRiskLevel,
    required this.alertsByCategory,
    required this.topRiskSchools,
    required this.calculatedAt,
  });

  final String districtId;
  final String districtName;
  final int totalSchools;
  final int totalStudents;
  final double overallAttendanceRate;
  final double overallFeeCollectionRate;
  final double overallExamPassRate;
  final Map<RiskLevel, int> schoolsByRiskLevel;
  final Map<RiskCategory, int> alertsByCategory;
  final List<SchoolRiskProfile> topRiskSchools;
  final DateTime calculatedAt;

  factory DistrictRiskSummary.fromJson(Map<String, dynamic> json) => DistrictRiskSummary(
    districtId: json['districtId'] as String,
    districtName: json['districtName'] as String,
    totalSchools: (json['totalSchools'] as num).toInt(),
    totalStudents: (json['totalStudents'] as num).toInt(),
    overallAttendanceRate: (json['overallAttendanceRate'] as num).toDouble(),
    overallFeeCollectionRate: (json['overallFeeCollectionRate'] as num).toDouble(),
    overallExamPassRate: (json['overallExamPassRate'] as num).toDouble(),
    schoolsByRiskLevel: (json['schoolsByRiskLevel'] as Map).map(
      (k, v) => MapEntry(
        RiskLevel.values.firstWhere((e) => e.value == k),
        (v as num).toInt(),
      ),
    ),
    alertsByCategory: (json['alertsByCategory'] as Map).map(
      (k, v) => MapEntry(
        RiskCategory.values.firstWhere((e) => e.value == k),
        (v as num).toInt(),
      ),
    ),
    topRiskSchools: (json['topRiskSchools'] as List)
        .map((e) => SchoolRiskProfile.fromJson(e as Map<String, dynamic>))
        .toList(),
    calculatedAt: DateTime.parse(json['calculatedAt'] as String),
  );

  Map<String, dynamic> toJson() => {
    'districtId': districtId,
    'districtName': districtName,
    'totalSchools': totalSchools,
    'totalStudents': totalStudents,
    'overallAttendanceRate': overallAttendanceRate,
    'overallFeeCollectionRate': overallFeeCollectionRate,
    'overallExamPassRate': overallExamPassRate,
    'schoolsByRiskLevel': schoolsByRiskLevel.map((k, v) => MapEntry(k.value, v)),
    'alertsByCategory': alertsByCategory.map((k, v) => MapEntry(k.value, v)),
    'topRiskSchools': topRiskSchools.map((e) => e.toJson()).toList(),
    'calculatedAt': calculatedAt.toIso8601String(),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DistrictRiskSummary &&
          runtimeType == other.runtimeType &&
          districtId == other.districtId &&
          districtName == other.districtName &&
          totalSchools == other.totalSchools &&
          totalStudents == other.totalStudents &&
          overallAttendanceRate == other.overallAttendanceRate &&
          overallFeeCollectionRate == other.overallFeeCollectionRate &&
          overallExamPassRate == other.overallExamPassRate &&
          schoolsByRiskLevel == other.schoolsByRiskLevel &&
          alertsByCategory == other.alertsByCategory &&
          topRiskSchools == other.topRiskSchools &&
          calculatedAt == other.calculatedAt;

  @override
  int get hashCode => Object.hash(
    districtId,
    districtName,
    totalSchools,
    totalStudents,
    overallAttendanceRate,
    overallFeeCollectionRate,
    overallExamPassRate,
    schoolsByRiskLevel,
    alertsByCategory,
    topRiskSchools,
    calculatedAt,
  );
}