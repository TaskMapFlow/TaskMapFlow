import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_map_flow/app/theme.dart';
import 'package:task_map_flow/core/extensions/context_extensions.dart';
import 'package:task_map_flow/core/result/result.dart';
import 'package:task_map_flow/features/workspaces/domain/models/workspace.dart';
import 'package:task_map_flow/features/workspaces/presentation/providers/workspace_providers.dart';

const List<String> kWorkspacePalette = [
  '#7C5CE8', // Primary purple
  '#38BDF8', // Cyan blue
  '#34D399', // Emerald green
  '#F472B6', // Rose pink
  '#FBBF24', // Amber gold
  '#818CF8', // Indigo
];

class CreateWorkspaceSheet extends ConsumerStatefulWidget {
  const CreateWorkspaceSheet({
    super.key,
    this.initialX = 1200,
    this.initialY = 1200,
  });

  final double initialX;
  final double initialY;

  static Future<Workspace?> show(
    BuildContext context, {
    double initialX = 1200,
    double initialY = 1200,
  }) {
    return showModalBottomSheet<Workspace>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateWorkspaceSheet(
        initialX: initialX,
        initialY: initialY,
      ),
    );
  }

  @override
  ConsumerState<CreateWorkspaceSheet> createState() =>
      _CreateWorkspaceSheetState();
}

class _CreateWorkspaceSheetState extends ConsumerState<CreateWorkspaceSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  WorkspaceType _selectedType = WorkspaceType.project;
  String _selectedColor = kWorkspacePalette.first;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Color _parseHex(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final uid = ref.read(currentUserIdProvider);
    if (uid == null || uid.isEmpty) {
      setState(() {
        _errorMessage = 'Oturum bilgisi bulunamadı.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result =
        await ref.read(workspaceControllerProvider.notifier).createWorkspace(
              name: _nameController.text.trim(),
              description: _descriptionController.text.trim(),
              type: _selectedType,
              color: _selectedColor,
              ownerId: uid,
              initialX: widget.initialX,
              initialY: widget.initialY,
            );

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      if (result case Success(:final value)) {
        Navigator.of(context).pop(value);
      } else if (result case Err(:final failure)) {
        setState(() {
          _errorMessage = failure.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

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
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.newAreaTitle,
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.4,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Text(
                l10n.areaTypeLabel,
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _TypeOption(
                    title: l10n.typeProject,
                    icon: Icons.rocket_launch_outlined,
                    isSelected: _selectedType == WorkspaceType.project,
                    selectedColor: _parseHex(_selectedColor),
                    onTap: () =>
                        setState(() => _selectedType = WorkspaceType.project),
                  ),
                  const SizedBox(width: 8),
                  _TypeOption(
                    title: l10n.typeLesson,
                    icon: Icons.school_outlined,
                    isSelected: _selectedType == WorkspaceType.lesson,
                    selectedColor: _parseHex(_selectedColor),
                    onTap: () =>
                        setState(() => _selectedType = WorkspaceType.lesson),
                  ),
                  const SizedBox(width: 8),
                  _TypeOption(
                    title: l10n.typeFreeform,
                    icon: Icons.bubble_chart_outlined,
                    isSelected: _selectedType == WorkspaceType.freeform,
                    selectedColor: _parseHex(_selectedColor),
                    onTap: () =>
                        setState(() => _selectedType = WorkspaceType.freeform),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                l10n.areaNameLabel,
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                key: const Key('workspaceNameInput'),
                controller: _nameController,
                maxLength: 100,
                style: TextStyle(color: textPrimary, fontSize: 15),
                decoration: InputDecoration(
                  hintText: l10n.areaNamePlaceholder,
                  hintStyle: TextStyle(
                    color: textSecondary.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                  filled: true,
                  fillColor: inputBg,
                  counterText: '',
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: inputBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: inputBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: purple, width: 1.5),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return l10n.areaNameRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Text(
                l10n.areaDescriptionLabel,
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                key: const Key('workspaceDescriptionInput'),
                controller: _descriptionController,
                maxLines: 3,
                maxLength: 500,
                style: TextStyle(color: textPrimary, fontSize: 15),
                decoration: InputDecoration(
                  hintText: l10n.areaDescriptionPlaceholder,
                  hintStyle: TextStyle(
                    color: textSecondary.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                  filled: true,
                  fillColor: inputBg,
                  counterText: '',
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: inputBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: inputBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: purple, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                l10n.areaColorLabel,
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: kWorkspacePalette.map((hex) {
                  final color = _parseHex(hex);
                  final isSelected = _selectedColor == hex;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = hex),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.transparent,
                          width: 2.5,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.5),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                )
                              ]
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check,
                              size: 22, color: Colors.white)
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 26),
              SizedBox(
                height: 52,
                child: FilledButton(
                  key: const Key('createWorkspaceSubmitButton'),
                  onPressed: _isLoading ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: purple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          l10n.create,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
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

class _TypeOption extends StatelessWidget {
  const _TypeOption({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.selectedColor,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final bool isSelected;
  final Color selectedColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isSelected
        ? selectedColor.withValues(alpha: 0.16)
        : (isDark ? AppColors.darkInputFill : AppColors.lightInputFill);
    final border = isSelected
        ? selectedColor
        : (isDark ? AppColors.darkInputBorder : AppColors.lightInputBorder);
    final text = isSelected
        ? selectedColor
        : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary);

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border, width: isSelected ? 1.5 : 1.0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22, color: text),
              const SizedBox(height: 6),
              Text(
                title,
                style: TextStyle(
                  color: text,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
