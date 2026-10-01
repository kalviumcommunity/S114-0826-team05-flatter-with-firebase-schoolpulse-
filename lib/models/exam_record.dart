import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

@immutable
class ExamRecord {
  const ExamRecord({
    required this.id,
    required this.districtId,
    required this.schoolId,
    required this.studentId,
    required this.examName,
    required this.subject,
    required this.type,
    required this.examDate,
    required this.maxScore,
    this.obtainedScore,
    this.grade,
    required this.status,
    this.evaluatedBy,
    this.evaluatedAt,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String districtId;
  final String schoolId;
  final String studentId;
  final String examName;
  final String subject;
  final ExamType type;
  final DateTime examDate;
  final double maxScore;
  final double? obtainedScore;
  final String? grade;
  final ExamStatus status;
  final String? evaluatedBy;
  final DateTime? evaluatedAt;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory ExamRecord.fromJson(Map<String, dynamic> json) => ExamRecord(
    id: json['id'] as String,
    districtId: json['districtId'] as String,
    schoolId: json['schoolId'] as String,
    studentId: json['studentId'] as String,
    examName: json['examName'] as String,
    subject: json['subject'] as String,
    type: ExamType.values.firstWhere((e) => e.value == json['type']),
    examDate: DateTime.parse(json['examDate'] as String),
    maxScore: (json['maxScore'] as num).toDouble(),
    obtainedScore: (json['obtainedScore'] as num?)?.toDouble(),
    grade: json['grade'] as String?,
    status: ExamStatus.values.firstWhere((e) => e.value == json['status']),
    evaluatedBy: json['evaluatedBy'] as String?,
    evaluatedAt: json['evaluatedAt'] != null ? DateTime.parse(json['evaluatedAt'] as String) : null,
    notes: json['notes'] as String?,
    createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
    updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
  );

  factory ExamRecord.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data()!;
    return ExamRecord.fromJson({'id': snapshot.id, ...data});
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'districtId': districtId,
    'schoolId': schoolId,
    'studentId': studentId,
    'examName': examName,
    'subject': subject,
    'type': type.value,
    'examDate': examDate.toIso8601String(),
    'maxScore': maxScore,
    'obtainedScore': obtainedScore,
    'grade': grade,
    'status': status.value,
    'evaluatedBy': evaluatedBy,
    'evaluatedAt': evaluatedAt?.toIso8601String(),
    'notes': notes,
    'createdAt': createdAt?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
  };

  double get percentage => maxScore > 0 && obtainedScore != null ? (obtainedScore! / maxScore) * 100 : 0;
  bool get isCompleted => status == ExamStatus.completed || status == ExamStatus.graded;
  bool get isOverdue => examDate.isBefore(DateTime.now()) && !isCompleted;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExamRecord &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          districtId == other.districtId &&
          schoolId == other.schoolId &&
          studentId == other.studentId &&
          examName == other.examName &&
          subject == other.subject &&
          type == other.type &&
          examDate == other.examDate &&
          maxScore == other.maxScore &&
          obtainedScore == other.obtainedScore &&
          grade == other.grade &&
          status == other.status &&
          evaluatedBy == other.evaluatedBy &&
          evaluatedAt == other.evaluatedAt &&
          notes == other.notes &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
    id,
    districtId,
    schoolId,
    studentId,
    examName,
    subject,
    type,
    examDate,
    maxScore,
    obtainedScore,
    grade,
    status,
    evaluatedBy,
    evaluatedAt,
    notes,
    createdAt,
    updatedAt,
  );
}

enum ExamType {
  // @JsonValue('quiz')
  quiz,
  // @JsonValue('midterm')
  midterm,
  // @JsonValue('final')
  finalExam,
  // @JsonValue('assignment')
  assignment,
  // @JsonValue('project')
  project,
  // @JsonValue('standardized')
  standardized,
  // @JsonValue('practical')
  practical,
}

extension ExamTypeExtension on ExamType {
  String get value => name;
  String get displayName {
    switch (this) {
      case ExamType.quiz:
        return 'Quiz';
      case ExamType.midterm:
        return 'Midterm';
      case ExamType.finalExam:
        return 'Final Exam';
      case ExamType.assignment:
        return 'Assignment';
      case ExamType.project:
        return 'Project';
      case ExamType.standardized:
        return 'Standardized Test';
      case ExamType.practical:
        return 'Practical';
    }
  }
}

enum ExamStatus {
  // @JsonValue('scheduled')
  scheduled,
  // @JsonValue('in_progress')
  inProgress,
  // @JsonValue('completed')
  completed,
  // @JsonValue('graded')
  graded,
  // @JsonValue('absent')
  absent,
  // @JsonValue('cancelled')
  cancelled,
}

extension ExamStatusExtension on ExamStatus {
  String get value => name;
  String get displayName {
    switch (this) {
      case ExamStatus.scheduled:
        return 'Scheduled';
      case ExamStatus.inProgress:
        return 'In Progress';
      case ExamStatus.completed:
        return 'Completed';
      case ExamStatus.graded:
        return 'Graded';
      case ExamStatus.absent:
        return 'Absent';
      case ExamStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color get color {
    switch (this) {
      case ExamStatus.scheduled:
        return const Color(0xFF3B82F6);
      case ExamStatus.inProgress:
        return const Color(0xFFF59E0B);
      case ExamStatus.completed:
        return const Color(0xFF8B5CF6);
      case ExamStatus.graded:
        return const Color(0xFF10B981);
      case ExamStatus.absent:
        return const Color(0xFFEF4444);
      case ExamStatus.cancelled:
        return const Color(0xFF9CA3AF);
    }
  }
}