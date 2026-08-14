import '../constants/permissions.dart';
import '../constants/roles.dart';
import 'role_bundles.dart';

/// Computes a user's effective permissions (spec §5, §27).
///
/// `effective = (union of role bundles) ∪ explicit grants − explicit
/// revocations`. System Administrators always receive every permission.
/// The backend remains the authority; this resolver mirrors the same rules
/// client-side for UI gating only.
abstract final class PermissionResolver {
  static Set<String> resolve({
    required Set<String> roles,
    Set<String> explicitGrants = const <String>{},
    Set<String> explicitRevocations = const <String>{},
  }) {
    final result = <String>{};
    for (final role in roles) {
      result.addAll(RoleBundles.bundles[role] ?? const <String>{});
    }
    result.addAll(explicitGrants);
    result.removeAll(explicitRevocations);

    if (roles.contains(Roles.systemAdmin)) {
      result.addAll(Permissions.all);
    }
    return result;
  }

  static bool hasPermission({
    required Set<String> effectivePermissions,
    required String permission,
  }) =>
      effectivePermissions.contains(permission);
}
