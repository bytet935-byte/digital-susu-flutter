import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/utils/validators.dart';
import '../../../authentication/domain/models/user.dart';
import '../../../authentication/presentation/providers/auth_providers.dart';
import '../providers/profile_providers.dart';

/// Edit profile form (spec §22): name, phone, email. Saves through the
/// profile repository and updates the active session immediately.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _fullName;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final auth = ref.read(authStateProvider);
    final user = switch (auth) {
      AuthAuthenticated(:final session) => session.user,
      _ => null,
    };
    _fullName = TextEditingController(text: user?.fullName ?? '');
    _phone = TextEditingController(
      text: user == null ? '' : _localPhone(user.phone),
    );
    _email = TextEditingController(text: user?.email ?? '');
  }

  @override
  void dispose() {
    _fullName.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  /// Converts E.164 (+233…) to a local 0-prefixed number for editing.
  String _localPhone(String phone) {
    final digits = PhoneFormatter.normalize(phone);
    if (digits.startsWith('233') && digits.length == 12) {
      return '0${digits.substring(3)}';
    }
    return phone;
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);
    try {
      final result = await ref
          .read(profileRepositoryProvider)
          .updateProfile(
            fullName: _fullName.text,
            phone: _phone.text,
            email: _email.text.isEmpty ? null : _email.text,
          );
      switch (result) {
        case Success<User>(:final value):
          ref.read(authControllerProvider.notifier).updateSessionUser(value);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile updated')),
            );
            context.pop();
          }
        case Failure<User>(:final error):
          if (mounted) _showError(error.message);
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
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Center(
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Text(
                      _fullName.text.isEmpty
                          ? 'D'
                          : _fullName.text[0].toUpperCase(),
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _fullName,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  validator: Validators.name,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  validator: Validators.phone,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _save(),
                  decoration: const InputDecoration(
                    labelText: 'Email (optional)',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: Validators.email,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _submitting ? null : _save,
                  child: _submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppColors.onPrimary,
                          ),
                        )
                      : const Text('Save Changes'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
