// lib/features/gamification/presentation/screens/shop_screen.dart
import 'package:flutter/material.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shop')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shopping_cart, size: 64),
            const SizedBox(height: 16),
            const Text(
              'In-App Shop',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Buy hearts, crates, and power-ups'),
            const SizedBox(height: 24),
            const Text('Shop Items - Coming Soon'),
          ],
        ),
      ),
    );
  }
}
