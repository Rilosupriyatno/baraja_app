// ============================================
// STATUS SECTION WIDGET - REFACTORED VERSION
// ============================================
// Menggunakan StatusManagementHelper untuk centralized status management
// File: widgets/tracking_detail/status_section_widget.dart

import 'package:flutter/material.dart';
import 'package:baraja_app/utils/status_management_helper.dart';

class StatusSectionWidget extends StatelessWidget {
  final String orderStatus;
  final Color statusColor;
  final IconData statusIcon;
  final Animation<double> pulseAnimation;
  final Map<String, dynamic>? orderData;

  const StatusSectionWidget({
    super.key,
    required this.orderStatus,
    required this.statusColor,
    required this.statusIcon,
    required this.pulseAnimation,
    this.orderData,
  });

  // ✅ REFACTORED: Menggunakan StatusManagementHelper
  Map<String, dynamic> _getStatusInfo() {
    if (orderData == null) return {};

    // Extract payment status
    final paymentStatus = orderData!['paymentStatus']?.toString() ?? '';

    // Extract order status
    final orderStatusValue = orderData!['orderStatus']?.toString() ??
        orderData!['status']?.toString() ?? '';

    // Extract order type
    final orderType = _extractOrderType();

    print('🔍 StatusSectionWidget - Payment Status: "$paymentStatus"');
    print('🔍 StatusSectionWidget - Order Status: "$orderStatusValue"');
    print('🔍 StatusSectionWidget - Order Type: "$orderType"');

    // ✅ Gunakan helper untuk mendapatkan status comprehensive
    return StatusManagementHelper.getComprehensiveStatus(
      paymentStatus: paymentStatus,
      orderStatus: orderStatusValue,
      orderType: orderType,
    );
  }

  // Helper untuk extract order type dari order data
  String? _extractOrderType() {
    if (orderData!['dineInData'] != null) return 'dine-in';
    if (orderData!['pickupData'] != null) return 'pickup';
    if (orderData!['takeAwayData'] != null) return 'take-away';
    if (orderData!['deliveryData'] != null) return 'delivery';

    // Fallback: cek dari field orderType jika ada
    return orderData!['orderType']?.toString();
  }

  @override
  Widget build(BuildContext context) {
    final statusInfo = _getStatusInfo();
    final shouldPulse = statusInfo['showPulse'] ?? true;

    // Get status dari helper (fallback ke parameter jika helper tidak ada data)
    final displayStatus = statusInfo['status']?.toString() ?? orderStatus;
    final displayColor = statusInfo['color'] as Color? ?? statusColor;
    final displayIcon = statusInfo['icon'] as IconData? ?? statusIcon;

    return AnimatedBuilder(
      animation: pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: shouldPulse ? pulseAnimation.value : 1.0,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  displayColor.withOpacity(0.1),
                  displayColor.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: displayColor.withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: displayColor.withOpacity(0.1),
                  spreadRadius: 0,
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: displayColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    displayIcon,
                    color: displayColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayStatus,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: displayColor,
                        ),
                      ),
                      if (statusInfo['subtitle'] != null &&
                          statusInfo['subtitle'].toString().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          statusInfo['subtitle'],
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: displayColor.withOpacity(0.8),
                          ),
                        ),
                      ],
                      if (statusInfo['description'] != null &&
                          statusInfo['description'].toString().isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          statusInfo['description'],
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: displayColor,
                    shape: BoxShape.circle,
                    boxShadow: shouldPulse ? [
                      BoxShadow(
                        color: displayColor.withOpacity(0.4),
                        spreadRadius: 2,
                        blurRadius: 8,
                      ),
                    ] : [],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}