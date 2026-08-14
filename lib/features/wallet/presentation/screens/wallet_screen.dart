import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_states.dart';

/// Wallet tab placeholder — personal/group wallet separation, top-ups and
/// withdrawals land in Phase 6 (spec §7).
class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wallet')),
      body: const AppEmptyState(
        title: 'Wallet arrives in Phase 6',
        message:
            'Top up, withdraw and track your personal wallet here. Group '
            'wallets stay strictly separate.',
        icon: Icons.account_balance_wallet_outlined,
      ),
    );
  }
}
