import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/models/money.dart';
import '../../../authentication/domain/models/user.dart';
import '../../domain/dashboard_models.dart';

/// Renders an amount in the design-reference "GHS 0.00" style (the React
/// home uses the ISO code rather than the ₵ symbol).
String _formatGhs(Money money) =>
    'GHS ${NumberFormat('#,##0.00').format(money.amountMajor)}';

// ---------------------------------------------------------------------------
// Blue app bar (design reference: Digital Susu home header)
// ---------------------------------------------------------------------------

/// Blue gradient header: brand logo, app name, notification bell with unread
/// badge and the profile avatar.
class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.unread,
    required this.onNotificationsTap,
    required this.onProfileTap,
    this.displayName,
  });

  final int unread;
  final VoidCallback onNotificationsTap;
  final VoidCallback onProfileTap;
  final String? displayName;

  String get _initials {
    final name = displayName?.trim() ?? '';
    if (name.isEmpty) return '';
    final parts = name.split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    final first = parts.isNotEmpty ? parts.first[0] : '';
    final last = parts.length > 1 ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 12, 20),
          child: Row(
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Text(
                  'D',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                AppConfig.appName,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: onNotificationsTap,
                tooltip: 'Notifications',
                icon: Badge(
                  isLabelVisible: unread > 0,
                  backgroundColor: AppColors.danger,
                  label: Text(
                    '$unread',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: const Icon(
                    Icons.notifications_outlined,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onProfileTap,
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.white.withValues(alpha: 0.25),
                  child: _initials.isEmpty
                      ? const Icon(Icons.person, color: Colors.white)
                      : Text(
                          _initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Greeting + KYC badge (design reference: "Hello, Kofi 👋" / "Verified")
// ---------------------------------------------------------------------------

/// "Hello, {first name} 👋" with a time-of-day subtitle and a KYC badge.
class GreetingSection extends StatelessWidget {
  const GreetingSection({super.key, this.user});

  final User? user;

  String get _firstName {
    final name = user?.fullName.trim() ?? '';
    if (name.isEmpty) return 'there';
    return name.split(RegExp(r'\s+')).first;
  }

  String _timeGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Hello, $_firstName 👋',
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: 4),
              Text(
                _timeGreeting(),
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        VerifiedBadge(verified: user?.kycStatus == 'VERIFIED'),
      ],
    );
  }
}

/// Blue pill badge — filled "Verified" for verified accounts, outline
/// "Verify" otherwise (design reference).
class VerifiedBadge extends StatelessWidget {
  const VerifiedBadge({super.key, required this.verified});

  final bool verified;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: verified ? AppColors.primary : AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            verified ? Icons.verified : Icons.verified_outlined,
            size: 14,
            color: verified ? Colors.white : AppColors.primary,
          ),
          const SizedBox(width: 4),
          Text(
            verified ? 'Verified' : 'Verify',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: verified ? Colors.white : AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Balance card (design reference: white card, eye toggle, "View Wallet >")
// ---------------------------------------------------------------------------

/// White balance card with a visibility toggle and a wallet shortcut.
class BalanceCard extends StatefulWidget {
  const BalanceCard({super.key, required this.balance, this.onViewWallet});

  final Money balance;
  final VoidCallback? onViewWallet;

  @override
  State<BalanceCard> createState() => _BalanceCardState();
}

class _BalanceCardState extends State<BalanceCard> {
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
              Text('Total Balance', style: theme.textTheme.bodyMedium),
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
              const Spacer(),
              TextButton(
                onPressed: widget.onViewWallet,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('View Wallet >'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _hidden ? 'GHS ••••' : _formatGhs(widget.balance),
            style: theme.textTheme.money.copyWith(
              fontSize: 28,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Quick money actions (design reference: + Top Up / Withdraw / Transfer)
// ---------------------------------------------------------------------------

class ActionButtons extends StatelessWidget {
  const ActionButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: FilledButton.icon(
            onPressed: () => context.go(AppRoutes.wallet),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Top Up'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => context.go(AppRoutes.wallet),
            icon: const Icon(Icons.arrow_upward, size: 18),
            label: const Text('Withdraw'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => context.go(AppRoutes.wallet),
            icon: const Icon(Icons.send, size: 18),
            label: const Text('Transfer'),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Grid menu (design reference: My Susu / Payments / Invite / History)
// ---------------------------------------------------------------------------

class QuickActions extends StatelessWidget {
  const QuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        _CircleAction(
          color: AppColors.primary,
          icon: Icons.autorenew,
          label: 'My Susu',
          onTap: () => context.go(AppRoutes.groups),
        ),
        _CircleAction(
          color: AppColors.quickPurple,
          icon: Icons.account_balance_wallet_outlined,
          label: 'Payments',
          onTap: () => context.go(AppRoutes.transactions),
        ),
        _CircleAction(
          color: AppColors.quickTeal,
          icon: Icons.person_add_alt_1_outlined,
          label: 'Invite',
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invite friends is coming soon'),
              behavior: SnackBarBehavior.floating,
            ),
          ),
        ),
        _CircleAction(
          color: AppColors.danger,
          icon: Icons.history,
          label: 'History',
          onTap: () => context.go(AppRoutes.transactions),
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
    required this.onTap,
  });

  final Color color;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

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
                fontSize: 12.5,
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
// Active susu card (design reference: Weekend Susu / Project Susu)
// ---------------------------------------------------------------------------

class SusuCard extends StatelessWidget {
  const SusuCard({super.key, required this.group, this.onTap});

  final DashboardGroup group;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isActive = group.status == 'ACTIVE';
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: <Widget>[
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.groups,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        group.name,
                        style: theme.textTheme.emphasis.copyWith(
                          fontSize: 15,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Group Susu • ${group.memberCount} Members',
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Next payout: ${group.nextPayout == null ? '—' : DateFormatter.formatDate(group.nextPayout!)}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Text(
                      _formatGhs(group.pot),
                      style: theme.textTheme.emphasis.copyWith(
                        fontSize: 15,
                        color: theme.colorScheme.onSurface,
                        fontFeatures: const <FontFeature>[
                          FontFeature.tabularFigures(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 5),
                    _StatusPill(active: isActive),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: active ? AppColors.secondaryContainer : AppColors.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        active ? 'Active' : 'Completed',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: active ? AppColors.success : AppColors.onSurfaceVariant,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Transaction row (green credits / red debits)
// ---------------------------------------------------------------------------

class TransactionTile extends StatelessWidget {
  const TransactionTile({super.key, required this.transaction});

  final DashboardTransaction transaction;

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
        _formatGhs(transaction.amount),
        style: theme.textTheme.emphasis.copyWith(color: amountColor),
      ),
    );
  }
}
