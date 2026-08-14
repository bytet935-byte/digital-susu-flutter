import 'package:equatable/equatable.dart';

/// App notification (spec §21).
class AppNotification extends Equatable {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    required this.createdAt,
    this.read = false,
  });

  final String id;
  final String title;
  final String body;

  /// Category values from AppConstants.notificationCategories:
  /// contribution_reminder, payment_confirmation, payout,
  /// missed_contribution, group_announcement, proposal,
  /// voting_reminder, transaction_alert, security_alert.
  final String category;
  final DateTime createdAt;
  final bool read;

  AppNotification copyWith({bool? read}) => AppNotification(
        id: id,
        title: title,
        body: body,
        category: category,
        createdAt: createdAt,
        read: read ?? this.read,
      );

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id'] as String,
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        category: json['category'] as String? ?? 'group_announcement',
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        read: json['read'] as bool? ?? false,
      );

  @override
  List<Object?> get props => <Object?>[
        id,
        title,
        body,
        category,
        createdAt,
        read,
      ];
}
