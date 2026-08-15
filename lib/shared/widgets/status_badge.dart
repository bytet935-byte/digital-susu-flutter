import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Reusable status badge (spec §21 component system).
///
/// Status is conveyed by text AND colour — never by colour alone (spec §28).
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final String status;

  static const Map<String, (String, Color)> _labels = <String, (String, Color)>{
    'SUCCESSFUL': ('Successful', AppColors.success),
    'PENDING': ('Pending', AppColors.warning),
    'FAILED': ('Failed', AppColors.danger),
    'REVERSED': ('Reversed', AppColors.onSurfaceVariant),
    'ACTIVE': ('Active', AppColors.success),
    'UPCOMING': ('Upcoming', AppColors.info),
    'COMPLETED': ('Completed', AppColors.onSurfaceVariant),
    'PAUSED': ('Paused', AppColors.warning),
  };

  @override
  Widget build(BuildContext context) {
    final (label, color) = _labels[status] ?? (status, AppColors.onSurfaceVariant);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, color: color)),
    );
  }
}
