import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/repository_selector.dart';
import '../../../../core/providers/network_providers.dart';
import '../../../../core/utils/result.dart';
import '../../../../shared/models/money.dart';
import '../../data/api_wallet_repository.dart';
import '../../data/mock_wallet_repository.dart';
import '../../domain/wallet_models.dart';
import '../../domain/wallet_repository.dart';

/// Switches mock/API via USE_MOCK_DATA (spec §11).
final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  return selectRepository<WalletRepository>(
    mock: MockWalletRepository(),
    api: ApiWalletRepository(ref.watch(apiClientProvider)),
  );
});

/// Loads the personal wallet summary; exposes refresh / topUp / withdraw.
final walletSummaryProvider =
    AsyncNotifierProvider<WalletSummaryController, WalletSummary>(
  WalletSummaryController.new,
);

class WalletSummaryController extends AsyncNotifier<WalletSummary> {
  @override
  Future<WalletSummary> build() => _fetch();

  Future<WalletSummary> _fetch() async {
    final result = await ref.read(walletRepositoryProvider).getSummary();
    return switch (result) {
      Success<WalletSummary>(:final value) => value,
      Failure<WalletSummary>(:final error) => throw error,
    };
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  /// Returns `true` on success so callers can confirm with a snackbar.
  Future<bool> topUp(Money amount) async {
    final result = await ref.read(walletRepositoryProvider).topUp(amount);
    return _apply(result);
  }

  /// Returns `true` on success so callers can confirm with a snackbar.
  Future<bool> withdraw(Money amount) async {
    final result = await ref.read(walletRepositoryProvider).withdraw(amount);
    return _apply(result);
  }

  bool _apply(Result<WalletSummary> result) {
    return switch (result) {
      Success<WalletSummary>(:final value) => _applyData(value),
      Failure<WalletSummary>(:final error) => _applyError(error),
    };
  }

  bool _applyData(WalletSummary value) {
    state = AsyncData<WalletSummary>(value);
    return true;
  }

  bool _applyError(Object error) {
    state = AsyncError<WalletSummary>(error, StackTrace.current);
    return false;
  }
}
