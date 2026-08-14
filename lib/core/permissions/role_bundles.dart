import '../constants/permissions.dart';
import '../constants/roles.dart';

/// Default permission bundle per role (spec §5).
///
/// These are *starting points* — groups may grant/revoke individual
/// permissions per member. [PermissionResolver] combines role bundles with
/// explicit grants and revocations.
abstract final class RoleBundles {
  static final Set<String> _all = Permissions.all.toSet();

  static final Map<String, Set<String>> bundles = <String, Set<String>>{
    Roles.systemAdmin: _all,
    Roles.groupOwner: <String>{
      Permissions.manageGroup,
      Permissions.manageMembers,
      Permissions.manageSettings,
      Permissions.manageAnnouncements,
      Permissions.manageFinances,
      Permissions.viewFinances,
      Permissions.approvePayments,
      Permissions.createPayouts,
      Permissions.contribute,
      Permissions.createProposal,
      Permissions.vote,
      Permissions.moderateChat,
      Permissions.sendMessages,
      Permissions.viewReports,
      Permissions.exportRecords,
      Permissions.manageKyc,
    },
    Roles.admin: <String>{
      Permissions.manageGroup,
      Permissions.manageMembers,
      Permissions.manageAnnouncements,
      Permissions.manageFinances,
      Permissions.viewFinances,
      Permissions.approvePayments,
      Permissions.createPayouts,
      Permissions.contribute,
      Permissions.createProposal,
      Permissions.vote,
      Permissions.moderateChat,
      Permissions.sendMessages,
      Permissions.viewReports,
      Permissions.exportRecords,
    },
    Roles.treasurer: <String>{
      Permissions.manageFinances,
      Permissions.viewFinances,
      Permissions.createPayouts,
      Permissions.contribute,
      Permissions.vote,
      Permissions.sendMessages,
      Permissions.viewReports,
      Permissions.exportRecords,
    },
    Roles.moderator: <String>{
      Permissions.moderateChat,
      Permissions.sendMessages,
      Permissions.createProposal,
      Permissions.vote,
      Permissions.contribute,
    },
    Roles.member: <String>{
      Permissions.contribute,
      Permissions.sendMessages,
      Permissions.createProposal,
      Permissions.vote,
    },
  };
}
