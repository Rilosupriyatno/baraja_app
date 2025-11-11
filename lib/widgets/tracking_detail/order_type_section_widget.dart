import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:baraja_app/utils/status_management_helper.dart';

/// ============================================
/// ORDER TYPE SECTION WIDGET - WITH EXPIRY COUNTDOWN
/// ============================================
/// Widget untuk menampilkan detail order type dengan countdown expiry
///
/// ✅ ENHANCEMENT: Tampilkan countdown expiry untuk payment pending
/// ✅ BENEFIT: User aware kapan order akan expire
/// ============================================

class OrderTypeSectionWidget extends StatefulWidget {
  final Map<String, dynamic> orderData;

  const OrderTypeSectionWidget({
    super.key,
    required this.orderData,
  });

  @override
  State<OrderTypeSectionWidget> createState() => _OrderTypeSectionWidgetState();
}

class _OrderTypeSectionWidgetState extends State<OrderTypeSectionWidget> {
  String? _remainingTime;

  @override
  void initState() {
    super.initState();
    _calculateRemainingTime();
  }

  @override
  void didUpdateWidget(OrderTypeSectionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.orderData != widget.orderData) {
      _calculateRemainingTime();
    }
  }

  // ✅ BARU: Hitung remaining time hingga expired
  void _calculateRemainingTime() {
    final paymentDetails = widget.orderData['paymentDetails'] as Map<String, dynamic>?;
    final expiryTime = paymentDetails?['expiry_time'] as String?;

    if (expiryTime == null || expiryTime.isEmpty) {
      setState(() => _remainingTime = null);
      return;
    }

    try {
      // Parse expiry time from Midtrans format
      final expiry = DateTime.parse(expiryTime);
      final now = DateTime.now();
      final difference = expiry.difference(now);

      if (difference.isNegative) {
        setState(() => _remainingTime = 'Expired');
      } else {
        final hours = difference.inHours;
        final minutes = difference.inMinutes.remainder(60);

        if (hours > 0) {
          setState(() => _remainingTime = '$hours jam $minutes menit');
        } else if (minutes > 0) {
          setState(() => _remainingTime = '$minutes menit');
        } else {
          setState(() => _remainingTime = 'Kurang dari 1 menit');
        }

        // Update setiap menit
        Future.delayed(const Duration(minutes: 1), () {
          if (mounted) _calculateRemainingTime();
        });
      }
    } catch (e) {
      print('❌ Error parsing expiry time: $e');
      setState(() => _remainingTime = null);
    }
  }

  // ✅ Helper method untuk format waktu pickup
  String _formatPickupTime(String rawTime) {
    try {
      final index = rawTime.indexOf(' GMT');
      final cleaned = index != -1 ? rawTime.substring(0, index) : rawTime;

      final formatterInput = DateFormat('EEE MMM dd yyyy HH:mm:ss', 'en_US');
      final dateTime = formatterInput.parse(cleaned);

      final formatterOutput = DateFormat('EEEE, dd MMM yyyy HH:mm', 'id_ID');
      return formatterOutput.format(dateTime);
    } catch (e) {
      return rawTime;
    }
  }

  // ✅ Helper method untuk mendapatkan order type dari data
  String _getOrderType() {
    if (widget.orderData['dineInData'] != null) return 'dine-in';
    if (widget.orderData['pickupData'] != null) return 'pickup';
    if (widget.orderData['takeAwayData'] != null) return 'take-away';
    if (widget.orderData['deliveryData'] != null) return 'delivery';
    return 'unknown';
  }

  // ✅ Helper method untuk cek apakah widget harus ditampilkan
  bool _shouldShowOrderTypeSection() {
    final orderType = _getOrderType();
    print("🔍 OrderTypeSectionWidget - Order Type: $orderType");

    // Jangan tampilkan jika order type unknown
    if (orderType == 'unknown') return false;

    // ✅ PERBAIKAN: Cek payment status - jangan tampilkan jika payment belum sukses
    final paymentStatus = widget.orderData['paymentStatus']?.toString().toLowerCase() ?? '';
    final isPaymentSuccessful = ['settlement', 'capture', 'paid', 'partial'].contains(paymentStatus);

    if (!isPaymentSuccessful) {
      print("⚠️ OrderTypeSectionWidget - Payment not successful ($paymentStatus), hiding section");
      return false;
    }

    print("✅ OrderTypeSectionWidget - Payment successful, showing section");
    return true;
  }

  // ✅ BARU: Cek apakah payment masih pending
  bool _isPaymentPending() {
    final paymentStatus = widget.orderData['paymentStatus']?.toString().toLowerCase() ?? '';
    return paymentStatus == 'pending';
  }

  // ✅ BARU: Cek apakah payment expired
  bool _isPaymentExpired() {
    final paymentStatus = widget.orderData['paymentStatus']?.toString().toLowerCase() ?? '';
    return ['expire', 'unpaid'].contains(paymentStatus);
  }

  @override
  Widget build(BuildContext context) {
    if (!_shouldShowOrderTypeSection()) {
      return const SizedBox.shrink();
    }

    final orderType = _getOrderType();

    // ✅ GUNAKAN: StatusManagementHelper untuk mendapatkan konfigurasi
    final config = StatusManagementHelper.getOrderTypeConfig(orderType);

    print("📦 OrderTypeSectionWidget - Config loaded for: $orderType");

    // Build section berdasarkan order type dengan data dari helper
    return _buildOrderTypeSection(config);
  }

  // ✅ REFACTORED: Universal builder yang menggunakan config dari helper
  Widget _buildOrderTypeSection(Map<String, dynamic> config) {
    final color = config['color'] as Color;
    final icon = config['icon'] as IconData;
    final title = config['title'] as String;
    final subtitle = config['subtitle'] as String;
    final badge = config['badge'] as String;
    final details = config['details'] as Map<String, dynamic>;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ Header - Menggunakan data dari config
          _buildHeader(
            color: color,
            icon: icon,
            title: title,
            subtitle: subtitle,
            badge: badge,
          ),

          // ✅ Details - Build rows berdasarkan config
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: _buildDetailRows(details),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Build header section
  Widget _buildHeader({
    required Color color,
    required IconData icon,
    required String title,
    required String subtitle,
    required String badge,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: color.withOpacity(0.3),
              ),
            ),
            child: Text(
              badge,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Build detail rows berdasarkan config dari helper
  List<Widget> _buildDetailRows(Map<String, dynamic> details) {
    final List<Widget> rows = [];
    int index = 0;

    details.forEach((key, detailConfig) {
      if (index > 0) {
        rows.add(const SizedBox(height: 16));
      }

      final rowWidget = _buildDetailRowFromConfig(key, detailConfig as Map<String, dynamic>);
      if (rowWidget != null) {
        rows.add(rowWidget);
        index++;
      }
    });

    return rows;
  }

  // ✅ ENHANCED: Build single detail row dengan logika expiry
  Widget? _buildDetailRowFromConfig(String key, Map<String, dynamic> detailConfig) {
    final icon = detailConfig['icon'] as IconData;
    final iconColor = detailConfig['iconColor'] as Color;
    final title = detailConfig['title'] as String;

    // Determine value: static value or dari orderData
    String value;

    if (detailConfig.containsKey('value')) {
      // Static value dari config
      value = detailConfig['value'] as String;

      // ✅ ENHANCEMENT: Jika ini adalah row "info" untuk dine-in, modifikasi valuenya
      final orderType = _getOrderType();
      if (orderType == 'dine-in' && key == 'info') {
        if (_isPaymentExpired()) {
          // Payment expired - hide row
          return null;
        } else if (_isPaymentPending() && _remainingTime != null) {
          // Payment pending - show expiry countdown
          if (_remainingTime == 'Expired') {
            // Sudah expired - hide row
            return null;
          }
          value = 'Pesanan akan otomatis dibatalkan dalam $_remainingTime';
          // Override icon dan color untuk countdown
          return _buildDetailRow(
            icon: Icons.timer_outlined,
            iconColor: Colors.orange,
            title: title,
            value: value,
          );
        }
        // Payment success - tetap gunakan value default
      }
    } else if (detailConfig.containsKey('valueKey')) {
      // Dynamic value dari orderData
      final valueKey = detailConfig['valueKey'] as String;
      final defaultValue = detailConfig['defaultValue'] as String? ?? 'Tidak tersedia';

      // Get data berdasarkan order type
      final orderType = _getOrderType();
      Map<String, dynamic>? typeData;

      switch (orderType) {
        case 'dine-in':
          typeData = widget.orderData['dineInData'] as Map<String, dynamic>?;
          break;
        case 'pickup':
          typeData = widget.orderData['pickupData'] as Map<String, dynamic>?;
          break;
        case 'take-away':
          typeData = widget.orderData['takeAwayData'] as Map<String, dynamic>?;
          break;
        case 'delivery':
          typeData = widget.orderData['deliveryData'] as Map<String, dynamic>?;
          break;
      }

      if (typeData == null || typeData[valueKey] == null) {
        // Skip row jika valueKey adalah 'pickupTime' dan datanya null
        if (valueKey == 'pickupTime') {
          return null;
        }
        value = defaultValue;
      } else {
        value = typeData[valueKey]?.toString() ?? defaultValue;

        // Format time jika diperlukan
        if (detailConfig['formatTime'] == true && value.isNotEmpty) {
          value = _formatPickupTime(value);
        }
      }
    } else {
      return null;
    }

    return _buildDetailRow(
      icon: icon,
      iconColor: iconColor,
      title: title,
      value: value,
    );
  }

  // ✅ Build single detail row UI
  Widget _buildDetailRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 16, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================
// USAGE EXAMPLE IN TRACKING DETAIL SCREEN:
// ============================================
// if (orderData != null)
//   SlideTransition(
//     position: _slideAnimation,
//     child: OrderTypeSectionWidget(orderData: orderData!),
//   ),
// ============================================