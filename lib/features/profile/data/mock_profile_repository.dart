import '../../../core/utils/result.dart';
import '../../authentication/domain/models/user.dart';
import '../domain/profile_repository.dart';

/// In-memory profile updates for demo mode.
class MockProfileRepository implements ProfileRepository {
  @override
  Future<Result<User>> updateProfile({
    required String fullName,
    required String phone,
    String? email,
  }) async {
    final user = User(
      id: 'usr_kwame',
      fullName: fullName.trim(),
      phone: phone.trim(),
      email: email?.trim().isEmpty ?? true ? null : email!.trim(),
      kycStatus: 'PENDING',
      createdAt: DateTime(2026, 1, 15),
    );
    return Success<User>(user);
  }
}
