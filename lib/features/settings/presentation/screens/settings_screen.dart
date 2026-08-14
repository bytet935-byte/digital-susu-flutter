import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/config/environment.dart';
import '../../../../core/providers/app_providers.dart';

/// Settings screen (spec §22): notification preferences (persisted locally)
/// and market configuration readout. Provider-level notification settings
/// arrive with push infrastructure (Phase 6/10).
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  static const String _key = AppConfig.localKeyNotificationSettings;

  bool _contributionReminders = true;
  bool _payoutAlerts = true;
  bool _announcements = true;
  bool _proposalsVoting = true;
  bool _securityAlerts = true;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    _load();
  }

  Future<void> _load() async {
    final storage = ref.read(localStorageProvider);
    final raw = await storage.readString(_key);
    final values = _parse(raw);
    if (mounted) {
      setState(() {
        _contributionReminders = values['contribution_reminders'] ?? true;
        _payoutAlerts = values['payout_alerts'] ?? true;
        _announcements = values['announcements'] ?? true;
        _proposalsVoting = values['proposals_voting'] ?? true;
        _securityAlerts = values['security_alerts'] ?? true;
      });
    }
  }

  Map<String, bool> _parse(String? raw) {
    if (raw == null || raw.isEmpty) return <String, bool>{};
    final map = <String, bool>{};
    for (final part in raw.split(',')) {
      final pair = part.split('=');
      if (pair.length == 2) {
        map[pair[0]] = pair[1] == 'true';
      }
    }
    return map;
  }

  Future<void> _save() async {
    final storage = ref.read(localStorageProvider);
    final value = <String, bool>{
      'contribution_reminders': _contributionReminders,
      'payout_alerts': _payoutAlerts,
      'announcements': _announcements,
      'proposals_voting': _proposalsVoting,
      'security_alerts': _securityAlerts,
    }.entries.map((e) => '${e.key}=${e.value}').join(',');
    await storage.writeString(_key, value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text('Notifications', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('Contribution reminders'),
            value: _contributionReminders,
            onChanged: (value) {
              setState(() => _contributionReminders = value);
              _save();
            },
          ),
          SwitchListTile(
            title: const Text('Payout alerts'),
            value: _payoutAlerts,
            onChanged: (value) {
              setState(() => _payoutAlerts = value);
              _save();
            },
          ),
          SwitchListTile(
            title: const Text('Group announcements'),
            value: _announcements,
            onChanged: (value) {
              setState(() => _announcements = value);
              _save();
            },
          ),
          SwitchListTile(
            title: const Text('Proposals & voting'),
            value: _proposalsVoting,
            onChanged: (value) {
              setState(() => _proposalsVoting = value);
              _save();
            },
          ),
          SwitchListTile(
            title: const Text('Security alerts'),
            value: _securityAlerts,
            onChanged: (value) {
              setState(() => _securityAlerts = value);
              _save();
            },
          ),
          const Divider(height: 32),
          Text('Market', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.flag_outlined),
            title: const Text('Country'),
            trailing: Text(
              AppConfig.countryName,
              style: theme.textTheme.emphasis,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.currency_exchange),
            title: const Text('Currency'),
            trailing: Text(
              '${AppConfig.currencyCode} ${AppConfig.currencySymbol}',
              style: theme.textTheme.emphasis,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.schedule_outlined),
            title: const Text('Timezone'),
            trailing: Text(AppConfig.timezone, style: theme.textTheme.caption),
          ),
          const Divider(height: 32),
          ListTile(
            leading: const Icon(Icons.storage_outlined),
            title: const Text('Data mode'),
            trailing: Text(
              AppEnvironment.useMockData ? 'Mock data' : 'Live API',
              style: theme.textTheme.emphasis,
            ),
          ),
        ],
      ),
    );
  }
}
