import 'package:flutter/material.dart';
import '../models/order.dart';
import '../models/order_type.dart';

class OrderTrackingHelper {
  // Format waktu
  static String formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  // Get order type text
  static String getOrderTypeText(OrderType type) {
    switch (type) {
      case OrderType.dineIn:
        return 'Makan di Tempat';
      case OrderType.delivery:
        return 'Pengantaran';
      case OrderType.pickup:
        return 'Ambil Sendiri';
    }
  }

  // Get status description
  static String getStatusDescription(OrderStatus status, OrderType orderType) {
    switch (status) {
      case OrderStatus.pending:
        return 'Menunggu konfirmasi pembayaran';
      case OrderStatus.processing:
        return 'Pesanan Anda sedang diproses oleh dapur';
      case OrderStatus.onTheWay:
        return 'Pesanan Anda sedang dalam perjalanan';
      case OrderStatus.ready:
        return 'Pesanan Anda siap untuk diambil';
      case OrderStatus.completed:
        return 'Pesanan Anda telah selesai';
      case OrderStatus.cancelled:
        return 'Pesanan Anda telah dibatalkan';
    }
  }

  // Get status color
  static Color getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.processing:
        return Colors.blue;
      case OrderStatus.onTheWay:
        return Colors.indigo;
      case OrderStatus.ready:
      case OrderStatus.completed:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }

  // Get status icon
  static IconData getStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Icons.access_time;
      case OrderStatus.processing:
        return Icons.restaurant;
      case OrderStatus.onTheWay:
        return Icons.delivery_dining;
      case OrderStatus.ready:
        return Icons.check_circle;
      case OrderStatus.completed:
        return Icons.done_all;
      case OrderStatus.cancelled:
        return Icons.cancel;
    }
  }

  // Determine next status based on current status and order type
  static OrderStatus getNextStatus(OrderStatus currentStatus, OrderType orderType) {
    switch (currentStatus) {
      case OrderStatus.pending:
        return OrderStatus.processing;
      case OrderStatus.processing:
        return orderType == OrderType.delivery
            ? OrderStatus.onTheWay
            : OrderStatus.ready;
      case OrderStatus.onTheWay:
      case OrderStatus.ready:
        return OrderStatus.completed;
      case OrderStatus.completed:
      case OrderStatus.cancelled:
      // Jika sudah completed atau cancelled, tidak ada next status
        return currentStatus;
    }
  }
}