import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../../../shared/widgets/app_states.dart';
import '../../domain/group_models.dart';
import '../providers/groups_providers.dart';

/// Governance tab (build spec §16, design reference "Group Chat" area):
/// open proposals with per-option vote bars and one-vote-per-member action.
class GroupProposalsTab extends ConsumerWidget {
  const GroupProposalsTab({super.key, required this.groupId});

  final String groupId;

  Future<void> _vote(
    BuildContext context,
    WidgetRef ref,
    GroupProposal proposal,
    String option,
  ) async {
    final ok = await ref
        .read(groupProposalsProvider(groupId).notifier)
        .vote(groupId: groupId, proposalId: proposal.id, option: option);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Vote recorded' : 'Voting failed. Please try again.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final proposalsAsync = ref.watch(groupProposalsProvider(groupId));
    return proposalsAsync.when(
      loading: () => const AppLoadingView(message: 'Loading proposals…'),
      error: (error, stackTrace) => AppErrorState(
        onRetry: () => ref.invalidate(groupProposalsProvider(groupId)),
      ),
      data: (proposals) {
        if (proposals.isEmpty) {
          return const AppEmptyState(
            title: 'No proposals yet',
            message: 'Proposals let members vote on group decisions.',
            icon: Icons.how_to_vote_outlined,
          );
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            ...proposals.map(
              (GroupProposal proposal) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ProposalCard(
                  proposal: proposal,
                  onVote: (String option) =>
                      _vote(context, ref, proposal, option),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ProposalCard extends StatelessWidget {
  const _ProposalCard({required this.proposal, required this.onVote});

  final GroupProposal proposal;
  final ValueChanged<String> onVote;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
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
              Expanded(
                child: Text(proposal.title, style: theme.textTheme.emphasis),
              ),
              const SizedBox(width: 8),
              _StatusChip(status: proposal.status),
            ],
          ),
          if (proposal.description.isNotEmpty) ...<Widget>[
            const SizedBox(height: 6),
            Text(proposal.description, style: theme.textTheme.bodyMedium),
          ],
          const SizedBox(height: 4),
          Text(
            'Proposed by ${proposal.createdByName ?? '—'} · '
            '${DateFormatter.formatDate(proposal.createdAt)}',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          for (final String option in proposal.options)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(option, style: theme.textTheme.bodyMedium),
                      Text(
                        '${proposal.votes[option] ?? 0} votes',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: proposal.totalVotes == 0
                          ? 0
                          : (proposal.votes[option] ?? 0) /
                              proposal.totalVotes,
                      minHeight: 6,
                      backgroundColor: AppColors.background,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          if (proposal.isOpen && proposal.myVote == null) ...<Widget>[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: proposal.options
                  .map(
                    (String option) => option == 'Approve'
                        ? FilledButton.tonalIcon(
                            onPressed: () => onVote(option),
                            icon: const Icon(Icons.thumb_up_alt_outlined,
                                size: 16),
                            label: Text(option),
                          )
                        : OutlinedButton.icon(
                            onPressed: () => onVote(option),
                            icon: const Icon(Icons.thumb_down_alt_outlined,
                                size: 16),
                            label: Text(option),
                          ),
                  )
                  .toList(),
            ),
          ],
          if (proposal.myVote != null) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              'You voted: ${proposal.myVote}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (proposal.votingEnds != null) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              proposal.isOpen
                  ? 'Voting ends ${DateFormatter.formatDate(proposal.votingEnds!)}'
                  : 'Voting ended ${DateFormatter.formatDate(proposal.votingEnds!)}',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (String label, Color color, Color background) = switch (status) {
      ProposalStatuses.passed => ('Passed', AppColors.success, AppColors.secondaryContainer),
      ProposalStatuses.rejected => ('Rejected', AppColors.danger, const Color(0xFFFEE2E2)),
      _ => ('Open', AppColors.primary, AppColors.primaryContainer),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
