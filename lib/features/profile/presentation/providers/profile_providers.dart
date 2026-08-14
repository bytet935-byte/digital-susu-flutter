import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/repository_selector.dart';
import '../../../../core/providers/network_providers.dart';
import '../data/api_profile_repository.dart';
import '../data/mock_profile_repository.dart';
import '../domain/profile_repository.dart';

/// Switches mock/API via USE_MOCK_DATA (spec §11).
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return selectRepository<ProfileRepository>(
    mock: MockProfileRepository(),
    api: ApiProfileRepository(ref.watch(apiClientProvider)),
  );
});
