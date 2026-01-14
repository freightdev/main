import 'dart:core';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fed_tms/core/styles/app_theme.dart';
import 'package:fed_tms/core/styles/app_theme.dart';
import 'package:fed_tms/features/drivers/data/models/driver.dart';
import 'package:fed_tms/features/drivers/data/models/driver.dart';


class DriverDetailScreen extends ConsumerWidget {
  final String driverId;

  const DriverDetailScreen({super.key, required this.driverId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Simple driver detail view
    final driver = Driver(
      id: driverId,
      firstName: [
        'John',
        'Jane',
        'Mike'
      ][int.parse(driverId.substring(0, 1)) % 3],
      lastName: [
        'Smith',
        'Johnson',
        'Williams'
      ][int.parse(driverId.substring(0, 1)) % 3],
      email: [
        'john.smith@email.com',
        'jane.johnson@trucking.com',
        'mike.williams@hwytms.com'
      ][int.parse(driverId.substring(0, 1)) % 3],
      phone: [
        '555-0123',
        '555-0456',
        '555-0789'
      ][int.parse(driverId.substring(0, 1)) % 3],
      status: DriverStatus.active,
      activeLoads: 12,
      totalLoads: 45,
      rating: 4.5,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Driver: ${driver.fullName}'),
        backgroundColor: AppTheme.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: AppTheme.primary,
              child: Text(
                driver.firstName[0],
                style:
                    const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            Text(driver.fullName,
                style: Theme.of(context).textTheme.displaySmall),
            Text(driver.email, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Status: ${driver.status.name}'),
                    const SizedBox(height: 8),
                    Text('Active Loads: ${driver.activeLoads}'),
                    Text('Total Loads: ${driver.totalLoads}'),
                    if (driver.rating != null)
                      Text('Rating: ${driver.rating!.toStringAsFixed(1)} ⭐'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
