// lib/features/gamification/presentation/screens/leaderboard_screen.dart
import 'package:flutter/material.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Leaderboard')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.leaderboard, size: 64, color: Colors.purple),
            const SizedBox(height: 16),
            const Text(
              'Leaderboard',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Compete with other dispatchers'),
            const SizedBox(height: 24),
            const Text('Rankings - Coming Soon'),
          ],
        ),
      ),
    );
  }
}
