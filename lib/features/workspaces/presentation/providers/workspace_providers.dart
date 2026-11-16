import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_map_flow/core/result/result.dart';
import 'package:task_map_flow/features/auth/domain/models/auth_state.dart';
import 'package:task_map_flow/features/auth/presentation/providers/auth_providers.dart';
import 'package:task_map_flow/features/workspaces/data/repositories/firebase_workspace_repository.dart';
import 'package:task_map_flow/features/workspaces/domain/models/map_node.dart';
import 'package:task_map_flow/features/workspaces/domain/models/resource_link.dart';
import 'package:task_map_flow/features/workspaces/domain/models/workspace.dart';
import 'package:task_map_flow/features/workspaces/domain/repositories/workspace_repository.dart';

final workspaceRepositoryProvider = Provider<WorkspaceRepository>((ref) {
  return FirebaseWorkspaceRepository();
});

final currentUserIdProvider = Provider<String?>((ref) {
  final status = ref.watch(authStatusProvider);
  return switch (status) {
    AuthGuest(:final user) => user.id,
    AuthAuthenticated(:final user) => user.id,
    AuthUnverified(:final user) => user.id,
    _ => null,
  };
});

final workspacesStreamProvider =
    StreamProvider.autoDispose<List<Workspace>>((ref) async* {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null || uid.isEmpty) {
    yield const [];
    return;
  }

  final stream = ref.watch(workspaceRepositoryProvider).watchWorkspaces(uid);
  await for (final result in stream) {
    switch (result) {
      case Success(:final value):
        yield value;
      case Err(:final failure):
        throw failure.message;
    }
  }
});

final mapNodesStreamProvider =
    StreamProvider.autoDispose<List<MapNode>>((ref) async* {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null || uid.isEmpty) {
    yield const [];
    return;
  }

  final stream = ref.watch(workspaceRepositoryProvider).watchMapNodes(uid);
  await for (final result in stream) {
    switch (result) {
      case Success(:final value):
        yield value;
      case Err(:final failure):
        throw failure.message;
    }
  }
});

final isEditModeProvider = StateProvider.autoDispose<bool>((ref) => false);

final workspaceControllerProvider =
    StateNotifierProvider<WorkspaceController, AsyncValue<void>>((ref) {
  final repo = ref.watch(workspaceRepositoryProvider);
  return WorkspaceController(repo);
});

class WorkspaceController extends StateNotifier<AsyncValue<void>> {
  WorkspaceController(this._repository) : super(const AsyncData(null));

  final WorkspaceRepository _repository;

  Future<Result<Workspace>> createWorkspace({
    required String name,
    String? description,
    required WorkspaceType type,
    required String color,
    required String ownerId,
    required double initialX,
    required double initialY,
    double width = 180,
    double height = 110,
  }) async {
    state = const AsyncLoading();
    final result = await _repository.createWorkspaceWithMapNode(
      name: name,
      description: description,
      type: type,
      color: color,
      ownerId: ownerId,
      initialX: initialX,
      initialY: initialY,
      width: width,
      height: height,
    );

    if (result case Success()) {
      state = const AsyncData(null);
    } else if (result case Err(:final failure)) {
      state = AsyncError(failure.message, StackTrace.current);
    }
    return result;
  }

  Future<Result<void>> updateWorkspace({
    required String workspaceId,
    required String name,
    String? description,
    required String color,
  }) async {
    state = const AsyncLoading();
    final result = await _repository.updateWorkspace(
      workspaceId: workspaceId,
      name: name,
      description: description,
      color: color,
    );

    if (result case Success()) {
      state = const AsyncData(null);
    } else if (result case Err(:final failure)) {
      state = AsyncError(failure.message, StackTrace.current);
    }
    return result;
  }

  Future<Result<void>> updateWorkspaceInfo({
    required String workspaceId,
    String? description,
    List<String>? tags,
    List<ResourceLink>? resources,
  }) async {
    state = const AsyncLoading();
    final result = await _repository.updateWorkspaceInfo(
      workspaceId: workspaceId,
      description: description,
      tags: tags,
      resources: resources,
    );

    if (result case Success()) {
      state = const AsyncData(null);
    } else if (result case Err(:final failure)) {
      state = AsyncError(failure.message, StackTrace.current);
    }
    return result;
  }

  Future<Result<void>> updateMapNodeLayout({
    required String nodeId,
    required double positionX,
    required double positionY,
    required double width,
    required double height,
  }) async {
    final result = await _repository.updateMapNodeLayout(
      nodeId: nodeId,
      positionX: positionX,
      positionY: positionY,
      width: width,
      height: height,
    );
    return result;
  }

  Future<Result<void>> deleteWorkspace({
    required String workspaceId,
    required String mapNodeId,
  }) async {
    state = const AsyncLoading();
    final result = await _repository.deleteWorkspaceAndMapNode(
      workspaceId: workspaceId,
      mapNodeId: mapNodeId,
    );

    if (result case Success()) {
      state = const AsyncData(null);
    } else if (result case Err(:final failure)) {
      state = AsyncError(failure.message, StackTrace.current);
    }
    return result;
  }
}
