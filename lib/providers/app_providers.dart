import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/models.dart';
import '../services/services.dart';
import '../services/firestore_service.dart';
import '../services/risk_calculation_service.dart';

// Auth providers
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authServiceProvider).currentUser;
});

final currentUserProfileProvider = FutureProvider<UserModel?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  return ref.watch(authServiceProvider).getUserProfile(user.uid);
});

// Firestore provider
final firestoreServiceProvider = Provider<FirestoreService>((ref) => FirestoreService());

// Notifier classes for Riverpod 3.x state management
class CurrentDistrictIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;
}

class SelectedSchoolIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;
}

class SelectedStudentIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;
}

class AttendanceDateRangeNotifier extends Notifier<DateTimeRange?> {
  @override
  DateTimeRange? build() => null;
}

class SidebarExpandedNotifier extends Notifier<bool> {
  @override
  bool build() => true;
}

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.system;
}

class SelectedNavigationIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;
}

// District providers
final currentDistrictIdProvider = NotifierProvider<CurrentDistrictIdNotifier, String?>(CurrentDistrictIdNotifier.new);

final districtsProvider = StreamProvider<List<DistrictModel>>((ref) {
  return ref.watch(firestoreServiceProvider).watchDistricts();
});

final currentDistrictProvider = FutureProvider<DistrictModel?>((ref) async {
  final districtId = ref.watch(currentDistrictIdProvider);
  if (districtId == null) return null;

  return ref.watch(firestoreServiceProvider).getDocument(
    collection: 'districts',
    id: districtId,
    fromFirestore: (doc) => DistrictModel.fromFirestore(doc),
  );
});

// School providers
final schoolsByDistrictProvider =
    StreamProvider.family<List<SchoolModel>, String>((ref, districtId) {
  return ref
      .watch(firestoreServiceProvider)
      .watchSchoolsByDistrict(districtId);
});

final selectedSchoolIdProvider = NotifierProvider<SelectedSchoolIdNotifier, String?>(SelectedSchoolIdNotifier.new);

final currentSchoolProvider = FutureProvider<SchoolModel?>((ref) async {
  final schoolId = ref.watch(selectedSchoolIdProvider);
  if (schoolId == null) return null;

  return ref.watch(firestoreServiceProvider).getDocument(
    collection: 'schools',
    id: schoolId,
    fromFirestore: (doc) => SchoolModel.fromFirestore(doc),
  );
});

// Student providers
final studentsBySchoolProvider =
    StreamProvider.family<List<StudentModel>, String>((ref, schoolId) {
  return ref
      .watch(firestoreServiceProvider)
      .watchStudentsBySchool(schoolId);
});

final studentsByDistrictProvider =
    FutureProvider.family<List<StudentModel>, String>((ref, districtId) {
  return ref
      .watch(firestoreServiceProvider)
      .getStudentsByDistrict(districtId);
});

final selectedStudentIdProvider = NotifierProvider<SelectedStudentIdNotifier, String?>(SelectedStudentIdNotifier.new);

final currentStudentProvider = FutureProvider<StudentModel?>((ref) async {
  final studentId = ref.watch(selectedStudentIdProvider);
  if (studentId == null) return null;

  return ref.watch(firestoreServiceProvider).getDocument(
    collection: 'students',
    id: studentId,
    fromFirestore: (doc) => StudentModel.fromFirestore(doc),
  );
});

// Attendance providers
final attendanceDateRangeProvider = NotifierProvider<AttendanceDateRangeNotifier, DateTimeRange?>(AttendanceDateRangeNotifier.new);

final attendanceBySchoolProvider =
    StreamProvider.family<List<AttendanceRecord>, String>((ref, schoolId) {
  final range = ref.watch(attendanceDateRangeProvider) ??
      DateTimeRange(
        start: DateTime.now().subtract(const Duration(days: 30)),
        end: DateTime.now(),
      );

  return ref
      .watch(firestoreServiceProvider)
      .watchAttendanceBySchool(
        schoolId,
        range.start,
        range.end,
      );
});

final attendanceByStudentProvider =
    FutureProvider.family<List<AttendanceRecord>, String>((ref, studentId) {
  final range = ref.watch(attendanceDateRangeProvider) ??
      DateTimeRange(
        start: DateTime.now().subtract(const Duration(days: 30)),
        end: DateTime.now(),
      );

  return ref
      .watch(firestoreServiceProvider)
      .getAttendanceByStudent(
        studentId,
        range.start,
        range.end,
      );
});

final attendanceBySchoolAndDateProvider =
    FutureProvider.family<List<AttendanceRecord>, SchoolDateKey>((ref, key) {
  return ref
      .watch(firestoreServiceProvider)
      .getAttendanceBySchoolAndDate(
        key.schoolId,
        key.date,
      );
});

class SchoolDateKey {
  final String schoolId;
  final DateTime date;

  const SchoolDateKey(this.schoolId, this.date);

  @override
  bool operator ==(Object other) =>
      other is SchoolDateKey &&
      other.schoolId == schoolId &&
      other.date == date;

  @override
  int get hashCode => Object.hash(schoolId, date);
}

// Fee providers
final feesBySchoolProvider =
    StreamProvider.family<List<FeeRecord>, String>((ref, schoolId) {
  return ref.watch(firestoreServiceProvider).watchFeesBySchool(schoolId);
});

final feesByStudentProvider =
    FutureProvider.family<List<FeeRecord>, String>((ref, studentId) {
  return ref.watch(firestoreServiceProvider).getFeesByStudent(studentId);
});

final overdueFeesBySchoolProvider =
    FutureProvider.family<List<FeeRecord>, String>((ref, schoolId) {
  return ref
      .watch(firestoreServiceProvider)
      .getOverdueFeesBySchool(schoolId);
});

// Exam providers
final examsBySchoolProvider =
    StreamProvider.family<List<ExamRecord>, String>((ref, schoolId) {
  return ref.watch(firestoreServiceProvider).watchExamsBySchool(schoolId);
});

final examsByStudentProvider =
    FutureProvider.family<List<ExamRecord>, String>((ref, studentId) {
  return ref.watch(firestoreServiceProvider).getExamsByStudent(studentId);
});

final upcomingExamsProvider =
    FutureProvider.family<List<ExamRecord>, UpcomingExamsKey>((ref, key) {
  return ref
      .watch(firestoreServiceProvider)
      .getUpcomingExamsBySchool(
        key.schoolId,
        key.daysAhead,
      );
});

class UpcomingExamsKey {
  final String schoolId;
  final int daysAhead;

  const UpcomingExamsKey(this.schoolId, this.daysAhead);

  @override
  bool operator ==(Object other) =>
      other is UpcomingExamsKey &&
      other.schoolId == schoolId &&
      other.daysAhead == daysAhead;

  @override
  int get hashCode => Object.hash(schoolId, daysAhead);
}

// Risk providers
final riskCalculationServiceProvider =
    Provider<RiskCalculationService>((ref) => RiskCalculationService());

final schoolRiskProfileProvider =
    FutureProvider.family<SchoolRiskProfile, String>((ref, schoolId) {
  return ref
      .watch(riskCalculationServiceProvider)
      .calculateSchoolRiskProfile(schoolId);
});

final districtRiskSummaryProvider =
    FutureProvider.family<DistrictRiskSummary, String>((ref, districtId) {
  return ref
      .watch(riskCalculationServiceProvider)
      .calculateDistrictRiskSummary(districtId);
});

final activeAlertsByDistrictProvider =
    StreamProvider.family<List<RiskAlert>, String>((ref, districtId) {
  return ref
      .watch(firestoreServiceProvider)
      .watchActiveAlertsByDistrict(districtId);
});

final activeAlertsBySchoolProvider =
    StreamProvider.family<List<RiskAlert>, String>((ref, schoolId) {
  return ref.watch(firestoreServiceProvider).watchQuery(
    collection: 'risk_alerts',
    filters: [
      QueryFilter('schoolId', schoolId),
      QueryFilter('isResolved', false),
    ],
    orderBy: [
      OrderByClause('level', true),
      OrderByClause('triggeredAt', true),
    ],
    fromFirestore: (doc) => RiskAlert.fromFirestore(doc),
  );
});

// UI State providers
final sidebarExpandedProvider = NotifierProvider<SidebarExpandedNotifier, bool>(SidebarExpandedNotifier.new);

final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

final selectedNavigationIndexProvider =
    NotifierProvider<SelectedNavigationIndexNotifier, int>(SelectedNavigationIndexNotifier.new);