import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_map_flow/core/result/result.dart';
import 'package:task_map_flow/features/notes/data/repositories/firebase_note_repository.dart';
import 'package:task_map_flow/features/notes/domain/models/note_model.dart';
import 'package:task_map_flow/features/notes/domain/repositories/note_repository.dart';
import 'package:task_map_flow/features/workspaces/presentation/providers/workspace_providers.dart';

final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  return FirebaseNoteRepository();
});

class NoteListState extends Equatable {
  const NoteListState({
    this.notes = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.errorMessage,
    this.cursor,
  });

  final List<NoteModel> notes;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? errorMessage;
  final Object? cursor;

  NoteListState copyWith({
    List<NoteModel>? notes,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? errorMessage,
    Object? cursor,
    bool clearError = false,
    bool clearCursor = false,
  }) {
    return NoteListState(
      notes: notes ?? this.notes,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      cursor: clearCursor ? null : (cursor ?? this.cursor),
    );
  }

  @override
  List<Object?> get props => [
        notes,
        isLoading,
        isLoadingMore,
        hasMore,
        errorMessage,
        cursor,
      ];
}

class NoteListNotifier extends StateNotifier<NoteListState> {
  NoteListNotifier({
    required this.repository,
    required this.workspaceId,
    required this.ownerId,
  }) : super(const NoteListState());

  final NoteRepository repository;
  final String workspaceId;
  final String ownerId;

  Future<void> loadInitial() async {
    if (ownerId.isEmpty) {
      state = const NoteListState();
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    final result = await repository.getNotes(
      workspaceId: workspaceId,
      ownerId: ownerId,
      limit: 10,
    );

    if (result case Success(:final value)) {
      state = state.copyWith(
        notes: value.notes,
        hasMore: value.hasMore,
        cursor: value.cursor,
        isLoading: false,
      );
    } else if (result case Err(:final failure)) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: failure.message,
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true, clearError: true);
    final result = await repository.getNotes(
      workspaceId: workspaceId,
      ownerId: ownerId,
      limit: 10,
      cursor: state.cursor,
    );

    if (result case Success(:final value)) {
      state = state.copyWith(
        notes: [...state.notes, ...value.notes],
        hasMore: value.hasMore,
        cursor: value.cursor,
        isLoadingMore: false,
      );
    } else if (result case Err(:final failure)) {
      state = state.copyWith(
        isLoadingMore: false,
        errorMessage: failure.message,
      );
    }
  }

  void onNoteCreated(NoteModel note) {
    state = state.copyWith(
      notes: [note, ...state.notes],
    );
  }

  void onNoteUpdated(NoteModel updatedNote) {
    final list = state.notes.map((n) {
      return n.id == updatedNote.id ? updatedNote : n;
    }).toList();
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    state = state.copyWith(notes: list);
  }

  void onNoteDeleted(String noteId) {
    state = state.copyWith(
      notes: state.notes.where((n) => n.id != noteId).toList(),
    );
  }
}

final noteListProvider = StateNotifierProvider.autoDispose
    .family<NoteListNotifier, NoteListState, String>((ref, workspaceId) {
  final uid = ref.watch(currentUserIdProvider) ?? '';
  final repo = ref.watch(noteRepositoryProvider);
  final notifier = NoteListNotifier(
    repository: repo,
    workspaceId: workspaceId,
    ownerId: uid,
  );
  notifier.loadInitial();
  return notifier;
});

final noteControllerProvider =
    StateNotifierProvider<NoteController, AsyncValue<void>>((ref) {
  final repo = ref.watch(noteRepositoryProvider);
  return NoteController(repo);
});

class NoteController extends StateNotifier<AsyncValue<void>> {
  NoteController(this._repository) : super(const AsyncData(null));

  final NoteRepository _repository;

  Future<Result<NoteModel>> createNote({
    required String workspaceId,
    required String ownerId,
    String? title,
    required String content,
  }) async {
    state = const AsyncLoading();
    final result = await _repository.createNote(
      workspaceId: workspaceId,
      ownerId: ownerId,
      title: title,
      content: content,
    );

    if (result case Success()) {
      state = const AsyncData(null);
    } else if (result case Err(:final failure)) {
      state = AsyncError(failure.message, StackTrace.current);
    }
    return result;
  }

  Future<Result<void>> updateNote({
    required String workspaceId,
    required String noteId,
    String? title,
    required String content,
  }) async {
    state = const AsyncLoading();
    final result = await _repository.updateNote(
      workspaceId: workspaceId,
      noteId: noteId,
      title: title,
      content: content,
    );

    if (result case Success()) {
      state = const AsyncData(null);
    } else if (result case Err(:final failure)) {
      state = AsyncError(failure.message, StackTrace.current);
    }
    return result;
  }

  Future<Result<void>> deleteNote({
    required String workspaceId,
    required String noteId,
  }) async {
    state = const AsyncLoading();
    final result = await _repository.deleteNote(
      workspaceId: workspaceId,
      noteId: noteId,
    );

    if (result case Success()) {
      state = const AsyncData(null);
    } else if (result case Err(:final failure)) {
      state = AsyncError(failure.message, StackTrace.current);
    }
    return result;
  }
}
