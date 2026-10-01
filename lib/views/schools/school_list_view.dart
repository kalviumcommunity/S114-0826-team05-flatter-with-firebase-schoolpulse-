import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/models.dart';
import '../../providers/app_providers.dart';
import '../../services/risk_calculation_service.dart';
import '../../utils/app_formatters.dart';
import '../../utils/app_theme.dart';
import '../../widgets/common_widgets.dart';

class SchoolListView extends ConsumerStatefulWidget {
  const SchoolListView({super.key});

  @override
  ConsumerState<SchoolListView> createState() => _SchoolListViewState();
}

class _SchoolListViewState extends ConsumerState<SchoolListView> {
  String _searchQuery = '';
  SchoolType? _filterType;
  RiskLevel? _filterRisk;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final districtId = ref.watch(currentDistrictIdProvider);
    final schoolsAsync = ref.watch(schoolsByDistrictProvider(districtId ?? ''));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Schools'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddSchoolDialog,
            tooltip: 'Add School',
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
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
                    hintText: 'Search schools...',
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
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<SchoolType>(
                        value: _filterType,
                        decoration: const InputDecoration(
                          labelText: 'Type',
                          prefixIcon: Icon(Icons.category),
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('All Types')),
                          ...SchoolType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.displayName))),
                        ],
                        onChanged: (value) => setState(() => _filterType = value),
                      ),
                    ),
                    const SizedBox(width: 12),
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

          // Schools List
          Expanded(
            child: schoolsAsync.when(
              data: (schools) {
                final filteredSchools = schools.where((school) {
                  final matchesSearch = _searchQuery.isEmpty ||
                      school.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                      school.code.toLowerCase().contains(_searchQuery.toLowerCase());
                  final matchesType = _filterType == null || school.type == _filterType;
                  return matchesSearch && matchesType;
                }).toList();

                if (filteredSchools.isEmpty) {
                  return const EmptyState(
                    icon: Icons.school_outlined,
                    title: 'No Schools Found',
                    message: 'Try adjusting your search or filters',
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredSchools.length,
                  itemBuilder: (context, index) {
                    final school = filteredSchools[index];
                    return _SchoolListTile(
                      school: school,
                      onTap: () => context.go('/schools/${school.id}'),
                    );
                  },
                );
              },
              loading: () => const LoadingState(message: 'Loading schools...'),
              error: (e, _) => ErrorState(message: e.toString(), onRetry: () => ref.invalidate(schoolsByDistrictProvider(districtId ?? ''))),
            ),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(String value) {
    if (value == 'refresh') {
      ref.invalidate(schoolsByDistrictProvider(ref.watch(currentDistrictIdProvider) ?? ''));
    }
  }

  void _showAddSchoolDialog() {
    final nameController = TextEditingController();
    final codeController = TextEditingController();
    final addressController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final principalNameController = TextEditingController();
    final principalPhoneController = TextEditingController();
    final principalEmailController = TextEditingController();
    SchoolType selectedType = SchoolType.elementary;
    int capacity = 500;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New School'),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(controller: nameController, decoration: const InputDecoration(labelText: 'School Name *')),
                TextFormField(controller: codeController, decoration: const InputDecoration(labelText: 'School Code *')),
                DropdownButtonFormField<SchoolType>(
                  value: selectedType,
                  decoration: const InputDecoration(labelText: 'Type *'),
                  items: SchoolType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.displayName))).toList(),
                  onChanged: (v) => selectedType = v!,
                ),
                TextFormField(controller: addressController, decoration: const InputDecoration(labelText: 'Address')),
                TextFormField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone')),
                TextFormField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
                TextFormField(controller: principalNameController, decoration: const InputDecoration(labelText: 'Principal Name')),
                TextFormField(controller: principalPhoneController, decoration: const InputDecoration(labelText: 'Principal Phone')),
                TextFormField(controller: principalEmailController, decoration: const InputDecoration(labelText: 'Principal Email')),
                TextFormField(
                  controller: TextEditingController(text: capacity.toString()),
                  decoration: const InputDecoration(labelText: 'Capacity'),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => capacity = int.tryParse(v) ?? 500,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (nameController.text.isEmpty || codeController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name and Code are required')));
                return;
              }
              try {
                final school = SchoolModel(
                  id: '',
                  districtId: ref.read(currentDistrictIdProvider)!,
                  name: nameController.text,
                  code: codeController.text,
                  type: selectedType,
                  address: addressController.text,
                  phone: phoneController.text,
                  email: emailController.text,
                  principalName: principalNameController.text,
                  principalPhone: principalPhoneController.text,
                  principalEmail: principalEmailController.text,
                  totalCapacity: capacity,
                  currentEnrollment: 0,
                  isActive: true,
                  createdAt: DateTime.now(),
                );
                await ref.read(firestoreServiceProvider).createSchool(school);
                Navigator.pop(context);
                ref.invalidate(schoolsByDistrictProvider(ref.read(currentDistrictIdProvider)!));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('School created')));
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

class _SchoolListTile extends ConsumerWidget {
  final SchoolModel school;
  final VoidCallback onTap;

  const _SchoolListTile({required this.school, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: _getTypeColor(school.type).withOpacity(0.1),
                child: Icon(_getTypeIcon(school.type), color: _getTypeColor(school.type)),
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
                            school.name,
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            school.code,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${school.type.displayName} • ${school.address}',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.people_outline, size: 14, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          '${school.currentEnrollment} / ${school.totalCapacity} (${school.utilizationRate.toStringAsFixed(0)}%)',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.phone_outlined, size: 14, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(school.phone, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
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

  Color _getTypeColor(SchoolType type) {
    switch (type) {
      case SchoolType.elementary:
        return AppTheme.successColor;
      case SchoolType.middle:
        return AppTheme.infoColor;
      case SchoolType.high:
        return AppTheme.primaryColor;
      case SchoolType.k12:
        return AppTheme.secondaryColor;
      case SchoolType.alternative:
        return AppTheme.warningColor;
      case SchoolType.charter:
        return AppTheme.accentColor;
    }
  }

  IconData _getTypeIcon(SchoolType type) {
    switch (type) {
      case SchoolType.elementary:
        return Icons.child_care;
      case SchoolType.middle:
        return Icons.school;
      case SchoolType.high:
        return Icons.menu_book;
      case SchoolType.k12:
        return Icons.school;
      case SchoolType.alternative:
        return Icons.alternate_email;
      case SchoolType.charter:
        return Icons.business;
    }
  }
}