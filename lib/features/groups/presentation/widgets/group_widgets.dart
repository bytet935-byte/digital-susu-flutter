import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../domain/group_models.dart';
/// Reusable group card (spec §21 component system; design reference "My
/// Susu" list): name, type label, pot, member count, next payout, status.
class GroupCard extends StatelessWidget {
  const GroupCard({super.key, required this.group, this.onTap});

  final SusuGroup group;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      CircleAvatar(
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Text(
                          group.name.isNotEmpty
                              ? group.name[0].toUpperCase()
                              : 'S',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(group.name, style: theme.textTheme.titleMedium),
                          Text(
                            GroupTypes.label(group.type),
                            style: theme.textTheme.caption,
                          ),
                        ],
                      ),
                    ],
                  ),
                  StatusBadge(status: group.status),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  _Metric(
                    label: 'Pot',
                    value: group.pot.format(),
                    color: AppColors.primary,
                  ),
                  _Metric(
                    label: 'Members',
                    value: '${group.memberCount}',
                  ),
                  _Metric(
                    label: 'Next payout',
                    value: group.nextPayout == null
                        ? '—'
                        : DateFormatter.formatDate(group.nextPayout!),
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

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: theme.textTheme.caption),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.emphasis.copyWith(
            color: color ?? theme.colorScheme.onSurface,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
