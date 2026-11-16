import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_map_flow/core/extensions/context_extensions.dart';
import 'package:task_map_flow/core/result/result.dart';
import 'package:task_map_flow/features/auth/domain/models/auth_state.dart';
import 'package:task_map_flow/features/auth/presentation/providers/auth_providers.dart';
import 'package:task_map_flow/features/team/domain/models/member_role.dart';
import 'package:task_map_flow/features/team/domain/models/workspace_member.dart';
import 'package:task_map_flow/features/team/presentation/providers/team_providers.dart';
import 'package:task_map_flow/features/workspaces/domain/models/workspace.dart';
import 'package:task_map_flow/features/workspaces/presentation/providers/workspace_providers.dart';

class WorkspaceTeamSection extends ConsumerStatefulWidget {
  const WorkspaceTeamSection({
    super.key,
    required this.workspace,
    required this.isDark,
    required this.cardBg,
    required this.cardBorder,
    required this.textPrimary,
    required this.textSecondary,
    required this.purple,
    required this.inputBg,
    required this.isReadOnly,
  });

  final Workspace workspace;
  final bool isDark;
  final Color cardBg;
  final Color cardBorder;
  final Color textPrimary;
  final Color textSecondary;
  final Color purple;
  final Color inputBg;
  final bool isReadOnly;

  @override
  ConsumerState<WorkspaceTeamSection> createState() =>
      _WorkspaceTeamSectionState();
}

class _WorkspaceTeamSectionState extends ConsumerState<WorkspaceTeamSection> {
  bool _isEnabling = false;

  Future<void> _handleEnableTeam() async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.enableTeamTitle),
        content: Text(l10n.enableTeamDescription),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: widget.purple),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.enableTeamButton),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isEnabling = true);

    final uid = ref.read(currentUserIdProvider) ?? '';
    final authStatus = ref.read(authStatusProvider);
    final displayName = switch (authStatus) {
      AuthAuthenticated(:final user) => user.displayName ??
          (user.email != null && user.email!.isNotEmpty
              ? user.email!.split('@').first
              : 'Kullanıcı'),
      AuthGuest(:final user) => user.displayName ?? 'Misafir',
      AuthUnverified(:final user) => user.displayName ??
          (user.email != null && user.email!.isNotEmpty
              ? user.email!.split('@').first
              : 'Kullanıcı'),
      _ => 'Alan Sahibi',
    };

    final repo = ref.read(teamRepositoryProvider);
    final result = await repo.enableTeamWork(
      workspaceId: widget.workspace.id,
      ownerUid: uid,
      ownerDisplayName: displayName,
    );

    if (mounted) {
      setState(() => _isEnabling = false);
      if (result case Success()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.teamEnabledSuccess)),
        );
      } else if (result case Err(:final failure)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failure.message),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _showInviteDialog() async {
    final l10n = context.l10n;
    final uid = ref.read(currentUserIdProvider) ?? '';
    final repo = ref.read(teamRepositoryProvider);

    // Show loading dialog
    if (!mounted) return;
    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      ),
    );

    final result = await repo.createInvite(
      workspaceId: widget.workspace.id,
      creatorUid: uid,
    );

    if (!mounted) return;
    Navigator.of(context).pop(); // Close loading

    if (result case Success(:final value)) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.vpn_key_rounded, color: widget.purple),
              const SizedBox(width: 8),
              Text(l10n.inviteCodeTitle),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.inviteCodeDescription,
                style: TextStyle(color: widget.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: widget.purple.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: widget.purple.withValues(alpha: 0.3)),
                ),
                child: Center(
                  child: SelectableText(
                    value.code,
                    style: TextStyle(
                      color: widget.purple,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 4,
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n.cancel),
            ),
            FilledButton.icon(
              icon: const Icon(Icons.copy_rounded, size: 16),
              label: Text(l10n.copyCode),
              style: FilledButton.styleFrom(backgroundColor: widget.purple),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: value.code));
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.codeCopied)),
                );
              },
            ),
          ],
        ),
      );
    } else if (result case Err(:final failure)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(failure.message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _updateMemberRole(
      WorkspaceMember member, MemberRole newRole) async {
    final repo = ref.read(teamRepositoryProvider);
    final result = await repo.updateMemberRole(
      workspaceId: widget.workspace.id,
      targetUid: member.userId,
      newRole: newRole,
    );
    if (result case Err(:final failure)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failure.message),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _removeMember(WorkspaceMember member) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.removeMember),
        content: Text(l10n.removeMemberConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.removeMember),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final repo = ref.read(teamRepositoryProvider);
    final result = await repo.removeMember(
      workspaceId: widget.workspace.id,
      targetUid: member.userId,
    );
    if (result case Err(:final failure)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failure.message),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _leaveTeam() async {
    final l10n = context.l10n;
    final uid = ref.read(currentUserIdProvider) ?? '';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.leaveTeam),
        content: Text(l10n.leaveTeamConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.leaveTeam),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final repo = ref.read(teamRepositoryProvider);
    final result = await repo.leaveTeam(
      workspaceId: widget.workspace.id,
      userUid: uid,
    );
    if (mounted) {
      if (result case Success()) {
        Navigator.of(context).pop(); // Back to list
      } else if (result case Err(:final failure)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failure.message),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final uid = ref.watch(currentUserIdProvider) ?? '';
    final isOwner = widget.workspace.ownerId == uid;

    // Not enabled state
    if (!widget.workspace.isTeamEnabled) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: widget.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: widget.cardBorder),
        ),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: widget.purple.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.groups_rounded, size: 28, color: widget.purple),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.enableTeamTitle,
              style: TextStyle(
                color: widget.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.enableTeamDescription,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: widget.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            if (isOwner && !widget.isReadOnly)
              FilledButton.icon(
                icon: _isEnabling
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.rocket_launch_rounded, size: 16),
                label: Text(l10n.enableTeamButton),
                style: FilledButton.styleFrom(
                  backgroundColor: widget.purple,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isEnabling ? null : _handleEnableTeam,
              ),
          ],
        ),
      );
    }

    final membersAsync =
        ref.watch(workspaceMembersStreamProvider(widget.workspace.id));
    final currentRoleAsync =
        ref.watch(currentUserMemberRoleProvider(widget.workspace.id));
    final callerRole = currentRoleAsync.valueOrNull ??
        (isOwner ? MemberRole.owner : MemberRole.member);

    return membersAsync.when(
      loading: () => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: CircularProgressIndicator(color: widget.purple),
        ),
      ),
      error: (err, _) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: widget.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: widget.cardBorder),
        ),
        child: Text(err.toString(),
            style: TextStyle(color: Theme.of(context).colorScheme.error)),
      ),
      data: (members) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Invite button
            Row(
              children: [
                Text(
                  '${l10n.membersTitle} (${members.length})',
                  style: TextStyle(
                    color: widget.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                if (callerRole.canManageInvites && !widget.isReadOnly)
                  FilledButton.icon(
                    icon: const Icon(Icons.person_add_rounded, size: 15),
                    label: Text(l10n.inviteMember),
                    style: FilledButton.styleFrom(
                      backgroundColor: widget.purple,
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _showInviteDialog,
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Members List
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: members.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final member = members[index];
                final isSelf = member.userId == uid;
                final isMemberOwner = member.role == MemberRole.owner;

                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: widget.cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: widget.cardBorder),
                  ),
                  child: Row(
                    children: [
                      // Avatar with initials
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isMemberOwner
                              ? widget.purple
                              : (member.role == MemberRole.admin
                                  ? const Color(0xFF38BDF8)
                                  : (widget.isDark
                                      ? const Color(0xFF2E2B3E)
                                      : const Color(0xFFE2E0EC))),
                        ),
                        child: Center(
                          child: Text(
                            member.initials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Name and details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    member.displayName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: widget.textPrimary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                if (isSelf) ...[
                                  const SizedBox(width: 6),
                                  Text(
                                    '(Siz)',
                                    style: TextStyle(
                                      color: widget.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            _RoleBadge(
                                role: member.role, purple: widget.purple),
                          ],
                        ),
                      ),

                      // Actions PopupMenu
                      if (!widget.isReadOnly)
                        PopupMenuButton<String>(
                          icon: Icon(Icons.more_vert_rounded,
                              size: 18, color: widget.textSecondary),
                          onSelected: (action) {
                            switch (action) {
                              case 'make_admin':
                                _updateMemberRole(member, MemberRole.admin);
                                break;
                              case 'remove_admin':
                                _updateMemberRole(member, MemberRole.member);
                                break;
                              case 'remove':
                                _removeMember(member);
                                break;
                              case 'leave':
                                _leaveTeam();
                                break;
                            }
                          },
                          itemBuilder: (ctx) {
                            final items = <PopupMenuEntry<String>>[];

                            // Owner controls
                            if (isOwner && !isMemberOwner) {
                              if (member.role == MemberRole.member) {
                                items.add(
                                  PopupMenuItem(
                                    value: 'make_admin',
                                    child: Text(l10n.makeAdmin),
                                  ),
                                );
                              } else if (member.role == MemberRole.admin) {
                                items.add(
                                  PopupMenuItem(
                                    value: 'remove_admin',
                                    child: Text(l10n.removeAdmin),
                                  ),
                                );
                              }
                              items.add(
                                PopupMenuItem(
                                  value: 'remove',
                                  child: Text(
                                    l10n.removeMember,
                                    style: TextStyle(
                                        color: Theme.of(ctx).colorScheme.error),
                                  ),
                                ),
                              );
                            }

                            // Admin controls
                            if (callerRole == MemberRole.admin &&
                                member.role == MemberRole.member) {
                              items.add(
                                PopupMenuItem(
                                  value: 'remove',
                                  child: Text(
                                    l10n.removeMember,
                                    style: TextStyle(
                                        color: Theme.of(ctx).colorScheme.error),
                                  ),
                                ),
                              );
                            }

                            // Leave team
                            if (isSelf && !isMemberOwner) {
                              items.add(
                                PopupMenuItem(
                                  value: 'leave',
                                  child: Text(
                                    l10n.leaveTeam,
                                    style: TextStyle(
                                        color: Theme.of(ctx).colorScheme.error),
                                  ),
                                ),
                              );
                            }

                            return items;
                          },
                        ),
                    ],
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role, required this.purple});

  final MemberRole role;
  final Color purple;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    final (color, label) = switch (role) {
      MemberRole.owner => (purple, l10n.memberRoleOwner),
      MemberRole.admin => (const Color(0xFF38BDF8), l10n.memberRoleAdmin),
      MemberRole.member => (const Color(0xFF94A3B8), l10n.memberRoleMember),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
