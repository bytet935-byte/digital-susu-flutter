import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../../../shared/widgets/app_states.dart';
import '../domain/app_transaction.dart';
import '../providers/transactions_providers.dart';

/// Activity / transaction history screen (spec §14): searchable, filterable,
/// with status indicators and a transaction detail sheet. Status is never
/// communicated by color alone (spec §28) — text badges are used.
class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() =>
      _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  static const List<String> _filters = <String>[
    'All',
    'Contributions',
    'Deposits',
    'Withdrawals',
    'Payouts',
  ];

  String _filter = 'All';
  String _query = '';

  List<AppTransaction> _apply(List<AppTransaction> items) {
    var result = items;
    switch (_filter) {
      case 'Contributions':
        result = result.where((t) => t.type == 'CONTRIBUTION').toList();
      case 'Deposits':
        result = result.where((t) => t.type == 'DEPOSIT').toList();
      case 'Withdrawals':
        result = result.where((t) => t.type == 'WITHDRAWAL').toList();
      case 'Payouts':
        result = result.where((t) => t.type == 'PAYOUT').toList();
      default:
        break;
    }
    if (_query.trim().isNotEmpty) {
      final q = _query.trim().toLowerCase();
      result = result
          .where((t) =>
              t.description.toLowerCase().contains(q) ||
              (t.reference?.toLowerCase().contains(q) ?? false) ||
              (t.groupName?.toLowerCase().contains(q) ?? false))
          .toList();
    }
    return result;
  }

  void _showDetails(AppTransaction transaction) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => _TransactionDetailsSheet(transaction: transaction),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final transactionsAsync = ref.watch(transactionsProvider);
    final controller = ref.read(transactionsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Activity')),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: 'Search transactions…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(() => _query = ''),
                      ),
              ),
            ),
          ),
          SizedBox(
            height: 56,
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final filter = _filters[index];
                final selected = filter == _filter;
                return FilterChip(
                  label: Text(filter),
                  selected: selected,
                  onSelected: (_) => setState(() => _filter = filter),
                );
              },
            ),
          ),
          Expanded(
            child: transactionsAsync.when(
              loading: () => const AppLoadingView(),
              error: (error, stackTrace) => AppErrorState(
                onRetry: () => controller.refresh(),
              ),
              data: (items) {
                final filtered = _apply(items);
                if (filtered.isEmpty) {
                  return const AppEmptyState(
                    title: 'No transactions found',
                    message:
                        'Try a different filter or search term. New '
                        'contributions appear here as you save.',
                    icon: Icons.receipt_long_outlined,
                  );
                }
                return ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, indent: 16, endIndent: 16),
                  itemBuilder: (context, index) {
                    final transaction = filtered[index];
                    return ListTile(
                      onTap: () => _showDetails(transaction),
                      leading: CircleAvatar(
                        backgroundColor: transaction.isCredit
                            ? AppColors.secondaryContainer
                            : theme.colorScheme.errorContainer,
                        child: Icon(
                          transaction.isCredit
                              ? Icons.arrow_downward
                              : Icons.arrow_upward,
                          size: 18,
                          color: transaction.isCredit
                              ? AppColors.moneyPositive
                              : AppColors.moneyNegative,
                        ),
                      ),
                      title: Text(
                        transaction.description,
                        style: theme.textTheme.bodyMedium,
                      ),
                      subtitle: Text(
                        '${DateFormatter.formatDateTime(transaction.timestamp)}'
                        '${transaction.groupName == null ? '' : ' · ${transaction.groupName}'}',
                        style: theme.textTheme.caption,
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: <Widget>[
                          Text(
                            transaction.amount.format(),
                            style: theme.textTheme.emphasis.copyWith(
                              color: transaction.isCredit
                                  ? AppColors.moneyPositive
                                  : AppColors.moneyNegative,
                            ),
                          ),
                          const SizedBox(height: 2),
                          StatusBadge(status: transaction.status),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Text badge — status is never conveyed by colour alone (spec §28).
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'SUCCESSFUL' => ('Successful', AppColors.success),
      'PENDING' => ('Pending', AppColors.warning),
      'FAILED' => ('Failed', AppColors.danger),
      'REVERSED' => ('Reversed', AppColors.onSurfaceVariant),
      _ => (status, AppColors.onSurfaceVariant),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, color: color)),
    );
  }
}

/// Transaction details sheet (spec §14): amount, type, date, status,
/// reference, group and payment method.
class _TransactionDetailsSheet extends StatelessWidget {
  const _TransactionDetailsSheet({required this.transaction});

  final AppTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Center(
            child: Text(
              transaction.amount.format(),
              style: theme.textTheme.displayLarge?.copyWith(
                color: transaction.isCredit
                    ? AppColors.moneyPositive
                    : AppColors.moneyNegative,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              transaction.description,
              style: theme.textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: 24),
          _DetailRow(label: 'Status', child: StatusBadge(status: transaction.status)),
          _DetailRow(label: 'Type', value: transaction.type),
          _DetailRow(
            label: 'Date & time',
            value: DateFormatter.formatDateTime(transaction.timestamp),
          ),
          _DetailRow(label: 'Reference', value: transaction.reference ?? '—'),
          _DetailRow(label: 'Group', value: transaction.groupName ?? '—'),
          _DetailRow(
            label: 'Payment method',
            value: transaction.paymentMethod ?? '—',
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, this.value, this.child});

  final String label;
  final String? value;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(label, style: theme.textTheme.bodySmall),
          child ??
              Text(
                value ?? '—',
                style: theme.textTheme.emphasis,
              ),
        ],
      ),
    );
  }
}
