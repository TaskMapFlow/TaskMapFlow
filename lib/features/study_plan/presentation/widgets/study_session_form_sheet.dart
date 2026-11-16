import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:task_map_flow/app/theme.dart';
import 'package:task_map_flow/core/extensions/context_extensions.dart';
import 'package:task_map_flow/core/result/result.dart';
import 'package:task_map_flow/features/study_plan/domain/models/study_session_model.dart';
import 'package:task_map_flow/features/study_plan/presentation/providers/study_plan_providers.dart';
import 'package:task_map_flow/features/workspaces/presentation/providers/workspace_providers.dart';

class StudySessionFormSheet extends ConsumerStatefulWidget {
  const StudySessionFormSheet({
    super.key,
    required this.workspaceId,
    this.existingSession,
    this.preselectedTopicId,
  });

  final String workspaceId;
  final StudySessionModel? existingSession;
  final String? preselectedTopicId;

  static Future<void> show(
    BuildContext context, {
    required String workspaceId,
    StudySessionModel? existingSession,
    String? preselectedTopicId,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StudySessionFormSheet(
        workspaceId: workspaceId,
        existingSession: existingSession,
        preselectedTopicId: preselectedTopicId,
      ),
    );
  }

  @override
  ConsumerState<StudySessionFormSheet> createState() =>
      _StudySessionFormSheetState();
}

class _StudySessionFormSheetState extends ConsumerState<StudySessionFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _durationController;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  String? _selectedTopicId;
  bool _isSubmitting = false;

  bool get _isEditing => widget.existingSession != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingSession;
    _titleController = TextEditingController(text: existing?.title ?? '');
    _durationController = TextEditingController(
      text: (existing?.plannedDurationMinutes ?? 45).toString(),
    );

    final initialDateTime =
        existing?.scheduledAt ?? DateTime.now().add(const Duration(hours: 1));
    _selectedDate = DateTime(
      initialDateTime.year,
      initialDateTime.month,
      initialDateTime.day,
    );
    _selectedTime = TimeOfDay(
      hour: initialDateTime.hour,
      minute: initialDateTime.minute,
    );

    _selectedTopicId = existing?.topicId ?? widget.preselectedTopicId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    final duration = int.tryParse(_durationController.text.trim()) ?? 0;
    if (duration < 1 || duration > 1440) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Süre 1 ile 1440 dakika arasında olmalıdır.')),
      );
      return;
    }

    final scheduledAt = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final uid = ref.read(currentUserIdProvider) ?? '';
    final title = _titleController.text.trim();

    setState(() => _isSubmitting = true);

    if (_isEditing) {
      final sessionId = widget.existingSession!.id;
      final result = await ref
          .read(studyPlanControllerProvider.notifier)
          .updateStudySession(
            workspaceId: widget.workspaceId,
            sessionId: sessionId,
            title: title,
            scheduledAt: scheduledAt,
            plannedDurationMinutes: duration,
            topicId: _selectedTopicId,
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
      final result = await ref
          .read(studyPlanControllerProvider.notifier)
          .createStudySession(
            workspaceId: widget.workspaceId,
            ownerId: uid,
            title: title,
            scheduledAt: scheduledAt,
            plannedDurationMinutes: duration,
            topicId: _selectedTopicId,
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
    final locale = Localizations.localeOf(context).languageCode;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF161522) : Colors.white;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final inputBg = isDark ? AppColors.darkInputFill : AppColors.lightInputFill;
    final purple =
        isDark ? AppColors.darkPrimaryPurple : AppColors.lightPrimaryPurple;

    final topicsAsync = ref.watch(topicsStreamProvider(widget.workspaceId));
    final topics = topicsAsync.valueOrNull ?? [];

    final formattedDate = DateFormat.yMMMMd(locale).format(_selectedDate);
    final formattedTime = _selectedTime.format(context);

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
                      _isEditing ? l10n.editSession : l10n.planSession,
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
                  l10n.sessionTitleLabel,
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
                    hintText: l10n.sessionTitlePlaceholder,
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
                // Topic dropdown
                Text(
                  l10n.sessionTopicLabel,
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String?>(
                  initialValue: topics.any((t) => t.id == _selectedTopicId)
                      ? _selectedTopicId
                      : null,
                  dropdownColor: bg,
                  style: TextStyle(color: textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: inputBg,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text(
                        l10n.noTopicSelected,
                        style: TextStyle(color: textSecondary),
                      ),
                    ),
                    ...topics.map(
                      (t) => DropdownMenuItem<String?>(
                        value: t.id,
                        child: Text(
                          t.title,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                  onChanged: (val) => setState(() => _selectedTopicId = val),
                ),
                const SizedBox(height: 14),
                // Date & Time pickers
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.sessionDateLabel,
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: _pickDate,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                              decoration: BoxDecoration(
                                color: inputBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF272435)
                                      : const Color(0xFFDCD8E8),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_today_rounded,
                                      size: 16, color: purple),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      formattedDate,
                                      style: TextStyle(
                                          color: textPrimary, fontSize: 13),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
                            l10n.sessionTimeLabel,
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: _pickTime,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                              decoration: BoxDecoration(
                                color: inputBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF272435)
                                      : const Color(0xFFDCD8E8),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.access_time_rounded,
                                      size: 16, color: purple),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      formattedTime,
                                      style: TextStyle(
                                          color: textPrimary, fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Planned Duration
                Text(
                  l10n.sessionPlannedDurationLabel,
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _durationController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: TextStyle(color: textPrimary),
                  decoration: InputDecoration(
                    suffixText: 'dk',
                    filled: true,
                    fillColor: inputBg,
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
                const SizedBox(height: 8),
                // Duration presets
                Wrap(
                  spacing: 6,
                  children: [25, 30, 45, 60, 90].map((mins) {
                    return ActionChip(
                      label: Text('$mins dk',
                          style: const TextStyle(fontSize: 11)),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        setState(() {
                          _durationController.text = mins.toString();
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                FilledButton(
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
                          _isEditing ? l10n.save : l10n.planSession,
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
