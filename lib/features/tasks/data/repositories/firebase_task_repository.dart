import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:task_map_flow/core/errors/failure.dart';
import 'package:task_map_flow/core/result/result.dart';
import 'package:task_map_flow/features/tasks/data/models/task_dto.dart';
import 'package:task_map_flow/features/tasks/domain/models/subtask_model.dart';
import 'package:task_map_flow/features/tasks/domain/models/task_model.dart';
import 'package:task_map_flow/features/tasks/domain/models/task_priority.dart';
import 'package:task_map_flow/features/tasks/domain/models/task_status.dart';
import 'package:task_map_flow/features/tasks/domain/repositories/task_repository.dart';

class FirebaseTaskRepository implements TaskRepository {
  FirebaseTaskRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _tasksCol(String workspaceId) =>
      _firestore.collection('workspaces').doc(workspaceId).collection('tasks');

  @override
  Stream<Result<List<TaskModel>>> watchTasks({
    required String workspaceId,
    required String ownerId,
    bool isTeam = false,
  }) async* {
    if (workspaceId.isEmpty || ownerId.isEmpty) {
      yield const Success([]);
      return;
    }

    try {
      bool teamEnabled = isTeam;
      if (!teamEnabled) {
        try {
          final wsSnap =
              await _firestore.collection('workspaces').doc(workspaceId).get();
          teamEnabled = wsSnap.data()?['isTeamEnabled'] == true;
        } catch (_) {}
      }

      final query = teamEnabled
          ? _tasksCol(workspaceId)
          : _tasksCol(workspaceId).where('ownerId', isEqualTo: ownerId);

      await for (final snapshot in query.snapshots()) {
        try {
          final tasks = snapshot.docs.map(TaskDto.fromFirestore).toList();
          tasks.sort((a, b) {
            if (a.status == TaskStatus.completed &&
                b.status != TaskStatus.completed) {
              return 1;
            }
            if (a.status != TaskStatus.completed &&
                b.status == TaskStatus.completed) {
              return -1;
            }
            if (a.dueDate != null && b.dueDate != null) {
              return a.dueDate!.compareTo(b.dueDate!);
            }
            if (a.dueDate != null) return -1;
            if (b.dueDate != null) return 1;
            return b.createdAt.compareTo(a.createdAt);
          });
          yield Success(tasks);
        } catch (e) {
          yield Err(_mapException(e));
        }
      }
    } catch (e) {
      yield Err(_mapException(e));
    }
  }

  @override
  Stream<Result<List<TaskModel>>> watchAssignedTasks(String userId) {
    if (userId.isEmpty) {
      return Stream.value(const Success([]));
    }

    final controller = StreamController<Result<List<TaskModel>>>();
    final taskSubs =
        <String, StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>{};
    final tasksByWorkspace = <String, List<TaskModel>>{};
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? ownedSub;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? joinedSub;
    var ownedWsIds = <String>{};
    var joinedWsIds = <String>{};

    void emitTasks() {
      if (controller.isClosed) return;
      final allTasks = tasksByWorkspace.values.expand((t) => t).toList();
      allTasks.sort((a, b) {
        if (a.status == TaskStatus.completed &&
            b.status != TaskStatus.completed) {
          return 1;
        }
        if (a.status != TaskStatus.completed &&
            b.status == TaskStatus.completed) {
          return -1;
        }
        if (a.dueDate != null && b.dueDate != null) {
          return a.dueDate!.compareTo(b.dueDate!);
        }
        if (a.dueDate != null) return -1;
        if (b.dueDate != null) return 1;
        return b.createdAt.compareTo(a.createdAt);
      });
      controller.add(Success(allTasks));
    }

    void updateSubscriptions() {
      final currentWsIds = {...ownedWsIds, ...joinedWsIds};

      // Remove subscriptions for workspaces the user left
      final toRemove =
          taskSubs.keys.where((id) => !currentWsIds.contains(id)).toList();
      for (final id in toRemove) {
        taskSubs[id]?.cancel();
        taskSubs.remove(id);
        tasksByWorkspace.remove(id);
      }

      if (currentWsIds.isEmpty) {
        emitTasks();
        return;
      }

      // Add subscriptions for newly joined or owned workspaces
      for (final wsId in currentWsIds) {
        if (!taskSubs.containsKey(wsId)) {
          taskSubs[wsId] = _tasksCol(wsId)
              .where('assigneeId', isEqualTo: userId)
              .snapshots()
              .listen(
            (snapshot) {
              final tasks = snapshot.docs.map(TaskDto.fromFirestore).toList();
              tasksByWorkspace[wsId] = tasks;
              emitTasks();
            },
            onError: (Object error) {
              // If permission denied (e.g. user removed from workspace), clean up that workspace
              taskSubs[wsId]?.cancel();
              taskSubs.remove(wsId);
              tasksByWorkspace.remove(wsId);
              emitTasks();
            },
          );
        }
      }
    }

    controller.onListen = () {
      ownedSub = _firestore
          .collection('workspaces')
          .where('ownerId', isEqualTo: userId)
          .snapshots()
          .listen(
        (snapshot) {
          ownedWsIds = snapshot.docs.map((d) => d.id).toSet();
          updateSubscriptions();
        },
        onError: (Object error) {
          if (!controller.isClosed) {
            controller.add(Err(_mapException(error)));
          }
        },
      );

      joinedSub = _firestore
          .collection('workspaces')
          .where('memberIds', arrayContains: userId)
          .snapshots()
          .listen(
        (snapshot) {
          joinedWsIds = snapshot.docs.map((d) => d.id).toSet();
          updateSubscriptions();
        },
        onError: (Object error) {
          if (!controller.isClosed) {
            controller.add(Err(_mapException(error)));
          }
        },
      );
    };

    controller.onCancel = () {
      ownedSub?.cancel();
      joinedSub?.cancel();
      for (final sub in taskSubs.values) {
        sub.cancel();
      }
      taskSubs.clear();
      tasksByWorkspace.clear();
      controller.close();
    };

    return controller.stream;
  }

  @override
  Future<Result<TaskModel>> createTask({
    required String workspaceId,
    required String ownerId,
    required String title,
    String? description,
    TaskStatus status = TaskStatus.todo,
    TaskPriority priority = TaskPriority.medium,
    DateTime? dueDate,
    String? sprintId,
    List<SubtaskModel> subtasks = const [],
    String? assigneeId,
  }) async {
    try {
      final now = DateTime.now();
      final docRef = _tasksCol(workspaceId).doc();

      final task = TaskModel(
        id: docRef.id,
        workspaceId: workspaceId,
        ownerId: ownerId,
        title: title.trim(),
        description: description?.trim() ?? '',
        status: status,
        priority: priority,
        dueDate: dueDate != null
            ? DateTime.utc(dueDate.year, dueDate.month, dueDate.day)
            : null,
        sprintId: (sprintId != null && sprintId.isNotEmpty) ? sprintId : null,
        subtasks: subtasks,
        assigneeId: (assigneeId != null && assigneeId.isNotEmpty)
            ? assigneeId.trim()
            : null,
        createdAt: now,
        updatedAt: now,
      );

      await docRef.set(TaskDto.toFirestore(task));
      return Success(task);
    } catch (e) {
      return Err(_mapException(e));
    }
  }

  @override
  Future<Result<void>> updateTask({
    required String workspaceId,
    required String taskId,
    required String title,
    String? description,
    required TaskStatus status,
    required TaskPriority priority,
    DateTime? dueDate,
    String? sprintId,
    List<SubtaskModel>? subtasks,
    String? assigneeId,
  }) async {
    try {
      final now = DateTime.now();
      final data = <String, dynamic>{
        'title': title.trim(),
        'description': description?.trim() ?? '',
        'status': status.toFirestoreString(),
        'priority': priority.toFirestoreString(),
        'dueDate': dueDate != null
            ? Timestamp.fromDate(
                DateTime.utc(dueDate.year, dueDate.month, dueDate.day))
            : null,
        'sprintId': (sprintId != null && sprintId.isNotEmpty) ? sprintId : null,
        'updatedAt': Timestamp.fromDate(now),
        'assigneeId': (assigneeId != null && assigneeId.isNotEmpty)
            ? assigneeId.trim()
            : null,
      };

      if (subtasks != null) {
        data['subtasks'] = subtasks.map((s) => s.toMap()).toList();
      }

      await _tasksCol(workspaceId).doc(taskId).update(data);
      return const Success(null);
    } catch (e) {
      return Err(_mapException(e));
    }
  }

  @override
  Future<Result<void>> updateTaskStatus({
    required String workspaceId,
    required String taskId,
    required TaskStatus status,
  }) async {
    try {
      final now = DateTime.now();
      await _tasksCol(workspaceId).doc(taskId).update({
        'status': status.toFirestoreString(),
        'updatedAt': Timestamp.fromDate(now),
      });
      return const Success(null);
    } catch (e) {
      return Err(_mapException(e));
    }
  }

  @override
  Future<Result<void>> toggleSubtask({
    required String workspaceId,
    required String taskId,
    required String subtaskId,
    required bool isCompleted,
  }) async {
    try {
      final docRef = _tasksCol(workspaceId).doc(taskId);
      final snapshot = await docRef.get();
      if (!snapshot.exists) {
        return const Err(NotFoundFailure('Görev bulunamadı.'));
      }
      final task = TaskDto.fromFirestore(snapshot);
      final updatedSubtasks = task.subtasks.map((s) {
        if (s.id == subtaskId) {
          return s.copyWith(isCompleted: isCompleted);
        }
        return s;
      }).toList();

      await docRef.update({
        'subtasks': updatedSubtasks.map((s) => s.toMap()).toList(),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      return const Success(null);
    } catch (e) {
      return Err(_mapException(e));
    }
  }

  @override
  Future<Result<void>> addSubtask({
    required String workspaceId,
    required String taskId,
    required String title,
  }) async {
    try {
      final docRef = _tasksCol(workspaceId).doc(taskId);
      final snapshot = await docRef.get();
      if (!snapshot.exists) {
        return const Err(NotFoundFailure('Görev bulunamadı.'));
      }
      final task = TaskDto.fromFirestore(snapshot);
      if (task.subtasks.length >= 20) {
        return const Err(
            ValidationFailure('En fazla 20 alt görev eklenebilir.'));
      }

      final newSubtask = SubtaskModel(
        id: 'sub_${DateTime.now().microsecondsSinceEpoch}',
        title: title.trim(),
        isCompleted: false,
      );

      final updatedSubtasks = [...task.subtasks, newSubtask];
      await docRef.update({
        'subtasks': updatedSubtasks.map((s) => s.toMap()).toList(),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      return const Success(null);
    } catch (e) {
      return Err(_mapException(e));
    }
  }

  @override
  Future<Result<void>> deleteSubtask({
    required String workspaceId,
    required String taskId,
    required String subtaskId,
  }) async {
    try {
      final docRef = _tasksCol(workspaceId).doc(taskId);
      final snapshot = await docRef.get();
      if (!snapshot.exists) {
        return const Err(NotFoundFailure('Görev bulunamadı.'));
      }
      final task = TaskDto.fromFirestore(snapshot);
      final updatedSubtasks =
          task.subtasks.where((s) => s.id != subtaskId).toList();

      await docRef.update({
        'subtasks': updatedSubtasks.map((s) => s.toMap()).toList(),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      return const Success(null);
    } catch (e) {
      return Err(_mapException(e));
    }
  }

  @override
  Future<Result<void>> assignTaskToSprint({
    required String workspaceId,
    required String taskId,
    required String? sprintId,
  }) async {
    try {
      final now = DateTime.now();
      await _tasksCol(workspaceId).doc(taskId).update({
        'sprintId': (sprintId != null && sprintId.isNotEmpty) ? sprintId : null,
        'updatedAt': Timestamp.fromDate(now),
      });
      return const Success(null);
    } catch (e) {
      return Err(_mapException(e));
    }
  }

  @override
  Future<Result<void>> moveTasksToBacklog({
    required String workspaceId,
    List<String>? taskIds,
    String? sprintId,
  }) async {
    try {
      final batch = _firestore.batch();
      final now = DateTime.now();

      if (taskIds != null && taskIds.isNotEmpty) {
        for (final id in taskIds) {
          final docRef = _tasksCol(workspaceId).doc(id);
          batch.update(docRef, {
            'sprintId': null,
            'updatedAt': Timestamp.fromDate(now),
          });
        }
      } else if (sprintId != null && sprintId.isNotEmpty) {
        final matches = await _tasksCol(workspaceId)
            .where('sprintId', isEqualTo: sprintId)
            .get();
        for (final doc in matches.docs) {
          batch.update(doc.reference, {
            'sprintId': null,
            'updatedAt': Timestamp.fromDate(now),
          });
        }
      } else {
        return const Success(null);
      }

      await batch.commit();
      return const Success(null);
    } catch (e) {
      return Err(_mapException(e));
    }
  }

  @override
  Future<Result<void>> deleteTask({
    required String workspaceId,
    required String taskId,
  }) async {
    try {
      await _tasksCol(workspaceId).doc(taskId).delete();
      return const Success(null);
    } catch (e) {
      return Err(_mapException(e));
    }
  }

  @override
  Future<Result<bool>> hasTasks({
    required String workspaceId,
    required String ownerId,
  }) async {
    if (workspaceId.isEmpty || ownerId.isEmpty) {
      return const Success(false);
    }
    try {
      final snap = await _tasksCol(workspaceId)
          .where('ownerId', isEqualTo: ownerId)
          .limit(1)
          .get();
      return Success(snap.docs.isNotEmpty);
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
        _ =>
          UnknownFailure(error.message ?? 'Veritabanı işlemi başarısız oldu.'),
      };
    }
    return UnknownFailure(error.toString());
  }
}
