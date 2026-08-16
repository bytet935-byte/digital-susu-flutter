import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/routing/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../features/calculator/presentation/susu_calculator_sheet.dart';
import '../../features/ussd/presentation/ussd_simulator.dart';

/// Application shell with the design-reference navigation (spec §21, §31):
/// Home · Groups · [+] · Wallet · Profile.
///
/// **Responsive (spec §19):** narrow screens use the bottom navigation bar;
/// wide screens (tablet/desktop ≥ 840dp) switch to a [NavigationRail] so the
/// extra space is used intelligently instead of stretching the mobile layout.
///
/// Uses [StatefulNavigationShell] (indexed stack) so each tab keeps its own
/// scroll/state. The centre "+" is the create-susu action (Phase 5).
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  /// Quick-action hub (spec): Deposit, Create Susu, Susu Calculator and
  /// USSD Mode, surfaced from the FAB / centre "+".
  void _openHub(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.add_circle_outline),
              title: const Text('Deposit'),
              subtitle: const Text('Add money to your wallet'),
              onTap: () {
                Navigator.of(context).pop();
                context.go(AppRoutes.wallet);
              },
            ),
            ListTile(
              leading: const Icon(Icons.groups_outlined),
              title: const Text('Create Susu'),
              subtitle: const Text('Start a new savings group'),
              onTap: () {
                Navigator.of(context).pop();
                context.go(AppRoutes.groupCreate);
              },
            ),
            ListTile(
              leading: const Icon(Icons.calculate_outlined),
              title: const Text('Susu Calculator'),
              subtitle: const Text('Estimate pots and cycles'),
              onTap: () {
                Navigator.of(context).pop();
                showSusuCalculatorSheet(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.phone_android),
              title: const Text('USSD Mode'),
              subtitle: const Text('Use the app without a smartphone'),
              onTap: () {
                Navigator.of(context).pop();
                showUssdSimulator(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 840) {
          return _DesktopShell(
            currentIndex: navigationShell.currentIndex,
            onSelect: _goBranch,
            onCreate: () => _openHub(context),
            body: navigationShell,
          );
        }
        return Scaffold(
          body: navigationShell,
          floatingActionButton: FloatingActionButton(
            onPressed: () => _openHub(context),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            tooltip: 'Quick actions',
            child: const Icon(Icons.add),
          ),
          bottomNavigationBar: _BottomBar(
            currentIndex: navigationShell.currentIndex,
            onSelect: _goBranch,
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Desktop / tablet layout: NavigationRail + body (spec §19, §21)
// ---------------------------------------------------------------------------

class _DesktopShell extends StatelessWidget {
  const _DesktopShell({
    required this.currentIndex,
    required this.onSelect,
    required this.onCreate,
    required this.body,
  });

  final int currentIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onCreate;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: <Widget>[
          NavigationRail(
            selectedIndex: currentIndex,
            onDestinationSelected: onSelect,
            labelType: NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 16),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'D',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            destinations: const <NavigationRailDestination>[
              NavigationRailDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: Text('Home'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.groups_outlined),
                selectedIcon: Icon(Icons.groups),
                label: Text('Groups'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.chat_bubble_outline),
                selectedIcon: Icon(Icons.chat_bubble),
                label: Text('Chats'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.account_balance_wallet_outlined),
                selectedIcon: Icon(Icons.account_balance_wallet),
                label: Text('Wallet'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: Text('Profile'),
              ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: body),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: onCreate,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Mobile layout: bottom navigation bar (design reference)
// ---------------------------------------------------------------------------

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.currentIndex,
    required this.onSelect,
  });

  final int currentIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.outline)),
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            _NavItem(
              icon: Icons.home_outlined,
              selectedIcon: Icons.home,
              label: 'Home',
              selected: currentIndex == 0,
              onTap: () => onSelect(0),
            ),
            _NavItem(
              icon: Icons.groups_outlined,
              selectedIcon: Icons.groups,
              label: 'Groups',
              selected: currentIndex == 1,
              onTap: () => onSelect(1),
            ),
            // Chats sits in the centre of the nav (spec: Chat tab).
            _NavItem(
              icon: Icons.chat_bubble_outline,
              selectedIcon: Icons.chat_bubble,
              label: 'Chats',
              selected: currentIndex == 2,
              onTap: () => onSelect(2),
            ),
            _NavItem(
              icon: Icons.account_balance_wallet_outlined,
              selectedIcon: Icons.account_balance_wallet,
              label: 'Wallet',
              selected: currentIndex == 3,
              onTap: () => onSelect(3),
            ),
            _NavItem(
              icon: Icons.person_outline,
              selectedIcon: Icons.person,
              label: 'Profile',
              selected: currentIndex == 4,
              onTap: () => onSelect(4),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.onSurfaceVariant;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(selected ? selectedIcon : icon, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
