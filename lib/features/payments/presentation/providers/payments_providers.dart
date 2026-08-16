import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/repository_selector.dart';
import '../../../../core/providers/network_providers.dart';
import '../../../../core/utils/result.dart';
import '../../data/api_payments_repository.dart';
import '../../data/mock_payments_repository.dart';
import '../../domain/payment_models.dart';
import '../../domain/payments_repository.dart';

/// Switches mock/API via USE_MOCK_DATA (spec §11).
final paymentsRepositoryProvider = Provider<PaymentsRepository>((ref) {
  return selectRepository<PaymentsRepository>(
    mock: MockPaymentsRepository(),
    api: ApiPaymentsRepository(ref.watch(apiClientProvider)),
  );
});

/// Loads the payments ledger; exposes refresh().
final paymentsProvider = AsyncNotifierProvider<PaymentsController, List<Payment>>(
  PaymentsController.new,
);

class PaymentsController extends AsyncNotifier<List<Payment>> {
  @override
  Future<List<Payment>> build() => _fetch();

  Future<List<Payment>> _fetch() async {
    final result = await ref.read(paymentsRepositoryProvider).getPayments();
    return switch (result) {
      Success<List<Payment>>(:final value) => value,
      Failure<List<Payment>>(:final error) => throw error,
    };
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }
}
