import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/models.dart';
import '../../providers/app_providers.dart';
import '../../utils/app_formatters.dart';
import '../../utils/app_theme.dart';
import '../../widgets/common_widgets.dart';

class StudentDetailView extends ConsumerStatefulWidget {
  final String studentId;

  const StudentDetailView({super.key, required this.studentId});

  @override
  ConsumerState<StudentDetailView> createState() => _StudentDetailViewState();
}

class _StudentDetailViewState extends ConsumerState<StudentDetailView> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final studentAsync = ref.watch(currentStudentProvider);
    final attendanceAsync = ref.watch(attendanceByStudentProvider(widget.studentId));
    final feesAsync = ref.watch(feesByStudentProvider(widget.studentId));
    final examsAsync = ref.watch(examsByStudentProvider(widget.studentId));

    return Scaffold(
      appBar: AppBar(
        title: studentAsync.when(
          data: (student) => Text(student != null ? '${student.firstName} ${student.lastName}' : 'Student Detail'),
          loading: () => const Text('Student Detail'),
          error: (_, _) => const Text('Student Detail'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showEditStudentDialog(studentAsync.value),
            tooltip: 'Edit Student',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'refresh') _refreshAll();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'refresh', child: Text('Refresh')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Student Header
          studentAsync.when(
            data: (student) => student != null ? _buildStudentHeader(student) : _buildStudentHeaderSkeleton(),
            loading: () => _buildStudentHeaderSkeleton(),
            error: (e, _) => ErrorState(message: e.toString()),
          ),

          // Tab Bar
          TabBar(
            tabs: const [
              Tab(text: 'Overview'),
              Tab(text: 'Attendance'),
              Tab(text: 'Fees'),
              Tab(text: 'Exams'),
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
                _buildOverviewTab(studentAsync, attendanceAsync, feesAsync, examsAsync),
                _buildAttendanceTab(attendanceAsync),
                _buildFeesTab(feesAsync),
                _buildExamsTab(examsAsync),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentHeader(StudentModel student) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(bottom: BorderSide(color: theme.colorScheme.outlineVariant)),
      ),
      child: Row(
        children: [
          AvatarWidget(
            firstName: student.firstName,
            lastName: student.lastName,
            radius: 30,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${student.firstName} ${student.lastName}',
                        style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    RiskLevelChip(level: student.riskLevel),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${student.studentNumber} • Grade ${student.gradeLevel}${student.section.isNotEmpty ? ' - ${student.section}' : ''}',
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                Text(
                  'Parent: ${student.parentPhone} • ${student.parentEmail}',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _MetricBadge(label: 'Attendance', value: '${student.attendanceScore}%', color: AppTheme.primaryColor),
              const SizedBox(height: 4),
              _MetricBadge(label: 'Fee Balance', value: '\$${student.feeBalance.toStringAsFixed(2)}', color: student.feeBalance > 0 ? AppTheme.errorColor : AppTheme.successColor),
              const SizedBox(height: 4),
              _MetricBadge(label: 'Exam Avg', value: '${student.examAverage.toStringAsFixed(1)}%', color: AppTheme.secondaryColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStudentHeaderSkeleton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey[300]!))),
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
    AsyncValue<StudentModel?> studentAsync,
    AsyncValue<List<AttendanceRecord>> attendanceAsync,
    AsyncValue<List<FeeRecord>> feesAsync,
    AsyncValue<List<ExamRecord>> examsAsync,
  ) {
    return RefreshIndicator(
      onRefresh: _refreshAll,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick Stats
            studentAsync.when(
              data: (student) => student != null ? _buildQuickStats(student, attendanceAsync, feesAsync, examsAsync) : const SizedBox(),
              loading: () => _buildQuickStatsSkeleton(),
              error: (_, _) => const SizedBox(),
            ),
            const SizedBox(height: 24),

            // Attendance Chart
            SectionCard(
              title: 'Attendance Trend (Last 30 Days)',
              child: studentAsync.when(
                data: (student) => student != null ? _buildStudentAttendanceChart(student, attendanceAsync) : const SizedBox(),
                loading: () => _buildChartSkeleton(),
                error: (_, _) => _buildChartSkeleton(),
              ),
            ),
            const SizedBox(height: 16),

            // Fee Summary
            feesAsync.when(
              data: (fees) => _buildFeeSummary(fees),
              loading: () => _buildFeeSummarySkeleton(),
              error: (_, _) => _buildFeeSummarySkeleton(),
            ),
            const SizedBox(height: 16),

            // Exam Summary
            examsAsync.when(
              data: (exams) => _buildExamSummary(exams),
              loading: () => _buildExamSummarySkeleton(),
              error: (_, _) => _buildExamSummarySkeleton(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats(StudentModel student, AsyncValue<List<AttendanceRecord>> attendanceAsync,
      AsyncValue<List<FeeRecord>> feesAsync, AsyncValue<List<ExamRecord>> examsAsync) {
    return Row(
      children: [
        Expanded(
          child: MetricCard(
            title: 'Attendance Rate',
            value: '${student.attendanceScore}%',
            subtitle: student.attendanceScore >= 90 ? 'Good' : 'Needs Improvement',
            icon: Icons.assignment_ind,
            color: student.attendanceScore >= 90 ? AppTheme.successColor : AppTheme.warningColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: feesAsync.when(
            data: (fees) {
              final totalDue = fees.fold<double>(0, (sum, f) => sum + f.amountDue);
              final totalPaid = fees.fold<double>(0, (sum, f) => sum + f.amountPaid);
              final overdue = fees.where((f) => f.isOverdue).length;
              return MetricCard(
                title: 'Fees',
                value: '\$${(totalDue - totalPaid).toStringAsFixed(2)}',
                subtitle: '$overdue overdue • \$${totalPaid.toStringAsFixed(2)} paid',
                icon: Icons.account_balance_wallet,
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
              final graded = exams.where((e) => e.status == ExamStatus.graded).toList();
              final avg = graded.isNotEmpty
                  ? graded.fold<double>(0, (sum, e) => sum + e.percentage) / graded.length
                  : 0.0;
              return MetricCard(
                title: 'Academic',
                value: '${avg.toStringAsFixed(1)}%',
                subtitle: '${graded.length} graded exams',
                icon: Icons.school,
                color: avg >= 70 ? AppTheme.successColor : AppTheme.warningColor,
              );
            },
            loading: () => _buildMetricSkeleton(),
            error: (_, _) => _buildMetricSkeleton(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: MetricCard(
            title: 'Risk Level',
            value: student.riskLevel.displayName,
            subtitle: 'Composite assessment',
            icon: Icons.warning_amber,
            color: student.riskLevel.color,
          ),
        ),
      ],
    );
  }

  Widget _buildStudentAttendanceChart(StudentModel student, AsyncValue<List<AttendanceRecord>> attendanceAsync) {
    return attendanceAsync.when(
      data: (records) {
        // Group by date and calculate daily rate
        final byDate = <DateTime, List<AttendanceRecord>>{};
        for (final record in records) {
          final date = DateTime(record.date.year, record.date.month, record.date.day);
          byDate.putIfAbsent(date, () => []).add(record);
        }

        final sortedDates = byDate.keys.toList()..sort();
        final last30 = sortedDates.length > 30 ? sortedDates.sublist(sortedDates.length - 30) : sortedDates;

        final spots = last30.asMap().entries.map((entry) {
          final i = entry.key;
          final date = entry.value;
          final dayRecords = byDate[date]!;
          final present = dayRecords.where((r) => r.status == AttendanceStatus.present).length;
          final total = dayRecords.length;
          final rate = total > 0 ? (present / total * 100) : 100.0;
          return FlSpot(i.toDouble(), rate.toDouble());
        }).toList();

        return LineChartWidget(
          spots: spots,
          lineColor: AppTheme.primaryColor,
          gradientStart: AppTheme.primaryColor,
          gradientEnd: AppTheme.secondaryColor,
          minY: 0,
          maxY: 100,
          targetLine: 90,
          targetLabel: 'Target: 90%',
        );
      },
      loading: () => _buildChartSkeleton(),
      error: (_, _) => _buildChartSkeleton(),
    );
  }

  Widget _buildFeeSummary(List<FeeRecord> fees) {
    final totalDue = fees.fold<double>(0, (sum, f) => sum + f.amountDue);
    final totalPaid = fees.fold<double>(0, (sum, f) => sum + f.amountPaid);
    final overdue = fees.where((f) => f.isOverdue).toList();
    final pending = fees.where((f) => f.status == FeeStatus.pending).toList();
    final partial = fees.where((f) => f.status == FeeStatus.partial).toList();

    return SectionCard(
      title: 'Fee Summary',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _SummaryItem(label: 'Total Due', value: AppFormatters.formatCurrency(totalDue), color: AppTheme.primaryColor)),
              Expanded(child: _SummaryItem(label: 'Total Paid', value: AppFormatters.formatCurrency(totalPaid), color: AppTheme.successColor)),
              Expanded(child: _SummaryItem(label: 'Balance', value: AppFormatters.formatCurrency(totalDue - totalPaid), color: totalDue > totalPaid ? AppTheme.errorColor : AppTheme.successColor)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _SummaryItem(label: 'Overdue', value: '${overdue.length}', color: AppTheme.errorColor)),
              Expanded(child: _SummaryItem(label: 'Pending', value: '${pending.length}', color: AppTheme.warningColor)),
              Expanded(child: _SummaryItem(label: 'Partial', value: '${partial.length}', color: AppTheme.infoColor)),
            ],
          ),
          if (overdue.isNotEmpty) ...[
            const Divider(height: 24),
            Text('Overdue Items', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ...overdue.take(3).map((fee) => ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(fee.feeType, style: const TextStyle(fontWeight: FontWeight.w500)),
              subtitle: Text('Due: ${AppFormatters.formatShortDate(fee.dueDate)} • Balance: ${AppFormatters.formatCurrency(fee.balance)}'),
              trailing: Text(AppFormatters.formatCurrency(fee.amountDue), style: const TextStyle(color: AppTheme.errorColor, fontWeight: FontWeight.w600)),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildExamSummary(List<ExamRecord> exams) {
    final graded = exams.where((e) => e.status == ExamStatus.graded).toList();
    final upcoming = exams.where((e) => e.status == ExamStatus.scheduled).toList();
    final avg = graded.isNotEmpty ? graded.fold<double>(0, (sum, e) => sum + e.percentage) / graded.length : 0.0;

    return SectionCard(
      title: 'Exam Summary',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _SummaryItem(label: 'Average Score', value: '${avg.toStringAsFixed(1)}%', color: avg >= 70 ? AppTheme.successColor : AppTheme.warningColor)),
              Expanded(child: _SummaryItem(label: 'Graded', value: '${graded.length}', color: AppTheme.primaryColor)),
              Expanded(child: _SummaryItem(label: 'Upcoming', value: '${upcoming.length}', color: AppTheme.infoColor)),
            ],
          ),
          if (upcoming.isNotEmpty) ...[
            const Divider(height: 24),
            Text('Upcoming Exams', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ...upcoming.take(5).map((exam) => ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(backgroundColor: exam.status.color.withOpacity(0.1), child: Icon(Icons.quiz, color: exam.status.color, size: 18)),
              title: Text(exam.examName, style: const TextStyle(fontWeight: FontWeight.w500)),
              subtitle: Text('${exam.subject} • ${AppFormatters.formatDate(exam.examDate)}'),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildAttendanceTab(AsyncValue<List<AttendanceRecord>> attendanceAsync) {
    return attendanceAsync.when(
      data: (records) {
        if (records.isEmpty) {
          return const EmptyState(icon: Icons.assignment_outlined, title: 'No Attendance Records', message: 'No attendance data available');
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
            final studentRecord = dayRecords.firstWhere((r) => r.studentId == widget.studentId, orElse: () => dayRecords.first);

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: studentRecord.status.color.withOpacity(0.1),
                  child: Icon(_getStatusIcon(studentRecord.status), color: studentRecord.status.color),
                ),
                title: Text(AppFormatters.formatDate(date), style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('${studentRecord.status.displayName}${studentRecord.period != null ? ' • ${studentRecord.period}' : ''}'),
                trailing: StatusChip(label: studentRecord.status.displayName, color: studentRecord.status.color, small: true),
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
          return const EmptyState(icon: Icons.account_balance_wallet_outlined, title: 'No Fee Records', message: 'No fee records for this student');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: fees.length,
          itemBuilder: (context, index) {
            final fee = fees[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(backgroundColor: fee.status.color.withOpacity(0.1), child: Icon(Icons.receipt, color: fee.status.color)),
                title: Text(fee.feeType, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${fee.description} • Due: ${AppFormatters.formatShortDate(fee.dueDate)}'),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: fee.paymentPercentage / 100,
                      backgroundColor: fee.status.color.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(fee.status.color),
                    ),
                  ],
                ),
                trailing: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    StatusChip(label: fee.status.displayName, color: fee.status.color, small: true),
                    Text('${AppFormatters.formatCurrency(fee.amountPaid)} / ${AppFormatters.formatCurrency(fee.amountDue)}', style: Theme.of(context).textTheme.bodySmall),
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
          return const EmptyState(icon: Icons.school_outlined, title: 'No Exams', message: 'No exams for this student');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: exams.length,
          itemBuilder: (context, index) {
            final exam = exams[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(backgroundColor: exam.status.color.withOpacity(0.1), child: Icon(Icons.quiz, color: exam.status.color)),
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

  Widget _buildQuickStatsSkeleton() {
    return Row(
      children: List.generate(4, (i) => Expanded(
        child: Padding(
          padding: EdgeInsets.only(right: i < 3 ? 12 : 0),
          child: _buildMetricSkeleton(),
        ),
      )),
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

  Widget _buildChartSkeleton() {
    return Card(child: SizedBox(height: 200, child: Center(child: LoadingState(message: ''))));
  }

  Widget _buildFeeSummarySkeleton() {
    return SectionCard(title: 'Fee Summary', child: Card(child: SizedBox(height: 100, child: Center(child: LoadingState(message: '')))));
  }

  Widget _buildExamSummarySkeleton() {
    return SectionCard(title: 'Exam Summary', child: Card(child: SizedBox(height: 100, child: Center(child: LoadingState(message: '')))));
  }

  Future<void> _refreshAll() async {
    ref.invalidate(currentStudentProvider);
    ref.invalidate(attendanceByStudentProvider(widget.studentId));
    ref.invalidate(feesByStudentProvider(widget.studentId));
    ref.invalidate(examsByStudentProvider(widget.studentId));
  }

  void _showEditStudentDialog(StudentModel? student) {
    if (student == null) return;
    // Implementation for editing student
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Edit student feature coming soon')));
  }

  IconData _getStatusIcon(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return Icons.check_circle;
      case AttendanceStatus.absent:
        return Icons.cancel;
      case AttendanceStatus.late:
        return Icons.access_time;
      case AttendanceStatus.excused:
        return Icons.verified;
      case AttendanceStatus.partial:
        return Icons.remove_circle_outline;
    }
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryItem({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(value, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ],
    );
  }
}

class _MetricBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricBadge({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 14)),
          Text(label, style: TextStyle(color: color, fontSize: 10)),
        ],
      ),
    );
  }
}