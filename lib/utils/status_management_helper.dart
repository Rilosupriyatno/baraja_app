import 'package:flutter/material.dart';

/// ============================================
/// CENTRALIZED STATUS MANAGEMENT HELPER
/// ============================================
/// Mengelola semua teks, warna, dan ikon status dalam satu file
/// untuk memudahkan maintenance dan konsistensi di seluruh aplikasi
///
/// USAGE MAPPING:
/// - StatusSectionWidget: getComprehensiveStatus(), getPaymentStatusInfo(), getOrderStatusInfo()
/// - OrderTypeSectionWidget: getOrderTypeConfig(), getOrderTypeColor(), getOrderTypeIcon()
/// - TrackingDetailOrderScreen: canCancelOrder(), canRateOrder(), getProgressPercentage()
/// - OrderDetailWidget: formatCurrency()
/// - OrderHistoryScreen: getStatusColorFromEnum(), getStatusIconFromEnum()
/// ============================================

class StatusManagementHelper {

  // ========================================
  // PAYMENT STATUS CONFIGURATION
  // ========================================
  // 📍 USED BY: StatusSectionWidget
  // 📍 PURPOSE: Menampilkan status pembayaran di tracking detail

  static Map<String, dynamic> getPaymentStatusInfo(String paymentStatus) {
    switch (paymentStatus.toLowerCase()) {
      case 'settlement':
      case 'capture':
      case 'paid':
        return {
          'label': 'Lunas',
          'subtitle': 'Pembayaran berhasil!',
          'description': 'Pesanan Anda sedang disiapkan oleh kasir/kami',
          'icon': Icons.check_circle,
          'color': const Color(0xFF10B981), // Green
          'showPulse': false,
        };

      case 'partial':
        return {
          'label': 'DP telah dibayar',
          'subtitle': 'Menunggu konfirmasi reservasi dan tim kasir untuk reservasi Anda',
          'description': 'Sisa pembayaran {remaining_amount} dapat dilunasi saat kedatangan',
          'icon': Icons.schedule,
          'color': const Color(0xFFF59E0B), // Amber
          'showPulse': true,
        };

      case 'pending':
        return {
          'label': 'Menunggu Pembayaran',
          'subtitle': 'Silakan selesaikan pembayaran sebelum {expiry_time}',
          'description': 'Menunggu pembayaran. Silakan selesaikan pembayaran sebelum {expiry_time}',
          'icon': Icons.access_time,
          'color': const Color(0xFFF68F3B), // Orange
          'showPulse': true,
        };

      case 'expire':
      case 'unpaid':
        return {
          'label': 'Kadaluarsa',
          'subtitle': 'Pesanan dibatalkan karena melewati batas waktu pembayaran',
          'description': 'Silakan buat pesanan baru jika masih berminat',
          'icon': Icons.timer_off,
          'color': const Color(0xFFEF4444), // Red
          'showPulse': false,
        };

      case 'cancel':
        return {
          'label': 'Dibatalkan',
          'subtitle': 'Pesanan dibatalkan',
          'description': 'Pesanan dibatalkan. {cancellation_reason}',
          'icon': Icons.cancel,
          'color': const Color(0xFFEF4444), // Red
          'showPulse': false,
        };

      case 'deny':
        return {
          'label': 'Pembayaran Ditolak',
          'subtitle': 'Pembayaran ditolak',
          'description': 'Silakan hubungi pihak bank Anda',
          'icon': Icons.block,
          'color': const Color(0xFFEF4444), // Red
          'showPulse': false,
        };

      case 'failure':
        return {
          'label': 'Pembayaran Gagal',
          'subtitle': 'Pembayaran gagal diproses',
          'description': 'Silakan coba lagi atau gunakan metode pembayaran lain',
          'icon': Icons.error,
          'color': const Color(0xFFEF4444), // Red
          'showPulse': false,
        };

      default:
        return {
          'label': 'Status Tidak Diketahui',
          'subtitle': 'Status pembayaran',
          'description': 'Menunggu konfirmasi pembayaran',
          'icon': Icons.help_outline,
          'color': const Color(0xFF6B7280), // Gray
          'showPulse': true,
        };
    }
  }

  // ========================================
  // ORDER STATUS CONFIGURATION
  // ========================================
  // 📍 USED BY: StatusSectionWidget
  // 📍 PURPOSE: Menampilkan status pesanan di tracking detail

  static Map<String, dynamic> getOrderStatusInfo(String orderStatus, {String? orderType}) {
    switch (orderStatus) {
      case 'Pending':
        return {
          'status': 'Menunggu Pembayaran',
          'subtitle': 'Silakan selesaikan pembayaran sebelum {expiry_time}',
          'description': 'Belum expired',
          'icon': Icons.alarm_outlined,
          'color': const Color(0xFFF68F3B), // Orange
          'showPulse': true,
        };

      case 'Reserved':
        return {
          'status': 'Reservasi Dikonfirmasi',
          'subtitle': 'Reservasi Anda telah dikonfirmasi! Kami tunggu kedatangan Anda pada {reservation_time}',
          'description': 'Jarak pukul {reservation_time}',
          'icon': Icons.edit_note_sharp,
          'color': const Color(0xFF3B82F6), // Blue
          'showPulse': true,
        };

      case 'Waiting':
        return {
          'status': 'Sedang Disiapkan',
          'subtitle': 'Pembayaran berhasil! Pesanan Anda sedang disiapkan oleh kami',
          'description': 'Pesanan Anda akan segera diproses oleh chef',
          'icon': Icons.restaurant_menu,
          'color': const Color(0xFF3B82F6), // Blue
          'showPulse': true,
        };

      case 'OnProcess':
        return {
          'status': 'Dalam Proses',
          'subtitle': 'Pesanan Anda sedang dalam proses pembuatan. Mohon menunggu sebentar!',
          'description': 'Chef sedang menyiapkan pesanan Anda',
          'icon': Icons.coffee_maker,
          'color': const Color(0xFFF59E0B), // Amber
          'showPulse': true,
        };

      case 'Ready':
      // Dynamic message based on order type
        String status = 'Pesanan Siap Diambil';
        String subtitle = 'Pesanan siap!';
        String description = 'Silakan ambil pesanan Anda';

        if (orderType == 'delivery' || orderType == 'Delivery') {
          status = 'Pesanan Siap Diantar';
          subtitle = 'Pesanan siap diantar';
          description = 'Kurir akan segera mengantarkan pesanan Anda';
        } else if (orderType == 'takeAway' || orderType == 'Take Away' || orderType == 'take-away') {
          status = 'Pesanan Siap Dibawa';
          subtitle = 'Pesanan siap dibawa';
          description = 'Silakan ambil pesanan Anda di kasir';
        }

        return {
          'status': status,
          'subtitle': subtitle,
          'description': description,
          'icon': Icons.check_circle,
          'color': const Color(0xFF10B981), // Green
          'showPulse': true,
        };

      case 'OnTheWay':
        return {
          'status': 'Pesanan Dalam Perjalanan',
          'subtitle': 'Dalam perjalanan',
          'description': 'Pesanan Anda sedang diantar ke alamat tujuan',
          'icon': Icons.local_shipping,
          'color': const Color(0xFF8B5CF6), // Purple
          'showPulse': true,
        };

      case 'Completed':
        return {
          'status': 'Selesai',
          'subtitle': 'Terima kasih telah memesan! Kami harap Anda menikmati acara kami. Sampai jumpa kembali! 🙏',
          'description': 'Terima kasih telah memesan di Baraja Coffee',
          'icon': Icons.done_all,
          'color': const Color(0xFF10B981), // Green
          'showPulse': false,
        };

      case 'Canceled':
      case 'Cancelled':
        return {
          'status': 'Dibatalkan',
          'subtitle': 'Pesanan dibatalkan',
          'description': 'Pesanan dibatalkan. {cancellation_reason}',
          'icon': Icons.cancel,
          'color': const Color(0xFFEF4444), // Red
          'showPulse': false,
        };

      default:
        return {
          'status': 'Status: $orderStatus',
          'subtitle': 'Status pesanan',
          'description': 'Pesanan Anda sedang diproses',
          'icon': Icons.info_outline,
          'color': const Color(0xFFF68F3B), // Orange
          'showPulse': true,
        };
    }
  }

  // ========================================
  // COMPREHENSIVE STATUS (Payment + Order)
  // ========================================
  // 📍 USED BY: StatusSectionWidget, TrackingDetailOrderScreen
  // 📍 PURPOSE: Menentukan status mana yang ditampilkan (payment vs order)

  static Map<String, dynamic> getComprehensiveStatus({
    required String paymentStatus,
    required String orderStatus,
    String? orderType,
  }) {
    // If payment is successful, prioritize order status
    if (_isPaymentSuccessful(paymentStatus)) {
      return getOrderStatusInfo(orderStatus, orderType: orderType);
    } else {
      // Payment not successful, show payment status
      return getPaymentStatusInfo(paymentStatus);
    }
  }

  // ========================================
  // ORDER TYPE CONFIGURATION
  // ========================================
  // 📍 USED BY: OrderTypeSectionWidget
  // 📍 PURPOSE: Konfigurasi lengkap untuk setiap tipe order (dine-in, pickup, takeaway, delivery)

  static Map<String, dynamic> getOrderTypeConfig(String orderType) {
    switch (orderType.toLowerCase()) {
      case 'dinein':
      case 'dine-in':
      case 'dine in':
        return {
          // Header texts
          'title': 'Informasi Dine In',
          'subtitle': 'Makan di tempat',
          'badge': 'Dine In',

          // Colors & Icon
          'color': Colors.orange,
          'icon': Icons.restaurant,

          // Detail rows
          'details': {
            'primary': {
              'icon': Icons.table_restaurant_rounded,
              'iconColor': Colors.orange,
              'title': 'Nomor Meja',
              'valueKey': 'tableNumber', // Field dari orderData
              'defaultValue': 'Belum ditentukan',
            },
            'info': {
              'icon': Icons.info_outline_rounded,
              'iconColor': Colors.blue,
              'title': 'Keterangan',
              'value': 'Pesanan akan disajikan langsung ke meja Anda',
            },
          },
        };

      case 'pickup':
        return {
          // Header texts
          'title': 'Informasi Pickup',
          'subtitle': 'Ambil di lokasi',
          'badge': 'Pickup',

          // Colors & Icon
          'color': Colors.green,
          'icon': Icons.store_rounded,

          // Detail rows
          'details': {
            'time': {
              'icon': Icons.access_time_rounded,
              'iconColor': Colors.green,
              'title': 'Waktu Pickup',
              'valueKey': 'pickupTime', // Field dari orderData
              'formatTime': true, // Perlu format waktu
            },
            'location': {
              'icon': Icons.location_on_rounded,
              'iconColor': Colors.purple,
              'title': 'Lokasi Pickup',
              'value': 'Ambil pesanan di kasir outlet',
            },
            'info': {
              'icon': Icons.info_outline_rounded,
              'iconColor': Colors.blue,
              'title': 'Keterangan',
              'value': 'Tunjukkan nomor pesanan saat mengambil',
            },
          },
        };

      case 'takeaway':
      case 'take-away':
      case 'take away':
        return {
          // Header texts
          'title': 'Informasi Take Away',
          'subtitle': 'Dibawa pulang',
          'badge': 'Take Away',

          // Colors & Icon
          'color': Colors.teal,
          'icon': Icons.takeout_dining_rounded,

          // Detail rows
          'details': {
            'packaging': {
              'icon': Icons.shopping_bag_rounded,
              'iconColor': Colors.teal,
              'title': 'Kemasan',
              'value': 'Pesanan dikemas untuk dibawa pulang',
            },
            'location': {
              'icon': Icons.location_on_rounded,
              'iconColor': Colors.purple,
              'title': 'Pengambilan',
              'value': 'Ambil pesanan di kasir outlet',
            },
            'info': {
              'icon': Icons.info_outline_rounded,
              'iconColor': Colors.blue,
              'title': 'Keterangan',
              'valueKey': 'note', // Field dari orderData
              'defaultValue': 'Pesanan siap dibawa pulang',
            },
          },
        };

      case 'delivery':
        return {
          // Header texts
          'title': 'Informasi Delivery',
          'subtitle': 'Antar ke alamat',
          'badge': 'Delivery',

          // Colors & Icon
          'color': Colors.indigo,
          'icon': Icons.delivery_dining_rounded,

          // Detail rows
          'details': {
            'address': {
              'icon': Icons.location_on_rounded,
              'iconColor': Colors.indigo,
              'title': 'Alamat Pengiriman',
              'valueKey': 'deliveryAddress', // Field dari orderData
              'defaultValue': 'Alamat tidak tersedia',
            },
            'method': {
              'icon': Icons.local_shipping_rounded,
              'iconColor': Colors.purple,
              'title': 'Metode Pengiriman',
              'value': 'Kurir akan mengantar ke alamat Anda',
            },
            'info': {
              'icon': Icons.info_outline_rounded,
              'iconColor': Colors.blue,
              'title': 'Keterangan',
              'value': 'Pastikan alamat dan nomor telepon dapat dihubungi',
            },
          },
        };

      default:
        return {
          'title': 'Informasi Pesanan',
          'subtitle': 'Detail pesanan',
          'badge': orderType,
          'color': Colors.grey,
          'icon': Icons.shopping_bag,
          'details': {},
        };
    }
  }

  // ========================================
  // DOWN PAYMENT STATUS
  // ========================================
  // 📍 USED BY: PaymentDetailWidget, ActionButtonWidget
  // 📍 PURPOSE: Status untuk down payment

  static Map<String, dynamic> getDownPaymentStatus({
    required bool isDownPayment,
    required bool downPaymentPaid,
    required num remainingAmount,
  }) {
    if (!isDownPayment) {
      return {};
    }

    if (downPaymentPaid && remainingAmount > 0) {
      return {
        'label': 'DP Dibayar - Sisa Belum Lunas',
        'subtitle': 'Down Payment sudah dibayar',
        'description': 'Silakan lunasi sisa pembayaran',
        'icon': Icons.schedule,
        'color': const Color(0xFFF68F3B), // Orange
        'showPulse': true,
      };
    } else if (downPaymentPaid && remainingAmount == 0) {
      return {
        'label': 'Lunas',
        'subtitle': 'Pembayaran selesai',
        'description': 'Semua pembayaran telah lunas',
        'icon': Icons.check_circle,
        'color': const Color(0xFF10B981), // Green
        'showPulse': false,
      };
    } else {
      return {
        'label': 'DP Belum Dibayar',
        'subtitle': 'Menunggu pembayaran DP',
        'description': 'Silakan selesaikan pembayaran down payment',
        'icon': Icons.pending,
        'color': const Color(0xFFEF4444), // Red
        'showPulse': true,
      };
    }
  }

  // ========================================
  // QUICK ACCESS METHODS (Backward Compatibility)
  // ========================================
  // 📍 USED BY: OrderTypeSectionWidget (legacy support)
  // 📍 PURPOSE: Method cepat untuk akses warna & icon

  /// Get color for order type
  static Color getOrderTypeColor(String orderType) {
    final config = getOrderTypeConfig(orderType);
    return config['color'] as Color? ?? Colors.grey;
  }

  /// Get icon for order type
  static IconData getOrderTypeIcon(String orderType) {
    final config = getOrderTypeConfig(orderType);
    return config['icon'] as IconData? ?? Icons.shopping_bag;
  }

  /// Get title for order type
  static String getOrderTypeTitle(String orderType) {
    final config = getOrderTypeConfig(orderType);
    return config['title'] as String? ?? 'Informasi Pesanan';
  }

  /// Get subtitle for order type
  static String getOrderTypeSubtitle(String orderType) {
    final config = getOrderTypeConfig(orderType);
    return config['subtitle'] as String? ?? 'Detail pesanan';
  }

  /// Get badge text for order type
  static String getOrderTypeBadge(String orderType) {
    final config = getOrderTypeConfig(orderType);
    return config['badge'] as String? ?? orderType;
  }

  // ========================================
  // HELPER METHODS
  // ========================================
  // 📍 USED BY: Multiple widgets
  // 📍 PURPOSE: Utility functions

  /// Check if payment is successful
  static bool _isPaymentSuccessful(String paymentStatus) {
    return ['settlement', 'capture', 'paid'].contains(paymentStatus.toLowerCase());
  }

  /// Check if order can be cancelled
  /// 📍 USED BY: ActionButtonWidget
  static bool canCancelOrder({
    required String paymentStatus,
    required String orderStatus,
  }) {
    return paymentStatus.toLowerCase() == 'pending' ||
        orderStatus == 'Pending' ||
        orderStatus == 'Waiting';
  }

  /// Check if order can be rated
  /// 📍 USED BY: ActionButtonWidget
  static bool canRateOrder({
    required String paymentStatus,
    required String orderStatus,
  }) {
    return _isPaymentSuccessful(paymentStatus) && orderStatus == 'Completed';
  }

  /// Get progress percentage for progress bar
  /// 📍 USED BY: TrackingDetailOrderScreen (optional)
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

  /// Format currency
  /// 📍 USED BY: OrderDetailWidget, PaymentDetailWidget
  static String formatCurrency(num amount) {
    return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
    )}';
  }

  // ========================================
  // LEGACY COMPATIBILITY (For Order Model)
  // ========================================
  // 📍 USED BY: OrderHistoryScreen
  // 📍 PURPOSE: Support untuk enum OrderStatus

  /// Get status color from OrderStatus enum
  static Color getStatusColorFromEnum(dynamic status) {
    final statusString = status.toString().split('.').last;
    switch (statusString) {
      case 'pending':
        return const Color(0xFFF68F3B);
      case 'waiting':
        return const Color(0xFF3B82F6);
      case 'processing':
        return const Color(0xFFF59E0B);
      case 'onTheWay':
        return const Color(0xFF8B5CF6);
      case 'ready':
        return const Color(0xFF10B981);
      case 'completed':
        return const Color(0xFF10B981);
      case 'cancelled':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF6B7280);
    }
  }

  /// Get status icon from OrderStatus enum
  static IconData getStatusIconFromEnum(dynamic status) {
    final statusString = status.toString().split('.').last;
    switch (statusString) {
      case 'pending':
        return Icons.access_time;
      case 'waiting':
        return Icons.hourglass_empty;
      case 'processing':
        return Icons.restaurant;
      case 'onTheWay':
        return Icons.delivery_dining;
      case 'ready':
        return Icons.check_circle;
      case 'completed':
        return Icons.done_all;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  /// Get status description from OrderStatus enum
  static String getStatusDescriptionFromEnum(dynamic status, String? orderType) {
    final statusString = status.toString().split('.').last;
    switch (statusString) {
      case 'pending':
        return 'Menunggu konfirmasi pembayaran';
      case 'waiting':
        return 'Menunggu pesanan Anda diproses';
      case 'processing':
        return 'Pesanan Anda sedang diproses oleh dapur';
      case 'onTheWay':
        return 'Pesanan Anda sedang dalam perjalanan';
      case 'ready':
        if (orderType?.toLowerCase() == 'takeaway' ||
            orderType?.toLowerCase() == 'take-away' ||
            orderType?.toLowerCase() == 'take away') {
          return 'Pesanan siap dibawa pulang';
        }
        return 'Pesanan Anda siap untuk diambil';
      case 'completed':
        return 'Pesanan Anda telah selesai';
      case 'cancelled':
        return 'Pesanan Anda telah dibatalkan';
      default:
        return 'Pesanan Anda sedang diproses';
    }
  }

  /// Get order type text from OrderType enum
  static String getOrderTypeTextFromEnum(dynamic type) {
    final typeString = type.toString().split('.').last;
    switch (typeString) {
      case 'dineIn':
        return 'Makan di Tempat';
      case 'delivery':
        return 'Pengantaran';
      case 'pickup':
        return 'Ambil Sendiri';
      case 'takeAway':
        return 'Take Away';
      case 'reservation':
        return 'Reservasi';
      default:
        return 'Unknown';
    }
  }
}

// ========================================
// EXTENSION HELPERS
// ========================================
// 📍 USED BY: Any widget yang bekerja dengan Map orderData
// 📍 PURPOSE: Shortcut methods untuk extract info dari orderData

extension StatusHelperExtension on Map<String, dynamic> {
  /// Get payment status info from order data
  Map<String, dynamic> getPaymentStatusInfo() {
    final paymentStatus = this['paymentStatus']?.toString() ?? '';
    return StatusManagementHelper.getPaymentStatusInfo(paymentStatus);
  }

  /// Get order status info from order data
  Map<String, dynamic> getOrderStatusInfo() {
    final orderStatus = this['orderStatus']?.toString() ??
        this['status']?.toString() ?? '';
    final orderType = _extractOrderType();
    return StatusManagementHelper.getOrderStatusInfo(
      orderStatus,
      orderType: orderType,
    );
  }

  /// Get comprehensive status from order data
  Map<String, dynamic> getComprehensiveStatus() {
    final paymentStatus = this['paymentStatus']?.toString() ?? '';
    final orderStatus = this['orderStatus']?.toString() ??
        this['status']?.toString() ?? '';
    final orderType = _extractOrderType();

    return StatusManagementHelper.getComprehensiveStatus(
      paymentStatus: paymentStatus,
      orderStatus: orderStatus,
      orderType: orderType,
    );
  }

  /// Extract order type from order data
  String? _extractOrderType() {
    if (this['dineInData'] != null) return 'dine-in';
    if (this['pickupData'] != null) return 'pickup';
    if (this['takeAwayData'] != null) return 'take-away';
    if (this['deliveryData'] != null) return 'delivery';
    return null;
  }
}