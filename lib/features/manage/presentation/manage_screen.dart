// Manage screen – workspace, sprint, and backlog management.
// CRUD operations are a future phase.
import 'package:flutter/material.dart';
import 'package:task_map_flow/core/extensions/context_extensions.dart';

class ManageScreen extends StatelessWidget {
  const ManageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.manageTab)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.dashboard_outlined, size: 64),
            const SizedBox(height: 16),
            Text(
              l10n.manageScreenPlaceholder,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
