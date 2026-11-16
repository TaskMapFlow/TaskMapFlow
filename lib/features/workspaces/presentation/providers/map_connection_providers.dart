import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_map_flow/core/result/result.dart';
import 'package:task_map_flow/features/workspaces/data/repositories/firebase_map_connection_repository.dart';
import 'package:task_map_flow/features/workspaces/domain/models/map_connection.dart';
import 'package:task_map_flow/features/workspaces/domain/repositories/map_connection_repository.dart';
import 'package:task_map_flow/features/workspaces/presentation/providers/workspace_providers.dart';

final mapConnectionRepositoryProvider =
    Provider<MapConnectionRepository>((ref) {
  return FirebaseMapConnectionRepository();
});

final mapConnectionsStreamProvider =
    StreamProvider.autoDispose<List<MapConnection>>((ref) async* {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null || uid.isEmpty) {
    yield const [];
    return;
  }

  final repo = ref.watch(mapConnectionRepositoryProvider);
  final stream = repo.watchConnections(uid);

  await for (final result in stream) {
    switch (result) {
      case Success(:final value):
        yield value;
      case Err(:final failure):
        throw failure.message;
    }
  }
});

/// Indicates whether the user is in "Connect Workspaces" mode on the map
final isConnectingModeProvider = StateProvider<bool>((ref) => false);

/// The workspace ID selected as the source for a new connection
final connectingSourceWorkspaceIdProvider =
    StateProvider<String?>((ref) => null);

final mapConnectionControllerProvider =
    StateNotifierProvider<MapConnectionController, AsyncValue<void>>((ref) {
  final repo = ref.watch(mapConnectionRepositoryProvider);
  return MapConnectionController(repo);
});

class MapConnectionController extends StateNotifier<AsyncValue<void>> {
  MapConnectionController(this._repository) : super(const AsyncData(null));

  final MapConnectionRepository _repository;

  Future<Result<MapConnection>> createConnection({
    required String ownerId,
    required String sourceWorkspaceId,
    required String targetWorkspaceId,
    required ConnectionType type,
  }) async {
    state = const AsyncLoading();
    final result = await _repository.createConnection(
      ownerId: ownerId,
      sourceWorkspaceId: sourceWorkspaceId,
      targetWorkspaceId: targetWorkspaceId,
      type: type,
    );
    if (result case Success()) {
      state = const AsyncData(null);
    } else if (result case Err(:final failure)) {
      state = AsyncError(failure.message, StackTrace.current);
    }
    return result;
  }

  Future<Result<void>> updateConnectionType({
    required String connectionId,
    required ConnectionType type,
  }) async {
    state = const AsyncLoading();
    final result = await _repository.updateConnectionType(
      connectionId: connectionId,
      type: type,
    );
    if (result case Success()) {
      state = const AsyncData(null);
    } else if (result case Err(:final failure)) {
      state = AsyncError(failure.message, StackTrace.current);
    }
    return result;
  }

  Future<Result<void>> deleteConnection(String connectionId) async {
    state = const AsyncLoading();
    final result = await _repository.deleteConnection(connectionId);
    if (result case Success()) {
      state = const AsyncData(null);
    } else if (result case Err(:final failure)) {
      state = AsyncError(failure.message, StackTrace.current);
    }
    return result;
  }
}
