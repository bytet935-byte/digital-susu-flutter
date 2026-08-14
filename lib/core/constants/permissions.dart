/// Canonical permission identifiers (spec §5).
///
/// Authorization is permission-driven: a user's *effective permissions* decide
/// what they may do. Roles (Member, Group Owner, Admin, Treasurer, Moderator,
/// System Administrator) are merely bundles of permissions assigned at
/// group/system level — the backend and app both check permissions, never
/// roles alone.
///
/// These constants are the single source of truth shared by the permission
/// resolver (Phase 3/5) and all feature-level guards.
abstract final class Permissions {
  // ---------------------------------------------------------------------------
  // Group & members
  // ---------------------------------------------------------------------------
  static const String manageMembers = 'MANAGE_MEMBERS';
  static const String manageGroup = 'MANAGE_GROUP';
  static const String manageSettings = 'MANAGE_SETTINGS';
  static const String manageAnnouncements = 'MANAGE_ANNOUNCEMENTS';

  // ---------------------------------------------------------------------------
  // Finance
  // ---------------------------------------------------------------------------
  static const String manageFinances = 'MANAGE_FINANCES';
  static const String viewFinances = 'VIEW_FINANCES';
  static const String approvePayments = 'APPROVE_PAYMENTS';
  static const String contribute = 'CONTRIBUTE';
  static const String createPayouts = 'CREATE_PAYOUTS';

  // ---------------------------------------------------------------------------
  // Governance & communication
  // ---------------------------------------------------------------------------
  static const String createProposal = 'CREATE_PROPOSAL';
  static const String vote = 'VOTE';
  static const String moderateChat = 'MODERATE_CHAT';
  static const String sendMessages = 'SEND_MESSAGES';

  // ---------------------------------------------------------------------------
  // Reporting & KYC
  // ---------------------------------------------------------------------------
  static const String viewReports = 'VIEW_REPORTS';
  static const String exportRecords = 'EXPORT_RECORDS';
  static const String manageKyc = 'MANAGE_KYC';

  // ---------------------------------------------------------------------------
  // System (reserved for System Administrator)
  // ---------------------------------------------------------------------------
  static const String manageUsers = 'MANAGE_USERS';
  static const String manageSystem = 'MANAGE_SYSTEM';

  /// All known permissions, used for validation and role-bundle definitions.
  static const List<String> all = <String>[
    manageMembers,
    manageGroup,
    manageSettings,
    manageAnnouncements,
    manageFinances,
    viewFinances,
    approvePayments,
    contribute,
    createPayouts,
    createProposal,
    vote,
    moderateChat,
    sendMessages,
    viewReports,
    exportRecords,
    manageKyc,
    manageUsers,
    manageSystem,
  ];
}
