// lib/features/ai_assistant/presentation/screens/ai_chat_screen.dart
import 'package:flutter/material.dart';

class AIChatScreen extends StatelessWidget {
  const AIChatScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Assistant')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.smart_toy, size: 64, color: Colors.blue),
            const SizedBox(height: 16),
            const Text(
              'AI Assistant',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Get help learning to dispatch'),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.chat),
              label: const Text('Start Chat'),
            ),
          ],
        ),
      ),
    );
  }
}
