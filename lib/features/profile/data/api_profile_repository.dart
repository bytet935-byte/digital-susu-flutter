import '../../../core/errors/app_exception.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/utils/result.dart';
import '../../authentication/domain/models/user.dart';
import '../domain/profile_repository.dart';

/// Real-backend profile repository: PUT /users/me.
class ApiProfileRepository implements ProfileRepository {
  ApiProfileRepository(this._client);

  final ApiClient _client;

  @override
  Future<Result<User>> updateProfile({
    required String fullName,
    required String phone,
    String? email,
  }) async {
    try {
      final data = await _client.putMap(
        ApiEndpoints.me,
        data: <String, dynamic>{
          'full_name': fullName,
          'phone': phone,
          if (email != null && email.isNotEmpty) 'email': email,
        },
      );
      return Success<User>(User.fromJson(data));
    } on AppException catch (error) {
      return Failure<User>(error);
    }
  }
}
