import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/result.dart';
import '../../../../shared/models/money.dart';
import '../../../groups/domain/group_models.dart';
import '../../../groups/presentation/providers/groups_providers.dart';

/// Contribution controller keyed by groupId (spec §9). `build` starts with
/// no receipt; [contribute] publishes the receipt on success.
final contributeProvider =
    AsyncNotifierProvider.family<ContributeController, GroupContribution?, String>(
  ContributeController.new,
);

class ContributeController
    extends FamilyAsyncNotifier<GroupContribution?, String> {
  @override
  Future<GroupContribution?> build(String arg) async => null;

  /// Returns `true` on success so the sheet can confirm and close.
  Future<bool> contribute({
    required String groupId,
    required Money amount,
    required String paymentMethod,
  }) async {
    state = const AsyncLoading();
    final result = await ref.read(groupsRepositoryProvider).contribute(
          groupId: groupId,
          amount: amount,
          paymentMethod: paymentMethod,
          idempotencyKey:
              'contrib_${DateTime.now().millisecondsSinceEpoch}_$groupId',
        );
    return switch (result) {
      Success<GroupContribution>(:final value) => _applyData(value),
      Failure<GroupContribution>(:final error) => _applyError(error),
    };
  }

  bool _applyData(GroupContribution value) {
    state = AsyncData<GroupContribution?>(value);
    return true;
  }

  bool _applyError(Object error) {
    state = AsyncError<GroupContribution?>(error, StackTrace.current);
    return false;
  }
}
