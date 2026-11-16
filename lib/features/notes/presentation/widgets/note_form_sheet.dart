import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_map_flow/app/theme.dart';
import 'package:task_map_flow/core/extensions/context_extensions.dart';
import 'package:task_map_flow/core/result/result.dart';
import 'package:task_map_flow/features/notes/domain/models/note_model.dart';
import 'package:task_map_flow/features/notes/presentation/providers/note_providers.dart';
import 'package:task_map_flow/features/workspaces/presentation/providers/workspace_providers.dart';

class NoteFormSheet extends ConsumerStatefulWidget {
  const NoteFormSheet({
    super.key,
    required this.workspaceId,
    this.existingNote,
  });

  final String workspaceId;
  final NoteModel? existingNote;

  static Future<void> show(
    BuildContext context, {
    required String workspaceId,
    NoteModel? existingNote,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => NoteFormSheet(
        workspaceId: workspaceId,
        existingNote: existingNote,
      ),
    );
  }

  @override
  ConsumerState<NoteFormSheet> createState() => _NoteFormSheetState();
}

class _NoteFormSheetState extends ConsumerState<NoteFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  bool _isSubmitting = false;

  bool get _isEditing => widget.existingNote != null;

  @override
  void initState() {
    super.initState();
    _titleController =
        TextEditingController(text: widget.existingNote?.title ?? '');
    _contentController =
        TextEditingController(text: widget.existingNote?.content ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    final uid = ref.read(currentUserIdProvider) ?? '';
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    setState(() => _isSubmitting = true);

    if (_isEditing) {
      final noteId = widget.existingNote!.id;
      final result = await ref.read(noteControllerProvider.notifier).updateNote(
            workspaceId: widget.workspaceId,
            noteId: noteId,
            title: title,
            content: content,
          );

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      if (result case Success()) {
        ref.read(noteListProvider(widget.workspaceId).notifier).onNoteUpdated(
              widget.existingNote!.copyWith(
                title: title,
                content: content,
                updatedAt: DateTime.now(),
              ),
            );
        Navigator.of(context).pop();
      } else if (result case Err(:final failure)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failure.message),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } else {
      final result = await ref.read(noteControllerProvider.notifier).createNote(
            workspaceId: widget.workspaceId,
            ownerId: uid,
            title: title,
            content: content,
          );

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      if (result case Success(:final value)) {
        ref
            .read(noteListProvider(widget.workspaceId).notifier)
            .onNoteCreated(value);
        Navigator.of(context).pop();
      } else if (result case Err(:final failure)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failure.message),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF161522) : Colors.white;
    final border = isDark ? const Color(0xFF262335) : const Color(0xFFE5E3EF);
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final inputBg = isDark ? AppColors.darkInputFill : AppColors.lightInputFill;
    final purple =
        isDark ? AppColors.darkPrimaryPurple : AppColors.lightPrimaryPurple;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: border),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _isEditing ? l10n.editNote : l10n.addNote,
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.noteTitleLabel,
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _titleController,
                maxLength: 150,
                style: TextStyle(color: textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: l10n.noteTitlePlaceholder,
                  hintStyle: TextStyle(
                      color: textSecondary.withValues(alpha: 0.5),
                      fontSize: 14),
                  filled: true,
                  fillColor: inputBg,
                  counterText: '',
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: purple, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                '${l10n.noteContentLabel} *',
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _contentController,
                maxLines: 6,
                minLines: 3,
                maxLength: 5000,
                style: TextStyle(color: textPrimary, fontSize: 14),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return l10n.noteContentPlaceholder;
                  }
                  return null;
                },
                decoration: InputDecoration(
                  hintText: l10n.noteContentPlaceholder,
                  hintStyle: TextStyle(
                      color: textSecondary.withValues(alpha: 0.5),
                      fontSize: 14),
                  filled: true,
                  fillColor: inputBg,
                  contentPadding: const EdgeInsets.all(14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: purple, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(l10n.cancel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: purple,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _isSubmitting ? null : _submit,
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(l10n.save),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
