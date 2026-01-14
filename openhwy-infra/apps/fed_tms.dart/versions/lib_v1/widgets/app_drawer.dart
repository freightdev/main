import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../styles/app_theme.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.backgroundDark,
      child: Column(
        children: [
          // Header with close button
          Container(
            height: 140,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1976D2), Color(0xFF2196F3)],
              ),
            ),
            child: Row(
              children: [
                // Logo and title in center
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.white,
                          child:
                              Icon(Icons.business, color: Color(0xFF1976D2))),
                      const SizedBox(height: 10),
                      const Text(
                        'TMS Pro',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Transport Management',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // Close button on right
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Close Drawer',
                  iconSize: 20,
                ),
                // Space on right for balance
                const SizedBox(width: 20),
              ],
            ),
          ),

          // Navigation items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              children: [
                ListTile(
                  leading: const Icon(Icons.dashboard, color: Colors.white),
                  title: const Text('Dashboard',
                      style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context); // Close drawer first
                    context.go('/dashboard');
                  },
                  selected: true,
                  selectedTileColor: Colors.white.withOpacity(0.1),
                ),
                ListTile(
                  leading:
                      const Icon(Icons.local_shipping, color: Colors.white),
                  title: const Text('Loads',
                      style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context); // Close drawer first
                    context.go('/loads');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.people, color: Colors.white),
                  title: const Text('Drivers',
                      style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context); // Close drawer first
                    context.go('/drivers');
                  },
                ),
                Container(
                  height: 1,
                  color: Colors.white24,
                ),
                ListTile(
                  leading: const Icon(Icons.attach_money, color: Colors.white),
                  title: const Text('Accounting',
                      style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context); // Close drawer first
                    context.go('/invoices');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.gavel, color: Colors.white),
                  title: const Text('Compliance',
                      style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context); // Close drawer first
                    context.go('/documents');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.notifications, color: Colors.white),
                  title: const Text('Notifications',
                      style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context); // Close drawer first
                    context.go('/notifications');
                  },
                ),
                Container(
                  height: 1,
                  color: Colors.white24,
                ),
                ListTile(
                  leading: const Icon(Icons.settings, color: Colors.white),
                  title: const Text('Settings',
                      style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context); // Close drawer first
                    context.go('/settings');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.person, color: Colors.white),
                  title: const Text('Profile',
                      style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context); // Close drawer first
                    context.go('/profile');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.analytics, color: Colors.white),
                  title: const Text('Analytics',
                      style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context); // Close drawer first
                    context.go('/analytics');
                  },
                ),
                ListTile(
                  leading:
                      const Icon(Icons.calendar_today, color: Colors.white),
                  title: const Text('Calendar',
                      style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context); // Close drawer first
                    context.go('/calendar');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.message, color: Colors.white),
                  title: const Text('Messages',
                      style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context); // Close drawer first
                    context.go('/messages');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.assessment, color: Colors.white),
                  title: const Text('Reports',
                      style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context); // Close drawer first
                    context.go('/reports');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
