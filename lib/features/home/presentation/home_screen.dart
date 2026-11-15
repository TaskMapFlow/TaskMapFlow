// Home screen – visual task map canvas.
// Map implementation is a future phase; screen is intentionally minimal.
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TaskMapFlow')),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.map_outlined, size: 64),
            SizedBox(height: 16),
            Text(
              'Harita görünümü bir sonraki aşamada eklenecek.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
