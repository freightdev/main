import 'package:flutter/material.dart';

import 'package:playground/core/styles/colors.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.backgroundDark,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1976D2), Color(0xFF2196F3)],
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 20),
                CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.business, color: Color(0xFF1976D2))),
                const SizedBox(height: 10),
                const Text(
                  'TMS Pro',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
          ListTile(
            leading: const Icon(Icons.dashboard, color: Colors.white),
            title:
                const Text('Dashboard', style: TextStyle(color: Colors.white)),
            onTap: () {},
            selected: true,
            selectedTileColor: Colors.white.withOpacity(0.1),
          ),
          ListTile(
            leading: const Icon(Icons.local_shipping, color: Colors.white),
            title: const Text('Loads', style: TextStyle(color: Colors.white)),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.people, color: Colors.white),
            title: const Text('Drivers', style: TextStyle(color: Colors.white)),
            onTap: () {},
          ),
          const Divider(color: Colors.white24),
          ListTile(
            leading: const Icon(Icons.attach_money, color: Colors.white),
            title:
                const Text('Accounting', style: TextStyle(color: Colors.white)),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.gavel, color: Colors.white),
            title:
                const Text('Compliance', style: TextStyle(color: Colors.white)),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.notifications, color: Colors.white),
            title: const Text('Notifications',
                style: TextStyle(color: Colors.white)),
            onTap: () {},
          ),
          const Divider(color: Colors.white24),
          ListTile(
            leading: const Icon(Icons.settings, color: Colors.white),
            title:
                const Text('Settings', style: TextStyle(color: Colors.white)),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
