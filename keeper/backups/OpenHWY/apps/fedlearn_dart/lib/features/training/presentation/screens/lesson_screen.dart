// lib/features/training/presentation/screens/lesson_screen.dart
import 'package:flutter/material.dart';

class LessonScreen extends StatelessWidget {
  final String courseId;
  final String lessonId;
  
  const LessonScreen({
    Key? key,
    required this.courseId,
    required this.lessonId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lesson')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Course: $courseId'),
            Text('Lesson: $lessonId'),
            const SizedBox(height: 24),
            const Text('Lesson Content - Coming Soon'),
          ],
        ),
      ),
    );
  }
}
