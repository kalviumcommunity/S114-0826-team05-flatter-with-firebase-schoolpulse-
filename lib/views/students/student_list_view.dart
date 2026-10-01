import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/models.dart';
import '../../providers/app_providers.dart';
import '../../utils/app_formatters.dart';
import '../../utils/app_theme.dart';
import '../../widgets/common_widgets.dart';

class StudentListView extends ConsumerStatefulWidget {
  final String? schoolId;

  const StudentListView({super.key, this.schoolId});

  @override
  ConsumerState<StudentListView> createState() => _StudentListViewState();
}

class _StudentListViewState extends ConsumerState<StudentListView> {
  String _searchQuery = '';
  String? _filterGrade;
  StudentStatus? _filterStatus;
  RiskLevel? _filterRisk;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final studentsAsync = widget.schoolId != null
        ? ref.watch(studentsBySchoolProvider(widget.schoolId!))
        : ref.watch(studentsByDistrictProvider(ref.watch(currentDistrictIdProvider) ?? ''));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.schoolId != null ? 'Students' : 'All Students'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddStudentDialog,
            tooltip: 'Add Student',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'refresh') {
                ref.invalidate(studentsBySchoolProvider(widget.schoolId!));
                ref.invalidate(studentsByDistrictProvider(ref.watch(currentDistrictIdProvider) ?? ''));
              }
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
          // Search and Filter Bar
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
                    hintText: 'Search students...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => setState(() => _searchQuery = ''),
                          )
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
                      child: DropdownButtonFormField<String>(
                        value: _filterGrade,
                        decoration: const InputDecoration(
                          labelText: 'Grade',
                          prefixIcon: Icon(Icons.grade),
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('All Grades')),
                          ...AppConstants.gradeLevels.map((g) => DropdownMenuItem(value: g, child: Text('Grade $g'))),
                        ],
                        onChanged: (value) => setState(() => _filterGrade = value),
                      ),
                    ),
                    Expanded(
                      child: DropdownButtonFormField<StudentStatus>(
                        value: _filterStatus,
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('All Status')),
                          ...StudentStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(s.displayName))),
                        ],
                        onChanged: (value) => setState(() => _filterStatus = value),
                      ),
                    ),
                    Expanded(
                      child: DropdownButtonFormField<RiskLevel>(
                        value: _filterRisk,
                        decoration: const InputDecoration(
                          labelText: 'Risk Level',
                          prefixIcon: Icon(Icons.warning_amber),
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('All Risk Levels')),
                          ...RiskLevel.values.map((r) => DropdownMenuItem(
                                value: r,
                                child: Row(
                                  children: [
                                    Container(width: 12, height: 12, decoration: BoxDecoration(color: r.color, shape: BoxShape.circle)),
                                    const SizedBox(width: 8),
                                    Text(r.displayName),
                                  ],
                                ),
                              )),
                        ],
                        onChanged: (value) => setState(() => _filterRisk = value),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Students List
          Expanded(
            child: studentsAsync.when(
              data: (students) {
                final filteredStudents = students.where((student) {
                  final matchesSearch = _searchQuery.isEmpty ||
                      student.firstName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                      student.lastName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                      student.studentNumber.contains(_searchQuery);
                  final matchesGrade = _filterGrade == null || student.gradeLevel == _filterGrade;
                  final matchesStatus = _filterStatus == null || student.status == _filterStatus;
                  final matchesRisk = _filterRisk == null || student.riskLevel == _filterRisk;
                  return matchesSearch && matchesGrade && matchesStatus && matchesRisk;
                }).toList();

                if (filteredStudents.isEmpty) {
                  return const EmptyState(
                    icon: Icons.people_outline,
                    title: 'No Students Found',
                    message: 'Try adjusting your search or filters',
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredStudents.length,
                  itemBuilder: (context, index) {
                    final student = filteredStudents[index];
                    return _StudentListTile(
                      student: student,
                      onTap: () {
                        ref.read(selectedStudentIdProvider.notifier).state = student.id;
                        context.go('/students/${student.id}');
                      },
                    );
                  },
                );
              },
              loading: () => const LoadingState(message: 'Loading students...'),
              error: (e, _) => ErrorState(message: e.toString()),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddStudentDialog() {
    final firstNameController = TextEditingController();
    final lastNameController = TextEditingController();
    final studentNumberController = TextEditingController();
    final gradeController = TextEditingController();
    final sectionController = TextEditingController();
    final parentPhoneController = TextEditingController();
    final parentEmailController = TextEditingController();
    String selectedGender = 'male';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Student'),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(controller: firstNameController, decoration: const InputDecoration(labelText: 'First Name *')),
                TextFormField(controller: lastNameController, decoration: const InputDecoration(labelText: 'Last Name *')),
                TextFormField(controller: studentNumberController, decoration: const InputDecoration(labelText: 'Student Number *')),
                DropdownButtonFormField<String>(
                  value: gradeController.text.isEmpty ? '1' : gradeController.text,
                  decoration: const InputDecoration(labelText: 'Grade Level *'),
                  items: AppConstants.gradeLevels.map((g) => DropdownMenuItem(value: g, child: Text('Grade $g'))).toList(),
                  onChanged: (v) => gradeController.text = v!,
                ),
                TextFormField(controller: sectionController, decoration: const InputDecoration(labelText: 'Section (e.g., A, B, C) *')),
                DropdownButtonFormField<String>(
                  value: selectedGender,
                  decoration: const InputDecoration(labelText: 'Gender *'),
                  items: Gender.values.map((g) => DropdownMenuItem(value: g.value, child: Text(g.value.capitalize()))).toList(),
                  onChanged: (v) => selectedGender = v!,
                ),
                TextFormField(controller: parentPhoneController, decoration: const InputDecoration(labelText: 'Parent Phone *'), keyboardType: TextInputType.phone),
                TextFormField(controller: parentEmailController, decoration: const InputDecoration(labelText: 'Parent Email *'), keyboardType: TextInputType.emailAddress),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (firstNameController.text.isEmpty || lastNameController.text.isEmpty ||
                  studentNumberController.text.isEmpty || gradeController.text.isEmpty ||
                  sectionController.text.isEmpty || parentPhoneController.text.isEmpty ||
                  parentEmailController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All fields are required')));
                return;
              }
              try {
                final student = StudentModel(
                  id: '',
                  districtId: ref.read(currentDistrictIdProvider)!,
                  schoolId: widget.schoolId!,
                  studentNumber: studentNumberController.text,
                  firstName: firstNameController.text,
                  lastName: lastNameController.text,
                  gradeLevel: gradeController.text,
                  section: sectionController.text,
                  dateOfBirth: DateTime.now().subtract(const Duration(days: 365 * 10)), // Placeholder
                  gender: Gender.values.firstWhere((g) => g.value == selectedGender),
                  parentPhone: parentPhoneController.text,
                  parentEmail: parentEmailController.text,
                  status: StudentStatus.active,
                  enrolledAt: DateTime.now(),
                  createdAt: DateTime.now(),
                );
                await ref.read(firestoreServiceProvider).createStudent(student);
                Navigator.pop(context);
                ref.invalidate(studentsBySchoolProvider(widget.schoolId!));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Student created')));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

class _StudentListTile extends StatelessWidget {
  final StudentModel student;
  final VoidCallback onTap;

  const _StudentListTile({required this.student, required this.onTap});

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

extension StringExtension on String {
  String capitalize() => '${this[0].toUpperCase()}${substring(1)}';
}