import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fed_tms/core/styles/app_theme.dart';
import 'package:fed_tms/features/loads/data/models/load.dart';
import 'package:fed_tms/features/loads/providers/load_provider.dart';


class LoadboardScreen extends ConsumerWidget {
  const LoadboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loadsAsync = ref.watch(loadsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Load Board'),
        backgroundColor: const Color(0xFF1976D2),
      ),
      body: loadsAsync.when(
        data: (loads) => RefreshIndicator(
          onRefresh: () async {
            ref.refresh(loadsProvider);
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: loads.length,
            itemBuilder: (context, index) {
              final load = loads[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  title: Text(
                    load.reference,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  subtitle: Text(
                    '${load.origin} → ${load.destination}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${load.rate?.toStringAsFixed(2) ?? '0.00'}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(load.status),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          load.status.name.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    // Navigate to load details
                  },
                ),
              );
            },
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text('Error loading loads: $err'),
        ),
      ),
    );
  }

  Color _getStatusColor(LoadStatus status) {
    switch (status) {
      case LoadStatus.pending:
        return Colors.orange;
      case LoadStatus.booked:
        return Colors.blue;
      case LoadStatus.inTransit:
        return Colors.purple;
      case LoadStatus.delivered:
        return Colors.green;
      case LoadStatus.cancelled:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
