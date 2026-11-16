import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_map_flow/app/theme.dart';
import 'package:task_map_flow/core/extensions/context_extensions.dart';
import 'package:task_map_flow/core/result/result.dart';
import 'package:task_map_flow/features/study_plan/domain/models/topic_model.dart';
import 'package:task_map_flow/features/study_plan/domain/models/topic_status.dart';
import 'package:task_map_flow/features/study_plan/presentation/providers/study_plan_providers.dart';
import 'package:task_map_flow/features/workspaces/presentation/providers/workspace_providers.dart';

class TopicFormSheet extends ConsumerStatefulWidget {
  const TopicFormSheet({
    super.key,
    required this.workspaceId,
    this.existingTopic,
    this.nextOrderIndex = 0,
  });

  final String workspaceId;
  final TopicModel? existingTopic;
  final int nextOrderIndex;

  static Future<void> show(
    BuildContext context, {
    required String workspaceId,
    TopicModel? existingTopic,
    int nextOrderIndex = 0,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TopicFormSheet(
        workspaceId: workspaceId,
        existingTopic: existingTopic,
        nextOrderIndex: nextOrderIndex,
      ),
    );
  }

  @override
  ConsumerState<TopicFormSheet> createState() => _TopicFormSheetState();
}

class _TopicFormSheetState extends ConsumerState<TopicFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TopicStatus _status;
  bool _isSubmitting = false;

  bool get _isEditing => widget.existingTopic != null;

  @override
  void initState() {
    super.initState();
    _titleController =
        TextEditingController(text: widget.existingTopic?.title ?? '');
    _descController =
        TextEditingController(text: widget.existingTopic?.description ?? '');
    _status = widget.existingTopic?.status ?? TopicStatus.notStarted;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    final uid = ref.read(currentUserIdProvider) ?? '';
    final title = _titleController.text.trim();
    final desc = _descController.text.trim();

    setState(() => _isSubmitting = true);

    if (_isEditing) {
      final topicId = widget.existingTopic!.id;
      final result =
          await ref.read(studyPlanControllerProvider.notifier).updateTopic(
                workspaceId: widget.workspaceId,
                topicId: topicId,
                title: title,
                description: desc.isEmpty ? null : desc,
                status: _status,
                orderIndex: widget.existingTopic!.orderIndex,
              );

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      if (result case Success()) {
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
      final result =
          await ref.read(studyPlanControllerProvider.notifier).createTopic(
                workspaceId: widget.workspaceId,
                ownerId: uid,
                title: title,
                description: desc.isEmpty ? null : desc,
                status: _status,
                orderIndex: widget.nextOrderIndex,
              );

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      if (result case Success()) {
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
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final inputBg = isDark ? AppColors.darkInputFill : AppColors.lightInputFill;
    final purple =
        isDark ? AppColors.darkPrimaryPurple : AppColors.lightPrimaryPurple;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(
            color: isDark ? const Color(0xFF262335) : const Color(0xFFE5E3EF),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF333045)
                          : const Color(0xFFDCD8E8),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _isEditing ? l10n.editTopic : l10n.addTopic,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      color: textSecondary,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.topicTitleLabel,
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
                  style: TextStyle(color: textPrimary),
                  decoration: InputDecoration(
                    hintText: l10n.topicTitlePlaceholder,
                    hintStyle:
                        TextStyle(color: textSecondary.withValues(alpha: 0.6)),
                    filled: true,
                    fillColor: inputBg,
                    counterText: '',
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return l10n.fieldRequired;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                Text(
                  l10n.topicDescLabel,
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _descController,
                  maxLength: 1000,
                  maxLines: 3,
                  style: TextStyle(color: textPrimary),
                  decoration: InputDecoration(
                    hintText: l10n.descriptionLabel,
                    hintStyle:
                        TextStyle(color: textSecondary.withValues(alpha: 0.6)),
                    filled: true,
                    fillColor: inputBg,
                    contentPadding: const EdgeInsets.all(14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  l10n.statusLabel,
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _StatusChip(
                      label: l10n.topicStatusNotStarted,
                      isSelected: _status == TopicStatus.notStarted,
                      color: Colors.blueGrey,
                      onTap: () =>
                          setState(() => _status = TopicStatus.notStarted),
                    ),
                    _StatusChip(
                      label: l10n.topicStatusInProgress,
                      isSelected: _status == TopicStatus.inProgress,
                      color: Colors.amber.shade800,
                      onTap: () =>
                          setState(() => _status = TopicStatus.inProgress),
                    ),
                    _StatusChip(
                      label: l10n.topicStatusCompleted,
                      isSelected: _status == TopicStatus.completed,
                      color: Colors.green,
                      onTap: () =>
                          setState(() => _status = TopicStatus.completed),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                FilledButton(
                  key: const Key('submitTopicButton'),
                  style: FilledButton.styleFrom(
                    backgroundColor: purple,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _isEditing ? l10n.save : l10n.addTopic,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color:
              isSelected ? color.withValues(alpha: 0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : color.withValues(alpha: 0.3),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? color
                    : Theme.of(context).colorScheme.onSurface,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
