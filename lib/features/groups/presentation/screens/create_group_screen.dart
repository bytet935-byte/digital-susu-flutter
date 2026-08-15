import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../domain/group_models.dart';
import '../providers/groups_providers.dart';

/// Create-group flow (FLOW 2, spec §14): name, type selection, description.
/// Rules/contribution schedules are configured from the group settings once
/// the schedule system lands (Phase 7).
class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _description = TextEditingController();
  String _type = GroupTypes.rotationalSusu;
  bool _submitting = false;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);
    try {
      final group = await ref.read(myGroupsProvider.notifier).createGroup(
            name: _name.text,
            type: _type,
            description: _description.text,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${group.name} created 🎉')),
        );
        context.go(AppRoutes.groupDetails(group.id));
      }
    } on AppException catch (error) {
      if (mounted) _showError(error.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Create Susu')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  'Start a community savings group',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _name,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Group Name',
                    prefixIcon: Icon(Icons.groups_outlined),
                  ),
                  validator: Validators.name,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _description,
                  textInputAction: TextInputAction.newline,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    prefixIcon: Icon(Icons.notes_outlined),
                  ),
                ),
                const SizedBox(height: 24),
                Text('Group Type', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                ...GroupTypes.values.map(
                  (type) => RadioListTile<String>(
                    value: type,
                    groupValue: _type,
                    onChanged: (value) =>
                        setState(() => _type = value ?? _type),
                    title: Text(_typeLabel(type)),
                    subtitle: Text(_typeSubtitle(type)),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppColors.onPrimary,
                          ),
                        )
                      : const Text('Create Group'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _typeLabel(String type) => switch (type) {
        GroupTypes.rotationalSusu => 'Rotational Susu',
        GroupTypes.savingsGoal => 'Savings Goal',
        GroupTypes.jointBusiness => 'Joint Business',
        _ => 'Susu Group',
      };

  String _typeSubtitle(String type) => switch (type) {
        GroupTypes.rotationalSusu =>
          'Members contribute regularly; the pot rotates per schedule.',
        GroupTypes.savingsGoal =>
          'Everyone saves toward a shared target amount.',
        GroupTypes.jointBusiness =>
          'Capital is pooled for a shared business or activity.',
        _ => '',
      };
}
