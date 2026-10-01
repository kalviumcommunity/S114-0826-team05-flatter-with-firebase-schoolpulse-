import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

@immutable
class FeeRecord {
  const FeeRecord({
    required this.id,
    required this.districtId,
    required this.schoolId,
    required this.studentId,
    required this.feeType,
    required this.description,
    required this.amountDue,
    required this.amountPaid,
    required this.dueDate,
    this.paidDate,
    required this.status,
    this.paymentMethod,
    this.transactionId,
    this.receiptNumber,
    this.collectedBy,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String districtId;
  final String schoolId;
  final String studentId;
  final String feeType;
  final String description;
  final double amountDue;
  final double amountPaid;
  final DateTime dueDate;
  final DateTime? paidDate;
  final FeeStatus status;
  final String? paymentMethod;
  final String? transactionId;
  final String? receiptNumber;
  final String? collectedBy;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory FeeRecord.fromJson(Map<String, dynamic> json) => FeeRecord(
    id: json['id'] as String,
    districtId: json['districtId'] as String,
    schoolId: json['schoolId'] as String,
    studentId: json['studentId'] as String,
    feeType: json['feeType'] as String,
    description: json['description'] as String,
    amountDue: (json['amountDue'] as num).toDouble(),
    amountPaid: (json['amountPaid'] as num).toDouble(),
    dueDate: DateTime.parse(json['dueDate'] as String),
    paidDate: json['paidDate'] != null ? DateTime.parse(json['paidDate'] as String) : null,
    status: FeeStatus.values.firstWhere((e) => e.value == json['status']),
    paymentMethod: json['paymentMethod'] as String?,
    transactionId: json['transactionId'] as String?,
    receiptNumber: json['receiptNumber'] as String?,
    collectedBy: json['collectedBy'] as String?,
    notes: json['notes'] as String?,
    createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
    updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
  );

  factory FeeRecord.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data()!;
    return FeeRecord.fromJson({'id': snapshot.id, ...data});
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'districtId': districtId,
    'schoolId': schoolId,
    'studentId': studentId,
    'feeType': feeType,
    'description': description,
    'amountDue': amountDue,
    'amountPaid': amountPaid,
    'dueDate': dueDate.toIso8601String(),
    'paidDate': paidDate?.toIso8601String(),
    'status': status.value,
    'paymentMethod': paymentMethod,
    'transactionId': transactionId,
    'receiptNumber': receiptNumber,
    'collectedBy': collectedBy,
    'notes': notes,
    'createdAt': createdAt?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
  };

  double get balance => amountDue - amountPaid;
  bool get isOverdue => dueDate.isBefore(DateTime.now()) && status != FeeStatus.paid;
  double get paymentPercentage => amountDue > 0 ? (amountPaid / amountDue) * 100 : 100;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FeeRecord &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          districtId == other.districtId &&
          schoolId == other.schoolId &&
          studentId == other.studentId &&
          feeType == other.feeType &&
          description == other.description &&
          amountDue == other.amountDue &&
          amountPaid == other.amountPaid &&
          dueDate == other.dueDate &&
          paidDate == other.paidDate &&
          status == other.status &&
          paymentMethod == other.paymentMethod &&
          transactionId == other.transactionId &&
          receiptNumber == other.receiptNumber &&
          collectedBy == other.collectedBy &&
          notes == other.notes &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
    id,
    districtId,
    schoolId,
    studentId,
    feeType,
    description,
    amountDue,
    amountPaid,
    dueDate,
    paidDate,
    status,
    paymentMethod,
    transactionId,
    receiptNumber,
    collectedBy,
    notes,
    createdAt,
    updatedAt,
  );
}

enum FeeStatus {
  // @JsonValue('pending')
  pending,
  // @JsonValue('partial')
  partial,
  // @JsonValue('paid')
  paid,
  // @JsonValue('overdue')
  overdue,
  // @JsonValue('waived')
  waived,
  // @JsonValue('cancelled')
  cancelled,
}

extension FeeStatusExtension on FeeStatus {
  String get value => name;
  String get displayName {
    switch (this) {
      case FeeStatus.pending:
        return 'Pending';
      case FeeStatus.partial:
        return 'Partial';
      case FeeStatus.paid:
        return 'Paid';
      case FeeStatus.overdue:
        return 'Overdue';
      case FeeStatus.waived:
        return 'Waived';
      case FeeStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color get color {
    switch (this) {
      case FeeStatus.pending:
        return const Color(0xFF6B7280);
      case FeeStatus.partial:
        return const Color(0xFFF59E0B);
      case FeeStatus.paid:
        return const Color(0xFF10B981);
      case FeeStatus.overdue:
        return const Color(0xFFEF4444);
      case FeeStatus.waived:
        return const Color(0xFF8B5CF6);
      case FeeStatus.cancelled:
        return const Color(0xFF9CA3AF);
    }
  }
}