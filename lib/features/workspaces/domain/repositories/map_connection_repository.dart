import 'package:task_map_flow/core/result/result.dart';
import 'package:task_map_flow/features/workspaces/domain/models/map_connection.dart';

abstract class MapConnectionRepository {
  Stream<Result<List<MapConnection>>> watchConnections(String ownerId);

  Future<Result<MapConnection>> createConnection({
    required String ownerId,
    required String sourceWorkspaceId,
    required String targetWorkspaceId,
    required ConnectionType type,
  });

  Future<Result<void>> updateConnectionType({
    required String connectionId,
    required ConnectionType type,
  });

  Future<Result<void>> deleteConnection(String connectionId);

  Future<Result<void>> deleteConnectionsForWorkspace(String workspaceId);
}
