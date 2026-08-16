import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../shared/models/money.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../../../shared/widgets/app_states.dart';
import '../providers/wallet_providers.dart';
import '../widgets/wallet_widgets.dart';

/// Personal wallet (Phase 6, spec §7): balance card with Top Up / Withdraw,
/// quick actions (Add Money, Send Money, Bank Transfer, Airtime) and recent
/// wallet transactions (green credits / red debits). Group wallets stay
/// strictly separate.
class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  Future<void> _topUp(BuildContext context, WidgetRef ref) async {
    final amount = await showWalletAmountSheet(
      context,
      title: 'Top Up Wallet',
      actionLabel: 'Top Up',
    );
    if (amount == null || !context.mounted) return;
    final ok = await ref.read(walletSummaryProvider.notifier).topUp(amount);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? 'Wallet topped up successfully'
            : 'Top up failed. Please try again.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _withdraw(BuildContext context, WidgetRef ref) async {
    final balance =
        ref.read(walletSummaryProvider).valueOrNull?.balance ?? Money.zero();
    final amount = await showWalletAmountSheet(
      context,
      title: 'Withdraw from Wallet',
      actionLabel: 'Withdraw',
      maxAmount: balance,
    );
    if (amount == null || !context.mounted) return;
    final ok = await ref.read(walletSummaryProvider.notifier).withdraw(amount);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? 'Withdrawal successful'
            : 'Withdrawal failed. Please try again.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _comingSoon(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final summaryAsync = ref.watch(walletSummaryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Wallet')),
      body: summaryAsync.when(
        loading: () => const AppLoadingView(message: 'Loading your wallet…'),
        error: (error, stackTrace) => AppErrorState(
          message: error is AppException
              ? error.message
              : 'Could not load your wallet',
          onRetry: () => ref.read(walletSummaryProvider.notifier).refresh(),
        ),
        data: (summary) => RefreshIndicator(
          onRefresh: () =>
              ref.read(walletSummaryProvider.notifier).refresh(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: <Widget>[
              WalletBalanceCard(
                balance: summary.balance,
                onTopUp: () => _topUp(context, ref),
                onWithdraw: () => _withdraw(context, ref),
              ),
              const SizedBox(height: 24),
              WalletQuickActions(
                onAddMoney: () => _topUp(context, ref),
                onSendMoney: () => _comingSoon(
                    context, 'Send Money arrives with payments (Phase 7)'),
                onBankTransfer: () => _comingSoon(
                    context, 'Bank Transfer arrives with payments (Phase 7)'),
                onAirtime: () =>
                    _comingSoon(context, 'Airtime arrives in Phase 7'),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text('Recent Transactions', style: theme.textTheme.titleMedium),
                  TextButton(
                    onPressed: () => context.go(AppRoutes.transactions),
                    child: const Text('See All'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (summary.recentTransactions.isEmpty)
                const AppEmptyState(
                  title: 'No transactions yet',
                  message: 'Top up your wallet to get started.',
                  icon: Icons.receipt_long_outlined,
                )
              else
                ...summary.recentTransactions
                    .take(6)
                    .map((t) => WalletTransactionTile(transaction: t)),
            ],
          ),
        ),
      ),
    );
  }
}
