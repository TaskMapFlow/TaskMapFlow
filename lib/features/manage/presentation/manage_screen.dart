// Manage screen – workspace, sprint, and backlog management.
// CRUD operations are a future phase.
import 'package:flutter/material.dart';

class ManageScreen extends StatelessWidget {
  const ManageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Yönet')),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.dashboard_outlined, size: 64),
            SizedBox(height: 16),
            Text(
              'Çalışma alanı yönetimi bir sonraki aşamada eklenecek.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
