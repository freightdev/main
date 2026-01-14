import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: const Color(0xFF0D1117),
      ),
      backgroundColor: const Color(0xFF0A0E27),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildNotificationItem(
            'New Load Assigned',
            'Load LD-12345 has been assigned to John Doe',
            '2 minutes ago',
            false,
          ),
          _buildNotificationItem(
            'Payment Received',
            'Payment of \$2,500 received for load LD-12344',
            '1 hour ago',
            true,
          ),
          _buildNotificationItem(
            'Document Expiring',
            'Driver license for Jane Smith expires in 30 days',
            '3 hours ago',
            false,
          ),
          _buildNotificationItem(
            'Load Delivered',
            'Load LD-12343 has been marked as delivered',
            '5 hours ago',
            true,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(
    String title,
    String message,
    String time,
    bool isRead,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isRead ? const Color(0xFF1A1F3A) : const Color(0xFF1E3A8A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: isRead ? Colors.grey : Colors.blue,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
