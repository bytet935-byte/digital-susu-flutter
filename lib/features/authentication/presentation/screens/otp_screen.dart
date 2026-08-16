import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../providers/auth_providers.dart';

/// OTP verification screen (spec §10, FLOW 1). Reached from registration
/// (`/otp?phone=...&flow=register`); on success the router listener sends
/// the user to the dashboard.
class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key, this.phone = '', this.flow = 'register'});

  final String phone;
  final String flow;

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final TextEditingController _code = TextEditingController();
  bool _submitting = false;
  bool _resending = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final error = Validators.otp(_code.text);
    if (error != null) {
      _showError(error);
      return;
    }
    setState(() => _submitting = true);
    try {
      await ref.read(authControllerProvider.notifier).verifyOtp(
            phone: widget.phone,
            code: _code.text.trim(),
          );
      // Router listener navigates to the dashboard.
    } on AppException catch (e) {
      if (mounted) _showError(e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _resend() async {
    setState(() => _resending = true);
    try {
      await ref.read(authControllerProvider.notifier).resendOtp(
            phone: widget.phone,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('A new code has been sent to your phone.')),
        );
      }
    } on AppException catch (e) {
      if (mounted) _showError(e.message);
    } finally {
      if (mounted) setState(() => _resending = false);
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
      appBar: AppBar(title: const Text('Verify Phone')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(height: 16),
              Icon(
                Icons.sms_outlined,
                size: 64,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Enter the 6-digit code',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'We sent a verification code to ${widget.phone.isEmpty ? 'your phone' : widget.phone}',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _code,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                maxLength: AppConfig.otpLength,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(
                  letterSpacing: 12,
                ),
                decoration: const InputDecoration(
                  hintText: '••••••',
                  counterText: '',
                  filled: true,
                ),
                onChanged: (value) {
                  if (value.length == AppConfig.otpLength) _verify();
                },
                onFieldSubmitted: (_) => _verify(),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _submitting ? null : _verify,
                child: _submitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppColors.onPrimary,
                        ),
                      )
                    : const Text('Verify'),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    "Didn't receive the code? ",
                    style: theme.textTheme.bodySmall,
                  ),
                  TextButton(
                    onPressed: _resending ? null : _resend,
                    child: Text(_resending ? 'Sending…' : 'Resend'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
