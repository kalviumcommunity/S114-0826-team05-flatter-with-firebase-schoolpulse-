import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

@immutable
class AttendanceRecord {
  const AttendanceRecord({
    required this.id,
    required this.districtId,
    required this.schoolId,
    required this.studentId,
    required this.date,
    required this.status,
    this.period,
    this.subject,
    this.recordedBy,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String districtId;
  final String schoolId;
  final String studentId;
  final DateTime date;
  final AttendanceStatus status;
  final String? period;
  final String? subject;
  final String? recordedBy;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) => AttendanceRecord(
    id: json['id'] as String,
    districtId: json['districtId'] as String,
    schoolId: json['schoolId'] as String,
    studentId: json['studentId'] as String,
    date: DateTime.parse(json['date'] as String),
    status: AttendanceStatus.values.firstWhere((e) => e.value == json['status']),
    period: json['period'] as String?,
    subject: json['subject'] as String?,
    recordedBy: json['recordedBy'] as String?,
    notes: json['notes'] as String?,
    createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
    updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
  );

  factory AttendanceRecord.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data()!;
    return AttendanceRecord.fromJson({'id': snapshot.id, ...data});
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'districtId': districtId,
    'schoolId': schoolId,
    'studentId': studentId,
    'date': date.toIso8601String(),
    'status': status.value,
    'period': period,
    'subject': subject,
    'recordedBy': recordedBy,
    'notes': notes,
    'createdAt': createdAt?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AttendanceRecord &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          districtId == other.districtId &&
          schoolId == other.schoolId &&
          studentId == other.studentId &&
          date == other.date &&
          status == other.status &&
          period == other.period &&
          subject == other.subject &&
          recordedBy == other.recordedBy &&
          notes == other.notes &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
    id,
    districtId,
    schoolId,
    studentId,
    date,
    status,
    period,
    subject,
    recordedBy,
    notes,
    createdAt,
    updatedAt,
  );
}

enum AttendanceStatus {
  // @JsonValue('present')
  present,
  // @JsonValue('absent')
  absent,
  // @JsonValue('late')
  late,
  // @JsonValue('excused')
  excused,
  // @JsonValue('partial')
  partial,
}

extension AttendanceStatusExtension on AttendanceStatus {
  String get value => name;
  String get displayName {
    switch (this) {
      case AttendanceStatus.present:
        return 'Present';
      case AttendanceStatus.absent:
        return 'Absent';
      case AttendanceStatus.late:
        return 'Late';
      case AttendanceStatus.excused:
        return 'Excused';
      case AttendanceStatus.partial:
        return 'Partial';
    }
  }

  double get weight {
    switch (this) {
      case AttendanceStatus.present:
        return 1.0;
      case AttendanceStatus.late:
        return 0.75;
      case AttendanceStatus.partial:
        return 0.5;
      case AttendanceStatus.excused:
        return 1.0;
      case AttendanceStatus.absent:
        return 0.0;
    }
  }

  Color get color {
    switch (this) {
      case AttendanceStatus.present:
        return const Color(0xFF10B981);
      case AttendanceStatus.absent:
        return const Color(0xFFEF4444);
      case AttendanceStatus.late:
        return const Color(0xFFF59E0B);
      case AttendanceStatus.excused:
        return const Color(0xFF3B82F6);
      case AttendanceStatus.partial:
        return const Color(0xFF8B5CF6);
    }
  }
}