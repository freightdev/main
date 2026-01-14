import 'package:flutter/material.dart';

import '../models/driver.dart';
import '../styles/app_theme.dart';

class DriverCard extends StatelessWidget {
  final Driver driver;
  final VoidCallback? onTap;

  const DriverCard({
    super.key,
    required this.driver,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.statusInfo,
                  child: Text(
                    driver.initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        driver.fullName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        driver.email,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'License: ${driver.licenseNumber}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildStatusBadge(),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStat('Miles', '${driver.totalMiles ?? 0}'),
                const SizedBox(width: 16),
                _buildStat('Revenue',
                    '\$${(driver.totalRevenue ?? 0).toStringAsFixed(2)}'),
                const SizedBox(width: 16),
                _buildStat('Hours', '${driver.hoursAvailable ?? 0}h'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color color;
    String text;

    switch (driver.status) {
      case DriverStatus.active:
        color = AppColors.statusSuccess;
        text = 'ACTIVE';
        break;
      case DriverStatus.onDuty:
        color = AppColors.statusInfo;
        text = 'ON DUTY';
        break;
      case DriverStatus.offDuty:
        color = AppColors.statusWarning;
        text = 'OFF DUTY';
        break;
      case DriverStatus.sleeping:
        color = AppColors.statusInfo;
        text = 'SLEEPING';
        break;
      case DriverStatus.inactive:
        color = AppColors.statusError;
        text = 'INACTIVE';
        break;
      case DriverStatus.online:
        color = AppColors.statusSuccess;
        text = 'ONLINE';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
