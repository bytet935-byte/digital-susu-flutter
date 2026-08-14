import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';

/// Application shell with the design-reference bottom navigation:
/// Home · Groups · [+] · Wallet · Profile (spec §31).
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

  void _createSusu(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Create Susu arrives in Phase 5')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: _BottomBar(
        currentIndex: navigationShell.currentIndex,
        onSelect: _goBranch,
        onCreate: () => _createSusu(context),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.currentIndex,
    required this.onSelect,
    required this.onCreate,
  });

  final int currentIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
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
            // Centre create action.
            GestureDetector(
              onTap: onCreate,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: <Color>[AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 30),
              ),
            ),
            _NavItem(
              icon: Icons.account_balance_wallet_outlined,
              selectedIcon: Icons.account_balance_wallet,
              label: 'Wallet',
              selected: currentIndex == 2,
              onTap: () => onSelect(2),
            ),
            _NavItem(
              icon: Icons.person_outline,
              selectedIcon: Icons.person,
              label: 'Profile',
              selected: currentIndex == 3,
              onTap: () => onSelect(3),
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
