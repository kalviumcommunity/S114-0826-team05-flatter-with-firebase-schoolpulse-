import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import '../../models/models.dart';
import '../../providers/app_providers.dart';
import '../../services/risk_calculation_service.dart';
import '../../utils/app_formatters.dart';
import '../../utils/app_theme.dart';
import '../../widgets/common_widgets.dart';

class DistrictDashboardView extends ConsumerStatefulWidget {
  final String? districtId;

  const DistrictDashboardView({super.key, this.districtId});

  @override
  ConsumerState<DistrictDashboardView> createState() => _DistrictDashboardViewState();
}

class _DistrictDashboardViewState extends ConsumerState<DistrictDashboardView> {
  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final districtId = widget.districtId ?? ref.watch(currentDistrictIdProvider);
    final userProfile = ref.watch(currentUserProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('District Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _selectDateRange,
            tooltip: 'Select Date Range',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(districtRiskSummaryProvider),
            tooltip: 'Refresh Data',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'settings') context.go('/settings');
              if (value == 'logout') _handleLogout();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'settings', child: Text('Settings')),
              const PopupMenuItem(value: 'logout', child: Text('Logout')),
            ],
          ),
        ],
      ),
      body: districtId == null
          ? _buildDistrictSelector()
          : _buildDashboard(districtId),
    );
  }

  Widget _buildDistrictSelector() {
    final districtsAsync = ref.watch(districtsProvider);

    return districtsAsync.when(
      data: (districts) {
        if (districts.isEmpty) {
          return const EmptyState(
            icon: Icons.location_city_outlined,
            title: 'No Districts Found',
            message: 'Contact your system administrator to set up districts.',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: districts.length,
          itemBuilder: (context, index) {
            final district = districts[index];
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primaryColor,
                  child: Text(district.name[0], style: const TextStyle(color: Colors.white)),
                ),
                title: Text(district.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('Code: ${district.code}'),
                onTap: () {
                  ref.read(currentDistrictIdProvider.notifier).state = district.id;
                },
              ),
            );
          },
        );
      },
      loading: () => const LoadingState(message: 'Loading districts...'),
      error: (e, _) => ErrorState(message: e.toString(), onRetry: () => ref.invalidate(districtsProvider)),
    );
  }

  Widget _buildDashboard(String districtId) {
    final riskSummaryAsync = ref.watch(districtRiskSummaryProvider(districtId));
    final activeAlertsAsync = ref.watch(activeAlertsByDistrictProvider(districtId));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(districtRiskSummaryProvider(districtId));
        ref.invalidate(activeAlertsByDistrictProvider(districtId));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'District Overview',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Last updated: ${AppFormatters.formatDateTime(DateTime.now())}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: _selectDateRange,
                  icon: const Icon(Icons.date_range, size: 18),
                  label: Text(
                    '${AppFormatters.formatShortDate(_dateRange.start)} - ${AppFormatters.formatShortDate(_dateRange.end)}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Risk Summary
            riskSummaryAsync.when(
              data: (summary) => _buildRiskSummary(summary),
              loading: () => const LoadingState(message: 'Calculating risk metrics...'),
              error: (e, _) => ErrorState(message: e.toString()),
            ),
            const SizedBox(height: 24),

            // Metric Cards Row
            riskSummaryAsync.when(
              data: (summary) => _buildMetricCards(summary),
              loading: () => _buildMetricCardsSkeleton(),
              error: (e, _) => _buildMetricCardsSkeleton(),
            ),
            const SizedBox(height: 24),

            // Charts Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: riskSummaryAsync.when(
                    data: (summary) => _buildAttendanceTrendChart(summary),
                    loading: () => _buildChartSkeleton(),
                    error: (e, _) => _buildChartSkeleton(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: riskSummaryAsync.when(
                    data: (summary) => _buildRiskDistributionChart(summary),
                    loading: () => _buildChartSkeleton(),
                    error: (e, _) => _buildChartSkeleton(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Second Charts Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 1,
                  child: riskSummaryAsync.when(
                    data: (summary) => _buildFeeCollectionChart(summary),
                    loading: () => _buildChartSkeleton(),
                    error: (e, _) => _buildChartSkeleton(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: riskSummaryAsync.when(
                    data: (summary) => _buildAcademicPerformanceChart(summary),
                    loading: () => _buildChartSkeleton(),
                    error: (e, _) => _buildChartSkeleton(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Active Alerts
            _buildActiveAlertsSection(activeAlertsAsync),
            const SizedBox(height: 24),

            // Top Risk Schools
            riskSummaryAsync.when(
              data: (summary) => _buildTopRiskSchools(summary.topRiskSchools),
              loading: () => _buildTopRiskSchoolsSkeleton(),
              error: (e, _) => _buildTopRiskSchoolsSkeleton(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskSummary(DistrictRiskSummary summary) {
    final theme = Theme.of(context);

    return SectionCard(
      title: 'District Risk Summary',
      subtitle: '${summary.totalSchools} schools • ${AppFormatters.formatNumber(summary.totalStudents)} students',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _RiskSummaryCard(
                  label: 'Overall Risk',
                  value: summary.schoolsByRiskLevel.entries
                      .fold<RiskLevel>(RiskLevel.low, (a, b) => b.key.priority > a.priority ? b.key : a)
                      .displayName,
                  color: summary.schoolsByRiskLevel.entries
                      .fold<RiskLevel>(RiskLevel.low, (a, b) => b.key.priority > a.priority ? b.key : a)
                      .color,
                  icon: Icons.analytics,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _RiskSummaryCard(
                  label: 'Critical Schools',
                  value: '${summary.schoolsByRiskLevel[RiskLevel.critical] ?? 0}',
                  color: RiskLevel.critical.color,
                  icon: Icons.dangerous,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _RiskSummaryCard(
                  label: 'High Risk Schools',
                  value: '${summary.schoolsByRiskLevel[RiskLevel.high] ?? 0}',
                  color: RiskLevel.high.color,
                  icon: Icons.warning,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _RiskSummaryCard(
                  label: 'Active Alerts',
                  value: '${summary.alertsByCategory.values.fold(0, (a, b) => a + b)}',
                  color: AppTheme.accentColor,
                  icon: Icons.notifications_active,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCards(DistrictRiskSummary summary) {
    return Row(
      children: [
        Expanded(
          child: MetricCard(
            title: 'Attendance Rate',
            value: '${summary.overallAttendanceRate.toStringAsFixed(1)}%',
            subtitle: summary.overallAttendanceRate >= 90 ? 'On Target' : 'Below Target',
            icon: Icons.assignment_ind,
            color: summary.overallAttendanceRate >= 90 ? AppTheme.successColor : AppTheme.warningColor,
            trend: Icon(
              summary.overallAttendanceRate >= 90 ? Icons.trending_up : Icons.trending_down,
              color: summary.overallAttendanceRate >= 90 ? AppTheme.successColor : AppTheme.errorColor,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: MetricCard(
            title: 'Fee Collection',
            value: '${summary.overallFeeCollectionRate.toStringAsFixed(1)}%',
            subtitle: summary.overallFeeCollectionRate >= 85 ? 'On Target' : 'Below Target',
            icon: Icons.account_balance_wallet,
            color: summary.overallFeeCollectionRate >= 85 ? AppTheme.successColor : AppTheme.warningColor,
            trend: Icon(
              summary.overallFeeCollectionRate >= 85 ? Icons.trending_up : Icons.trending_down,
              color: summary.overallFeeCollectionRate >= 85 ? AppTheme.successColor : AppTheme.errorColor,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: MetricCard(
            title: 'Exam Pass Rate',
            value: '${summary.overallExamPassRate.toStringAsFixed(1)}%',
            subtitle: summary.overallExamPassRate >= 70 ? 'On Target' : 'Below Target',
            icon: Icons.school,
            color: summary.overallExamPassRate >= 70 ? AppTheme.successColor : AppTheme.warningColor,
            trend: Icon(
              summary.overallExamPassRate >= 70 ? Icons.trending_up : Icons.trending_down,
              color: summary.overallExamPassRate >= 70 ? AppTheme.successColor : AppTheme.errorColor,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: MetricCard(
            title: 'Total Students',
            value: AppFormatters.formatNumber(summary.totalStudents),
            subtitle: '${summary.totalSchools} schools',
            icon: Icons.people,
            color: AppTheme.infoColor,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCardsSkeleton() {
    return Row(
      children: List.generate(4, (index) => Expanded(
        child: Padding(
          padding: EdgeInsets.only(right: index < 3 ? 12 : 0),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 24, width: 80, color: Colors.grey[300]),
                  const SizedBox(height: 12),
                  Container(height: 32, width: 120, color: Colors.grey[300]),
                  const SizedBox(height: 8),
                  Container(height: 16, width: 100, color: Colors.grey[300]),
                ],
              ),
            ),
          ),
        ),
      )),
    );
  }

  Widget _buildAttendanceTrendChart(DistrictRiskSummary summary) {
    // Generate sample trend data (in real app, this would come from historical data)
    final spots = List.generate(30, (i) {
      final base = summary.overallAttendanceRate;
      final variance = (i % 7 - 3) * 1.5;
      return FlSpot(i.toDouble(), (base + variance).clamp(70, 100));
    });

    return SectionCard(
      title: 'Attendance Trend (30 Days)',
      subtitle: 'Daily attendance rate across district',
      child: LineChartWidget(
        spots: spots,
        lineColor: AppTheme.primaryColor,
        gradientStart: AppTheme.primaryColor,
        gradientEnd: AppTheme.secondaryColor,
        minY: 70,
        maxY: 100,
        targetLine: 90,
        targetLabel: 'Target: 90%',
      ),
    );
  }

  Widget _buildRiskDistributionChart(DistrictRiskSummary summary) {
    final theme = Theme.of(context);

    final sections = <PieChartSectionData>[];
    final riskLevels = [RiskLevel.critical, RiskLevel.high, RiskLevel.medium, RiskLevel.low];

    for (final level in riskLevels) {
      final count = summary.schoolsByRiskLevel[level] ?? 0;
      if (count > 0) {
        sections.add(PieChartSectionData(
          color: level.color,
          value: count.toDouble(),
          title: '$count',
          radius: 50,
          titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
        ));
      }
    }

    if (sections.isEmpty) {
      sections.add(PieChartSectionData(
        color: theme.colorScheme.outlineVariant,
        value: 1,
        title: 'No Data',
        radius: 50,
        titleStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12),
      ));
    }

    return SectionCard(
      title: 'Schools by Risk Level',
      subtitle: 'Distribution across district',
      child: Column(
        children: [
          SizedBox(
            height: 180,
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Center(
                    child: PieChartWidget(sections: sections, radius: 80),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: riskLevels.map((level) {
                      final count = summary.schoolsByRiskLevel[level] ?? 0;
                      if (count == 0) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: level.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${level.displayName}: $count',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeeCollectionChart(DistrictRiskSummary summary) {
    final theme = Theme.of(context);

    // Generate sample monthly fee collection data
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
    final rates = List<double>.generate(6, (i) {
      final base = summary.overallFeeCollectionRate;
      final variance = (i - 2) * 3.0;
      return (base + variance).clamp(50.0, 100.0);
    });

    final barGroups = List.generate(months.length, (i) {
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: rates[i],
            color: rates[i] >= 85 ? AppTheme.successColor : AppTheme.warningColor,
            width: 16,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    });

    return SectionCard(
      title: 'Fee Collection by Month',
      subtitle: 'Monthly collection rates',
      child: BarChartWidget(
        barGroups: barGroups,
        xLabels: months,
        barColor: AppTheme.primaryColor,
        maxY: 100,
      ),
    );
  }

  Widget _buildAcademicPerformanceChart(DistrictRiskSummary summary) {
    final theme = Theme.of(context);

    // Grade distribution
    final sections = [
      PieChartSectionData(
        color: AppTheme.successColor,
        value: summary.overallExamPassRate * 0.7,
        title: '${(summary.overallExamPassRate * 0.7).toInt()}%',
        radius: 50,
        titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
      ),
      PieChartSectionData(
        color: AppTheme.warningColor,
        value: (100 - summary.overallExamPassRate) * 0.6,
        title: '${((100 - summary.overallExamPassRate) * 0.6).toInt()}%',
        radius: 50,
        titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
      ),
      PieChartSectionData(
        color: AppTheme.errorColor,
        value: (100 - summary.overallExamPassRate) * 0.4,
        title: '${((100 - summary.overallExamPassRate) * 0.4).toInt()}%',
        radius: 50,
        titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    ];

    return SectionCard(
      title: 'Exam Performance',
      subtitle: 'Pass / At Risk / Failing',
      child: Column(
        children: [
          SizedBox(
            height: 180,
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Center(
                    child: PieChartWidget(sections: sections, radius: 80),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _LegendItem(color: AppTheme.successColor, label: 'Passing', value: '${(summary.overallExamPassRate * 0.7).toInt()}%'),
                      _LegendItem(color: AppTheme.warningColor, label: 'At Risk', value: '${((100 - summary.overallExamPassRate) * 0.6).toInt()}%'),
                      _LegendItem(color: AppTheme.errorColor, label: 'Failing', value: '${((100 - summary.overallExamPassRate) * 0.4).toInt()}%'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveAlertsSection(AsyncValue<List<RiskAlert>> alertsAsync) {
    return alertsAsync.when(
      data: (alerts) {
        if (alerts.isEmpty) {
          return SectionCard(
            title: 'Active Alerts',
            subtitle: 'No active alerts',
            child: const EmptyState(
              icon: Icons.check_circle_outline,
              title: 'All Clear',
              message: 'No active risk alerts at this time',
            ),
          );
        }

        return SectionCard(
          title: 'Active Alerts',
          subtitle: '${alerts.length} alerts requiring attention',
          actions: [
            TextButton(
              onPressed: () => context.go('/risk'),
              child: const Text('View All'),
            ),
          ],
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: alerts.take(5).length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final alert = alerts[index];
              return ListTile(
                contentPadding: EdgeInsets.zero,
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
                onTap: () {
                  // Navigate to alert detail
                },
              );
            },
          ),
        );
      },
      loading: () => SectionCard(
        title: 'Active Alerts',
        child: const LoadingState(message: 'Loading alerts...'),
      ),
      error: (e, _) => SectionCard(
        title: 'Active Alerts',
        child: ErrorState(message: e.toString()),
      ),
    );
  }

  Widget _buildTopRiskSchools(List<SchoolRiskProfile> schools) {
    final theme = Theme.of(context);

    if (schools.isEmpty) {
      return SectionCard(
        title: 'Top Risk Schools',
        subtitle: 'Schools requiring attention',
        child: const EmptyState(
          icon: Icons.school_outlined,
          title: 'No Risk Schools',
          message: 'All schools are within acceptable risk thresholds',
        ),
      );
    }

    return SectionCard(
      title: 'Top Risk Schools',
      subtitle: 'Schools requiring attention',
      actions: [
        TextButton(
          onPressed: () => context.go('/schools'),
          child: const Text('View All'),
        ),
      ],
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: schools.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final school = schools[index];
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: school.overallRiskLevel.color.withOpacity(0.1),
              child: Icon(Icons.school, color: school.overallRiskLevel.color),
            ),
            title: Text(school.schoolName, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${school.totalStudents} students • ${school.activeAlerts.length} alerts'),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 4,
                  children: [
                    RiskLevelChip(level: school.overallRiskLevel, small: true),
                    ...school.categoryRisks.entries
                        .where((e) => e.value.priority >= RiskLevel.medium.priority)
                        .map((e) => Chip(
                              label: Text(e.key.displayName, style: const TextStyle(fontSize: 10)),
                              backgroundColor: e.value.color.withOpacity(0.1),
                              side: BorderSide(color: e.value.color.withOpacity(0.3)),
                              visualDensity: VisualDensity.compact,
                            )),
                  ],
                ),
              ],
            ),
            trailing: Text(
              '${school.compositeScore.toStringAsFixed(1)}%',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: school.overallRiskLevel.color,
              ),
            ),
            onTap: () => context.go('/schools/${school.schoolId}'),
          );
        },
      ),
    );
  }

  Widget _buildTopRiskSchoolsSkeleton() {
    return SectionCard(
      title: 'Top Risk Schools',
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 5,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, __) => ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(backgroundColor: Colors.grey[300]),
          title: Container(height: 16, width: 150, color: Colors.grey[300]),
          subtitle: Container(height: 12, width: 100, color: Colors.grey[300]),
        ),
      ),
    );
  }

  Widget _buildChartSkeleton() {
    return SectionCard(
      title: 'Chart',
      child: Card(
        child: SizedBox(height: 200, child: Center(child: LoadingState(message: ''))),
      ),
    );
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
    );
    if (picked != null) {
      setState(() => _dateRange = picked);
    }
  }

  Future<void> _handleLogout() async {
    await ref.read(authServiceProvider).signOut();
    if (mounted) {
      context.go('/login');
    }
  }
}

class _RiskSummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _RiskSummaryCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final String value;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}