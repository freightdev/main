// lib/features/training/presentation/screens/quiz_screen.dart
import 'package:flutter/material.dart';

class QuizScreen extends StatelessWidget {
  final String courseId;
  final String quizId;
  
  const QuizScreen({
    Key? key,
    required this.courseId,
    required this.quizId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quiz')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.quiz, size: 64),
            const SizedBox(height: 16),
            Text('Quiz: $quizId'),
            const SizedBox(height: 24),
            const Text('Quiz Questions - Coming Soon'),
          ],
        ),
      ),
    );
  }
}
