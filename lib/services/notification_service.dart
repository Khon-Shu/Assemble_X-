import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final List<Map<String, dynamic>> _notifications = [];

  // Initialize notifications (minimal setup for in-app notifications)
  Future<void> initialize() async {
    // No initialization needed for in-app only notifications
  }

  // Get all notifications
  List<Map<String, dynamic>> get notifications => List.unmodifiable(_notifications);
  
  // Get unread notifications count
  int get unreadCount => _notifications.where((n) => !n['isRead']).length;

  // Add a new notification to the in-app list
  void addNotification({
    required String title,
    required String body,
    String? payload,
  }) {
    _notifications.insert(0, {
      'id': DateTime.now().millisecondsSinceEpoch,
      'title': title,
      'body': body,
      'time': DateTime.now(),
      'isRead': false,
      'payload': payload,
    });
    
    // You can add a state management solution here if needed
    // to notify listeners about the new notification
  }
  
  // Mark a notification as read
  void markAsRead(int id) {
    final index = _notifications.indexWhere((n) => n['id'] == id);
    if (index != -1) {
      _notifications[index]['isRead'] = true;
    }
  }
  
  // Mark all notifications as read
  void markAllAsRead() {
    for (var notification in _notifications) {
      notification['isRead'] = true;
    }
  }

  // Show a notification when a product is added/updated/deleted
  void showProductNotification({
    required String productName, 
    required String category,
    required String action, // 'added', 'updated', or 'deleted'
  }) {
    final actionText = action == 'added' ? 'added to' : 
                      (action == 'updated' ? 'updated in' : 'removed from');
    
    addNotification(
      title: 'Product ${action.capitalize()}!',
      body: '$productName was $actionText the $category section',
      payload: '/products/$category',
    );
  }
}

// Extension to capitalize first letter of a string
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
