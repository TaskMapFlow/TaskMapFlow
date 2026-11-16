import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:task_map_flow/app/theme.dart';
import 'package:task_map_flow/core/extensions/context_extensions.dart';
import 'package:task_map_flow/features/notes/domain/models/note_model.dart';
import 'package:url_launcher/url_launcher.dart';

class NoteCard extends StatelessWidget {
  const NoteCard({
    super.key,
    required this.note,
    required this.isDark,
    required this.accentColor,
    required this.onTap,
    this.onEdit,
    this.onDelete,
  });

  final NoteModel note;
  final bool isDark;
  final Color accentColor;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    final cardBg = isDark ? const Color(0xFF161522) : Colors.white;
    final cardBorder =
        isDark ? const Color(0xFF262335) : const Color(0xFFE5E3EF);
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final formattedDate =
        DateFormat.yMMMd(locale).add_Hm().format(note.updatedAt);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: note.title.isNotEmpty
                      ? Text(
                          note.title,
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      : Text(
                          l10n.tabNotes,
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                ),
                if (onEdit != null || onDelete != null)
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_horiz_rounded,
                        size: 20, color: textSecondary),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    color: isDark ? const Color(0xFF1E1C2E) : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: cardBorder),
                    ),
                    onSelected: (value) {
                      if (value == 'edit') {
                        onEdit?.call();
                      } else if (value == 'delete') {
                        onDelete?.call();
                      }
                    },
                    itemBuilder: (context) => [
                      if (onEdit != null)
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined,
                                  size: 16, color: textPrimary),
                              const SizedBox(width: 8),
                              Text(l10n.editNote,
                                  style: TextStyle(
                                      color: textPrimary, fontSize: 13)),
                            ],
                          ),
                        ),
                      if (onDelete != null)
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline_rounded,
                                  size: 16,
                                  color: Theme.of(context).colorScheme.error),
                              const SizedBox(width: 8),
                              Text(
                                l10n.delete,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              note.content,
              style: TextStyle(
                color: textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.access_time_rounded,
                    size: 12, color: textSecondary.withValues(alpha: 0.7)),
                const SizedBox(width: 4),
                Text(
                  '${l10n.noteUpdated}: $formattedDate',
                  style: TextStyle(
                    color: textSecondary.withValues(alpha: 0.7),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class NoteDetailSheet extends StatelessWidget {
  const NoteDetailSheet({
    super.key,
    required this.note,
    required this.isDark,
    required this.accentColor,
    this.onEdit,
    this.onDelete,
  });

  final NoteModel note;
  final bool isDark;
  final Color accentColor;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  static Future<void> show(
    BuildContext context, {
    required NoteModel note,
    required bool isDark,
    required Color accentColor,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => NoteDetailSheet(
        note: note,
        isDark: isDark,
        accentColor: accentColor,
        onEdit: onEdit,
        onDelete: onDelete,
      ),
    );
  }

  Future<void> _launchUrl(BuildContext context, String urlString) async {
    final l10n = context.l10n;
    final trimmed = urlString.trim();
    final uri = Uri.tryParse(trimmed);
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.invalidUrlError),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    try {
      final launched =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.urlLaunchError),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.urlLaunchError),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  List<InlineSpan> _buildContentSpans(
    BuildContext context,
    String text,
    TextStyle normalStyle,
    TextStyle linkStyle,
  ) {
    final urlRegex = RegExp(r'https?://[^\s]+', caseSensitive: false);
    final spans = <InlineSpan>[];
    int lastEnd = 0;

    for (final match in urlRegex.allMatches(text)) {
      if (match.start > lastEnd) {
        spans.add(
          TextSpan(
            text: text.substring(lastEnd, match.start),
            style: normalStyle,
          ),
        );
      }
      final matchedUrl = match.group(0)!;
      spans.add(
        TextSpan(
          text: matchedUrl,
          style: linkStyle,
          recognizer: TapGestureRecognizer()
            ..onTap = () => _launchUrl(context, matchedUrl),
        ),
      );
      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(lastEnd),
          style: normalStyle,
        ),
      );
    }

    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    final bg = isDark ? const Color(0xFF161522) : Colors.white;
    final border = isDark ? const Color(0xFF262335) : const Color(0xFFE5E3EF);
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final formattedDate =
        DateFormat.yMMMMd(locale).add_Hm().format(note.updatedAt);

    final normalStyle = TextStyle(
      color: textPrimary,
      fontSize: 14,
      height: 1.5,
    );
    final linkStyle = TextStyle(
      color: accentColor,
      fontSize: 14,
      height: 1.5,
      decoration: TextDecoration.underline,
      decorationColor: accentColor,
      fontWeight: FontWeight.w600,
    );

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: border),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
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
            Row(
              children: [
                Expanded(
                  child: Text(
                    note.title.isNotEmpty ? note.title : l10n.tabNotes,
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (onEdit != null)
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    color: textSecondary,
                    tooltip: l10n.editNote,
                    onPressed: () {
                      Navigator.of(context).pop();
                      onEdit?.call();
                    },
                  ),
                if (onDelete != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 20),
                    color: Theme.of(context).colorScheme.error,
                    tooltip: l10n.delete,
                    onPressed: () {
                      Navigator.of(context).pop();
                      onDelete?.call();
                    },
                  ),
              ],
            ),
            Text(
              '${l10n.noteUpdated}: $formattedDate',
              style: TextStyle(color: textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 14),
            Flexible(
              child: SingleChildScrollView(
                child: SelectableText.rich(
                  TextSpan(
                    children: _buildContentSpans(
                      context,
                      note.content,
                      normalStyle,
                      linkStyle,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
