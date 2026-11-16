import 'package:task_map_flow/core/result/result.dart';
import 'package:task_map_flow/features/profile/domain/models/user_profile.dart';

abstract interface class ProfileRepository {
  Stream<Result<UserProfile?>> watchProfile(String userId);

  Future<Result<UserProfile?>> getProfile(String userId);

  Future<Result<UserProfile>> saveProfile(UserProfile profile);
}
