import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:task_map_flow/app/theme.dart';
import 'package:task_map_flow/core/extensions/context_extensions.dart';
import 'package:task_map_flow/core/result/result.dart';
import 'package:task_map_flow/features/tasks/domain/models/task_model.dart';
import 'package:task_map_flow/features/tasks/domain/models/task_priority.dart';
import 'package:task_map_flow/features/tasks/domain/models/task_status.dart';
import 'package:task_map_flow/features/tasks/presentation/providers/task_providers.dart';
import 'package:task_map_flow/features/workspaces/domain/models/workspace.dart';
import 'package:task_map_flow/features/workspaces/presentation/providers/workspace_providers.dart';

class TaskFormSheet extends ConsumerStatefulWidget {
  const TaskFormSheet({
    super.key,
    required this.workspaceId,
    required this.workspaceType,
    this.initialTask,
  });

  final String workspaceId;
  final WorkspaceType workspaceType;
  final TaskModel? initialTask;

  static Future<void> show({
    required BuildContext context,
    required String workspaceId,
    required WorkspaceType workspaceType,
    TaskModel? initialTask,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TaskFormSheet(
        workspaceId: workspaceId,
        workspaceType: workspaceType,
        initialTask: initialTask,
      ),
    );
  }

  @override
  ConsumerState<TaskFormSheet> createState() => _TaskFormSheetState();
}

class _TaskFormSheetState extends ConsumerState<TaskFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TaskStatus _selectedStatus;
  late TaskPriority _selectedPriority;
  DateTime? _selectedDueDate;
  bool _isLoading = false;
  String? _errorMessage;

  bool get _isEditing => widget.initialTask != null;
  bool get _isLesson => widget.workspaceType == WorkspaceType.lesson;

  @override
  void initState() {
    super.initState();
    final task = widget.initialTask;
    _titleController = TextEditingController(text: task?.title ?? '');
    _descController = TextEditingController(text: task?.description ?? '');
    _selectedStatus = task?.status ?? TaskStatus.todo;
    _selectedPriority = task?.priority ?? TaskPriority.medium;
    _selectedDueDate = task?.dueDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final initialDate = _selectedDueDate ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _selectedDueDate = DateTime.utc(picked.year, picked.month, picked.day);
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final uid = ref.read(currentUserIdProvider);
    if (uid == null || uid.isEmpty) {
      setState(() {
        _errorMessage = context.l10n.authErrorUnknown;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final controller = ref.read(taskControllerProvider.notifier);
    final title = _titleController.text.trim();
    final description = _descController.text.trim();

    Result<dynamic> result;
    if (_isEditing) {
      result = await controller.updateTask(
        workspaceId: widget.workspaceId,
        taskId: widget.initialTask!.id,
        title: title,
        description: description,
        status: _selectedStatus,
        priority: _selectedPriority,
        dueDate: _selectedDueDate,
      );
    } else {
      result = await controller.createTask(
        workspaceId: widget.workspaceId,
        ownerId: uid,
        title: title,
        description: description,
        status: _selectedStatus,
        priority: _selectedPriority,
        dueDate: _selectedDueDate,
      );
    }

    if (mounted) {
      setState(() => _isLoading = false);
      if (result case Success()) {
        Navigator.of(context).pop();
      } else if (result case Err(:final failure)) {
        setState(() => _errorMessage = failure.message);
      }
    }
  }

  Future<void> _confirmDelete() async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteTaskConfirmTitle),
        content: Text(l10n.deleteTaskConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isLoading = true);
      final result = await ref.read(taskControllerProvider.notifier).deleteTask(
            workspaceId: widget.workspaceId,
            taskId: widget.initialTask!.id,
          );
      if (mounted) {
        setState(() => _isLoading = false);
        if (result case Success()) {
          Navigator.of(context).pop();
        } else if (result case Err(:final failure)) {
          setState(() => _errorMessage = failure.message);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final locale = Localizations.localeOf(context).languageCode;

    final bg = isDark ? const Color(0xFF14131B) : Colors.white;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final inputBorder =
        isDark ? AppColors.darkInputBorder : AppColors.lightInputBorder;
    final inputBg = isDark ? AppColors.darkInputFill : AppColors.lightInputFill;
    final purple =
        isDark ? AppColors.darkPrimaryPurple : AppColors.lightPrimaryPurple;

    final sheetTitle =
        _isEditing ? l10n.editTask : (_isLesson ? l10n.addStep : l10n.addTask);
    final titleLabel = _isLesson ? l10n.stepTitle : l10n.taskTitle;
    final titlePlaceholder =
        _isLesson ? l10n.stepTitlePlaceholder : l10n.taskTitlePlaceholder;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF262335) : const Color(0xFFE2E0EE),
          ),
        ),
      ),
      padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottomInset),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF2F2C3D)
                        : const Color(0xFFD6D4E5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title bar with Delete icon if editing
              Row(
                children: [
                  Text(
                    sheetTitle,
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  if (_isEditing)
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded),
                      color: Theme.of(context).colorScheme.error,
                      tooltip: l10n.deleteTask,
                      onPressed: _isLoading ? null : _confirmDelete,
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Error banner if any
              if (_errorMessage != null) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .error
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .error
                          .withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Task Title Input
              Text(
                titleLabel,
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
                  hintText: titlePlaceholder,
                  hintStyle: TextStyle(
                      color: textSecondary.withValues(alpha: 0.6),
                      fontSize: 13),
                  filled: true,
                  fillColor: inputBg,
                  counterText: '',
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: inputBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: inputBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: purple, width: 1.5),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return l10n.taskTitleRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Description Input
              Text(
                l10n.taskDescription,
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _descController,
                maxLines: 3,
                maxLength: 1000,
                style: TextStyle(color: textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: l10n.taskDescriptionPlaceholder,
                  hintStyle: TextStyle(
                      color: textSecondary.withValues(alpha: 0.6),
                      fontSize: 13),
                  filled: true,
                  fillColor: inputBg,
                  counterText: '',
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: inputBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: inputBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: purple, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Status Selector
              Text(
                l10n.taskStatus,
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: [
                  _StatusChip(
                    label: l10n.statusTodo,
                    isSelected: _selectedStatus == TaskStatus.todo,
                    onTap: () =>
                        setState(() => _selectedStatus = TaskStatus.todo),
                  ),
                  _StatusChip(
                    label: l10n.statusInProgress,
                    isSelected: _selectedStatus == TaskStatus.inProgress,
                    onTap: () =>
                        setState(() => _selectedStatus = TaskStatus.inProgress),
                  ),
                  _StatusChip(
                    label: l10n.statusCompleted,
                    isSelected: _selectedStatus == TaskStatus.completed,
                    onTap: () =>
                        setState(() => _selectedStatus = TaskStatus.completed),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Priority Selector
              Text(
                l10n.taskPriority,
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: [
                  _PriorityChip(
                    label: l10n.priorityLow,
                    isSelected: _selectedPriority == TaskPriority.low,
                    color: const Color(0xFF94A3B8),
                    onTap: () =>
                        setState(() => _selectedPriority = TaskPriority.low),
                  ),
                  _PriorityChip(
                    label: l10n.priorityMedium,
                    isSelected: _selectedPriority == TaskPriority.medium,
                    color: const Color(0xFF818CF8),
                    onTap: () =>
                        setState(() => _selectedPriority = TaskPriority.medium),
                  ),
                  _PriorityChip(
                    label: l10n.priorityHigh,
                    isSelected: _selectedPriority == TaskPriority.high,
                    color: const Color(0xFFF87171),
                    onTap: () =>
                        setState(() => _selectedPriority = TaskPriority.high),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Due Date Selector
              Text(
                l10n.dueDate,
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today_outlined, size: 16),
                      label: Text(
                        _selectedDueDate != null
                            ? DateFormat.yMMMd(locale).format(_selectedDueDate!)
                            : l10n.selectDate,
                        style: TextStyle(
                          color: _selectedDueDate != null
                              ? textPrimary
                              : textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        side: BorderSide(
                          color: _selectedDueDate != null
                              ? purple
                              : (isDark
                                  ? const Color(0xFF2E2B3E)
                                  : const Color(0xFFDFDDE8)),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _pickDueDate,
                    ),
                  ),
                  if (_selectedDueDate != null) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 20),
                      color: textSecondary,
                      tooltip: l10n.clearDate,
                      onPressed: () => setState(() => _selectedDueDate = null),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 20),

              // Submit Button
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: purple,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _isEditing ? l10n.save : sheetTitle,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ],
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
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final purple =
        isDark ? AppColors.darkPrimaryPurple : AppColors.lightPrimaryPurple;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : textSecondary,
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
      ),
      selectedColor: purple,
      backgroundColor:
          isDark ? const Color(0xFF1E1C2B) : const Color(0xFFF1F0F7),
      side: BorderSide(
        color: isSelected
            ? purple
            : (isDark ? const Color(0xFF2C293C) : const Color(0xFFDFDDE8)),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}

class _PriorityChip extends StatelessWidget {
  const _PriorityChip({
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : textSecondary,
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
      ),
      selectedColor: color,
      backgroundColor:
          isDark ? const Color(0xFF1E1C2B) : const Color(0xFFF1F0F7),
      side: BorderSide(
        color: isSelected
            ? color
            : (isDark ? const Color(0xFF2C293C) : const Color(0xFFDFDDE8)),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}
