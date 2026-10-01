import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';

class RiskCalculationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Weights for composite risk score
  static const double attendanceWeight = 0.35;
  static const double feeWeight = 0.25;
  static const double academicWeight = 0.25;
  static const double enrollmentWeight = 0.15;

  // Thresholds
  static const double attendanceCriticalThreshold = 70.0;
  static const double attendanceHighThreshold = 80.0;
  static const double attendanceMediumThreshold = 90.0;

  static const double feeCriticalThreshold = 50.0;
  static const double feeHighThreshold = 70.0;
  static const double feeMediumThreshold = 85.0;

  static const double academicCriticalThreshold = 50.0;
  static const double academicHighThreshold = 60.0;
  static const double academicMediumThreshold = 70.0;

  Future<SchoolRiskProfile> calculateSchoolRiskProfile(String schoolId) async {
    final schoolDoc = await _firestore.collection('schools').doc(schoolId).get();
    if (!schoolDoc.exists) throw Exception('School not found');

    final school = SchoolModel.fromFirestore(schoolDoc);
    final districtId = school.districtId;

    // Get students
    final studentsSnapshot = await _firestore
        .collection('students')
        .where('schoolId', isEqualTo: schoolId)
        .where('status', isEqualTo: StudentStatus.active.value)
        .get();

    final students = studentsSnapshot.docs.map(StudentModel.fromFirestore).toList();
    final totalStudents = students.length;

    if (totalStudents == 0) {
      return SchoolRiskProfile(
        schoolId: schoolId,
        schoolName: school.name,
        districtId: districtId,
        totalStudents: 0,
        attendanceRate: 100.0,
        feeCollectionRate: 100.0,
        examPassRate: 100.0,
        enrollmentTrend: 0.0,
        overallRiskLevel: RiskLevel.low,
        compositeScore: 100.0,
        categoryRisks: {
          RiskCategory.attendance: RiskLevel.low,
          RiskCategory.fees: RiskLevel.low,
          RiskCategory.academic: RiskLevel.low,
          RiskCategory.enrollment: RiskLevel.low,
          RiskCategory.operational: RiskLevel.low,
        },
        activeAlerts: [],
        calculatedAt: DateTime.now(),
      );
    }

    // Calculate attendance rate
    final attendanceRate = await _calculateAttendanceRate(schoolId, students);

    // Calculate fee collection rate
    final feeCollectionRate = await _calculateFeeCollectionRate(schoolId);

    // Calculate exam pass rate
    final examPassRate = await _calculateExamPassRate(schoolId, students);

    // Calculate enrollment trend
    final enrollmentTrend = _calculateEnrollmentTrend(school);

    // Determine category risk levels
    final attendanceRisk = _getAttendanceRiskLevel(attendanceRate);
    final feeRisk = _getFeeRiskLevel(feeCollectionRate);
    final academicRisk = _getAcademicRiskLevel(examPassRate);
    final enrollmentRisk = _getEnrollmentRiskLevel(enrollmentTrend);

    final categoryRisks = {
      RiskCategory.attendance: attendanceRisk,
      RiskCategory.fees: feeRisk,
      RiskCategory.academic: academicRisk,
      RiskCategory.enrollment: enrollmentRisk,
      RiskCategory.operational: _getOperationalRiskLevel(attendanceRisk, feeRisk, academicRisk, enrollmentRisk),
    };

    // Calculate composite score
    final compositeScore = _calculateCompositeScore(
      attendanceRate,
      feeCollectionRate,
      examPassRate,
      enrollmentTrend,
    );

    final overallRiskLevel = _getOverallRiskLevel(compositeScore);

    // Get active alerts
    final alertsSnapshot = await _firestore
        .collection('risk_alerts')
        .where('schoolId', isEqualTo: schoolId)
        .where('isResolved', isEqualTo: false)
        .orderBy('level', descending: true)
        .orderBy('triggeredAt', descending: true)
        .limit(10)
        .get();

    final activeAlerts = alertsSnapshot.docs.map(RiskAlert.fromFirestore).toList();

    return SchoolRiskProfile(
      schoolId: schoolId,
      schoolName: school.name,
      districtId: districtId,
      totalStudents: totalStudents,
      attendanceRate: attendanceRate,
      feeCollectionRate: feeCollectionRate,
      examPassRate: examPassRate,
      enrollmentTrend: enrollmentTrend,
      overallRiskLevel: overallRiskLevel,
      compositeScore: compositeScore,
      categoryRisks: categoryRisks,
      activeAlerts: activeAlerts,
      calculatedAt: DateTime.now(),
    );
  }

  Future<double> _calculateAttendanceRate(String schoolId, List<StudentModel> students) async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    final attendanceSnapshot = await _firestore
        .collection('attendance')
        .where('schoolId', isEqualTo: schoolId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
        .get();

    if (attendanceSnapshot.docs.isEmpty) return 100.0;

    final records = attendanceSnapshot.docs.map(AttendanceRecord.fromFirestore).toList();
    double totalWeight = 0;
    double presentWeight = 0;

    for (final record in records) {
      totalWeight += 1.0;
      presentWeight += record.status.weight;
    }

    return totalWeight > 0 ? (presentWeight / totalWeight) * 100 : 100.0;
  }

  Future<double> _calculateFeeCollectionRate(String schoolId) async {
    final feesSnapshot = await _firestore
        .collection('fees')
        .where('schoolId', isEqualTo: schoolId)
        .where('status', whereIn: [FeeStatus.pending.value, FeeStatus.partial.value, FeeStatus.paid.value, FeeStatus.overdue.value])
        .get();

    if (feesSnapshot.docs.isEmpty) return 100.0;

    final fees = feesSnapshot.docs.map(FeeRecord.fromFirestore).toList();
    double totalDue = 0;
    double totalPaid = 0;

    for (final fee in fees) {
      totalDue += fee.amountDue;
      totalPaid += fee.amountPaid;
    }

    return totalDue > 0 ? (totalPaid / totalDue) * 100 : 100.0;
  }

  Future<double> _calculateExamPassRate(String schoolId, List<StudentModel> students) async {
    final studentIds = students.map((s) => s.id).toList();
    if (studentIds.isEmpty) return 100.0;

    final examsSnapshot = await _firestore
        .collection('exams')
        .where('schoolId', isEqualTo: schoolId)
        .where('status', isEqualTo: ExamStatus.graded.value)
        .get();

    if (examsSnapshot.docs.isEmpty) return 100.0;

    final exams = examsSnapshot.docs.map(ExamRecord.fromFirestore).toList();
    int passed = 0;
    int total = exams.length;

    for (final exam in exams) {
      if (exam.percentage >= 60) passed++;
    }

    return total > 0 ? (passed / total) * 100 : 100.0;
  }

  double _calculateEnrollmentTrend(SchoolModel school) {
    // Simplified: compare current enrollment to capacity
    // In production, this would compare to previous period
    if (school.totalCapacity == 0) return 0.0;
    return ((school.currentEnrollment / school.totalCapacity) - 0.8) * 100;
  }

  RiskLevel _getAttendanceRiskLevel(double rate) {
    if (rate < attendanceCriticalThreshold) return RiskLevel.critical;
    if (rate < attendanceHighThreshold) return RiskLevel.high;
    if (rate < attendanceMediumThreshold) return RiskLevel.medium;
    return RiskLevel.low;
  }

  RiskLevel _getFeeRiskLevel(double rate) {
    if (rate < feeCriticalThreshold) return RiskLevel.critical;
    if (rate < feeHighThreshold) return RiskLevel.high;
    if (rate < feeMediumThreshold) return RiskLevel.medium;
    return RiskLevel.low;
  }

  RiskLevel _getAcademicRiskLevel(double rate) {
    if (rate < academicCriticalThreshold) return RiskLevel.critical;
    if (rate < academicHighThreshold) return RiskLevel.high;
    if (rate < academicMediumThreshold) return RiskLevel.medium;
    return RiskLevel.low;
  }

  RiskLevel _getEnrollmentRiskLevel(double trend) {
    if (trend < -20) return RiskLevel.critical;
    if (trend < -10) return RiskLevel.high;
    if (trend < 0) return RiskLevel.medium;
    return RiskLevel.low;
  }

  RiskLevel _getOperationalRiskLevel(
    RiskLevel attendance,
    RiskLevel fees,
    RiskLevel academic,
    RiskLevel enrollment,
  ) {
    final levels = [attendance, fees, academic, enrollment];
    final maxPriority = levels.map((l) => l.priority).reduce((a, b) => a > b ? a : b);
    return RiskLevel.values.firstWhere((l) => l.priority == maxPriority);
  }

  double _calculateCompositeScore(
    double attendanceRate,
    double feeRate,
    double examRate,
    double enrollmentTrend,
  ) {
    // Normalize enrollment trend to 0-100 scale
    double enrollmentScore = 100;
    if (enrollmentTrend < 0) {
      enrollmentScore = (100 + enrollmentTrend).clamp(0, 100);
    }

    return (attendanceRate * attendanceWeight) +
        (feeRate * feeWeight) +
        (examRate * academicWeight) +
        (enrollmentScore * enrollmentWeight);
  }

  RiskLevel _getOverallRiskLevel(double compositeScore) {
    if (compositeScore < 60) return RiskLevel.critical;
    if (compositeScore < 70) return RiskLevel.high;
    if (compositeScore < 80) return RiskLevel.medium;
    return RiskLevel.low;
  }

  Future<DistrictRiskSummary> calculateDistrictRiskSummary(String districtId) async {
    final schoolsSnapshot = await _firestore
        .collection('schools')
        .where('districtId', isEqualTo: districtId)
        .where('isActive', isEqualTo: true)
        .get();

    final schools = schoolsSnapshot.docs.map(SchoolModel.fromFirestore).toList();
    final totalSchools = schools.length;

    if (totalSchools == 0) {
      return DistrictRiskSummary(
        districtId: districtId,
        districtName: '',
        totalSchools: 0,
        totalStudents: 0,
        overallAttendanceRate: 100.0,
        overallFeeCollectionRate: 100.0,
        overallExamPassRate: 100.0,
        schoolsByRiskLevel: {},
        alertsByCategory: {},
        topRiskSchools: [],
        calculatedAt: DateTime.now(),
      );
    }

    var totalStudents = 0;
    double totalAttendanceRate = 0;
    double totalFeeRate = 0;
    double totalExamRate = 0;
    final Map<RiskLevel, int> schoolsByRiskLevel = {for (var l in RiskLevel.values) l: 0};
    final Map<RiskCategory, int> alertsByCategory = {for (var c in RiskCategory.values) c: 0};
    final List<SchoolRiskProfile> schoolProfiles = [];

    for (final school in schools) {
      final profile = await calculateSchoolRiskProfile(school.id);
      schoolProfiles.add(profile);

      totalStudents += profile.totalStudents;
      totalAttendanceRate += profile.attendanceRate;
      totalFeeRate += profile.feeCollectionRate;
      totalExamRate += profile.examPassRate;
      schoolsByRiskLevel[profile.overallRiskLevel] = (schoolsByRiskLevel[profile.overallRiskLevel] ?? 0) + 1;

      for (final alert in profile.activeAlerts) {
        alertsByCategory[alert.category] = (alertsByCategory[alert.category] ?? 0) + 1;
      }
    }

    // Sort by risk level and get top 5
    schoolProfiles.sort((a, b) => b.overallRiskLevel.priority.compareTo(a.overallRiskLevel.priority));
    final topRiskSchools = schoolProfiles.take(5).toList();

    return DistrictRiskSummary(
      districtId: districtId,
      districtName: '', // Would be fetched from district doc
      totalSchools: totalSchools,
      totalStudents: totalStudents,
      overallAttendanceRate: totalAttendanceRate / totalSchools,
      overallFeeCollectionRate: totalFeeRate / totalSchools,
      overallExamPassRate: totalExamRate / totalSchools,
      schoolsByRiskLevel: schoolsByRiskLevel,
      alertsByCategory: alertsByCategory,
      topRiskSchools: topRiskSchools,
      calculatedAt: DateTime.now(),
    );
  }

  Future<void> generateAlertsForSchool(String schoolId) async {
    final profile = await calculateSchoolRiskProfile(schoolId);
    final alertsToCreate = <RiskAlert>[];

    // Attendance alerts
    if (profile.categoryRisks[RiskCategory.attendance]!.priority >= RiskLevel.high.priority) {
      alertsToCreate.add(RiskAlert(
        id: '',
        districtId: profile.districtId,
        schoolId: schoolId,
        category: RiskCategory.attendance,
        level: profile.categoryRisks[RiskCategory.attendance]!,
        title: 'Low Attendance Rate',
        description: 'School attendance rate is ${profile.attendanceRate.toStringAsFixed(1)}%',
        metrics: {'attendanceRate': profile.attendanceRate},
        affectedEntities: [schoolId],
        triggeredAt: DateTime.now(),
      ));
    }

    // Fee alerts
    if (profile.categoryRisks[RiskCategory.fees]!.priority >= RiskLevel.high.priority) {
      alertsToCreate.add(RiskAlert(
        id: '',
        districtId: profile.districtId,
        schoolId: schoolId,
        category: RiskCategory.fees,
        level: profile.categoryRisks[RiskCategory.fees]!,
        title: 'Low Fee Collection Rate',
        description: 'Fee collection rate is ${profile.feeCollectionRate.toStringAsFixed(1)}%',
        metrics: {'feeCollectionRate': profile.feeCollectionRate},
        affectedEntities: [schoolId],
        triggeredAt: DateTime.now(),
      ));
    }

    // Academic alerts
    if (profile.categoryRisks[RiskCategory.academic]!.priority >= RiskLevel.high.priority) {
      alertsToCreate.add(RiskAlert(
        id: '',
        districtId: profile.districtId,
        schoolId: schoolId,
        category: RiskCategory.academic,
        level: profile.categoryRisks[RiskCategory.academic]!,
        title: 'Low Exam Pass Rate',
        description: 'Exam pass rate is ${profile.examPassRate.toStringAsFixed(1)}%',
        metrics: {'examPassRate': profile.examPassRate},
        affectedEntities: [schoolId],
        triggeredAt: DateTime.now(),
      ));
    }

    // Enrollment alerts
    if (profile.categoryRisks[RiskCategory.enrollment]!.priority >= RiskLevel.high.priority) {
      alertsToCreate.add(RiskAlert(
        id: '',
        districtId: profile.districtId,
        schoolId: schoolId,
        category: RiskCategory.enrollment,
        level: profile.categoryRisks[RiskCategory.enrollment]!,
        title: 'Declining Enrollment',
        description: 'Enrollment trend is ${profile.enrollmentTrend.toStringAsFixed(1)}%',
        metrics: {'enrollmentTrend': profile.enrollmentTrend},
        affectedEntities: [schoolId],
        triggeredAt: DateTime.now(),
      ));
    }

    // Composite alert
    if (profile.overallRiskLevel.priority >= RiskLevel.high.priority) {
      alertsToCreate.add(RiskAlert(
        id: '',
        districtId: profile.districtId,
        schoolId: schoolId,
        category: RiskCategory.composite,
        level: profile.overallRiskLevel,
        title: 'High Overall Risk',
        description: 'Composite risk score is ${profile.compositeScore.toStringAsFixed(1)}',
        metrics: {'compositeScore': profile.compositeScore},
        affectedEntities: [schoolId],
        triggeredAt: DateTime.now(),
      ));
    }

    // Batch create alerts
    if (alertsToCreate.isNotEmpty) {
      final batch = _firestore.batch();
      for (final alert in alertsToCreate) {
        final docRef = _firestore.collection('risk_alerts').doc();
        batch.set(docRef, alert.copyWith(id: docRef.id).toJson());
      }
      await batch.commit();
    }
  }
}

final riskCalculationServiceProvider = Provider<RiskCalculationService>((ref) => RiskCalculationService());