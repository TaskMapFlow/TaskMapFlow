import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_map_flow/core/result/result.dart';
import 'package:task_map_flow/features/tasks/data/repositories/firebase_sprint_repository.dart';
import 'package:task_map_flow/features/tasks/domain/models/sprint_model.dart';
import 'package:task_map_flow/features/tasks/domain/repositories/sprint_repository.dart';
import 'package:task_map_flow/features/workspaces/presentation/providers/workspace_providers.dart';

final sprintRepositoryProvider = Provider<SprintRepository>((ref) {
  return FirebaseSprintRepository();
});

final sprintsStreamProvider = StreamProvider.autoDispose
    .family<List<SprintModel>, String>((ref, workspaceId) async* {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null || uid.isEmpty || workspaceId.isEmpty) {
    yield const [];
    return;
  }

  final repo = ref.watch(sprintRepositoryProvider);
  final stream = repo.watchSprints(workspaceId: workspaceId, ownerId: uid);

  await for (final result in stream) {
    switch (result) {
      case Success(:final value):
        yield value;
      case Err(:final failure):
        throw failure.message;
    }
  }
});

final sprintControllerProvider =
    StateNotifierProvider<SprintController, AsyncValue<void>>((ref) {
  final repo = ref.watch(sprintRepositoryProvider);
  return SprintController(repo);
});

class SprintController extends StateNotifier<AsyncValue<void>> {
  SprintController(this._repository) : super(const AsyncData(null));

  final SprintRepository _repository;

  Future<Result<SprintModel>> createSprint({
    required String workspaceId,
    required String ownerId,
    required String name,
    String? goal,
    required DateTime startDate,
    required DateTime endDate,
    SprintStatus status = SprintStatus.planned,
  }) async {
    state = const AsyncLoading();
    final result = await _repository.createSprint(
      workspaceId: workspaceId,
      ownerId: ownerId,
      name: name,
      goal: goal,
      startDate: startDate,
      endDate: endDate,
      status: status,
    );
    if (result case Success()) {
      state = const AsyncData(null);
    } else if (result case Err(:final failure)) {
      state = AsyncError(failure.message, StackTrace.current);
    }
    return result;
  }

  Future<Result<void>> updateSprint({
    required String workspaceId,
    required String sprintId,
    required String name,
    String? goal,
    required DateTime startDate,
    required DateTime endDate,
    required SprintStatus status,
  }) async {
    state = const AsyncLoading();
    final result = await _repository.updateSprint(
      workspaceId: workspaceId,
      sprintId: sprintId,
      name: name,
      goal: goal,
      startDate: startDate,
      endDate: endDate,
      status: status,
    );
    if (result case Success()) {
      state = const AsyncData(null);
    } else if (result case Err(:final failure)) {
      state = AsyncError(failure.message, StackTrace.current);
    }
    return result;
  }

  Future<Result<void>> updateSprintStatus({
    required String workspaceId,
    required String sprintId,
    required SprintStatus status,
  }) async {
    final result = await _repository.updateSprintStatus(
      workspaceId: workspaceId,
      sprintId: sprintId,
      status: status,
    );
    return result;
  }

  Future<Result<void>> deleteSprint({
    required String workspaceId,
    required String sprintId,
  }) async {
    state = const AsyncLoading();
    final result = await _repository.deleteSprint(
      workspaceId: workspaceId,
      sprintId: sprintId,
    );
    if (result case Success()) {
      state = const AsyncData(null);
    } else if (result case Err(:final failure)) {
      state = AsyncError(failure.message, StackTrace.current);
    }
    return result;
  }
}
