import 'dart:async';
import 'package:task_map_flow/core/result/result.dart';
import 'package:task_map_flow/features/profile/domain/models/user_profile.dart';
import 'package:task_map_flow/features/profile/domain/repositories/profile_repository.dart';

class FakeProfileRepository implements ProfileRepository {
  final Map<String, UserProfile> _profiles = {};
  final Map<String, StreamController<Result<UserProfile?>>> _controllers = {};

  StreamController<Result<UserProfile?>> _getController(String userId) {
    return _controllers.putIfAbsent(
      userId,
      () => StreamController<Result<UserProfile?>>.broadcast(),
    );
  }

  @override
  Stream<Result<UserProfile?>> watchProfile(String userId) async* {
    yield Success(_profiles[userId]);
    yield* _getController(userId).stream;
  }

  @override
  Future<Result<UserProfile?>> getProfile(String userId) async {
    return Success(_profiles[userId]);
  }

  @override
  Future<Result<UserProfile>> saveProfile(UserProfile profile) async {
    _profiles[profile.id] = profile;
    _getController(profile.id).add(Success(profile));
    return Success(profile);
  }
}
