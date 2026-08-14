import 'package:equatable/equatable.dart';

/// Application user (spec §22).
///
/// `fromJson`/`toJson` are used by the session cache and API payloads.
class User extends Equatable {
  const User({
    required this.id,
    required this.fullName,
    required this.phone,
    this.email,
    this.profilePhotoUrl,
    this.kycStatus = 'NOT_STARTED',
    required this.createdAt,
  });

  final String id;
  final String fullName;
  final String phone;
  final String? email;
  final String? profilePhotoUrl;

  /// KYC state: NOT_STARTED / PENDING / VERIFIED / REJECTED / EXPIRED (spec §23).
  final String kycStatus;

  final DateTime createdAt;

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        fullName: json['full_name'] as String? ?? json['fullName'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        email: json['email'] as String?,
        profilePhotoUrl: json['profile_photo_url'] as String?,
        kycStatus: json['kyc_status'] as String? ?? 'NOT_STARTED',
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'full_name': fullName,
        'phone': phone,
        'email': email,
        'profile_photo_url': profilePhotoUrl,
        'kyc_status': kycStatus,
        'created_at': createdAt.toIso8601String(),
      };

  @override
  List<Object?> get props => <Object?>[
        id,
        fullName,
        phone,
        email,
        profilePhotoUrl,
        kycStatus,
        createdAt,
      ];
}
