import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_map_flow/core/result/result.dart';
import 'package:task_map_flow/features/profile/data/repositories/firebase_profile_repository.dart';
import 'package:task_map_flow/features/profile/domain/models/user_profile.dart';
import 'package:task_map_flow/features/profile/domain/repositories/profile_repository.dart';
import 'package:task_map_flow/features/workspaces/presentation/providers/workspace_providers.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return FirebaseProfileRepository();
});

final userProfileStreamProvider =
    StreamProvider.autoDispose<UserProfile?>((ref) async* {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null || uid.isEmpty) {
    yield null;
    return;
  }

  final repo = ref.watch(profileRepositoryProvider);
  final stream = repo.watchProfile(uid);
  await for (final result in stream) {
    switch (result) {
      case Success(:final value):
        yield value;
      case Err(:final failure):
        throw failure.message;
    }
  }
});

final profileControllerProvider =
    StateNotifierProvider<ProfileController, AsyncValue<void>>((ref) {
  final repo = ref.watch(profileRepositoryProvider);
  return ProfileController(repo);
});

class ProfileController extends StateNotifier<AsyncValue<void>> {
  ProfileController(this._repository) : super(const AsyncData(null));

  final ProfileRepository _repository;

  Future<Result<UserProfile>> saveProfile(UserProfile profile) async {
    state = const AsyncLoading();
    final result = await _repository.saveProfile(profile);
    if (result case Success()) {
      state = const AsyncData(null);
    } else if (result case Err(:final failure)) {
      state = AsyncError(failure.message, StackTrace.current);
    }
    return result;
  }
}
