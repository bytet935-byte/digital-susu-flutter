/// Canonical roles and their default permission bundles (spec §5).
///
/// Authorization is permission-driven: roles are convenience bundles that map
/// to [Permissions]; a user's *effective permissions* = role bundles + any
/// explicit per-member grants/revocations. Checks always use permissions,
/// never roles alone.
abstract final class Roles {
  static const String member = 'MEMBER';
  static const String groupOwner = 'GROUP_OWNER';
  static const String admin = 'ADMIN';
  static const String treasurer = 'TREASURER';
  static const String moderator = 'MODERATOR';
  static const String systemAdmin = 'SYSTEM_ADMIN';
}
