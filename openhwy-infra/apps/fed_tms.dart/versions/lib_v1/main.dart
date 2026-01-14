import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'styles/app_theme.dart';
import 'router.dart';
// Temporarily disable playground
// import 'playground.dart';

void main() {
  runApp(
    const ProviderScope(
      child: FedTmsApp(),
    ),
  );
}

class FedTmsApp extends ConsumerWidget {
  const FedTmsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'OPENHWY-TMS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}
