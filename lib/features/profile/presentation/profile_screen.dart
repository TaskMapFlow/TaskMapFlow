// Profile screen – user bio, CV link, GitHub, completed work archive.
// Content is a future phase.
import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_outlined, size: 64),
            SizedBox(height: 16),
            Text(
              'Profil içeriği bir sonraki aşamada eklenecek.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
