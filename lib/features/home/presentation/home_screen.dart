// Home screen – visual task map canvas.
// Map implementation is a future phase; screen is intentionally minimal.
import 'package:flutter/material.dart';
import 'package:task_map_flow/core/extensions/context_extensions.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.appTitle)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.map_outlined, size: 64),
            const SizedBox(height: 16),
            Text(
              l10n.homeScreenPlaceholder,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
