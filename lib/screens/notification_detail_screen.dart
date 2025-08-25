import 'package:flutter/material.dart';
import '../widgets/utils/classic_app_bar.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationDetailScreen extends StatefulWidget {
  final NotificationModel notification;

  const NotificationDetailScreen({
    super.key,
    required this.notification,
  });

  @override
  State<NotificationDetailScreen> createState() => _NotificationDetailScreenState();
}

class _NotificationDetailScreenState extends State<NotificationDetailScreen> {
  late NotificationModel _notification;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _notification = widget.notification;

    // Mark as read when opening detail page
    if (!_notification.isRead) {
      _markAsRead();
    }
  }

  Future<void> _markAsRead() async {
    if (_notification.isRead) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await NotificationService().markNotificationAsRead(_notification.id);
      setState(() {
        _notification = _notification.copyWith(isRead: true);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menandai sebagai dibaca: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];

    return '${date.day} ${months[date.month]} ${date.year}, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Color _getTypeColor() {
    switch (_notification.type) {
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

  IconData _getTypeIcon() {
    switch (_notification.type) {
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

  String _getTypeLabel() {
    switch (_notification.type) {
      case 'event':
        return 'Event';
      case 'promo':
        return 'Promosi';
      case 'update':
        return 'Update';
      case 'info':
      default:
        return 'Informasi';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: ClassicAppBar(
        title: 'Detail Notifikasi',
        actions: [
          if (!_notification.isRead)
            IconButton(
              icon: _isLoading
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Icon(Icons.mark_email_read),
              onPressed: _isLoading ? null : _markAsRead,
              tooltip: 'Tandai sebagai dibaca',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Card(
              elevation: 2,
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Type Badge and Read Status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getTypeColor().withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getTypeIcon(),
                                size: 16,
                                color: _getTypeColor(),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _getTypeLabel(),
                                style: TextStyle(
                                  color: _getTypeColor(),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _notification.isRead
                                ? Colors.grey.withOpacity(0.1)
                                : Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _notification.isRead ? Icons.check : Icons.fiber_new,
                                size: 12,
                                color: _notification.isRead ? Colors.grey : Colors.red,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _notification.isRead ? 'Dibaca' : 'Baru',
                                style: TextStyle(
                                  color: _notification.isRead ? Colors.grey : Colors.red,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Title
                    Text(
                      _notification.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Date
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(_notification.createdAt),
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Image (if exists)
            if (_notification.imageUrl != null && _notification.imageUrl!.isNotEmpty)
              Card(
                elevation: 2,
                margin: EdgeInsets.zero,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    _notification.imageUrl!,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 200,
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: Icon(
                            Icons.broken_image,
                            size: 48,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 200,
                        color: Colors.grey.shade100,
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      );
                    },
                  ),
                ),
              ),

            if (_notification.imageUrl != null && _notification.imageUrl!.isNotEmpty)
              const SizedBox(height: 16),

            // Message Content
            Card(
              elevation: 2,
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.message,
                          size: 20,
                          color: Colors.grey.shade700,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Pesan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _notification.message,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                    ),
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