import 'package:flutter_test/flutter_test.dart';
import 'package:digital_susu/core/constants/permissions.dart';
import 'package:digital_susu/core/constants/roles.dart';
import 'package:digital_susu/core/permissions/permission_resolver.dart';

void main() {
  group('PermissionResolver — effective permissions (spec §5)', () {
    test('member bundle is minimal', () {
      final perms = PermissionResolver.resolve(roles: <String>{Roles.member});
      expect(perms, containsAll(<String>[
        Permissions.contribute,
        Permissions.sendMessages,
        Permissions.createProposal,
        Permissions.vote,
      ]));
      expect(perms, isNot(contains(Permissions.manageFinances)));
      expect(perms, isNot(contains(Permissions.manageMembers)));
    });

    test('group owner bundle covers group and finance management', () {
      final perms =
          PermissionResolver.resolve(roles: <String>{Roles.groupOwner});
      expect(perms, containsAll(<String>[
        Permissions.manageGroup,
        Permissions.manageMembers,
        Permissions.manageFinances,
        Permissions.approvePayments,
        Permissions.viewReports,
        Permissions.exportRecords,
      ]));
    });

    test('treasurer manages finances but not members', () {
      final perms =
          PermissionResolver.resolve(roles: <String>{Roles.treasurer});
      expect(perms, contains(Permissions.manageFinances));
      expect(perms, contains(Permissions.createPayouts));
      expect(perms, isNot(contains(Permissions.manageMembers)));
    });

    test('system admin receives every permission', () {
      final perms =
          PermissionResolver.resolve(roles: <String>{Roles.systemAdmin});
      for (final permission in Permissions.all) {
        expect(perms, contains(permission));
      }
    });

    test('explicit grants add permissions beyond roles', () {
      final perms = PermissionResolver.resolve(
        roles: <String>{Roles.member},
        explicitGrants: <String>{Permissions.manageFinances},
      );
      expect(perms, contains(Permissions.manageFinances));
    });

    test('explicit revocations remove permissions', () {
      final perms = PermissionResolver.resolve(
        roles: <String>{Roles.groupOwner},
        explicitRevocations: <String>{Permissions.manageMembers},
      );
      expect(perms, isNot(contains(Permissions.manageMembers)));
    });

    test('hasPermission helper', () {
      final perms = PermissionResolver.resolve(roles: <String>{Roles.member});
      expect(
        PermissionResolver.hasPermission(
          effectivePermissions: perms,
          permission: Permissions.vote,
        ),
        isTrue,
      );
      expect(
        PermissionResolver.hasPermission(
          effectivePermissions: perms,
          permission: Permissions.approvePayments,
        ),
        isFalse,
      );
    });
  });
}
