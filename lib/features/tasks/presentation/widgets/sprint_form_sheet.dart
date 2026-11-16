import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:task_map_flow/app/theme.dart';
import 'package:task_map_flow/core/extensions/context_extensions.dart';
import 'package:task_map_flow/core/result/result.dart';
import 'package:task_map_flow/features/tasks/domain/models/sprint_model.dart';
import 'package:task_map_flow/features/tasks/presentation/providers/sprint_providers.dart';
import 'package:task_map_flow/features/workspaces/presentation/providers/workspace_providers.dart';

class SprintFormSheet extends ConsumerStatefulWidget {
  const SprintFormSheet({
    super.key,
    required this.workspaceId,
    this.initialSprint,
  });

  final String workspaceId;
  final SprintModel? initialSprint;

  static Future<void> show({
    required BuildContext context,
    required String workspaceId,
    SprintModel? initialSprint,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SprintFormSheet(
        workspaceId: workspaceId,
        initialSprint: initialSprint,
      ),
    );
  }

  @override
  ConsumerState<SprintFormSheet> createState() => _SprintFormSheetState();
}

class _SprintFormSheetState extends ConsumerState<SprintFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _goalController;
  late DateTime _startDate;
  late DateTime _endDate;
  late SprintStatus _status;
  bool _isLoading = false;
  String? _errorMessage;

  bool get _isEditing => widget.initialSprint != null;

  @override
  void initState() {
    super.initState();
    final sprint = widget.initialSprint;
    _nameController = TextEditingController(text: sprint?.name ?? '');
    _goalController = TextEditingController(text: sprint?.goal ?? '');

    final now = DateTime.now();
    _startDate =
        sprint?.startDate ?? DateTime.utc(now.year, now.month, now.day);
    _endDate = sprint?.endDate ??
        DateTime.utc(now.year, now.month, now.day)
            .add(const Duration(days: 14));
    _status = sprint?.status ?? SprintStatus.planned;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _goalController.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _startDate = DateTime.utc(picked.year, picked.month, picked.day);
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate.add(const Duration(days: 14));
        }
      });
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate.isBefore(_startDate) ? _startDate : _endDate,
      firstDate: _startDate,
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _endDate = DateTime.utc(picked.year, picked.month, picked.day);
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_endDate.isBefore(_startDate)) {
      setState(() {
        _errorMessage = context.l10n.dateOrderError;
      });
      return;
    }

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

    final controller = ref.read(sprintControllerProvider.notifier);
    final name = _nameController.text.trim();
    final goal = _goalController.text.trim();

    Result<dynamic> result;
    if (_isEditing) {
      result = await controller.updateSprint(
        workspaceId: widget.workspaceId,
        sprintId: widget.initialSprint!.id,
        name: name,
        goal: goal,
        startDate: _startDate,
        endDate: _endDate,
        status: _status,
      );
    } else {
      result = await controller.createSprint(
        workspaceId: widget.workspaceId,
        ownerId: uid,
        name: name,
        goal: goal,
        startDate: _startDate,
        endDate: _endDate,
        status: _status,
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

              Text(
                _isEditing ? l10n.editSprint : l10n.createSprint,
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),

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
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Sprint Name
              Text(
                l10n.sprintName,
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameController,
                maxLength: 100,
                style: TextStyle(color: textPrimary, fontSize: 15),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Lütfen sprint adı girin';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  hintText: 'Sprint 1',
                  hintStyle: TextStyle(
                      color: textSecondary.withValues(alpha: 0.6),
                      fontSize: 14),
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
              ),
              const SizedBox(height: 14),

              // Sprint Goal
              Text(
                l10n.sprintGoal,
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _goalController,
                maxLines: 2,
                maxLength: 500,
                style: TextStyle(color: textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Bu sprintin ana hedefi...',
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

              // Date Range Selectors
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.startDate,
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.calendar_today_outlined,
                              size: 15),
                          label: Text(
                            DateFormat.yMMMd(locale).format(_startDate),
                            style: TextStyle(color: textPrimary, fontSize: 12),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 10),
                            side: BorderSide(color: inputBorder),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _pickStartDate,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.endDate,
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.event_available_outlined,
                              size: 15),
                          label: Text(
                            DateFormat.yMMMd(locale).format(_endDate),
                            style: TextStyle(color: textPrimary, fontSize: 12),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 10),
                            side: BorderSide(color: inputBorder),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _pickEndDate,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Status (if editing)
              if (_isEditing) ...[
                Text(
                  'Durum',
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
                    ChoiceChip(
                      label: Text(l10n.sprintStatusPlanned),
                      selected: _status == SprintStatus.planned,
                      onSelected: (val) {
                        if (val) {
                          setState(() => _status = SprintStatus.planned);
                        }
                      },
                    ),
                    ChoiceChip(
                      label: Text(l10n.sprintStatusActive),
                      selected: _status == SprintStatus.active,
                      onSelected: (val) {
                        if (val) {
                          setState(() => _status = SprintStatus.active);
                        }
                      },
                    ),
                    ChoiceChip(
                      label: Text(l10n.sprintStatusCompleted),
                      selected: _status == SprintStatus.completed,
                      onSelected: (val) {
                        if (val) {
                          setState(() => _status = SprintStatus.completed);
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 14),
              ],

              const SizedBox(height: 8),

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
                        _isEditing ? l10n.save : l10n.createSprint,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
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
