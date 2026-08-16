import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/models/money.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../../../shared/widgets/app_states.dart';
import '../../../wallet/presentation/providers/wallet_providers.dart';
import '../../../wallet/presentation/widgets/wallet_widgets.dart';
import '../../domain/payment_models.dart';
import '../providers/payments_providers.dart';

/// Payments screen (design reference screen 10): wallet balance on top,
/// payments below with timestamps, color-coded amounts (green credits / red
/// debits) and status chips.
class PaymentsScreen extends ConsumerWidget {
  const PaymentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final paymentsAsync = ref.watch(paymentsProvider);
    final balance = ref.watch(walletSummaryProvider).valueOrNull?.balance;

    return Scaffold(
      appBar: AppBar(title: const Text('Payments')),
      body: paymentsAsync.when(
        loading: () => const AppLoadingView(message: 'Loading payments…'),
        error: (error, stackTrace) => AppErrorState(
          message: error is AppException
              ? error.message
              : 'Could not load your payments',
          onRetry: () => ref.read(paymentsProvider.notifier).refresh(),
        ),
        data: (payments) => RefreshIndicator(
          onRefresh: () => ref.read(paymentsProvider.notifier).refresh(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: <Widget>[
              if (balance != null) ...<Widget>[
                _BalanceHeader(balance: balance),
                const SizedBox(height: 20),
              ],
              Text('Recent Payments', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              if (payments.isEmpty)
                const AppEmptyState(
                  title: 'No payments yet',
                  icon: Icons.receipt_long_outlined,
                )
              else
                ...payments.map((Payment p) => PaymentTile(payment: p)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact wallet balance header (design reference screen 10).
class _BalanceHeader extends StatelessWidget {
  const _BalanceHeader({required this.balance});

  final Money balance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Wallet Balance',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Text(
            formatGhs(balance),
            style: theme.textTheme.money.copyWith(
              fontSize: 26,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class PaymentTile extends StatelessWidget {
  const PaymentTile({super.key, required this.payment});

  final Payment payment;

  static IconData _iconFor(String type) => switch (type) {
        'CONTRIBUTION' => Icons.savings_outlined,
        'TOP_UP' => Icons.add_circle_outline,
        'WITHDRAWAL' => Icons.arrow_upward,
        'SEND' => Icons.send,
        'AIRTIME' => Icons.phone_android,
        _ => Icons.receipt_long_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final amountColor = payment.isCredit
        ? AppColors.moneyPositive
        : AppColors.moneyNegative;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        child: Icon(
          _iconFor(payment.type),
          size: 18,
          color: amountColor,
        ),
      ),
      title: Text(payment.description, style: theme.textTheme.bodyMedium),
      subtitle: Text(
        DateFormatter.formatDateTime(payment.timestamp),
        style: theme.textTheme.bodySmall,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Text(
            formatGhs(payment.amount),
            style: theme.textTheme.emphasis.copyWith(color: amountColor),
          ),
          const SizedBox(height: 4),
          _StatusChip(status: payment.status),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (String label, Color color, Color background) = switch (status) {
      PaymentStatuses.pending => ('Pending', AppColors.warning, const Color(0xFFFEF3C7)),
      PaymentStatuses.failed => ('Failed', AppColors.danger, const Color(0xFFFEE2E2)),
      _ => ('Completed', AppColors.success, AppColors.secondaryContainer),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
