import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/models.dart';
import '../../providers/app_providers.dart';
import '../../utils/app_formatters.dart';
import '../../utils/app_theme.dart';
import '../../widgets/common_widgets.dart';

class RiskAlertsView extends ConsumerStatefulWidget {
  final String? schoolId;

  const RiskAlertsView({super.key, this.schoolId});

  @override
  ConsumerState<RiskAlertsView> createState() => _RiskAlertsViewState();
}

class _RiskAlertsViewState extends ConsumerState<RiskAlertsView> {
  RiskLevel? _filterLevel;
  RiskCategory? _filterCategory;
  bool _showResolved = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final districtId = ref.watch(currentDistrictIdProvider);
    final schoolId = widget.schoolId;

    final alertsAsync = schoolId != null
        ? ref.watch(activeAlertsBySchoolProvider(schoolId))
        : ref.watch(activeAlertsByDistrictProvider(districtId ?? ''));

    final riskSummaryAsync = schoolId != null
        ? ref.watch(schoolRiskProfileProvider(schoolId))
        : (districtId != null ? ref.watch(districtRiskSummaryProvider(districtId)) : null);

    return Scaffold(
      appBar: AppBar(
        title: Text(schoolId != null ? 'Risk Alerts' : 'District Risk Overview'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'refresh') _refreshAll();
              if (value == 'generate') _generateAlerts();
              if (value == 'resolved') setState(() => _showResolved = !_showResolved);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'refresh', child: Text('Refresh')),
              const PopupMenuItem(value: 'generate', child: Text('Generate Alerts')),
              PopupMenuItem(value: 'resolved', child: Text(_showResolved ? 'Hide Resolved' : 'Show Resolved')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Risk Summary Header
          if (riskSummaryAsync != null)
            riskSummaryAsync.when(
              data: (summary) {
                if (summary is SchoolRiskProfile) {
                  return _buildRiskSummaryHeader(summary);
                } else if (summary is DistrictRiskSummary) {
                  return _buildDistrictRiskSummaryHeader(summary);
                }
                return const SizedBox.shrink();
              },
              loading: () => _buildRiskSummaryHeaderSkeleton(),
              error: (_, _) => const SizedBox.shrink(),
            ),

          // Filter Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(bottom: BorderSide(color: theme.colorScheme.outlineVariant)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<RiskLevel>(
                    value: _filterLevel,
                    decoration: const InputDecoration(labelText: 'Risk Level', border: OutlineInputBorder(), isDense: true),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All Levels')),
                      ...RiskLevel.values.map((l) => DropdownMenuItem(
                            value: l,
                            child: Row(
                              children: [
                                Container(width: 12, height: 12, decoration: BoxDecoration(color: l.color, shape: BoxShape.circle)),
                                const SizedBox(width: 8),
                                Text(l.displayName),
                              ],
                            ),
                          )),
                    ],
                    onChanged: (value) => setState(() => _filterLevel = value),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<RiskCategory>(
                    value: _filterCategory,
                    decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder(), isDense: true),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All Categories')),
                      ...RiskCategory.values.map((c) => DropdownMenuItem(
                            value: c,
                            child: Row(
                              children: [
                                Icon(c.icon, size: 18),
                                const SizedBox(width: 8),
                                Text(c.displayName),
                              ],
                            ),
                          )),
                    ],
                    onChanged: (value) => setState(() => _filterCategory = value),
                  ),
                ),
              ],
            ),
          ),

          // Alerts List
          Expanded(
            child: alertsAsync.when(
              data: (alerts) {
                var filteredAlerts = alerts.where((alert) {
                  final matchesLevel = _filterLevel == null || alert.level == _filterLevel;
                  final matchesCategory = _filterCategory == null || alert.category == _filterCategory;
                  return matchesLevel && matchesCategory;
                }).toList();

                // Sort by level priority and date
                filteredAlerts.sort((a, b) {
                  final levelCompare = b.level.priority.compareTo(a.level.priority);
                  if (levelCompare != 0) return levelCompare;
                  return b.triggeredAt.compareTo(a.triggeredAt);
                });

                if (filteredAlerts.isEmpty) {
                  return EmptyState(
                    icon: _showResolved ? Icons.check_circle_outline : Icons.filter_list_off,
                    title: _showResolved ? 'No Resolved Alerts' : 'No Active Alerts',
                    message: _showResolved
                        ? 'All alerts are currently active'
                        : 'All systems operating normally - no active risk alerts',
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredAlerts.length,
                  itemBuilder: (context, index) {
                    final alert = filteredAlerts[index];
                    return _AlertCard(
                      alert: alert,
                      onResolve: () => _resolveAlert(alert),
                      onViewDetails: () => _showAlertDetails(alert),
                    );
                  },
                );
              },
              loading: () => const LoadingState(message: 'Loading alerts...'),
              error: (e, _) => ErrorState(message: e.toString()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskSummaryHeader(SchoolRiskProfile profile) {
    return Container(
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
                        fontSize: 18,
                        color: profile.overallRiskLevel.color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    _RiskMetricChip(label: 'Composite Score', value: '${profile.compositeScore.toStringAsFixed(1)}%', color: profile.overallRiskLevel.color),
                    _RiskMetricChip(label: 'Attendance', value: '${profile.attendanceRate.toStringAsFixed(1)}%', color: profile.categoryRisks[RiskCategory.attendance]!.color),
                    _RiskMetricChip(label: 'Fees', value: '${profile.feeCollectionRate.toStringAsFixed(1)}%', color: profile.categoryRisks[RiskCategory.fees]!.color),
                    _RiskMetricChip(label: 'Academic', value: '${profile.examPassRate.toStringAsFixed(1)}%', color: profile.categoryRisks[RiskCategory.academic]!.color),
                    _RiskMetricChip(label: 'Enrollment', value: '${profile.enrollmentTrend >= 0 ? '+' : ''}${profile.enrollmentTrend.toStringAsFixed(1)}%', color: profile.categoryRisks[RiskCategory.enrollment]!.color),
                  ],
                ),
              ],
            ),
          ),
          RiskIndicator(level: profile.overallRiskLevel, size: 56, showLabel: true),
        ],
      ),
    );
  }

  Widget _buildRiskSummaryHeaderSkeleton() {
    return Container(
      height: 120,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey[300]!))),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 24, width: 200, color: Colors.grey[300]),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 16,
                  children: List.generate(5, (i) => Container(height: 32, width: 100, color: Colors.grey[300])),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(width: 80, height: 80, decoration: BoxDecoration(color: Colors.grey[300], shape: BoxShape.circle)),
        ],
      ),
    );
  }

  Widget _buildDistrictRiskSummaryHeader(DistrictRiskSummary summary) {
    // For district view, we'd show different metrics
    return const SizedBox.shrink(); // Simplified for now
  }

  void _refreshAll() {
    final districtId = ref.read(currentDistrictIdProvider);
    final schoolId = widget.schoolId;
    if (schoolId != null) {
      ref.invalidate(activeAlertsBySchoolProvider(schoolId));
      ref.invalidate(schoolRiskProfileProvider(schoolId));
    } else if (districtId != null) {
      ref.invalidate(activeAlertsByDistrictProvider(districtId));
      ref.invalidate(districtRiskSummaryProvider(districtId));
    }
  }

  void _generateAlerts() async {
    final schoolId = widget.schoolId;
    if (schoolId != null) {
      try {
        await ref.read(riskCalculationServiceProvider).generateAlertsForSchool(schoolId);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Alerts generated')));
        _refreshAll();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
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

  void _showAlertDetails(RiskAlert alert) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(alert.category.icon, color: alert.level.color),
            const SizedBox(width: 8),
            Expanded(child: Text(alert.title)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RiskIndicator(level: alert.level, size: 32, showLabel: true),
              const SizedBox(height: 16),
              Text(alert.description, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 16),
              Text('Category: ${alert.category.displayName}', style: const TextStyle(fontWeight: FontWeight.w500)),
              Text('Triggered: ${AppFormatters.formatDateTime(alert.triggeredAt)}'),
              if (alert.acknowledgedAt != null) Text('Acknowledged: ${AppFormatters.formatDateTime(alert.acknowledgedAt!)}'),
              if (alert.isResolved) ...[
                Text('Resolved: ${AppFormatters.formatDateTime(alert.resolvedAt!)}'),
                Text('Resolved by: ${alert.resolvedBy}'),
                if (alert.resolutionNotes != null) Text('Resolution: ${alert.resolutionNotes}'),
              ],
              const SizedBox(height: 16),
              Text('Metrics:', style: const TextStyle(fontWeight: FontWeight.w600)),
              ...alert.metrics.entries.map((e) => Text('  ${e.key}: ${e.value}')),
              const SizedBox(height: 16),
              Text('Affected Entities:', style: const TextStyle(fontWeight: FontWeight.w600)),
              ...alert.affectedEntities.map((e) => Text('  • $e')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          if (!alert.isResolved)
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                _resolveAlert(alert);
              },
              child: const Text('Resolve'),
            ),
        ],
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final RiskAlert alert;
  final VoidCallback onResolve;
  final VoidCallback onViewDetails;

  const _AlertCard({
    required this.alert,
    required this.onResolve,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: alert.level.color.withOpacity(0.3)),
      ),
      child: ExpansionTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: alert.level.color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(alert.category.icon, color: alert.level.color, size: 24),
        ),
        title: Text(alert.title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(alert.description),
            const SizedBox(height: 4),
            Row(
              children: [
                RiskLevelChip(level: alert.level, small: true),
                const SizedBox(width: 8),
                Chip(
                  label: Text(alert.category.displayName, style: const TextStyle(fontSize: 11)),
                  avatar: Icon(alert.category.icon, size: 14),
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: 8),
                Text(
                  AppFormatters.formatRelativeTime(alert.triggeredAt),
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!alert.isResolved)
              IconButton(
                icon: const Icon(Icons.check_circle_outline),
                color: AppTheme.successColor,
                onPressed: onResolve,
                tooltip: 'Resolve',
              ),
            IconButton(
              icon: const Icon(Icons.visibility_outlined),
              onPressed: onViewDetails,
              tooltip: 'View Details',
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (alert.metrics.isNotEmpty) ...[
                  Text('Metrics', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: alert.metrics.entries.map((e) => Chip(
                          label: Text('${e.key}: ${e.value}'),
                          visualDensity: VisualDensity.compact,
                        )).toList(),
                  ),
                  const SizedBox(height: 16),
                ],
                if (alert.affectedEntities.isNotEmpty) ...[
                  Text('Affected Entities', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: alert.affectedEntities.map((e) => Chip(
                          label: Text(e),
                          visualDensity: VisualDensity.compact,
                        )).toList(),
                  ),
                  const SizedBox(height: 16),
                ],
                if (alert.isResolved && alert.resolutionNotes != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.successColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: AppTheme.successColor),
                        const SizedBox(width: 8),
                        Expanded(child: Text('Resolution: ${alert.resolutionNotes}', style: TextStyle(color: AppTheme.successColor))),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RiskMetricChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _RiskMetricChip({required this.label, required this.value, required this.color});

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
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 12)),
          Text(label, style: TextStyle(color: color, fontSize: 10)),
        ],
      ),
    );
  }
}