import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/models.dart';
import '../../providers/app_providers.dart';
import '../../utils/app_formatters.dart';
import '../../utils/app_theme.dart';
import '../../widgets/common_widgets.dart';

class AttendanceView extends ConsumerStatefulWidget {
  final String schoolId;

  const AttendanceView({super.key, required this.schoolId});

  @override
  ConsumerState<AttendanceView> createState() => _AttendanceViewState();
}

class _AttendanceViewState extends ConsumerState<AttendanceView> {
  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );
  String _searchQuery = '';
  AttendanceStatus? _filterStatus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final attendanceAsync = ref.watch(attendanceBySchoolProvider(widget.schoolId));
    final studentsAsync = ref.watch(studentsBySchoolProvider(widget.schoolId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _selectDateRange,
            tooltip: 'Date Range',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showRecordAttendanceDialog,
            tooltip: 'Record Attendance',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'refresh') ref.invalidate(attendanceBySchoolProvider(widget.schoolId));
              if (value == 'export') _exportAttendance();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'refresh', child: Text('Refresh')),
              const PopupMenuItem(value: 'export', child: Text('Export')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(bottom: BorderSide(color: theme.colorScheme.outlineVariant)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search students...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() => _searchQuery = ''))
                              : null,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                        ),
                        onChanged: (value) => setState(() => _searchQuery = value),
                      ),
                    ),
                    const SizedBox(width: 12),
                    DropdownButtonFormField<AttendanceStatus>(
                      value: _filterStatus,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All Status')),
                        ...AttendanceStatus.values.map((s) => DropdownMenuItem(value: s, child: Row(
                          children: [
                            Container(width: 12, height: 12, decoration: BoxDecoration(color: s.color, shape: BoxShape.circle)),
                            const SizedBox(width: 8),
                            Text(s.displayName),
                          ],
                        ))),
                      ],
                      onChanged: (value) => setState(() => _filterStatus = value),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: _selectDateRange,
                      icon: const Icon(Icons.date_range, size: 18),
                      label: Text('${AppFormatters.formatShortDate(_dateRange.start)} - ${AppFormatters.formatShortDate(_dateRange.end)}'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Attendance List
          Expanded(
            child: attendanceAsync.when(
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
                    var dayRecords = byDate[date]!;

                    // Apply filters
                    if (_searchQuery.isNotEmpty) {
                      dayRecords = dayRecords.where((r) =>
                          r.studentId.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
                    }
                    if (_filterStatus != null) {
                      dayRecords = dayRecords.where((r) => r.status == _filterStatus).toList();
                    }

                    if (dayRecords.isEmpty) return const SizedBox.shrink();

                    final present = dayRecords.where((r) => r.status == AttendanceStatus.present).length;
                    final absent = dayRecords.where((r) => r.status == AttendanceStatus.absent).length;
                    final late = dayRecords.where((r) => r.status == AttendanceStatus.late).length;
                    final excused = dayRecords.where((r) => r.status == AttendanceStatus.excused).length;
                    final total = dayRecords.length;
                    final rate = total > 0 ? (present / total * 100) : 0;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          radius: 20,
                          backgroundColor: rate >= 90 ? AppTheme.successColor.withOpacity(0.1) : rate >= 75 ? AppTheme.warningColor.withOpacity(0.1) : AppTheme.errorColor.withOpacity(0.1),
                          child: Text(
                            '${rate.toInt()}%',
                            style: TextStyle(
                              color: rate >= 90 ? AppTheme.successColor : rate >= 75 ? AppTheme.warningColor : AppTheme.errorColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        title: Text(AppFormatters.formatDate(date), style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('${present}P • ${absent}A • ${late}L • ${excused}E • $total Total'),
                        trailing: Text('${rate.toStringAsFixed(1)}%', style: TextStyle(fontWeight: FontWeight.bold, color: rate >= 90 ? AppTheme.successColor : rate >= 75 ? AppTheme.warningColor : AppTheme.errorColor)),
                        children: dayRecords.map((record) => _AttendanceRecordTile(record: record)).toList(),
                      ),
                    );
                  },
                );
              },
              loading: () => const LoadingState(message: 'Loading attendance...'),
              error: (e, _) => ErrorState(message: e.toString()),
            ),
          ),
        ],
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
      // Note: In a real app, you'd pass this to the provider
    }
  }

  void _showRecordAttendanceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Record Attendance'),
        content: const Text('Attendance recording feature - bulk entry by class/section'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Open Recorder')),
        ],
      ),
    );
  }

  void _exportAttendance() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Export feature coming soon')));
  }
}

class _AttendanceRecordTile extends StatelessWidget {
  final AttendanceRecord record;

  const _AttendanceRecordTile({required this.record});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        radius: 16,
        backgroundColor: record.status.color.withOpacity(0.1),
        child: Icon(_getStatusIcon(record.status), color: record.status.color, size: 16),
      ),
      title: Text('Student ${record.studentId}', style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text('${record.status.displayName}${record.period != null ? ' • ${record.period}' : ''}${record.subject != null ? ' • ${record.subject}' : ''}'),
      trailing: StatusChip(label: record.status.displayName, color: record.status.color, small: true),
    );
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