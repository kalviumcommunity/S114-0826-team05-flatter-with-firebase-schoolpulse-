import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/models.dart';
import '../../providers/app_providers.dart';
import '../../utils/app_formatters.dart';
import '../../utils/app_theme.dart';
import '../../widgets/common_widgets.dart';

class FeesView extends ConsumerStatefulWidget {
  final String schoolId;

  const FeesView({super.key, required this.schoolId});

  @override
  ConsumerState<FeesView> createState() => _FeesViewState();
}

class _FeesViewState extends ConsumerState<FeesView> {
  String _searchQuery = '';
  FeeStatus? _filterStatus;
  String? _filterType;
  late final overdueAsync = ref.watch(overdueFeesBySchoolProvider(widget.schoolId));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final feesAsync = ref.watch(feesBySchoolProvider(widget.schoolId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fee Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddFeeDialog,
            tooltip: 'Add Fee Record',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'refresh') {
                ref.invalidate(feesBySchoolProvider(widget.schoolId));
                ref.invalidate(overdueFeesBySchoolProvider(widget.schoolId));
              }
              if (value == 'export') _exportFees();
              if (value == 'overdue') _showOverdueDialog();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'refresh', child: Text('Refresh')),
              const PopupMenuItem(value: 'overdue', child: Text('View Overdue')),
              const PopupMenuItem(value: 'export', child: Text('Export')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary Cards
          overdueAsync.when(
            data: (overdue) => Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(bottom: BorderSide(color: theme.colorScheme.outlineVariant)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: MetricCard(
                      title: 'Overdue Records',
                      value: '${overdue.length}',
                      icon: Icons.warning_amber,
                      color: overdue.isNotEmpty ? AppTheme.errorColor : AppTheme.successColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: MetricCard(
                      title: 'Total Overdue Amount',
                      value: AppFormatters.formatCurrency(overdue.fold<double>(0, (sum, f) => sum + f.balance)),
                      icon: Icons.attach_money,
                      color: AppTheme.errorColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: feesAsync.when(
                      data: (fees) {
                        final totalDue = fees.fold<double>(0, (sum, f) => sum + f.amountDue);
                        final totalPaid = fees.fold<double>(0, (sum, f) => sum + f.amountPaid);
                        final rate = totalDue > 0 ? (totalPaid / totalDue * 100) : 100;
                        return MetricCard(
                          title: 'Collection Rate',
                          value: '${rate.toStringAsFixed(1)}%',
                          icon: Icons.trending_up,
                          color: rate >= 85 ? AppTheme.successColor : AppTheme.warningColor,
                        );
                      },
                      loading: () => _buildMetricSkeleton(),
                      error: (_, _) => _buildMetricSkeleton(),
                    ),
                  ),
                ],
              ),
            ),
            loading: () => const SizedBox(height: 100, child: LoadingState()),
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
                    hintText: 'Search fees...',
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
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<FeeStatus>(
                        value: _filterStatus,
                        decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder(), isDense: true),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('All Status')),
                          ...FeeStatus.values.map((s) => DropdownMenuItem(
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
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _filterType,
                        decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder(), isDense: true),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('All Types')),
                          ...AppConstants.feeTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))),
                        ],
                        onChanged: (value) => setState(() => _filterType = value),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Fees List
          Expanded(
            child: feesAsync.when(
              data: (fees) {
                var filteredFees = fees.where((fee) {
                  final matchesSearch = _searchQuery.isEmpty ||
                      fee.feeType.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                      fee.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                      fee.studentId.contains(_searchQuery);
                  final matchesStatus = _filterStatus == null || fee.status == _filterStatus;
                  final matchesType = _filterType == null || fee.feeType == _filterType;
                  return matchesSearch && matchesStatus && matchesType;
                }).toList();

                // Sort by due date (overdue first)
                filteredFees.sort((a, b) {
                  if (a.isOverdue && !b.isOverdue) return -1;
                  if (!a.isOverdue && b.isOverdue) return 1;
                  return a.dueDate.compareTo(b.dueDate);
                });

                if (filteredFees.isEmpty) {
                  return const EmptyState(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'No Fee Records',
                    message: 'No fees match your current filters',
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredFees.length,
                  itemBuilder: (context, index) {
                    final fee = filteredFees[index];
                    return _FeeRecordTile(
                      fee: fee,
                      onTap: () => _showFeeDetailDialog(fee),
                      onPayment: () => _showRecordPaymentDialog(fee),
                    );
                  },
                );
              },
              loading: () => const LoadingState(message: 'Loading fees...'),
              error: (e, _) => ErrorState(message: e.toString()),
            ),
          ),
        ],
      ),
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

  void _showAddFeeDialog() {
    // Implementation for adding fee
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add fee feature coming soon')));
  }

  void _showFeeDetailDialog(FeeRecord fee) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(fee.feeType),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Description: ${fee.description}'),
            Text('Amount Due: ${AppFormatters.formatCurrency(fee.amountDue)}'),
            Text('Amount Paid: ${AppFormatters.formatCurrency(fee.amountPaid)}'),
            Text('Balance: ${AppFormatters.formatCurrency(fee.balance)}'),
            Text('Due Date: ${AppFormatters.formatDate(fee.dueDate)}'),
            Text('Status: ${fee.status.displayName}'),
            if (fee.paidDate != null) Text('Paid Date: ${AppFormatters.formatDate(fee.paidDate!)}'),
            if (fee.paymentMethod != null) Text('Payment Method: ${fee.paymentMethod}'),
            if (fee.transactionId != null) Text('Transaction ID: ${fee.transactionId}'),
            if (fee.receiptNumber != null) Text('Receipt: ${fee.receiptNumber}'),
            if (fee.notes != null) Text('Notes: ${fee.notes}'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showRecordPaymentDialog(FeeRecord fee) {
    final amountController = TextEditingController(text: fee.balance.toStringAsFixed(2));
    String paymentMethod = 'Cash';
    final transactionController = TextEditingController();
    final receiptController = TextEditingController();
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Record Payment - ${fee.feeType}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Balance Due: ${AppFormatters.formatCurrency(fee.balance)}', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextFormField(
                controller: amountController,
                decoration: const InputDecoration(labelText: 'Payment Amount *', prefixText: '\$'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: paymentMethod,
                decoration: const InputDecoration(labelText: 'Payment Method'),
                items: ['Cash', 'Card', 'Check', 'Bank Transfer', 'Online', 'Other']
                    .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                    .toList(),
                onChanged: (v) => paymentMethod = v!,
              ),
              const SizedBox(height: 16),
              TextFormField(controller: transactionController, decoration: const InputDecoration(labelText: 'Transaction ID')),
              const SizedBox(height: 16),
              TextFormField(controller: receiptController, decoration: const InputDecoration(labelText: 'Receipt Number')),
              const SizedBox(height: 16),
              TextFormField(controller: notesController, decoration: const InputDecoration(labelText: 'Notes'), maxLines: 2),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text) ?? 0;
              if (amount <= 0 || amount > fee.balance) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid amount')));
                return;
              }
              try {
                await ref.read(firestoreServiceProvider).updateDocument(
                  collection: 'fees',
                  id: fee.id,
                  data: {
                    'amountPaid': fee.amountPaid + amount,
                    'status': fee.amountPaid + amount >= fee.amountDue ? FeeStatus.paid.value : FeeStatus.partial.value,
                    'paidDate': DateTime.now(),
                    'paymentMethod': paymentMethod,
                    'transactionId': transactionController.text,
                    'receiptNumber': receiptController.text,
                    'notes': notesController.text,
                  },
                );
                Navigator.pop(context);
                ref.invalidate(feesBySchoolProvider(widget.schoolId));
                ref.invalidate(overdueFeesBySchoolProvider(widget.schoolId));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment recorded')));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Record Payment'),
          ),
        ],
      ),
    );
  }

  void _showOverdueDialog() {
    overdueAsync.whenData((overdue) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Overdue Fees (${overdue.length})'),
          content: SizedBox(
            width: 500,
            height: 400,
            child: ListView.builder(
              itemCount: overdue.length,
              itemBuilder: (context, index) {
                final fee = overdue[index];
                return ListTile(
                  dense: true,
                  leading: CircleAvatar(backgroundColor: AppTheme.errorColor.withOpacity(0.1), child: Icon(Icons.warning, color: AppTheme.errorColor)),
                  title: Text(fee.feeType, style: const TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: Text('Student ${fee.studentId} • Due: ${AppFormatters.formatShortDate(fee.dueDate)}'),
                  trailing: Text(AppFormatters.formatCurrency(fee.balance), style: const TextStyle(color: AppTheme.errorColor, fontWeight: FontWeight.bold)),
                  onTap: () {
                    Navigator.pop(context);
                    _showFeeDetailDialog(fee);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          ],
        ),
      );
    });
  }

  void _exportFees() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Export feature coming soon')));
  }
}

class _FeeRecordTile extends StatelessWidget {
  final FeeRecord fee;
  final VoidCallback onTap;
  final VoidCallback onPayment;

  const _FeeRecordTile({required this.fee, required this.onTap, required this.onPayment});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: fee.isOverdue ? theme.colorScheme.errorContainer.withOpacity(0.1) : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: fee.status.color.withOpacity(0.1),
                child: Icon(Icons.receipt, color: fee.status.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(fee.feeType, style: const TextStyle(fontWeight: FontWeight.w600)),
                        ),
                        if (fee.isOverdue)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: AppTheme.errorColor, borderRadius: BorderRadius.circular(8)),
                            child: const Text('OVERDUE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('Student ${fee.studentId} • ${fee.description}', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text('Due: ${AppFormatters.formatShortDate(fee.dueDate)}', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                        const SizedBox(width: 16),
                        Expanded(
                          child: LinearProgressIndicator(
                            value: fee.paymentPercentage / 100,
                            backgroundColor: fee.status.color.withOpacity(0.2),
                            valueColor: AlwaysStoppedAnimation<Color>(fee.status.color),
                            minHeight: 4,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('${fee.paymentPercentage.toStringAsFixed(0)}%', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600, color: fee.status.color)),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  StatusChip(label: fee.status.displayName, color: fee.status.color, small: true),
                  const SizedBox(height: 4),
                  Text(
                    '${AppFormatters.formatCurrency(fee.amountPaid)} / ${AppFormatters.formatCurrency(fee.amountDue)}',
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  if (fee.balance > 0) ...[
                    const SizedBox(height: 4),
                    FilledButton.tonal(
                      onPressed: onPayment,
                      style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
                      child: const Text('Pay', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}