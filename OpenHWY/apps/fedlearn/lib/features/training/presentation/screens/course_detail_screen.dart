// lib/features/training/presentation/screens/course_details_screen.dart
import 'package:flutter/material.dart';

class CourseDetailsScreen extends StatelessWidget {
  final String courseId;
  
  const CourseDetailsScreen({
    Key? key,
    required this.courseId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Course Details')),
      body: Center(
        child: Text('Course Details for: $courseId'),
      ),
    );
  }
}
