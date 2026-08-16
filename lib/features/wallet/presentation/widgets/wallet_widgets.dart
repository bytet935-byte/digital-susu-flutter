import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/models/money.dart';
import '../../domain/wallet_models.dart';

/// Renders an amount in the design-reference "GHS 0.00" style.
String formatGhs(Money money) =>
    'GHS ${NumberFormat('#,##0.00').format(money.amountMajor)}';

// ---------------------------------------------------------------------------
// Balance card (design reference: balance card with Top Up / Withdraw)
// ---------------------------------------------------------------------------

class WalletBalanceCard extends StatefulWidget {
  const WalletBalanceCard({
    super.key,
    required this.balance,
    this.onTopUp,
    this.onWithdraw,
  });

  final Money balance;
  final VoidCallback? onTopUp;
  final VoidCallback? onWithdraw;

  @override
  State<WalletBalanceCard> createState() => _WalletBalanceCardState();
}

class _WalletBalanceCardState extends State<WalletBalanceCard> {
  bool _hidden = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text('Available Balance', style: theme.textTheme.bodyMedium),
              const SizedBox(width: 2),
              InkWell(
                onTap: () => setState(() => _hidden = !_hidden),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Icon(
                    _hidden
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 18,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _hidden ? 'GHS ••••' : formatGhs(widget.balance),
            style: theme.textTheme.money.copyWith(
              fontSize: 30,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: <Widget>[
              Expanded(
                child: FilledButton.icon(
                  onPressed: widget.onTopUp,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Top Up'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: widget.onWithdraw,
                  icon: const Icon(Icons.arrow_upward, size: 18),
                  label: const Text('Withdraw'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Quick actions (design reference: Add Money, Send Money, Bank Transfer,
// Airtime)
// ---------------------------------------------------------------------------

class WalletQuickActions extends StatelessWidget {
  const WalletQuickActions({
    super.key,
    this.onAddMoney,
    this.onSendMoney,
    this.onBankTransfer,
    this.onAirtime,
  });

  final VoidCallback? onAddMoney;
  final VoidCallback? onSendMoney;
  final VoidCallback? onBankTransfer;
  final VoidCallback? onAirtime;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        _CircleAction(
          color: AppColors.primary,
          icon: Icons.add,
          label: 'Add Money',
          onTap: onAddMoney,
        ),
        _CircleAction(
          color: AppColors.quickPurple,
          icon: Icons.send,
          label: 'Send Money',
          onTap: onSendMoney,
        ),
        _CircleAction(
          color: AppColors.quickTeal,
          icon: Icons.account_balance,
          label: 'Bank Transfer',
          onTap: onBankTransfer,
        ),
        _CircleAction(
          color: AppColors.danger,
          icon: Icons.phone_android,
          label: 'Airtime',
          onTap: onAirtime,
        ),
      ],
    );
  }
}

class _CircleAction extends StatelessWidget {
  const _CircleAction({
    required this.color,
    required this.icon,
    required this.label,
    this.onTap,
  });

  final Color color;
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Transaction row (green credits / red debits)
// ---------------------------------------------------------------------------

class WalletTransactionTile extends StatelessWidget {
  const WalletTransactionTile({super.key, required this.transaction});

  final WalletTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final amountColor = transaction.isCredit
        ? AppColors.moneyPositive
        : AppColors.moneyNegative;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        child: Icon(
          transaction.isCredit ? Icons.arrow_downward : Icons.arrow_upward,
          size: 18,
          color: amountColor,
        ),
      ),
      title: Text(transaction.description, style: theme.textTheme.bodyMedium),
      subtitle: Text(
        DateFormatter.formatDateTime(transaction.timestamp),
        style: theme.textTheme.bodySmall,
      ),
      trailing: Text(
        formatGhs(transaction.amount),
        style: theme.textTheme.emphasis.copyWith(color: amountColor),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Amount entry sheet (shared by Top Up / Withdraw)
// ---------------------------------------------------------------------------

/// Presets per the Contribute design (spec §9): GHS 10 / 20 / 50 / 100.
const List<Money> _amountPresets = <Money>[
  Money(1000),
  Money(2000),
  Money(5000),
  Money(10000),
];

/// Opens the amount sheet; resolves with the chosen [Money] or `null` if
/// dismissed. Pass [maxAmount] (e.g. wallet balance) to cap the entry.
Future<Money?> showWalletAmountSheet(
  BuildContext context, {
  required String title,
  required String actionLabel,
  Money? maxAmount,
}) {
  return showModalBottomSheet<Money>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    builder: (context) => _WalletAmountSheet(
      title: title,
      actionLabel: actionLabel,
      maxAmount: maxAmount,
    ),
  );
}

class _WalletAmountSheet extends StatefulWidget {
  const _WalletAmountSheet({
    required this.title,
    required this.actionLabel,
    this.maxAmount,
  });

  final String title;
  final String actionLabel;
  final Money? maxAmount;

  @override
  State<_WalletAmountSheet> createState() => _WalletAmountSheetState();
}

class _WalletAmountSheetState extends State<_WalletAmountSheet> {
  final TextEditingController _controller = TextEditingController();
  Money? _selectedPreset;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _confirm() {
    final text = _controller.text.trim();
    final Money amount;
    if (text.isEmpty && _selectedPreset != null) {
      amount = _selectedPreset!;
    } else {
      final parsed = double.tryParse(text);
      if (parsed == null || parsed <= 0) {
        setState(() => _error = 'Enter an amount greater than zero');
        return;
      }
      amount = Money((parsed * 100).round());
    }
    if (widget.maxAmount != null && amount > widget.maxAmount!) {
      setState(() => _error = 'Amount exceeds your available balance');
      return;
    }
    Navigator.of(context).pop(amount);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottomInset + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(widget.title, style: theme.textTheme.titleMedium),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: _amountPresets
                .map(
                  (Money preset) => ChoiceChip(
                    label: Text('GHS ${preset.amountMajor.toStringAsFixed(0)}'),
                    selected: _selectedPreset == preset,
                    onSelected: (bool selected) => setState(() {
                      _selectedPreset = selected ? preset : null;
                      _error = null;
                      if (selected) _controller.clear();
                    }),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            onChanged: (String value) => setState(() {
              _selectedPreset = null;
              _error = null;
            }),
            decoration: const InputDecoration(
              labelText: 'Amount',
              prefixText: 'GHS ',
              border: OutlineInputBorder(),
            ),
          ),
          if (_error != null) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: const TextStyle(color: AppColors.danger, fontSize: 12),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _confirm,
            child: Text(widget.actionLabel),
          ),
        ],
      ),
    );
  }
}
