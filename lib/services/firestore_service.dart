import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Generic CRUD operations
  Future<String> createDocument<T>({
    required String collection,
    required T data,
    required Map<String, dynamic> Function(T) toJson,
  }) async {
    final docRef = await _firestore.collection(collection).add(toJson(data));
    return docRef.id;
  }

  Future<void> updateDocument({
    required String collection,
    required String id,
    required Map<String, dynamic> data,
  }) async {
    await _firestore.collection(collection).doc(id).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteDocument({
    required String collection,
    required String id,
  }) async {
    await _firestore.collection(collection).doc(id).delete();
  }

  Future<T?> getDocument<T>({
    required String collection,
    required String id,
    required T Function(DocumentSnapshot<Map<String, dynamic>>) fromFirestore,
  }) async {
    final doc = await _firestore.collection(collection).doc(id).get();
    if (doc.exists) {
      return fromFirestore(doc);
    }
    return null;
  }

  Stream<T> watchDocument<T>({
    required String collection,
    required String id,
    required T Function(DocumentSnapshot<Map<String, dynamic>>) fromFirestore,
  }) {
    return _firestore.collection(collection).doc(id).snapshots().map((doc) {
      if (doc.exists) {
        return fromFirestore(doc);
      }
      throw Exception('Document not found');
    });
  }

  Future<List<T>> queryDocuments<T>({
    required String collection,
    required List<QueryFilter> filters,
    required List<OrderByClause> orderBy,
    int? limit,
    required T Function(DocumentSnapshot<Map<String, dynamic>>) fromFirestore,
  }) async {
    Query<Map<String, dynamic>> query = _firestore.collection(collection);

    for (final filter in filters) {
      query = query.where(filter.field, isEqualTo: filter.value);
    }

    for (final order in orderBy) {
      query = query.orderBy(order.field, descending: order.descending);
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    final snapshot = await query.get();
    return snapshot.docs.map(fromFirestore).toList();
  }

  Stream<List<T>> watchQuery<T>({
    required String collection,
    required List<QueryFilter> filters,
    required List<OrderByClause> orderBy,
    int? limit,
    required T Function(DocumentSnapshot<Map<String, dynamic>>) fromFirestore,
  }) {
    Query<Map<String, dynamic>> query = _firestore.collection(collection);

    for (final filter in filters) {
      query = query.where(filter.field, isEqualTo: filter.value);
    }

    for (final order in orderBy) {
      query = query.orderBy(order.field, descending: order.descending);
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map(fromFirestore).toList();
    });
  }

  // Batch operations
  Future<void> batchWrite(List<BatchOperation> operations) async {
    final batch = _firestore.batch();
    for (final op in operations) {
      switch (op.type) {
        case BatchOperationType.set:
          batch.set(op.docRef, op.data!);
          break;
        case BatchOperationType.update:
          batch.update(op.docRef, {...op.data!, 'updatedAt': FieldValue.serverTimestamp()});
          break;
        case BatchOperationType.delete:
          batch.delete(op.docRef);
          break;
      }
    }
    await batch.commit();
  }

  // District operations
  Future<String> createDistrict(DistrictModel district) async {
    return createDocument(
      collection: 'districts',
      data: district,
      toJson: (d) => d.toJson(),
    );
  }

  Stream<List<DistrictModel>> watchDistricts() {
    return watchQuery(
      collection: 'districts',
      filters: [QueryFilter('isActive', true)],
      orderBy: [OrderByClause('name', false)],
      fromFirestore: (doc) => DistrictModel.fromFirestore(doc),
    );
  }

  // School operations
  Future<String> createSchool(SchoolModel school) async {
    return createDocument(
      collection: 'schools',
      data: school,
      toJson: (s) => s.toJson(),
    );
  }

  Future<List<SchoolModel>> getSchoolsByDistrict(String districtId) async {
    return queryDocuments(
      collection: 'schools',
      filters: [
        QueryFilter('districtId', districtId),
        QueryFilter('isActive', true),
      ],
      orderBy: [OrderByClause('name', false)],
      fromFirestore: (doc) => SchoolModel.fromFirestore(doc),
    );
  }

  Stream<List<SchoolModel>> watchSchoolsByDistrict(String districtId) {
    return watchQuery(
      collection: 'schools',
      filters: [
        QueryFilter('districtId', districtId),
        QueryFilter('isActive', true),
      ],
      orderBy: [OrderByClause('name', false)],
      fromFirestore: (doc) => SchoolModel.fromFirestore(doc),
    );
  }

  // Student operations
  Future<String> createStudent(StudentModel student) async {
    return createDocument(
      collection: 'students',
      data: student,
      toJson: (s) => s.toJson(),
    );
  }

  Future<List<StudentModel>> getStudentsBySchool(String schoolId) async {
    return queryDocuments(
      collection: 'students',
      filters: [
        QueryFilter('schoolId', schoolId),
        QueryFilter('status', StudentStatus.active.value),
      ],
      orderBy: [OrderByClause('lastName', false), OrderByClause('firstName', false)],
      fromFirestore: (doc) => StudentModel.fromFirestore(doc),
    );
  }

  Stream<List<StudentModel>> watchStudentsBySchool(String schoolId) {
    return watchQuery(
      collection: 'students',
      filters: [
        QueryFilter('schoolId', schoolId),
        QueryFilter('status', StudentStatus.active.value),
      ],
      orderBy: [OrderByClause('lastName', false), OrderByClause('firstName', false)],
      fromFirestore: (doc) => StudentModel.fromFirestore(doc),
    );
  }

  Future<List<StudentModel>> getStudentsByDistrict(String districtId) async {
    return queryDocuments(
      collection: 'students',
      filters: [
        QueryFilter('districtId', districtId),
        QueryFilter('status', StudentStatus.active.value),
      ],
      orderBy: [OrderByClause('schoolId', false), OrderByClause('lastName', false)],
      fromFirestore: (doc) => StudentModel.fromFirestore(doc),
    );
  }

  // Attendance operations
  Future<String> createAttendanceRecord(AttendanceRecord record) async {
    return createDocument(
      collection: 'attendance',
      data: record,
      toJson: (r) => r.toJson(),
    );
  }

  Future<List<AttendanceRecord>> getAttendanceByStudent(String studentId, DateTime start, DateTime end) async {
    return queryDocuments(
      collection: 'attendance',
      filters: [
        QueryFilter('studentId', studentId),
        QueryFilter('date', Timestamp.fromDate(start)),
        QueryFilter('date', Timestamp.fromDate(end)),
      ],
      orderBy: [OrderByClause('date', true)],
      fromFirestore: (doc) => AttendanceRecord.fromFirestore(doc),
    );
  }

  Stream<List<AttendanceRecord>> watchAttendanceBySchool(String schoolId, DateTime start, DateTime end) {
    return watchQuery(
      collection: 'attendance',
      filters: [
        QueryFilter('schoolId', schoolId),
        QueryFilter('date', Timestamp.fromDate(start)),
        QueryFilter('date', Timestamp.fromDate(end)),
      ],
      orderBy: [OrderByClause('date', true)],
      fromFirestore: (doc) => AttendanceRecord.fromFirestore(doc),
    );
  }

  Future<List<AttendanceRecord>> getAttendanceBySchoolAndDate(String schoolId, DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return queryDocuments(
      collection: 'attendance',
      filters: [
        QueryFilter('schoolId', schoolId),
        QueryFilter('date', Timestamp.fromDate(startOfDay)),
        QueryFilter('date', Timestamp.fromDate(endOfDay)),
      ],
      orderBy: [OrderByClause('studentId', false)],
      fromFirestore: (doc) => AttendanceRecord.fromFirestore(doc),
    );
  }

  // Fee operations
  Future<String> createFeeRecord(FeeRecord record) async {
    return createDocument(
      collection: 'fees',
      data: record,
      toJson: (r) => r.toJson(),
    );
  }

  Future<List<FeeRecord>> getFeesByStudent(String studentId) async {
    return queryDocuments(
      collection: 'fees',
      filters: [QueryFilter('studentId', studentId)],
      orderBy: [OrderByClause('dueDate', true)],
      fromFirestore: (doc) => FeeRecord.fromFirestore(doc),
    );
  }

  Stream<List<FeeRecord>> watchFeesBySchool(String schoolId) {
    return watchQuery(
      collection: 'fees',
      filters: [QueryFilter('schoolId', schoolId)],
      orderBy: [OrderByClause('dueDate', true)],
      fromFirestore: (doc) => FeeRecord.fromFirestore(doc),
    );
  }

  Future<List<FeeRecord>> getOverdueFeesBySchool(String schoolId) async {
    return queryDocuments(
      collection: 'fees',
      filters: [
        QueryFilter('schoolId', schoolId),
        QueryFilter('status', FeeStatus.overdue.value),
      ],
      orderBy: [OrderByClause('dueDate', true)],
      fromFirestore: (doc) => FeeRecord.fromFirestore(doc),
    );
  }

  // Exam operations
  Future<String> createExamRecord(ExamRecord record) async {
    return createDocument(
      collection: 'exams',
      data: record,
      toJson: (r) => r.toJson(),
    );
  }

  Future<List<ExamRecord>> getExamsByStudent(String studentId) async {
    return queryDocuments(
      collection: 'exams',
      filters: [QueryFilter('studentId', studentId)],
      orderBy: [OrderByClause('examDate', true)],
      fromFirestore: (doc) => ExamRecord.fromFirestore(doc),
    );
  }

  Stream<List<ExamRecord>> watchExamsBySchool(String schoolId) {
    return watchQuery(
      collection: 'exams',
      filters: [QueryFilter('schoolId', schoolId)],
      orderBy: [OrderByClause('examDate', true)],
      fromFirestore: (doc) => ExamRecord.fromFirestore(doc),
    );
  }

  Future<List<ExamRecord>> getUpcomingExamsBySchool(String schoolId, int daysAhead) async {
    final now = DateTime.now();
    final future = now.add(Duration(days: daysAhead));
    return queryDocuments(
      collection: 'exams',
      filters: [
        QueryFilter('schoolId', schoolId),
        QueryFilter('examDate', Timestamp.fromDate(now)),
        QueryFilter('examDate', Timestamp.fromDate(future)),
      ],
      orderBy: [OrderByClause('examDate', false)],
      fromFirestore: (doc) => ExamRecord.fromFirestore(doc),
    );
  }

  // Risk Alert operations
  Future<String> createRiskAlert(RiskAlert alert) async {
    return createDocument(
      collection: 'risk_alerts',
      data: alert,
      toJson: (a) => a.toJson(),
    );
  }

  Stream<List<RiskAlert>> watchActiveAlertsByDistrict(String districtId) {
    return watchQuery(
      collection: 'risk_alerts',
      filters: [
        QueryFilter('districtId', districtId),
        QueryFilter('isResolved', false),
      ],
      orderBy: [
        OrderByClause('level', true),
        OrderByClause('triggeredAt', true),
      ],
      fromFirestore: (doc) => RiskAlert.fromFirestore(doc),
    );
  }

  Future<void> resolveAlert(String alertId, String resolvedBy, String notes) async {
    await updateDocument(
      collection: 'risk_alerts',
      id: alertId,
      data: {
        'isResolved': true,
        'resolvedBy': resolvedBy,
        'resolvedAt': FieldValue.serverTimestamp(),
        'resolutionNotes': notes,
      },
    );
  }
}

class QueryFilter {
  final String field;
  final dynamic value;
  const QueryFilter(this.field, this.value);
}

class OrderByClause {
  final String field;
  final bool descending;
  const OrderByClause(this.field, this.descending);
}

enum BatchOperationType { set, update, delete }

class BatchOperation {
  final BatchOperationType type;
  final DocumentReference docRef;
  final Map<String, dynamic>? data;
  const BatchOperation(this.type, this.docRef, this.data);
}

final firestoreServiceProvider = Provider<FirestoreService>((ref) => FirestoreService());