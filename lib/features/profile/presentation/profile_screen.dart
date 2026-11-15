// Profile screen – user bio, CV link, GitHub, completed work archive.
// Content is a future phase.
import 'package:flutter/material.dart';
import 'package:task_map_flow/core/extensions/context_extensions.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileTab)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person_outlined, size: 64),
            const SizedBox(height: 16),
            Text(
              l10n.profileScreenPlaceholder,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
