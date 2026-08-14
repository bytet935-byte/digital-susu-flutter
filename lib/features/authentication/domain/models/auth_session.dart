import 'package:equatable/equatable.dart';

import 'user.dart';

/// Authenticated session (spec §10): access + refresh tokens plus the user.
///
/// Tokens are persisted separately in secure storage (via `TokenStore`);
/// [toJson]/[fromJson] support caching the user profile.
class AuthSession extends Equatable {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  final String accessToken;
  final String refreshToken;
  final User user;

  factory AuthSession.fromJson(Map<String, dynamic> json) => AuthSession(
        accessToken: json['access_token'] as String,
        refreshToken: json['refresh_token'] as String? ?? '',
        user: User.fromJson(json['user'] as Map<String, dynamic>),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'access_token': accessToken,
        'refresh_token': refreshToken,
        'user': user.toJson(),
      };

  @override
  List<Object?> get props => <Object?>[accessToken, refreshToken, user];
}
