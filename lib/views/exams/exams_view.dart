import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/models.dart';
import '../../providers/app_providers.dart';
import '../../utils/app_formatters.dart';
import '../../utils/app_theme.dart';
import '../../widgets/common_widgets.dart';

class ExamsView extends ConsumerStatefulWidget {
  final String schoolId;

  const ExamsView({super.key, required this.schoolId});

  @override
  ConsumerState<ExamsView> createState() => _ExamsViewState();
}

class _ExamsViewState extends ConsumerState<ExamsView> {
  String _searchQuery = '';
  ExamStatus? _filterStatus;
  ExamType? _filterType;
  String? _filterSubject;
  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now().add(const Duration(days: 60)),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final examsAsync = ref.watch(examsBySchoolProvider(widget.schoolId));
    final upcomingAsync = ref.watch(upcomingExamsProvider(UpcomingExamsKey(widget.schoolId, 30)));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Examinations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddExamDialog,
            tooltip: 'Schedule Exam',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'refresh') ref.invalidate(examsBySchoolProvider(widget.schoolId));
              if (value == 'export') _exportExams();
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
          // Upcoming Exams Banner
          upcomingAsync.when(
            data: (upcoming) {
              if (upcoming.isEmpty) return const SizedBox.shrink();
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  border: Border(bottom: BorderSide(color: theme.colorScheme.outlineVariant)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.event, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Text('Upcoming Exams (Next 30 Days)', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: theme.colorScheme.primary)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 80,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: upcoming.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final exam = upcoming[index];
                          return _UpcomingExamCard(exam: exam);
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),

          // Filter Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(bottom: BorderSide(color: theme.colorScheme.outlineVariant)),
            ),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search exams...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() => _searchQuery = ''))
                        : null,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<ExamStatus>(
                        value: _filterStatus,
                        decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder(), isDense: true),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('All Status')),
                          ...ExamStatus.values.map((s) => DropdownMenuItem(
                                value: s,
                                child: Row(
                                  children: [
                                    Container(width: 12, height: 12, decoration: BoxDecoration(color: s.color, shape: BoxShape.circle)),
                                    const SizedBox(width: 8),
                                    Text(s.displayName),
                                  ],
                                ),
                              )),
                        ],
                        onChanged: (value) => setState(() => _filterStatus = value),
                      ),
                    ),
                    Expanded(
                      child: DropdownButtonFormField<ExamType>(
                        value: _filterType,
                        decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder(), isDense: true),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('All Types')),
                          ...ExamType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.displayName))),
                        ],
                        onChanged: (value) => setState(() => _filterType = value),
                      ),
                    ),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _filterSubject,
                        decoration: const InputDecoration(labelText: 'Subject', border: OutlineInputBorder(), isDense: true),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('All Subjects')),
                          // Subjects would be populated from data
                        ],
                        onChanged: (value) => setState(() => _filterSubject = value),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Exams List
          Expanded(
            child: examsAsync.when(
              data: (exams) {
                var filteredExams = exams.where((exam) {
                  final matchesSearch = _searchQuery.isEmpty ||
                      exam.examName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                      exam.subject.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                      exam.studentId.contains(_searchQuery);
                  final matchesStatus = _filterStatus == null || exam.status == _filterStatus;
                  final matchesType = _filterType == null || exam.type == _filterType;
                  return matchesSearch && matchesStatus && matchesType;
                }).toList();

                // Sort by date (upcoming first)
                filteredExams.sort((a, b) => a.examDate.compareTo(b.examDate));

                if (filteredExams.isEmpty) {
                  return const EmptyState(
                    icon: Icons.school_outlined,
                    title: 'No Exams Found',
                    message: 'No exams match your current filters',
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredExams.length,
                  itemBuilder: (context, index) {
                    final exam = filteredExams[index];
                    return _ExamRecordTile(exam: exam);
                  },
                );
              },
              loading: () => const LoadingState(message: 'Loading exams...'),
              error: (e, _) => ErrorState(message: e.toString()),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddExamDialog() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add exam feature coming soon')));
  }

  void _exportExams() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Export feature coming soon')));
  }
}

class _UpcomingExamCard extends StatelessWidget {
  final ExamRecord exam;

  const _UpcomingExamCard({required this.exam});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final daysUntil = exam.examDate.difference(DateTime.now()).inDays;

    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: exam.status.color.withOpacity(0.3)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: exam.status.color.withOpacity(0.1),
                child: Icon(Icons.quiz, color: exam.status.color, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  exam.examName,
                  style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('${exam.subject} • ${exam.type.displayName}', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 12, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(AppFormatters.formatShortDate(exam.examDate), style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.schedule, size: 12, color: daysUntil <= 3 ? AppTheme.errorColor : AppTheme.warningColor),
              const SizedBox(width: 4),
              Text(
                '$daysUntil days',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: daysUntil <= 3 ? AppTheme.errorColor : AppTheme.warningColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExamRecordTile extends StatelessWidget {
  final ExamRecord exam;

  const _ExamRecordTile({required this.exam});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final daysUntil = exam.examDate.difference(DateTime.now()).inDays;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _showExamDetail(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: exam.status.color.withOpacity(0.1),
                child: Icon(Icons.quiz, color: exam.status.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(exam.examName, style: const TextStyle(fontWeight: FontWeight.w600)),
                        ),
                        StatusChip(label: exam.status.displayName, color: exam.status.color, small: true),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('${exam.subject} • ${exam.type.displayName} • Student ${exam.studentId}', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 12, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(AppFormatters.formatDate(exam.examDate), style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                        const SizedBox(width: 16),
                        if (daysUntil >= 0)
                          Row(
                            children: [
                              Icon(Icons.schedule, size: 12, color: daysUntil <= 3 ? AppTheme.errorColor : AppTheme.warningColor),
                              const SizedBox(width: 4),
                              Text(
                                '$daysUntil days',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: daysUntil <= 3 ? AppTheme.errorColor : AppTheme.warningColor,
                                ),
                              ),
                            ],
                          )
                        else
                          Text('Completed', style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.successColor)),
                      ],
                    ),
                  ],
                ),
              ),
              if (exam.obtainedScore != null) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${exam.percentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: exam.percentage >= 60 ? AppTheme.successColor : AppTheme.errorColor,
                      ),
                    ),
                    Text('${exam.obtainedScore!.toStringAsFixed(0)}/${exam.maxScore.toStringAsFixed(0)}', style: theme.textTheme.bodySmall),
                    if (exam.grade != null)
                      Text('Grade: ${exam.grade}', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showExamDetail(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(exam.examName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Subject: ${exam.subject}'),
            Text('Type: ${exam.type.displayName}'),
            Text('Date: ${AppFormatters.formatDate(exam.examDate)}'),
            Text('Status: ${exam.status.displayName}'),
            if (exam.obtainedScore != null) ...[
              Text('Score: ${exam.obtainedScore!.toStringAsFixed(0)}/${exam.maxScore.toStringAsFixed(0)}'),
              Text('Percentage: ${exam.percentage.toStringAsFixed(1)}%'),
              if (exam.grade != null) Text('Grade: ${exam.grade}'),
            ],
            if (exam.evaluatedBy != null) Text('Evaluated by: ${exam.evaluatedBy}'),
            if (exam.evaluatedAt != null) Text('Evaluated at: ${AppFormatters.formatDateTime(exam.evaluatedAt!)}'),
            if (exam.notes != null) Text('Notes: ${exam.notes}'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }
}