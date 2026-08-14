import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_states.dart';

/// Phase 1 placeholder — the permission-aware dashboard overview lands in
/// Phase 4 (spec §13).
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: const AppEmptyState(
        title: 'Dashboard coming in Phase 4',
        message:
            'Balances, groups, upcoming contributions, savings progress and '
            'notifications will appear here — filtered by your permissions.',
        icon: Icons.space_dashboard_outlined,
      ),
    );
  }
}
