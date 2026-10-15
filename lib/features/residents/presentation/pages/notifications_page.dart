import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../mock/residents_mock_data.dart';
import '../widgets/notification_card.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({
    super.key,
    required this.notifications,
    required this.onMarkAllAsRead,
  });

  final List<NotificationItem> notifications;
  final VoidCallback onMarkAllAsRead;

  @override
  Widget build(BuildContext context) {
    final unreadCount = notifications.where((item) => !item.isRead).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        if (notifications.isEmpty)
          const Center(
            child: Column(
              children: [
                Icon(
                  Icons.notifications_off_outlined,
                  size: 52,
                  color: AppColors.muted,
                ),
                SizedBox(height: 12),
                Text(
                  'No notifications',
                  style: TextStyle(
                    color: AppColors.navy,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'You are all caught up.',
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          )
        else ...[
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Recent updates',
                  style: TextStyle(
                    color: AppColors.navy,
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (unreadCount > 0)
                TextButton.icon(
                  onPressed: onMarkAllAsRead,
                  icon: const Icon(Icons.done_all_rounded, size: 18),
                  label: const Text('Mark all as read'),
                  style: TextButton.styleFrom(foregroundColor: AppColors.navy),
                ),
            ],
          ),
          const SizedBox(height: 16),
          ...notifications.map(
            (notification) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: NotificationCard(notification: notification),
            ),
          ),
        ],
      ],
    );
  }
}
