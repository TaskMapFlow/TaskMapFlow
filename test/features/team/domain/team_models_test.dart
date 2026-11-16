import 'package:flutter_test/flutter_test.dart';
import 'package:task_map_flow/features/team/domain/models/member_role.dart';
import 'package:task_map_flow/features/team/domain/models/workspace_invite.dart';
import 'package:task_map_flow/features/team/domain/models/workspace_member.dart';

void main() {
  group('MemberRole Tests', () {
    test('fromString parses correctly and falls back to member', () {
      expect(MemberRole.fromString('owner'), MemberRole.owner);
      expect(MemberRole.fromString('ADMIN'), MemberRole.admin);
      expect(MemberRole.fromString('member'), MemberRole.member);
      expect(MemberRole.fromString('unknown'), MemberRole.member);
      expect(MemberRole.fromString(null), MemberRole.member);
    });

    test('role permission getters work as expected', () {
      expect(MemberRole.owner.isOwner, isTrue);
      expect(MemberRole.owner.canManageTeam, isTrue);
      expect(MemberRole.owner.canManageInvites, isTrue);

      expect(MemberRole.admin.isAdmin, isTrue);
      expect(MemberRole.admin.canManageTeam, isTrue);
      expect(MemberRole.admin.canManageInvites, isTrue);

      expect(MemberRole.member.isMember, isTrue);
      expect(MemberRole.member.canManageTeam, isFalse);
      expect(MemberRole.member.canManageInvites, isFalse);
    });
  });

  group('WorkspaceMember Tests', () {
    test('initials generator returns correct uppercase initials', () {
      final now = DateTime.now();
      final m1 = WorkspaceMember(
        id: 'u1',
        workspaceId: 'ws1',
        displayName: 'Doğukan Şendoğan',
        role: MemberRole.owner,
        joinedAt: now,
        updatedAt: now,
      );
      expect(m1.initials, 'DŞ');
      expect(m1.userId, 'u1');

      final m2 = m1.copyWith(displayName: 'Ada');
      expect(m2.initials, 'A');

      final m3 = m1.copyWith(displayName: '');
      expect(m3.initials, '?');
    });

    test('equality and copyWith work properly', () {
      final now = DateTime.now();
      final m1 = WorkspaceMember(
        id: 'u1',
        workspaceId: 'ws1',
        displayName: 'Doğukan',
        role: MemberRole.owner,
        joinedAt: now,
        updatedAt: now,
      );
      final m2 = WorkspaceMember(
        id: 'u1',
        workspaceId: 'ws1',
        displayName: 'Doğukan',
        role: MemberRole.owner,
        joinedAt: now,
        updatedAt: now,
      );
      expect(m1, equals(m2));

      final updated = m1.copyWith(role: MemberRole.admin);
      expect(updated.role, MemberRole.admin);
      expect(m1.role, MemberRole.owner);
    });
  });

  group('WorkspaceInvite Tests', () {
    test('validity and expiration checks', () {
      final now = DateTime.now();
      final validInvite = WorkspaceInvite(
        id: 'inv_1',
        workspaceId: 'ws1',
        workspaceName: 'Proje',
        code: 'ABCD1234',
        role: MemberRole.member,
        creatorId: 'u1',
        expiresAt: now.add(const Duration(days: 7)),
        createdAt: now,
      );
      expect(validInvite.isValid, isTrue);
      expect(validInvite.isExpired, isFalse);

      final expiredInvite = WorkspaceInvite(
        id: 'inv_2',
        workspaceId: 'ws1',
        workspaceName: 'Proje',
        code: 'ABCD1234',
        role: MemberRole.member,
        creatorId: 'u1',
        expiresAt: now.subtract(const Duration(days: 1)),
        createdAt: now.subtract(const Duration(days: 8)),
      );
      expect(expiredInvite.isValid, isFalse);
      expect(expiredInvite.isExpired, isTrue);

      final revokedInvite = WorkspaceInvite(
        id: 'inv_3',
        workspaceId: 'ws1',
        workspaceName: 'Proje',
        code: 'ABCD1234',
        role: MemberRole.member,
        creatorId: 'u1',
        expiresAt: now.add(const Duration(days: 7)),
        isRevoked: true,
        createdAt: now,
      );
      expect(revokedInvite.isValid, isFalse);
    });
  });
}
