// lib/features/marketplace/presentation/screens/browse_drivers_screen.dart
import 'package:flutter/material.dart';

class BrowseDriversScreen extends StatelessWidget {
  const BrowseDriversScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Browse Drivers')),
      body: const Center(child: Text('Browse Drivers - Coming Soon')),
    );
  }
}
