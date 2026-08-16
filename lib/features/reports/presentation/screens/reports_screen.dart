import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/models/money.dart';
import '../../../../shared/widgets/app_states.dart';
import '../../../groups/domain/group_models.dart';
import '../../../groups/presentation/providers/groups_providers.dart';
import '../../../payments/domain/payment_models.dart';
import '../../../payments/presentation/providers/payments_providers.dart';
import '../../../payments/presentation/screens/payments_screen.dart';
import '../../../wallet/presentation/providers/wallet_providers.dart';

/// Reports Center (spec Profile tab): an audit-trail summary of wallet,
/// susu pots and contributions, with one-tap export (copies a text report
/// to the clipboard for email/paste).
class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  static String _ghs(Money money) =>
      'GHS ${NumberFormat('#,##0.00').format(money.amountMajor)}';

  Future<void> _export(
    BuildContext context,
    Money balance,
    Money inSusu,
    Money contributed,
    List<Payment> payments,
  ) async {
    final buffer = StringBuffer()
      ..writeln('Digital Susu Report — ${DateFormatter.formatDate(DateTime.now())}')
      ..writeln()
      ..writeln('Wallet balance: ${_ghs(balance)}')
      ..writeln('In susu groups: ${_ghs(inSusu)}')
      ..writeln('My contributions: ${_ghs(contributed)}')
      ..writeln()
      ..writeln('Recent activity:');
    for (final payment in payments) {
      buffer.writeln('- ${payment.description}: ${_ghs(payment.amount)}');
    }
    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Report copied to clipboard — paste it into an email'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final walletAsync = ref.watch(walletSummaryProvider);
    final groupsAsync = ref.watch(myGroupsProvider);
    final paymentsAsync = ref.watch(paymentsProvider);

    final balance = walletAsync.valueOrNull?.balance ?? Money.zero();
    final activeGroups =
        (groupsAsync.valueOrNull ?? const <SusuGroup>[])
            .where((SusuGroup g) => g.isActive)
            .toList();
    final inSusu =
        activeGroups.fold<Money>(Money.zero(), (Money sum, SusuGroup g) => sum + g.pot);
    final contributed = activeGroups.fold<Money>(
        Money.zero(), (Money sum, SusuGroup g) => sum + g.myContribution);
    final payments = paymentsAsync.valueOrNull ?? const <Payment>[];

    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: <Widget>[
          Text('Financial summary', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          _SummaryCard(
            label: 'Wallet balance',
            value: _ghs(balance),
            icon: Icons.account_balance_wallet_outlined,
            color: AppColors.primary,
          ),
          const SizedBox(height: 10),
          _SummaryCard(
            label: 'In susu groups',
            value: _ghs(inSusu),
            icon: Icons.groups_outlined,
            color: AppColors.quickTeal,
          ),
          const SizedBox(height: 10),
          _SummaryCard(
            label: 'My contributions',
            value: _ghs(contributed),
            icon: Icons.savings_outlined,
            color: AppColors.quickPurple,
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text('Recent activity', style: theme.textTheme.titleMedium),
              TextButton.icon(
                onPressed: () => _export(
                    context, balance, inSusu, contributed, payments),
                icon: const Icon(Icons.ios_share, size: 18),
                label: const Text('Export'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (payments.isEmpty)
            const AppEmptyState(
              title: 'No activity yet',
              icon: Icons.receipt_long_outlined,
            )
          else
            ...payments
                .take(6)
                .map((payment) => PaymentTile(payment: payment)),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: theme.textTheme.bodyMedium),
          ),
          Text(
            value,
            style: theme.textTheme.emphasis.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
