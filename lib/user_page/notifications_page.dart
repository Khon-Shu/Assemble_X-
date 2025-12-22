import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:assemblex/services/notification_service.dart';
import 'package:intl/intl.dart';

class NotificationsPage extends StatelessWidget {
  final NotificationService notificationService;
  
  const NotificationsPage({
    Key? key,
    required this.notificationService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: GoogleFonts.montserrat(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (notificationService.notifications.isNotEmpty)
            TextButton(
              onPressed: () {
                notificationService.markAllAsRead();
                // Force rebuild
                (context as Element).markNeedsBuild();
              },
              child: Text(
                'Mark all as read',
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
      body: notificationService.notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: notificationService.notifications.length,
              itemBuilder: (context, index) {
                final notification = notificationService.notifications[index];
                return _buildNotificationItem(context, notification);
              },
            ),
    );
  }

  Widget _buildNotificationItem(
      BuildContext context, Map<String, dynamic> notification) {
    final isRead = notification['isRead'] as bool;
    final time = notification['time'] as DateTime;
    final timeAgo = _formatTimeAgo(time);

    return Dismissible(
      key: Key(notification['id'].toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        // Remove the notification from the list
        notificationService.notifications.removeWhere(
            (n) => n['id'] == notification['id']);
        // Show a snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Notification deleted')),
        );
      },
      child: ListTile(
        onTap: () {
          // Mark as read when tapped
          if (!isRead) {
            notificationService.markAsRead(notification['id']);
            // Force rebuild
            (context as Element).markNeedsBuild();
          }
          // Handle navigation if needed
          // Navigator.push(...);
        },
        leading: CircleAvatar(
          backgroundColor: isRead
              ? Colors.grey[300]
              : Theme.of(context).colorScheme.primary,
          child: Icon(
            _getNotificationIcon(notification['title'] as String),
            color: isRead ? Colors.grey[600] : Colors.white,
          ),
        ),
        title: Text(
          notification['title'],
          style: GoogleFonts.montserrat(
            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
            color: isRead ? Colors.grey[600] : Colors.black,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification['body'],
              style: GoogleFonts.montserrat(
                color: isRead ? Colors.grey[500] : Colors.grey[700],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              timeAgo,
              style: GoogleFonts.montserrat(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
        trailing: !isRead
            ? Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              )
            : null,
      ),
    );
  }

  IconData _getNotificationIcon(String title) {
    if (title.contains('Added')) return Icons.add_circle_outline;
    if (title.contains('Updated')) return Icons.update;
    if (title.contains('Deleted')) return Icons.delete_outline;
    return Icons.notifications_none;
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) {
      final minutes = difference.inMinutes;
      return '$minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
    }
    if (difference.inDays < 1) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    }
    if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days ${days == 1 ? 'day' : 'days'} ago';
    }
    return DateFormat('MMM d, y').format(dateTime);
  }
}
