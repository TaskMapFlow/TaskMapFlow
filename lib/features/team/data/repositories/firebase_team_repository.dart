import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:task_map_flow/core/errors/failure.dart';
import 'package:task_map_flow/core/result/result.dart';
import 'package:task_map_flow/features/team/data/models/workspace_member_dto.dart';
import 'package:task_map_flow/features/team/domain/models/member_role.dart';
import 'package:task_map_flow/features/team/domain/models/workspace_invite.dart';
import 'package:task_map_flow/features/team/domain/models/workspace_member.dart';
import 'package:task_map_flow/features/team/domain/repositories/team_repository.dart';

class FirebaseTeamRepository implements TeamRepository {
  FirebaseTeamRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    String? functionsBaseUrl,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _functionsBaseUrl = functionsBaseUrl;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final String? _functionsBaseUrl;

  CollectionReference<Map<String, dynamic>> _workspacesCol() =>
      _firestore.collection('workspaces');

  CollectionReference<Map<String, dynamic>> _membersCol(String workspaceId) =>
      _workspacesCol().doc(workspaceId).collection('members');

  String _resolveFunctionsUrl(String functionName) {
    if (_functionsBaseUrl != null && _functionsBaseUrl.isNotEmpty) {
      return '$_functionsBaseUrl/$functionName';
    }
    // Check if running against local Firebase emulator or live
    // Default emulator port for functions is 5001
    final host = _firestore.settings.host;
    final isEmulator = host != null &&
        (host.contains('localhost') || host.contains('127.0.0.1'));

    if (isEmulator) {
      final host = Platform.isAndroid ? '10.0.2.2' : '127.0.0.1';
      return 'http://$host:5001/taskmapflow/us-central1/$functionName';
    }

    return 'https://us-central1-taskmapflow.cloudfunctions.net/$functionName';
  }

  Future<Map<String, dynamic>> _callFunction(
    String functionName,
    Map<String, dynamic> data,
  ) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const PermissionFailure('Oturum açmanız gerekiyor.');
    }

    final idToken = await user.getIdToken();
    final url = Uri.parse(_resolveFunctionsUrl(functionName));

    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 10);

    try {
      final request = await client.postUrl(url);
      request.headers.set('Content-Type', 'application/json');
      if (idToken != null) {
        request.headers.set('Authorization', 'Bearer $idToken');
      }
      request.write(jsonEncode({'data': data}));

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(responseBody) as Map<String, dynamic>;
        return (decoded['result'] as Map<String, dynamic>?) ?? {};
      } else {
        String errorMessage = 'Sunucu işlemi başarısız oldu.';
        try {
          final decoded = jsonDecode(responseBody) as Map<String, dynamic>;
          final error = decoded['error'];
          if (error is Map && error['message'] != null) {
            errorMessage = error['message'].toString();
          }
        } catch (_) {}

        if (response.statusCode == 404) {
          throw const UnknownFailure(
            'Davet sistemi Cloud Functions gerektirir. Canlıda çalıştırmak için Firebase Blaze planı aktif edilmelidir.',
          );
        }

        throw UnknownFailure(errorMessage);
      }
    } on SocketException {
      throw const NetworkFailure(
        'Bulut fonksiyonuna ulaşılamadı. Yerel Emulator veya internet bağlantınızı kontrol edin. (Canlı ortam için Blaze planı gereklidir).',
      );
    } finally {
      client.close();
    }
  }

  @override
  Stream<Result<List<WorkspaceMember>>> watchMembers(
      String workspaceId) async* {
    if (workspaceId.isEmpty) {
      yield const Success([]);
      return;
    }

    try {
      await for (final snapshot in _membersCol(workspaceId).snapshots()) {
        try {
          final members =
              snapshot.docs.map(WorkspaceMemberDto.fromFirestore).toList();

          members.sort((a, b) {
            final roleOrder = {
              MemberRole.owner: 0,
              MemberRole.admin: 1,
              MemberRole.member: 2,
            };
            final diff = (roleOrder[a.role] ?? 3) - (roleOrder[b.role] ?? 3);
            if (diff != 0) return diff;
            return a.joinedAt.compareTo(b.joinedAt);
          });

          yield Success(members);
        } catch (e) {
          yield Err(_mapException(e));
        }
      }
    } catch (e) {
      yield Err(_mapException(e));
    }
  }

  @override
  Future<Result<List<WorkspaceMember>>> getMembers(String workspaceId) async {
    if (workspaceId.isEmpty) {
      return const Success([]);
    }

    try {
      final snapshot = await _membersCol(workspaceId).get();
      final members =
          snapshot.docs.map(WorkspaceMemberDto.fromFirestore).toList();

      members.sort((a, b) {
        final roleOrder = {
          MemberRole.owner: 0,
          MemberRole.admin: 1,
          MemberRole.member: 2,
        };
        final diff = (roleOrder[a.role] ?? 3) - (roleOrder[b.role] ?? 3);
        if (diff != 0) return diff;
        return a.joinedAt.compareTo(b.joinedAt);
      });

      return Success(members);
    } catch (e) {
      return Err(_mapException(e));
    }
  }

  @override
  Stream<Result<WorkspaceMember?>> watchUserMember(
      String workspaceId, String uid) async* {
    if (workspaceId.isEmpty || uid.isEmpty) {
      yield const Success(null);
      return;
    }

    try {
      await for (final snapshot
          in _membersCol(workspaceId).doc(uid).snapshots()) {
        try {
          if (!snapshot.exists) {
            yield const Success(null);
          } else {
            yield Success(WorkspaceMemberDto.fromFirestore(snapshot));
          }
        } catch (e) {
          yield Err(_mapException(e));
        }
      }
    } catch (e) {
      yield Err(_mapException(e));
    }
  }

  @override
  Future<Result<void>> enableTeamWork({
    required String workspaceId,
    required String ownerUid,
    required String ownerDisplayName,
  }) async {
    try {
      final now = DateTime.now();
      final wsDoc = _workspacesCol().doc(workspaceId);
      final memberDoc = _membersCol(workspaceId).doc(ownerUid);

      final batch = _firestore.batch();
      batch.update(wsDoc, {
        'isTeamEnabled': true,
        'memberIds': FieldValue.arrayUnion([ownerUid]),
        'updatedAt': Timestamp.fromDate(now),
      });

      final ownerMember = WorkspaceMember(
        id: ownerUid,
        workspaceId: workspaceId,
        displayName:
            ownerDisplayName.isNotEmpty ? ownerDisplayName : 'Alan Sahibi',
        role: MemberRole.owner,
        joinedAt: now,
        updatedAt: now,
      );

      batch.set(memberDoc, WorkspaceMemberDto.toFirestore(ownerMember));
      await batch.commit();

      return const Success(null);
    } catch (e) {
      return Err(_mapException(e));
    }
  }

  @override
  Future<Result<WorkspaceInvite>> createInvite({
    required String workspaceId,
    required String creatorUid,
  }) async {
    try {
      final res = await _callFunction('createInvite', {
        'workspaceId': workspaceId,
        'role': 'member',
      });

      final invite = WorkspaceInvite(
        id: res['code'] as String? ?? '',
        workspaceId: workspaceId,
        workspaceName: res['workspaceName'] as String? ?? '',
        code: res['code'] as String? ?? '',
        role: MemberRole.fromString(res['role'] as String? ?? 'member'),
        creatorId: creatorUid,
        createdAt: DateTime.now(),
        expiresAt: res['expiresAt'] != null
            ? DateTime.parse(res['expiresAt'].toString())
            : DateTime.now().add(const Duration(days: 7)),
      );

      return Success(invite);
    } catch (e) {
      if (e is Failure) return Err(e);
      return Err(_mapException(e));
    }
  }

  @override
  Future<Result<String>> acceptInvite({
    required String code,
    required String userUid,
    required String userDisplayName,
  }) async {
    if (_auth.currentUser?.isAnonymous == true) {
      return const Err(
        PermissionFailure(
          'Misafir kullanıcılar davet kabul edemez. Lütfen önce profil ekranından bir hesap bağlayın veya kayıt olun.',
        ),
      );
    }

    try {
      final res = await _callFunction('acceptInvite', {
        'code': code.trim().toUpperCase(),
      });

      final workspaceId = res['workspaceId'] as String? ?? '';
      return Success(workspaceId);
    } catch (e) {
      if (e is Failure) return Err(e);
      return Err(_mapException(e));
    }
  }

  @override
  Future<Result<void>> revokeInvite({
    required String workspaceId,
    required String inviteId,
  }) async {
    try {
      await _callFunction('revokeInvite', {
        'workspaceId': workspaceId,
        'code': inviteId,
      });
      return const Success(null);
    } catch (e) {
      if (e is Failure) return Err(e);
      return Err(_mapException(e));
    }
  }

  @override
  Future<Result<void>> updateMemberRole({
    required String workspaceId,
    required String targetUid,
    required MemberRole newRole,
  }) async {
    try {
      await _callFunction('updateMemberRole', {
        'workspaceId': workspaceId,
        'targetUid': targetUid,
        'newRole': newRole.toFirestoreString(),
      });
      return const Success(null);
    } catch (e) {
      if (e is Failure) return Err(e);
      return Err(_mapException(e));
    }
  }

  @override
  Future<Result<void>> removeMember({
    required String workspaceId,
    required String targetUid,
  }) async {
    try {
      await _callFunction('removeMember', {
        'workspaceId': workspaceId,
        'targetUid': targetUid,
      });
      return const Success(null);
    } catch (e) {
      if (e is Failure) return Err(e);
      return Err(_mapException(e));
    }
  }

  @override
  Future<Result<void>> leaveTeam({
    required String workspaceId,
    required String userUid,
  }) async {
    return removeMember(workspaceId: workspaceId, targetUid: userUid);
  }

  Failure _mapException(Object error) {
    if (error is Failure) return error;
    if (error is FirebaseException) {
      return switch (error.code) {
        'permission-denied' =>
          const PermissionFailure('Erişim reddedildi. Yetkiniz bulunmuyor.'),
        'unavailable' || 'network-request-failed' => const NetworkFailure(
            'Bağlantı hatası. İnternet bağlantınızı kontrol edin.'),
        'not-found' => const NotFoundFailure('Kayıt bulunamadı.'),
        _ =>
          UnknownFailure(error.message ?? 'Veritabanı işlemi başarısız oldu.'),
      };
    }
    return UnknownFailure(error.toString());
  }
}
