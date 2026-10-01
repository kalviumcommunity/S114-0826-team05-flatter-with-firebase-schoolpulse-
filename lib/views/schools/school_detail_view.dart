import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/models.dart';
import '../../providers/app_providers.dart';
import '../../utils/app_formatters.dart';
import '../../utils/app_theme.dart';
import '../../widgets/common_widgets.dart';

class SchoolDetailView extends ConsumerStatefulWidget {
  final String schoolId;

  const SchoolDetailView({super.key, required this.schoolId});

  @override
  ConsumerState<SchoolDetailView> createState() => _SchoolDetailViewState();
}

class _SchoolDetailViewState extends ConsumerState<SchoolDetailView> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final schoolAsync = ref.watch(currentSchoolProvider);
    final riskProfileAsync = ref.watch(schoolRiskProfileProvider(widget.schoolId));
    final studentsAsync = ref.watch(studentsBySchoolProvider(widget.schoolId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('School Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(currentSchoolProvider);
              ref.invalidate(schoolRiskProfileProvider(widget.schoolId));
              ref.invalidate(studentsBySchoolProvider(widget.schoolId));
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: schoolAsync.when(
        data: (school) {
          if (school == null) {
            return const EmptyState(
              icon: Icons.school_outlined,
              title: 'School Not Found',
              message: 'The requested school could not be found',
            );
          }
          return _buildSchoolDetails(school, riskProfileAsync, studentsAsync);
        },
        loading: () => const LoadingState(message: 'Loading school details...'),
        error: (e, _) => ErrorState(message: e.toString()),
      ),
    );
  }

  Widget _buildSchoolDetails(SchoolModel school, AsyncValue<SchoolRiskProfile> riskProfileAsync, AsyncValue<List<StudentModel>> studentsAsync) {
    return CustomScrollView(
      slivers: [
        // School Header
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      child: const Icon(Icons.school, color: Colors.white, size: 32),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            school.name,
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${school.code} • ${school.type.displayName}',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    _InfoChip(
                      label: 'District',
                      value: school.districtId,
                      icon: Icons.location_city,
                    ),
                    _InfoChip(
                      label: 'Capacity',
                      value: '${school.currentEnrollment}/${school.totalCapacity}',
                      icon: Icons.people,
                    ),
                    _InfoChip(
                      label: 'Utilization',
                      value: '${school.utilizationRate.toStringAsFixed(1)}%',
                      icon: Icons.analytics,
                    ),
                    _InfoChip(
                      label: 'Grades',
                      value: school.gradeLevels.join(', '),
                      icon: Icons.grade,
                    ),
                    _InfoChip(
                      label: 'Phone',
                      value: school.phone,
                      icon: Icons.phone,
                    ),
                    _InfoChip(
                      label: 'Email',
                      value: school.email,
                      icon: Icons.email,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Risk Profile Section
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Risk Profile',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: riskProfileAsync.when(
            data: (profile) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _RiskMetricCard(
                          title: 'Attendance',
                          value: '${profile.attendanceRate.toStringAsFixed(1)}%',
                          icon: Icons.assignment_ind,
                          color: profile.categoryRisks[RiskCategory.attendance]!.color,
                          riskLevel: profile.categoryRisks[RiskCategory.attendance]!,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _RiskMetricCard(
                          title: 'Fee Collection',
                          value: '${profile.feeCollectionRate.toStringAsFixed(1)}%',
                          icon: Icons.account_balance_wallet,
                          color: profile.categoryRisks[RiskCategory.fees]!.color,
                          riskLevel: profile.categoryRisks[RiskCategory.fees]!,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _RiskMetricCard(
                            title: 'Exam Pass Rate',
                            value: '${profile.examPassRate.toStringAsFixed(1)}%',
                            icon: Icons.school,
                            color: profile.categoryRisks[RiskCategory.academic]!.color,
                            riskLevel: profile.categoryRisks[RiskCategory.academic]!,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _RiskMetricCard(
                            title: 'Enrollment Trend',
                            value: '${profile.enrollmentTrend >= 0 ? '+' : ''}${profile.enrollmentTrend.toStringAsFixed(1)}%',
                            icon: Icons.people,
                            color: profile.categoryRisks[RiskCategory.enrollment]!.color,
                            riskLevel: profile.categoryRisks[RiskCategory.enrollment]!,
                          ),
                        ),
                      ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _RiskMetricCard(
                            title: 'Overall Risk',
                            value: profile.overallRiskLevel.displayName,
                            icon: Icons.warning_amber,
                            color: profile.overallRiskLevel.color,
                            riskLevel: profile.overallRiskLevel,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _RiskMetricCard(
                            title: 'Composite Score',
                            value: '${profile.compositeScore.toStringAsFixed(1)}',
                            icon: Icons.analytics,
                            color: _getCompositeColor(profile.compositeScore),
                            riskLevel: profile.overallRiskLevel,
                          ),
                        ),
                      ],
                ),
              ),
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: LoadingState(message: 'Loading risk profile...'),
            ),
            error: (e, _) => ErrorState(message: e.toString()),
          ),
        ),

        // Active Alerts Section
        if (riskProfileAsync.hasValue && riskProfileAsync.value!.activeAlerts.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Active Alerts',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () => context.go('/schools/${widget.schoolId}/risk'),
                    child: const Text('View All'),
                  ),
                ],
              ),
            ),
          ),
        if (riskProfileAsync.hasValue && riskProfileAsync.value!.activeAlerts.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: riskProfileAsync.value!.activeAlerts.take(3).map((alert) => _AlertListTile(alert: alert)).toList(),
              ),
            ),
          ),

        // Students Section
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Students',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () => context.go('/schools/${widget.schoolId}/students'),
                  child: const Text('View All'),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: studentsAsync.when(
            data: (students) {
              if (students.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: EmptyState(
                    icon: Icons.people_outline,
                    title: 'No Students',
                    message: 'No students enrolled at this school',
                  ),
                );
              }
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: students.take(5).map((student) => _StudentListTile(
                    student: student,
                    onTap: () => context.go('/students/${student.id}'),
                  )).toList(),
                ),
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: LoadingState(message: 'Loading students...'),
            ),
            error: (e, _) => ErrorState(message: e.toString()),
          ),
        ),
      ],
    );
  }

  Color _getCompositeColor(double score) {
    if (score < 60) return AppTheme.errorColor;
    if (score < 70) return AppTheme.errorColor;
    if (score < 80) return AppTheme.warningColor;
    return AppTheme.successColor;
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InfoChip({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _RiskMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final RiskLevel riskLevel;

  const _RiskMetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.riskLevel,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                RiskLevelChip(level: riskLevel, small: true),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertListTile extends StatelessWidget {
  final RiskAlert alert;

  const _AlertListTile({required this.alert});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      border: Border.all(color: alert.level.color.withOpacity(0.3)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: alert.level.color.withOpacity(0.1),
          child: Icon(alert.category.icon, color: alert.level.color),
        ),
        title: Text(alert.title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(alert.description),
        trailing: RiskLevelChip(level: alert.level),
        onTap: () {
          // Could navigate to alert details
        },
      ),
    );
  }
}

class _StudentListTile extends StatelessWidget {
  final StudentModel student;
  final VoidCallback onTap;

  const _StudentListTile({
    required this.student,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              AvatarWidget(
                firstName: student.firstName,
                lastName: student.lastName,
                radius: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${student.firstName} ${student.lastName}',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        RiskLevelChip(level: student.riskLevel, small: true),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Grade ${student.gradeLevel}${student.section.isNotEmpty ? ' - Section ${student.section}' : ''} • ${student.studentNumber}',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.assignment_ind, size: 14, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          '${student.attendanceScore}% attendance',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.account_balance_wallet, size: 14, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          '\$${student.feeBalance.toStringAsFixed(2)} balance',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: student.feeBalance > 0 ? AppTheme.errorColor : AppTheme.successColor,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.school, size: 14, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          '${student.examAverage.toStringAsFixed(1)}% avg',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}