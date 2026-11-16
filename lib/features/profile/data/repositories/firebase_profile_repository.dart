import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:task_map_flow/core/errors/failure.dart';
import 'package:task_map_flow/core/result/result.dart';
import 'package:task_map_flow/features/profile/data/models/user_profile_dto.dart';
import 'package:task_map_flow/features/profile/domain/models/user_profile.dart';
import 'package:task_map_flow/features/profile/domain/repositories/profile_repository.dart';

class FirebaseProfileRepository implements ProfileRepository {
  FirebaseProfileRepository({
    FirebaseFirestore? firestore,
    fb_auth.FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? fb_auth.FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final fb_auth.FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _usersCol =>
      _firestore.collection('users');

  @override
  Stream<Result<UserProfile?>> watchProfile(String userId) async* {
    if (userId.isEmpty) {
      yield const Success(null);
      return;
    }

    try {
      await for (final snapshot in _usersCol.doc(userId).snapshots()) {
        if (!snapshot.exists) {
          yield const Success(null);
        } else {
          yield Success(UserProfileDto.fromFirestore(snapshot));
        }
      }
    } catch (e) {
      yield Err(_mapException(e));
    }
  }

  @override
  Future<Result<UserProfile?>> getProfile(String userId) async {
    if (userId.isEmpty) {
      return const Success(null);
    }
    try {
      final doc = await _usersCol.doc(userId).get();
      if (!doc.exists) {
        return const Success(null);
      }
      return Success(UserProfileDto.fromFirestore(doc));
    } catch (e) {
      return Err(_mapException(e));
    }
  }

  @override
  Future<Result<UserProfile>> saveProfile(UserProfile profile) async {
    try {
      final now = DateTime.now();
      final docRef = _usersCol.doc(profile.id);
      final existingDoc = await docRef.get();

      final UserProfile profileToSave;
      if (existingDoc.exists) {
        final existing = UserProfileDto.fromFirestore(existingDoc);
        profileToSave = profile.copyWith(
          createdAt: existing.createdAt,
          updatedAt: now,
        );
      } else {
        profileToSave = profile.copyWith(
          createdAt: now,
          updatedAt: now,
        );
      }

      await docRef.set(UserProfileDto.toFirestore(profileToSave));

      // Attempt to update Auth displayName as well, but do NOT fail if Auth update fails
      try {
        final currentUser = _auth.currentUser;
        if (currentUser != null &&
            currentUser.uid == profile.id &&
            currentUser.displayName != profile.displayName) {
          await currentUser.updateDisplayName(profile.displayName);
        }
      } catch (_) {
        // Firestore profile is the source of truth, ignore Auth displayName failure
      }

      return Success(profileToSave);
    } catch (e) {
      return Err(_mapException(e));
    }
  }

  Failure _mapException(Object error) {
    if (error is FirebaseException) {
      return switch (error.code) {
        'permission-denied' =>
          const PermissionFailure('Erişim reddedildi. Yetkiniz bulunmuyor.'),
        'unavailable' || 'network-request-failed' => const NetworkFailure(
            'Bağlantı hatası. İnternet bağlantınızı kontrol edin.'),
        'not-found' => const NotFoundFailure('Kayıt bulunamadı.'),
        _ => UnknownFailure(error.message ?? 'Profil işlemi başarısız oldu.'),
      };
    }
    return UnknownFailure(error.toString());
  }
}
