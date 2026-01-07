// lib/features/marketplace/presentation/screens/browse_dispatchers_screen.dart
import 'package:flutter/material.dart';

class BrowseDispatchersScreen extends StatelessWidget {
  const BrowseDispatchersScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Browse Dispatchers')),
      body: const Center(child: Text('Browse Dispatchers - Coming Soon')),
    );
  }
}
