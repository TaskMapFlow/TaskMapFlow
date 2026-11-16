import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:task_map_flow/app/theme.dart';
import 'package:task_map_flow/core/extensions/context_extensions.dart';
import 'package:task_map_flow/features/study_plan/domain/models/study_session_model.dart';

class CompleteSessionDialog extends StatefulWidget {
  const CompleteSessionDialog({
    super.key,
    required this.session,
  });

  final StudySessionModel session;

  static Future<({int? actualDuration, String? notes})?> show(
    BuildContext context, {
    required StudySessionModel session,
  }) {
    return showDialog<({int? actualDuration, String? notes})>(
      context: context,
      builder: (ctx) => CompleteSessionDialog(session: session),
    );
  }

  @override
  State<CompleteSessionDialog> createState() => _CompleteSessionDialogState();
}

class _CompleteSessionDialogState extends State<CompleteSessionDialog> {
  late TextEditingController _durationController;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _durationController = TextEditingController(
      text: widget.session.actualDurationMinutes?.toString() ?? '',
    );
    _notesController = TextEditingController(
      text: widget.session.reflectionNotes ?? '',
    );
  }

  @override
  void dispose() {
    _durationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() {
    final durationText = _durationController.text.trim();
    final actualDuration =
        durationText.isNotEmpty ? int.tryParse(durationText) : null;
    final notes = _notesController.text.trim();

    Navigator.of(context).pop((
      actualDuration: actualDuration,
      notes: notes.isNotEmpty ? notes : null,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final inputBg = isDark ? AppColors.darkInputFill : AppColors.lightInputFill;
    final purple =
        isDark ? AppColors.darkPrimaryPurple : AppColors.lightPrimaryPurple;

    return AlertDialog(
      title: Text(
        l10n.completeSessionDialogTitle,
        style: TextStyle(color: textPrimary, fontSize: 18),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.session.title,
              style: TextStyle(
                color: textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${l10n.sessionPlannedDurationLabel}: ${widget.session.plannedDurationMinutes} dk',
              style: TextStyle(color: textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.actualDurationLabel,
              style: TextStyle(
                color: textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _durationController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: TextStyle(color: textPrimary),
              decoration: InputDecoration(
                hintText: 'Örn. 45',
                filled: true,
                fillColor: inputBg,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              l10n.reflectionNotesLabel,
              style: TextStyle(
                color: textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _notesController,
              maxLength: 1000,
              maxLines: 3,
              style: TextStyle(color: textPrimary),
              decoration: InputDecoration(
                hintText: l10n.reflectionNotesPlaceholder,
                hintStyle:
                    TextStyle(color: textSecondary.withValues(alpha: 0.6)),
                filled: true,
                fillColor: inputBg,
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: purple),
          onPressed: _submit,
          child: Text(l10n.markSessionCompleted),
        ),
      ],
    );
  }
}
