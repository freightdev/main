import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../styles/app_theme.dart';
import '../widgets/app_button.dart';

class CompanySetupScreen extends StatelessWidget {
  const CompanySetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Company Setup'),
        backgroundColor: Color(0xFF1A1A2E),
      ),
      body: Center(
        child: TextButton(
          onPressed: () {
            context.go('/dashboard');
          },
          child: Text('Complete Setup'),
        ),
      ),
    );
  }
}
