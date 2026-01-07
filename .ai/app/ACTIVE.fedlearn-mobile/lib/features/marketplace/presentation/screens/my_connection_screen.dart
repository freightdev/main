// lib/features/marketplace/presentation/screens/my_connections_screen.dart
import 'package:flutter/material.dart';

class MyConnectionsScreen extends StatelessWidget {
  const MyConnectionsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Connections')),
      body: const Center(child: Text('Your Connections - Coming Soon')),
    );
  }
}
