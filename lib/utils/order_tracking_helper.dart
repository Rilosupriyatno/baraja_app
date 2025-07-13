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
      case OrderType.reservation:
        return 'Reservasi';
    }
  }

  // Get comprehensive status info based on payment and order status
  static Map<String, dynamic> getComprehensiveStatusInfo(
      String paymentStatus,
      String orderStatus,
      OrderType orderType,
      ) {
    // If payment is successful, focus on order status
    if (paymentStatus == 'settlement' || paymentStatus == 'capture') {
      return _getOrderStatusInfo(orderStatus, orderType);
    } else {
      return _getPaymentStatusInfo(paymentStatus);
    }
  }

  // Get order status info when payment is successful
  static Map<String, dynamic> _getOrderStatusInfo(String orderStatus, OrderType orderType) {
    switch (orderStatus) {
      case 'Pending':
        return {
          'status': 'Menunggu konfirmasi kasir',
          'description': 'Pesanan Anda akan segera diproses',
          'color': const Color(0xFFF68F3B),
          'icon': Icons.alarm_outlined,
          'showPulse': true,
        };
      case 'Waiting':
        return {
          'status': 'Menunggu konfirmasi kitchen',
          'description': 'Pesanan Anda akan segera diproses oleh chef',
          'color': const Color(0xFF3B82F6),
          'icon': Icons.restaurant_menu,
          'showPulse': true,
        };
      case 'OnProcess':
        return {
          'status': 'Pesananmu sedang dibuat',
          'description': 'Chef sedang menyiapkan pesanan Anda',
          'color': const Color(0xFFF59E0B),
          'icon': Icons.coffee_maker,
          'showPulse': true,
        };
      case 'Ready':
        String statusText = orderType == OrderType.delivery
            ? 'Pesanan siap diantar'
            : 'Pesanan siap diambil';
        return {
          'status': statusText,
          'description': orderType == OrderType.delivery
              ? 'Kurir akan segera mengantarkan pesanan Anda'
              : 'Silakan ambil pesanan Anda',
          'color': const Color(0xFF10B981),
          'icon': Icons.check_circle,
          'showPulse': true,
        };
      case 'OnTheWay':
        return {
          'status': 'Pesanan dalam perjalanan',
          'description': 'Pesanan Anda sedang diantar ke alamat tujuan',
          'color': const Color(0xFF8B5CF6),
          'icon': Icons.local_shipping,
          'showPulse': true,
        };
      case 'Completed':
        return {
          'status': 'Selamat Menikmati',
          'description': 'Terima kasih telah memesan di Baraja Coffee',
          'color': const Color(0xFF10B981),
          'icon': Icons.done_all,
          'showPulse': false,
        };
      case 'Canceled':
      case 'Cancelled':
        return {
          'status': 'Pesanan dibatalkan',
          'description': 'Pesanan telah dibatalkan',
          'color': const Color(0xFFEF4444),
          'icon': Icons.cancel,
          'showPulse': false,
        };
      default:
        return {
          'status': 'Status: $orderStatus',
          'description': 'Pesanan Anda sedang diproses',
          'color': const Color(0xFFF68F3B),
          'icon': Icons.info_outline,
          'showPulse': true,
        };
    }
  }

  // Get payment status info when payment is not successful
  static Map<String, dynamic> _getPaymentStatusInfo(String paymentStatus) {
    switch (paymentStatus) {
      case 'pending':
        return {
          'status': 'Menunggu Pembayaran',
          'description': 'Selesaikan pembayaran sebelum waktu habis',
          'color': const Color(0xFFF59E0B),
          'icon': Icons.access_time,
          'showPulse': true,
        };
      case 'expire':
        return {
          'status': 'Pembayaran Kadaluarsa',
          'description': 'Silakan buat pesanan baru untuk melanjutkan',
          'color': const Color(0xFFEF4444),
          'icon': Icons.timer_off,
          'showPulse': false,
        };
      case 'cancel':
        return {
          'status': 'Pesanan Dibatalkan',
          'description': 'Pembayaran telah dibatalkan',
          'color': const Color(0xFFEF4444),
          'icon': Icons.cancel,
          'showPulse': false,
        };
      default:
        return {
          'status': 'Status pembayaran: $paymentStatus',
          'description': 'Menunggu konfirmasi pembayaran',
          'color': const Color(0xFF6B7280),
          'icon': Icons.help_outline,
          'showPulse': true,
        };
    }
  }

  // Get status description (legacy support)
  static String getStatusDescription(OrderStatus status, OrderType orderType) {
    switch (status) {
      case OrderStatus.pending:
        return 'Menunggu konfirmasi pembayaran';
      case OrderStatus.waiting:
        return 'Menunggu pesanan Anda diproses';
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

  // Get status color (legacy support)
  static Color getStatusColor(OrderStatus status) {
    return {
      OrderStatus.pending: const Color(0xFFF68F3B),
      OrderStatus.waiting: const Color(0xFF3B82F6),
      OrderStatus.processing: const Color(0xFFF59E0B),
      OrderStatus.onTheWay: const Color(0xFF8B5CF6),
      OrderStatus.ready: const Color(0xFF10B981),
      OrderStatus.completed: const Color(0xFF10B981),
      OrderStatus.cancelled: const Color(0xFFEF4444),
    }[status]!;
  }

  static IconData getStatusIcon(OrderStatus status) {
    return {
      OrderStatus.pending: Icons.access_time,
      OrderStatus.waiting: Icons.hourglass_empty,
      OrderStatus.processing: Icons.restaurant,
      OrderStatus.onTheWay: Icons.delivery_dining,
      OrderStatus.ready: Icons.check_circle,
      OrderStatus.completed: Icons.done_all,
      OrderStatus.cancelled: Icons.cancel,
    }[status]!;
  }

  // Determine next status based on current status and order type
  static OrderStatus getNextStatus(OrderStatus currentStatus, OrderType orderType) {
    switch (currentStatus) {
      case OrderStatus.pending:
        return OrderStatus.waiting;
      case OrderStatus.waiting:
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
        return currentStatus;
    }
  }

  // Check if order can be cancelled
  static bool canCancelOrder(String paymentStatus, String orderStatus) {
    // Can cancel if payment is pending or order is still in early stages
    return paymentStatus == 'pending' ||
        orderStatus == 'Pending' ||
        orderStatus == 'Waiting';
  }

  // Check if order can be rated
  static bool canRateOrder(String paymentStatus, String orderStatus) {
    // Can rate only if payment is successful and order is completed
    return (paymentStatus == 'settlement' || paymentStatus == 'capture') &&
        orderStatus == 'Completed';
  }

  // Get progress percentage for progress bar
  static double getProgressPercentage(String orderStatus) {
    switch (orderStatus) {
      case 'Pending':
        return 0.2;
      case 'Waiting':
        return 0.4;
      case 'OnProcess':
        return 0.6;
      case 'Ready':
        return 0.8;
      case 'OnTheWay':
        return 0.9;
      case 'Completed':
        return 1.0;
      case 'Canceled':
      case 'Cancelled':
        return 0.0;
      default:
        return 0.1;
    }
  }
}