// lib/features/training/presentation/screens/progress_screen.dart
import 'package:flutter/material.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your Progress')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.trending_up, size: 64, color: Colors.green),
            const SizedBox(height: 16),
            const Text(
              'Progress Tracking',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            const Text('Detailed progress metrics - Coming Soon'),
          ],
        ),
      ),
    );
  }
}
