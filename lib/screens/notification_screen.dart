import 'package:baraja_app/screens/notification_detail_screen.dart';
import 'package:flutter/material.dart';
import '../widgets/utils/classic_app_bar.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationScreen extends StatefulWidget {
  final String userId;
  const NotificationScreen({super.key, required this.userId});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<NotificationModel> notifications = [];
  bool isLoading = true;
  bool isMarkingAllAsRead = false;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      isLoading = true;
    });

    try {
      final result = await NotificationService().getUserNotifications(widget.userId);
      setState(() {
        notifications = result;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat notifikasi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _markAllAsRead() async {
    if (notifications.every((n) => n.isRead)) return;

    setState(() {
      isMarkingAllAsRead = true;
    });

    try {
      await NotificationService().markAllNotificationsAsRead(widget.userId);

      // Refresh data dari server untuk memastikan konsistensi
      await _loadNotifications();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Semua notifikasi ditandai sebagai dibaca'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menandai semua sebagai dibaca: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        isMarkingAllAsRead = false;
      });
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'event':
        return Colors.blue;
      case 'promo':
        return Colors.orange;
      case 'update':
        return Colors.purple;
      case 'info':
      default:
        return Colors.green;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'event':
        return Icons.event;
      case 'promo':
        return Icons.local_offer;
      case 'update':
        return Icons.system_update;
      case 'info':
      default:
        return Icons.info;
    }
  }

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: ClassicAppBar(
        title: 'Pemberitahuan',
        actions: [
          if (unreadCount > 0)
            IconButton(
              icon: isMarkingAllAsRead
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Icon(Icons.mark_email_read),
              onPressed: isMarkingAllAsRead ? null : _markAllAsRead,
              tooltip: 'Tandai semua sebagai dibaca',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNotifications,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadNotifications,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : notifications.isEmpty
            ? ListView(
          children: const [
            SizedBox(height: 200),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    "Tidak ada notifikasi",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        )
            : Column(
          children: [
            // Unread count banner
            if (unreadCount > 0)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                color: Colors.blue.shade50,
                child: Text(
                  '$unreadCount notifikasi belum dibaca',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            // Notifications list
            Expanded(
              child: ListView.builder(
                itemCount: notifications.length,
                padding: const EdgeInsets.all(16),
                itemBuilder: (context, index) {
                  final notif = notifications[index];
                  return Card(
                    elevation: notif.isRead ? 1 : 3,
                    margin: const EdgeInsets.only(bottom: 12),
                    color: notif.isRead ? Colors.white : Colors.blue.shade50,
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: Stack(
                        children: [
                          CircleAvatar(
                            backgroundColor: _getTypeColor(notif.type).withOpacity(0.1),
                            child: Icon(
                              _getTypeIcon(notif.type),
                              color: _getTypeColor(notif.type),
                            ),
                          ),
                          if (!notif.isRead)
                            Positioned(
                              top: 0,
                              right: 0,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                      title: Text(
                        notif.title,
                        style: TextStyle(
                          fontWeight: notif.isRead ? FontWeight.normal : FontWeight.bold,
                          color: notif.isRead ? Colors.black87 : Colors.black,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            notif.message,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: notif.isRead ? Colors.grey.shade600 : Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 12,
                                color: Colors.grey.shade500,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "${notif.createdAt.day}/${notif.createdAt.month}/${notif.createdAt.year}",
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey,
                      ),
                      onTap: () async {
                        // Navigate to detail page
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => NotificationDetailScreen(
                              notification: notif,
                            ),
                          ),
                        );

                        // SOLUSI SEDERHANA: Refresh data saat kembali dari detail
                        // Ini memastikan data selalu sinkron dengan database
                        await _loadNotifications();
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}