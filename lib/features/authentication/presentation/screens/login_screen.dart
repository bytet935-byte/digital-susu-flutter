import 'package:flutter/material.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/config/environment.dart';

/// Phase 1 placeholder — proves branding, Ghana-first config wiring and the
/// Material theme. The real login flow (phone/email, password, OTP) lands in
/// Phase 3.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Icon(
                  Icons.savings_outlined,
                  size: 72,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  AppConfig.appName,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Savings • Susu • Group finance',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 32),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: <Widget>[
                        _ConfigRow(
                          label: 'Country',
                          value:
                              '${AppConfig.countryName} (${AppConfig.countryCode})',
                        ),
                        _ConfigRow(
                          label: 'Currency',
                          value:
                              '${AppConfig.currencyCode} ${AppConfig.currencySymbol}',
                        ),
                        _ConfigRow(
                          label: 'Phone',
                          value: AppConfig.phoneCountryCode,
                        ),
                        _ConfigRow(
                          label: 'Timezone',
                          value: AppConfig.timezone,
                        ),
                        _ConfigRow(
                          label: 'Locale',
                          value: AppConfig.locale,
                        ),
                        _ConfigRow(
                          label: 'Data mode',
                          value: AppEnvironment.useMockData
                              ? 'Mock (USE_MOCK_DATA=true)'
                              : 'Live API',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Authentication arrives in Phase 3.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ConfigRow extends StatelessWidget {
  const _ConfigRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(label, style: theme.textTheme.bodySmall),
          Text(
            value,
            style: theme.textTheme.labelLarge!.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
