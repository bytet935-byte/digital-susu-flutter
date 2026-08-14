import '../../../../core/utils/result.dart';
import '../../authentication/domain/models/user.dart';

/// Profile management contract (spec §22).
abstract interface class ProfileRepository {
  Future<Result<User>> updateProfile({
    required String fullName,
    required String phone,
    String? email,
  });
}
