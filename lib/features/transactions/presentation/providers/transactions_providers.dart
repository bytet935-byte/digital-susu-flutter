import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/repository_selector.dart';
import '../../../../core/providers/network_providers.dart';
import '../../../../core/utils/result.dart';
import '../../data/api_transactions_repository.dart';
import '../../data/mock_transactions_repository.dart';
import '../../domain/app_transaction.dart';
import '../../domain/transactions_repository.dart';
/// Switches mock/API via USE_MOCK_DATA (spec §11).
final transactionsRepositoryProvider = Provider<TransactionsRepository>(
  (ref) => selectRepository<TransactionsRepository>(
    mock: MockTransactionsRepository(),
    api: ApiTransactionsRepository(ref.watch(apiClientProvider)),
  ),
);

/// Loads the transaction history (spec §14).
final transactionsProvider =
    AsyncNotifierProvider<TransactionsController, List<AppTransaction>>(
  TransactionsController.new,
);

class TransactionsController extends AsyncNotifier<List<AppTransaction>> {
  @override
  Future<List<AppTransaction>> build() => _fetch();

  Future<List<AppTransaction>> _fetch() async {
    final result = await ref.read(transactionsRepositoryProvider).getTransactions();
    return switch (result) {
      Success<List<AppTransaction>>(:final value) => value,
      Failure<List<AppTransaction>>(:final error) => throw error,
    };
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }
}
