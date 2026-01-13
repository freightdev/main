// lib/features/gamification/presentation/screens/badges_screen.dart
import 'package:flutter/material.dart';

class BadgesScreen extends StatelessWidget {
  const BadgesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Badges')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.stars, size: 64, color: Colors.amber),
            const SizedBox(height: 16),
            const Text(
              'Your Badges',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            const Text('Badge Collection - Coming Soon'),
          ],
        ),
      ),
    );
  }
}
