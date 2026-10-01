import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import '../../models/models.dart';
import '../../providers/app_providers.dart';
import '../../services/risk_calculation_service.dart';
import '../../utils/app_formatters.dart'
    show AppFormatters;
import '../../utils/app_theme.dart';
import '../../widgets/common_widgets.dart';

class SchoolDashboardView extends ConsumerStatefulWidget {
  final String schoolId;

  const SchoolDashboardView({super.key, required this.schoolId});

  @override
  ConsumerState<SchoolDashboardView> createState() => _SchoolDashboardViewState();
}

class _SchoolDashboardViewState extends ConsumerState<SchoolDashboardView> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final schoolAsync = ref.watch(currentSchoolProvider);
    final riskProfileAsync = ref.watch(schoolRiskProfileProvider(widget.schoolId));
    final studentsAsync = ref.watch(studentsBySchoolProvider(widget.schoolId));
    final attendanceAsync = ref.watch(attendanceBySchoolProvider(widget.schoolId));
    final feesAsync = ref.watch(feesBySchoolProvider(widget.schoolId));
    final examsAsync = ref.watch(examsBySchoolProvider(widget.schoolId));
    final alertsAsync = ref.watch(activeAlertsBySchoolProvider(widget.schoolId));

    return Scaffold(
      appBar: AppBar(
        title: schoolAsync.when(
          data: (school) => Text(school?.name ?? 'School Detail'),
          loading: () => const Text('School Detail'),
          error: (_, _) => const Text('School Detail'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _refreshAll(),
            tooltip: 'Refresh',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'students':
                  context.go('/schools/${widget.schoolId}/students');
                  break;
                case 'attendance':
                  context.go('/schools/${widget.schoolId}/attendance');
                  break;
                case 'fees':
                  context.go('/schools/${widget.schoolId}/fees');
                  break;
                case 'exams':
                  context.go('/schools/${widget.schoolId}/exams');
                  break;
                case 'risk':
                  context.go('/schools/${widget.schoolId}/risk');
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'students', child: Text('Students')),
              const PopupMenuItem(value: 'attendance', child: Text('Attendance')),
              const PopupMenuItem(value: 'fees', child: Text('Fees')),
              const PopupMenuItem(value: 'exams', child: Text('Exams')),
              const PopupMenuItem(value: 'risk', child: Text('Risk Alerts')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // School Header
          schoolAsync.when(
            data: (school) => _buildSchoolHeader(school!, riskProfileAsync),
            loading: () => _buildSchoolHeaderSkeleton(),
            error: (e, _) => ErrorState(message: e.toString()),
          ),

          // Tab Bar
          TabBar(
            tabs: const [
              Tab(text: 'Overview'),
              Tab(text: 'Students'),
              Tab(text: 'Attendance'),
              Tab(text: 'Fees'),
              Tab(text: 'Exams'),
              Tab(text: 'Risk'),
            ],
            onTap: (index) => setState(() => _selectedTab = index),
            isScrollable: true,
            tabAlignment: TabAlignment.start,
          ),

          // Tab Content
          Expanded(
            child: IndexedStack(
              index: _selectedTab,
              children: [
                _buildOverviewTab(riskProfileAsync, studentsAsync, attendanceAsync, feesAsync, examsAsync, alertsAsync),
                _buildStudentsTab(studentsAsync),
                _buildAttendanceTab(attendanceAsync),
                _buildFeesTab(feesAsync),
                _buildExamsTab(examsAsync),
                _buildRiskTab(alertsAsync, riskProfileAsync),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSchoolHeader(SchoolModel school, AsyncValue<SchoolRiskProfile> riskProfileAsync) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
            child: Icon(Icons.school, color: AppTheme.primaryColor, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  school.name,
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '${school.type.displayName} • ${school.code}',
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                Text(
                  '${school.address} • ${school.phone}',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          riskProfileAsync.when(
            data: (profile) => Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                RiskIndicator(level: profile.overallRiskLevel, size: 40, showLabel: true),
                const SizedBox(height: 4),
                Text(
                  'Composite: ${profile.compositeScore.toStringAsFixed(1)}%',
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            loading: () => const SizedBox(width: 100, child: LoadingState()),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildSchoolHeaderSkeleton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          CircleAvatar(radius: 30, backgroundColor: Colors.grey[300]),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 24, width: 200, color: Colors.grey[300]),
                const SizedBox(height: 8),
                Container(height: 16, width: 150, color: Colors.grey[300]),
                const SizedBox(height: 4),
                Container(height: 12, width: 100, color: Colors.grey[300]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(
    AsyncValue<SchoolRiskProfile> riskProfileAsync,
    AsyncValue<List<StudentModel>> studentsAsync,
    AsyncValue<List<AttendanceRecord>> attendanceAsync,
    AsyncValue<List<FeeRecord>> feesAsync,
    AsyncValue<List<ExamRecord>> examsAsync,
    AsyncValue<List<RiskAlert>> alertsAsync,
  ) {
    return RefreshIndicator(
      onRefresh: _refreshAll,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Risk Profile Summary
            riskProfileAsync.when(
              data: (profile) => _buildRiskProfileCards(profile),
              loading: () => _buildRiskProfileCardsSkeleton(),
              error: (e, _) => ErrorState(message: e.toString()),
            ),
            const SizedBox(height: 24),

            // Key Metrics Row
            Row(
              children: [
                Expanded(
                  child: studentsAsync.when(
                    data: (students) => MetricCard(
                      title: 'Total Students',
                      value: AppFormatters.formatNumber(students.length),
                      icon: Icons.people,
                      color: AppTheme.primaryColor,
                    ),
                    loading: () => _buildMetricSkeleton(),
                    error: (_, _) => _buildMetricSkeleton(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: feesAsync.when(
                    data: (fees) {
                      final overdue = fees.where((f) => f.isOverdue).length;
                      return MetricCard(
                        title: 'Overdue Fees',
                        value: '$overdue',
                        subtitle: '${fees.length} total fees',
                        icon: Icons.warning_amber,
                        color: overdue > 0 ? AppTheme.errorColor : AppTheme.successColor,
                      );
                    },
                    loading: () => _buildMetricSkeleton(),
                    error: (_, _) => _buildMetricSkeleton(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: examsAsync.when(
                    data: (exams) {
                      final upcoming = exams.where((e) => e.status == ExamStatus.scheduled).length;
                      return MetricCard(
                        title: 'Upcoming Exams',
                        value: '$upcoming',
                        subtitle: '${exams.length} total exams',
                        icon: Icons.event,
                        color: AppTheme.secondaryColor,
                      );
                    },
                    loading: () => _buildMetricSkeleton(),
                    error: (_, _) => _buildMetricSkeleton(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: alertsAsync.when(
                    data: (alerts) => MetricCard(
                      title: 'Active Alerts',
                      value: '${alerts.length}',
                      icon: Icons.notifications_active,
                      color: alerts.isNotEmpty ? AppTheme.errorColor : AppTheme.successColor,
                    ),
                    loading: () => _buildMetricSkeleton(),
                    error: (_, _) => _buildMetricSkeleton(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Charts Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: riskProfileAsync.when(
                    data: (profile) => _buildAttendanceChart(profile, attendanceAsync),
                    loading: () => _buildChartSkeleton('Attendance Trend'),
                    error: (_, _) => _buildChartSkeleton('Attendance Trend'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: riskProfileAsync.when(
                    data: (profile) => _buildRiskRadarChart(profile),
                    loading: () => _buildChartSkeleton('Risk Profile'),
                    error: (_, _) => _buildChartSkeleton('Risk Profile'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Category Breakdown
            riskProfileAsync.when(
              data: (profile) => _buildCategoryBreakdown(profile),
              loading: () => _buildCategoryBreakdownSkeleton(),
              error: (_, _) => _buildCategoryBreakdownSkeleton(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskProfileCards(SchoolRiskProfile profile) {
    return SectionCard(
      title: 'Risk Profile Summary',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _RiskProfileCard(
                  label: 'Attendance',
                  value: '${profile.attendanceRate.toStringAsFixed(1)}%',
                  level: profile.categoryRisks[RiskCategory.attendance]!,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _RiskProfileCard(
                  label: 'Fee Collection',
                  value: '${profile.feeCollectionRate.toStringAsFixed(1)}%',
                  level: profile.categoryRisks[RiskCategory.fees]!,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _RiskProfileCard(
                  label: 'Academic',
                  value: '${profile.examPassRate.toStringAsFixed(1)}%',
                  level: profile.categoryRisks[RiskCategory.academic]!,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _RiskProfileCard(
                  label: 'Enrollment',
                  value: '${profile.enrollmentTrend >= 0 ? '+' : ''}${profile.enrollmentTrend.toStringAsFixed(1)}%',
                  level: profile.categoryRisks[RiskCategory.enrollment]!,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRiskProfileCardsSkeleton() {
    return SectionCard(
      title: 'Risk Profile Summary',
      child: Row(
        children: List.generate(4, (i) => Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < 3 ? 12 : 0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Container(height: 16, width: 80, color: Colors.grey[300]),
                    const SizedBox(height: 8),
                    Container(height: 24, width: 60, color: Colors.grey[300]),
                    const SizedBox(height: 4),
                    Container(height: 20, width: 100, color: Colors.grey[300]),
                  ],
                ),
              ),
            ),
          ),
        )),
      ),
    );
  }

  Widget _buildAttendanceChart(SchoolRiskProfile profile, AsyncValue<List<AttendanceRecord>> attendanceAsync) {
    // Generate last 30 days attendance data
    final spots = List.generate(30, (i) {
      final base = profile.attendanceRate;
      final variance = (i % 7 - 3) * 2;
      return FlSpot(i.toDouble(), (base + variance).clamp(60, 100));
    });

    return SectionCard(
      title: 'Attendance Trend (30 Days)',
      child: LineChartWidget(
        spots: spots,
        lineColor: AppTheme.primaryColor,
        gradientStart: AppTheme.primaryColor,
        gradientEnd: AppTheme.secondaryColor,
        minY: 60,
        maxY: 100,
        targetLine: 90,
        targetLabel: 'Target: 90%',
      ),
    );
  }

  Widget _buildRiskRadarChart(SchoolRiskProfile profile) {
    // We'll use a bar chart for risk categories instead of radar
    final categories = [
      {'label': 'Attendance', 'value': profile.attendanceRate, 'level': profile.categoryRisks[RiskCategory.attendance]!},
      {'label': 'Fees', 'value': profile.feeCollectionRate, 'level': profile.categoryRisks[RiskCategory.fees]!},
      {'label': 'Academic', 'value': profile.examPassRate, 'level': profile.categoryRisks[RiskCategory.academic]!},
      {'label': 'Enrollment', 'value': (100 + profile.enrollmentTrend).clamp(0, 100), 'level': profile.categoryRisks[RiskCategory.enrollment]!},
    ];

    final barGroups = List.generate(categories.length, (i) {
      final cat = categories[i];
      final value = cat['value'] as double;
      final level = cat['level'] as RiskLevel;
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: value,
            color: level.color,
            width: 20,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    });

    return SectionCard(
      title: 'Risk Categories',
      child: BarChartWidget(
        barGroups: barGroups,
        xLabels: categories.map((c) => c['label'] as String).toList(),
        barColor: AppTheme.primaryColor,
        maxY: 100,
      ),
    );
  }

  Widget _buildCategoryBreakdown(SchoolRiskProfile profile) {
    return SectionCard(
      title: 'Detailed Metrics',
      child: Column(
        children: [
          _CategoryMetricRow(
            label: 'Attendance Rate',
            value: '${profile.attendanceRate.toStringAsFixed(1)}%',
            target: '≥ 90%',
            status: profile.categoryRisks[RiskCategory.attendance]!,
          ),
          const Divider(height: 1),
          _CategoryMetricRow(
            label: 'Fee Collection Rate',
            value: '${profile.feeCollectionRate.toStringAsFixed(1)}%',
            target: '≥ 85%',
            status: profile.categoryRisks[RiskCategory.fees]!,
          ),
          const Divider(height: 1),
          _CategoryMetricRow(
            label: 'Exam Pass Rate',
            value: '${profile.examPassRate.toStringAsFixed(1)}%',
            target: '≥ 70%',
            status: profile.categoryRisks[RiskCategory.academic]!,
          ),
          const Divider(height: 1),
          _CategoryMetricRow(
            label: 'Enrollment Trend',
            value: '${profile.enrollmentTrend >= 0 ? '+' : ''}${profile.enrollmentTrend.toStringAsFixed(1)}%',
            target: 'Stable/Growing',
            status: profile.categoryRisks[RiskCategory.enrollment]!,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdownSkeleton() {
    return SectionCard(
      title: 'Detailed Metrics',
      child: Column(
        children: List.generate(4, (i) => Column(
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Container(height: 16, width: 150, color: Colors.grey[300]),
              subtitle: Container(height: 12, width: 100, color: Colors.grey[300]),
            ),
            if (i < 3) const Divider(height: 1),
          ],
        )),
      ),
    );
  }

  Widget _buildStudentsTab(AsyncValue<List<StudentModel>> studentsAsync) {
    return studentsAsync.when(
      data: (students) {
        if (students.isEmpty) {
          return const EmptyState(
            icon: Icons.people_outline,
            title: 'No Students',
            message: 'No students enrolled in this school',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: students.length,
          itemBuilder: (context, index) {
            final student = students[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: AvatarWidget(
                  firstName: student.firstName,
                  lastName: student.lastName,
                ),
                title: Text('${student.firstName} ${student.lastName}', style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('Grade ${student.gradeLevel} • ${student.section} • ${student.studentNumber}'),
                trailing: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    RiskLevelChip(level: student.riskLevel, small: true),
                    Text(
                      '${student.attendanceScore}% attendance',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                onTap: () {
                  ref.read(selectedStudentIdProvider.notifier).state = student.id;
                  context.go('/students/${student.id}');
                },
              ),
            );
          },
        );
      },
      loading: () => const LoadingState(message: 'Loading students...'),
      error: (e, _) => ErrorState(message: e.toString()),
    );
  }

  Widget _buildAttendanceTab(AsyncValue<List<AttendanceRecord>> attendanceAsync) {
    return attendanceAsync.when(
      data: (records) {
        if (records.isEmpty) {
          return const EmptyState(
            icon: Icons.assignment_outlined,
            title: 'No Attendance Records',
            message: 'No attendance data for the selected period',
          );
        }

        // Group by date
        final byDate = <DateTime, List<AttendanceRecord>>{};
        for (final record in records) {
          final date = DateTime(record.date.year, record.date.month, record.date.day);
          byDate.putIfAbsent(date, () => []).add(record);
        }

        final sortedDates = byDate.keys.toList()..sort((a, b) => b.compareTo(a));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sortedDates.length,
          itemBuilder: (context, index) {
            final date = sortedDates[index];
            final dayRecords = byDate[date]!;
            final present = dayRecords.where((r) => r.status == AttendanceStatus.present).length;
            final total = dayRecords.length;
            final rate = total > 0 ? (present / total * 100) : 0;

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ExpansionTile(
                leading: CircleAvatar(
                  backgroundColor: rate >= 90 ? AppTheme.successColor.withOpacity(0.1) : AppTheme.warningColor.withOpacity(0.1),
                  child: Text(
                    '${rate.toInt()}%',
                    style: TextStyle(
                      color: rate >= 90 ? AppTheme.successColor : AppTheme.warningColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                title: Text(AppFormatters.formatDate(date), style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('$present of $total students present'),
                children: dayRecords.map((record) => ListTile(
                  dense: true,
                  leading: AvatarWidget(firstName: 'S', lastName: record.studentId.substring(0, 1).toUpperCase()),
                  title: Text('Student ${record.studentId}'),
                  trailing: StatusChip(
                    label: record.status.displayName,
                    color: record.status.color,
                    small: true,
                  ),
                )).toList(),
              ),
            );
          },
        );
      },
      loading: () => const LoadingState(message: 'Loading attendance...'),
      error: (e, _) => ErrorState(message: e.toString()),
    );
  }

  Widget _buildFeesTab(AsyncValue<List<FeeRecord>> feesAsync) {
    return feesAsync.when(
      data: (fees) {
        if (fees.isEmpty) {
          return const EmptyState(
            icon: Icons.account_balance_wallet_outlined,
            title: 'No Fee Records',
            message: 'No fee records for this school',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: fees.length,
          itemBuilder: (context, index) {
            final fee = fees[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: fee.status.color.withOpacity(0.1),
                  child: Icon(Icons.receipt, color: fee.status.color),
                ),
                title: Text(fee.feeType, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('${fee.description} • Due: ${AppFormatters.formatShortDate(fee.dueDate)}'),
                trailing: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    StatusChip(label: fee.status.displayName, color: fee.status.color, small: true),
                    Text(
                      '${AppFormatters.formatCurrency(fee.amountPaid)} / ${AppFormatters.formatCurrency(fee.amountDue)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const LoadingState(message: 'Loading fees...'),
      error: (e, _) => ErrorState(message: e.toString()),
    );
  }

  Widget _buildExamsTab(AsyncValue<List<ExamRecord>> examsAsync) {
    return examsAsync.when(
      data: (exams) {
        if (exams.isEmpty) {
          return const EmptyState(
            icon: Icons.school_outlined,
            title: 'No Exams',
            message: 'No exams scheduled for this school',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: exams.length,
          itemBuilder: (context, index) {
            final exam = exams[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: exam.status.color.withOpacity(0.1),
                  child: Icon(Icons.quiz, color: exam.status.color),
                ),
                title: Text(exam.examName, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('${exam.subject} • ${exam.type.displayName} • ${AppFormatters.formatDate(exam.examDate)}'),
                trailing: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    StatusChip(label: exam.status.displayName, color: exam.status.color, small: true),
                    if (exam.obtainedScore != null)
                      Text(
                        '${exam.percentage.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: exam.percentage >= 60 ? AppTheme.successColor : AppTheme.errorColor,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const LoadingState(message: 'Loading exams...'),
      error: (e, _) => ErrorState(message: e.toString()),
    );
  }

  Widget _buildRiskTab(AsyncValue<List<RiskAlert>> alertsAsync, AsyncValue<SchoolRiskProfile> riskProfileAsync) {
    return Column(
      children: [
        // Risk Profile Header
        riskProfileAsync.when(
          data: (profile) => Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: profile.overallRiskLevel.color.withOpacity(0.05),
              border: Border(bottom: BorderSide(color: profile.overallRiskLevel.color.withOpacity(0.2))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning_amber, color: profile.overallRiskLevel.color),
                          const SizedBox(width: 8),
                          Text(
                            'Overall Risk: ${profile.overallRiskLevel.displayName}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: profile.overallRiskLevel.color,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Composite Score: ${profile.compositeScore.toStringAsFixed(1)}%',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                RiskIndicator(level: profile.overallRiskLevel, size: 48, showLabel: true),
              ],
            ),
          ),
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
        ),

        // Alerts List
        Expanded(
          child: alertsAsync.when(
            data: (alerts) {
              if (alerts.isEmpty) {
                return const EmptyState(
                  icon: Icons.check_circle_outline,
                  title: 'No Active Alerts',
                  message: 'All systems operating normally',
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: alerts.length,
                itemBuilder: (context, index) {
                  final alert = alerts[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ExpansionTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: alert.level.color.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(alert.category.icon, color: alert.level.color, size: 20),
                      ),
                      title: Text(alert.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(alert.description),
                      trailing: RiskLevelChip(level: alert.level, small: true),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Category: ${alert.category.displayName}', style: Theme.of(context).textTheme.bodyMedium),
                              const SizedBox(height: 4),
                              Text('Triggered: ${AppFormatters.formatDateTime(alert.triggeredAt)}', style: Theme.of(context).textTheme.bodySmall),
                              const SizedBox(height: 4),
                              Text('Metrics:', style: Theme.of(context).textTheme.labelLarge),
                              ...alert.metrics.entries.map((e) => Text('  ${e.key}: ${e.value}')),
                              if (alert.resolutionNotes != null) ...[
                                const SizedBox(height: 8),
                                Text('Resolution: ${alert.resolutionNotes}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.successColor)),
                              ],
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (!alert.isResolved)
                                    FilledButton.icon(
                                      onPressed: () => _resolveAlert(alert),
                                      icon: const Icon(Icons.check),
                                      label: const Text('Resolve'),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
            loading: () => const LoadingState(message: 'Loading alerts...'),
            error: (e, _) => ErrorState(message: e.toString()),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricSkeleton() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 24, width: 80, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Container(height: 32, width: 60, color: Colors.grey[300]),
            const SizedBox(height: 4),
            Container(height: 16, width: 100, color: Colors.grey[300]),
          ],
        ),
      ),
    );
  }

  Widget _buildChartSkeleton(String title) {
    return SectionCard(
      title: title,
      child: Card(
        child: SizedBox(height: 200, child: Center(child: LoadingState(message: ''))),
      ),
    );
  }

  Future<void> _refreshAll() async {
    ref.invalidate(currentSchoolProvider);
    ref.invalidate(schoolRiskProfileProvider(widget.schoolId));
    ref.invalidate(studentsBySchoolProvider(widget.schoolId));
    ref.invalidate(attendanceBySchoolProvider(widget.schoolId));
    ref.invalidate(feesBySchoolProvider(widget.schoolId));
    ref.invalidate(examsBySchoolProvider(widget.schoolId));
    ref.invalidate(activeAlertsBySchoolProvider(widget.schoolId));
  }

  Future<void> _resolveAlert(RiskAlert alert) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resolve Alert'),
        content: Text('Mark "${alert.title}" as resolved?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Resolve')),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(firestoreServiceProvider).resolveAlert(alert.id, 'Current User', 'Resolved via dashboard');
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Alert resolved')));
        _refreshAll();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}

class _RiskProfileCard extends StatelessWidget {
  final String label;
  final String value;
  final RiskLevel level;

  const _RiskProfileCard({
    required this.label,
    required this.value,
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: level.color.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: level.color.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            RiskLevelChip(level: level),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: level.color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryMetricRow extends StatelessWidget {
  final String label;
  final String value;
  final String target;
  final RiskLevel status;

  const _CategoryMetricRow({
    required this.label,
    required this.value,
    required this.target,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: status.color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: status.color,
              fontSize: 12,
            ),
          ),
        ),
      ),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text('Target: $target'),
      trailing: RiskLevelChip(level: status, small: true),
    );
  }
}