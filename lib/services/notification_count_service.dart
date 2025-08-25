// services/notification_count_service.dart
import 'package:flutter/material.dart';
import 'notification_service.dart';

class NotificationCountService extends ChangeNotifier {
  static final NotificationCountService _instance = NotificationCountService._internal();
  factory NotificationCountService() => _instance;
  NotificationCountService._internal();

  int _unreadCount = 0;
  bool _isLoading = false;

  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;

  // Fetch unread notification count
  Future<void> fetchUnreadCount(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final notifications = await NotificationService().getUserNotifications(userId);
      _unreadCount = notifications.where((n) => !n.isRead).length;
    } catch (e) {
      print('Error fetching notification count: $e');
      _unreadCount = 0;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Decrease count when notification is read
  void decreaseCount([int amount = 1]) {
    if (_unreadCount > 0) {
      _unreadCount = (_unreadCount - amount).clamp(0, _unreadCount);
      notifyListeners();
    }
  }

  // Increase count when new notification arrives
  void increaseCount([int amount = 1]) {
    _unreadCount += amount;
    notifyListeners();
  }

  // Reset count (when mark all as read)
  void resetCount() {
    _unreadCount = 0;
    notifyListeners();
  }

  // Set specific count
  void setCount(int count) {
    _unreadCount = count.clamp(0, 999);
    notifyListeners();
  }
}