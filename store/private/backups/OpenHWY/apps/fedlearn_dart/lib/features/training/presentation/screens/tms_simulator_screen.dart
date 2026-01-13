// lib/features/training/presentation/screens/tms_simulator_screen.dart
import 'package:flutter/material.dart';

class TMSSimulatorScreen extends StatelessWidget {
  const TMSSimulatorScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TMS Simulator')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.computer, size: 64),
            const SizedBox(height: 16),
            const Text(
              'TMS Simulator',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Practice dispatching in a safe environment'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // Start simulator
              },
              child: const Text('Start Practice Session'),
            ),
          ],
        ),
      ),
    );
  }
}
