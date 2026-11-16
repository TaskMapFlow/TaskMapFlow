import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_map_flow/app/theme.dart';
import 'package:task_map_flow/core/extensions/context_extensions.dart';
import 'package:task_map_flow/core/result/result.dart';
import 'package:task_map_flow/features/profile/domain/models/user_profile.dart';
import 'package:task_map_flow/features/profile/presentation/providers/profile_providers.dart';
import 'package:task_map_flow/features/workspaces/presentation/providers/workspace_providers.dart';

class EditProfileSheet extends ConsumerStatefulWidget {
  const EditProfileSheet({
    super.key,
    required this.currentProfile,
    required this.authDisplayName,
  });

  final UserProfile? currentProfile;
  final String authDisplayName;

  static Future<void> show({
    required BuildContext context,
    required UserProfile? currentProfile,
    required String authDisplayName,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => EditProfileSheet(
        currentProfile: currentProfile,
        authDisplayName: authDisplayName,
      ),
    );
  }

  @override
  ConsumerState<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _githubController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final initialName = widget.currentProfile?.displayName.isNotEmpty == true
        ? widget.currentProfile!.displayName
        : widget.authDisplayName;
    _nameController = TextEditingController(text: initialName);
    _bioController =
        TextEditingController(text: widget.currentProfile?.bio ?? '');
    _githubController =
        TextEditingController(text: widget.currentProfile?.githubUrl ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _githubController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final uid = ref.read(currentUserIdProvider);
    if (uid == null || uid.isEmpty) return;

    setState(() => _isSubmitting = true);

    final now = DateTime.now();
    final profile = UserProfile(
      id: uid,
      displayName: _nameController.text.trim(),
      bio: _bioController.text.trim(),
      githubUrl: _githubController.text.trim(),
      createdAt: widget.currentProfile?.createdAt ?? now,
      updatedAt: now,
    );

    final result =
        await ref.read(profileControllerProvider.notifier).saveProfile(profile);

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (result case Success()) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.profileSavedSuccess),
          ),
        );
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
    final sheetBg = isDark ? const Color(0xFF161522) : Colors.white;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final inputBg = isDark ? AppColors.darkInputFill : AppColors.lightInputFill;
    final purple =
        isDark ? AppColors.darkPrimaryPurple : AppColors.lightPrimaryPurple;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 24,
        left: 20,
        right: 20,
      ),
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.editProfile,
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    color: textSecondary,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Display Name
              Text(
                l10n.profileNameLabel,
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                key: const Key('profileDisplayNameField'),
                controller: _nameController,
                maxLength: 100,
                style: TextStyle(color: textPrimary, fontSize: 15),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: inputBg,
                  counterText: '',
                  hintText: l10n.profileNamePlaceholder,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return l10n.profileNameEmptyError;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Bio
              Text(
                l10n.profileBioLabel,
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                key: const Key('profileBioField'),
                controller: _bioController,
                maxLength: 300,
                maxLines: 3,
                minLines: 2,
                style: TextStyle(color: textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: inputBg,
                  hintText: l10n.profileBioPlaceholder,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // GitHub URL
              Text(
                l10n.githubUrlLabel,
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                key: const Key('profileGithubUrlField'),
                controller: _githubController,
                maxLength: 200,
                keyboardType: TextInputType.url,
                style: TextStyle(color: textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: inputBg,
                  counterText: '',
                  prefixIcon: const Icon(Icons.code_rounded, size: 20),
                  hintText: l10n.githubUrlPlaceholder,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (val) {
                  if (val != null && val.trim().isNotEmpty) {
                    if (!UserProfile.isValidGithubUrl(val)) {
                      return l10n.invalidGithubUrlError;
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Save Button
              FilledButton(
                key: const Key('saveProfileButton'),
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
                        l10n.save,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
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
