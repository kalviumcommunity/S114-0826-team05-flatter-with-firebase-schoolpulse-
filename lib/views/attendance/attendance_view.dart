import 'package:cloud_firestore/cloud_firestore.dart';
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
      builder: (context) => _RecordAttendanceDialog(schoolId: widget.schoolId),
    );
  }

  void _exportAttendance() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Export feature coming soon')));
  }
}

class _RecordAttendanceDialog extends ConsumerStatefulWidget {
  final String schoolId;

  const _RecordAttendanceDialog({required this.schoolId});

  @override
  ConsumerState<_RecordAttendanceDialog> createState() => _RecordAttendanceDialogState();
}

class _RecordAttendanceDialogState extends ConsumerState<_RecordAttendanceDialog> {
  DateTime _selectedDate = DateTime.now();
  String? _selectedGrade;
  String? _selectedSection;
  String? _selectedPeriod;
  final Map<String, AttendanceStatus> _studentStatuses = {};
  bool _isLoading = false;
  bool _isSaving = false;
  List<StudentModel> _students = [];

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);
    try {
      final students = await ref.read(firestoreServiceProvider).getStudentsBySchool(widget.schoolId);
      if (mounted) {
        setState(() {
          _students = students;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading students: $e')));
      }
    }
  }

  List<StudentModel> get _filteredStudents {
    var filtered = _students.where((s) => s.status == StudentStatus.active).toList();
    if (_selectedGrade != null) {
      filtered = filtered.where((s) => s.gradeLevel == _selectedGrade).toList();
    }
    if (_selectedSection != null) {
      filtered = filtered.where((s) => s.section == _selectedSection).toList();
    }
    filtered.sort((a, b) => a.lastName.compareTo(b.lastName));
    return filtered;
  }

  Future<void> _saveAttendance() async {
    if (_studentStatuses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please set attendance for at least one student')));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final batchOps = <Map<String, dynamic>>[];

      for (final entry in _studentStatuses.entries) {
        final studentId = entry.key;
        final status = entry.value;
        final record = AttendanceRecord(
          id: '',
          districtId: _students.firstWhere((s) => s.id == studentId).districtId,
          schoolId: widget.schoolId,
          studentId: studentId,
          date: _selectedDate,
          status: status,
          period: _selectedPeriod,
          recordedBy: ref.read(currentUserProvider)?.uid,
          createdAt: DateTime.now(),
        );
        batchOps.add(record.toJson());
      }

      // Create records in batch
      final batch = FirebaseFirestore.instance.batch();
      final collectionRef = FirebaseFirestore.instance.collection('attendance');

      for (final data in batchOps) {
        final docRef = collectionRef.doc();
        batch.set(docRef, {...data, 'id': docRef.id});
      }

      await batch.commit();

      if (mounted) {
        Navigator.pop(context);
        ref.invalidate(attendanceBySchoolProvider(widget.schoolId));
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Attendance recorded successfully')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Record Attendance'),
      content: SizedBox(
        width: 600,
        height: 600,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Date Selection
                    ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: const Text('Date'),
                      subtitle: Text(AppFormatters.formatDate(_selectedDate)),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime.now().subtract(const Duration(days: 365)),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null && mounted) {
                            setState(() => _selectedDate = picked);
                          }
                        },
                      ),
                    ),

                    // Grade Filter
                    DropdownButtonFormField<String>(
                      value: _selectedGrade,
                      decoration: const InputDecoration(labelText: 'Grade', prefixIcon: Icon(Icons.grade)),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All Grades')),
                        ...AppConstants.gradeLevels.map((g) => DropdownMenuItem(value: g, child: Text('Grade $g'))),
                      ],
                      onChanged: (value) => setState(() => _selectedGrade = value),
                    ),

                    // Section Filter
                    DropdownButtonFormField<String>(
                      value: _selectedSection,
                      decoration: const InputDecoration(labelText: 'Section', prefixIcon: Icon(Icons.people)),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All Sections')),
                        ..._students.map((s) => s.section).toSet().map((s) => DropdownMenuItem(value: s, child: Text('Section $s'))),
                      ],
                      onChanged: (value) => setState(() => _selectedSection = value),
                    ),

                    // Period
                    DropdownButtonFormField<String>(
                      value: _selectedPeriod,
                      decoration: const InputDecoration(labelText: 'Period (Optional)', prefixIcon: Icon(Icons.access_time)),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('No Period')),
                        const DropdownMenuItem(value: 'Morning', child: Text('Morning')),
                        const DropdownMenuItem(value: 'Afternoon', child: Text('Afternoon')),
                        const DropdownMenuItem(value: 'Period 1', child: Text('Period 1')),
                        const DropdownMenuItem(value: 'Period 2', child: Text('Period 2')),
                        const DropdownMenuItem(value: 'Period 3', child: Text('Period 3')),
                        const DropdownMenuItem(value: 'Period 4', child: Text('Period 4')),
                        const DropdownMenuItem(value: 'Period 5', child: Text('Period 5')),
                        const DropdownMenuItem(value: 'Period 6', child: Text('Period 6')),
                      ],
                      onChanged: (value) => setState(() => _selectedPeriod = value),
                    ),

                    const SizedBox(height: 16),

                    // Student List
                    if (_filteredStudents.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('No students found for selected filters'),
                      )
                    else
                      Column(
                        children: _filteredStudents.map((student) {
                          final currentStatus = _studentStatuses[student.id] ?? AttendanceStatus.present;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  AvatarWidget(firstName: student.firstName, lastName: student.lastName, radius: 20),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('${student.firstName} ${student.lastName}', style: const TextStyle(fontWeight: FontWeight.w600)),
                                        Text('Grade ${student.gradeLevel}${student.section.isNotEmpty ? ' - Section ${student.section}' : ''} • ${student.studentNumber}',
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  SegmentedButton<AttendanceStatus>(
                                    segments: AttendanceStatus.values.map((status) {
                                      return ButtonSegment<AttendanceStatus>(
                                        value: status,
                                        label: Text(status.displayName),
                                        icon: Icon(_getStatusIcon(status), size: 16),
                                      );
                                    }).toList(),
                                    selected: {currentStatus},
                                    onSelectionChanged: (Set<AttendanceStatus> newSelection) {
                                      setState(() {
                                        _studentStatuses[student.id] = newSelection.first;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: _isSaving ? null : _saveAttendance,
          child: _isSaving
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Save Attendance'),
        ),
      ],
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