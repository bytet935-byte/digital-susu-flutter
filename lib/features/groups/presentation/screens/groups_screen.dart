import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_states.dart';

/// Groups tab placeholder — full group management (create/join/members/
/// permissions/chat) lands in Phase 5 (spec §14).
class GroupsScreen extends StatelessWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Groups')),
      body: const AppEmptyState(
        title: 'Groups arrive in Phase 5',
        message:
            'Create susu groups, invite members, set rules and manage '
            'contributions here.',
        icon: Icons.groups_outlined,
      ),
    );
  }
}
