import 'dart:convert';
import 'package:flutter/material.dart';
import '../../utils/currency_formatter.dart';
import '../tracking_detail/payment_row_widget.dart';

class GroOrderDetailWidget extends StatelessWidget {
  final Map<String, dynamic> orderData;
  final bool showAddOrderButton;
  final VoidCallback? onAddOrder;
  final VoidCallback? onFinalPayment; // Callback for final payment

  const GroOrderDetailWidget({
    super.key,
    required this.orderData,
    this.showAddOrderButton = false,
    this.onAddOrder,
    this.onFinalPayment,
  });

  // Method untuk mendapatkan status pembayaran dengan dukungan down payment
  Map<String, dynamic> _getPaymentStatus(String? status, Map<String, dynamic>? paymentDetails) {
    // Check if this is a down payment scenario
    if (paymentDetails != null && paymentDetails['isDownPayment'] == true) {
      final isDownPaymentPaid = paymentDetails['downPaymentPaid'] == true;
      final remainingAmount = _getNumericValue(paymentDetails['remainingAmount']);
      
      // Check if there's a pending Final Payment
      final hasPendingFinalPayment = paymentDetails['hasPendingFinalPayment'] == true;
      
      // ✅ FIX: Check if Final Payment has been settled
      final pendingDetails = paymentDetails['finalPaymentDetails'] as Map<String, dynamic>?;
      final finalPaymentStatus = pendingDetails?['status']?.toString().toLowerCase();
      final isFinalPaymentSettled = finalPaymentStatus == 'settlement' || finalPaymentStatus == 'capture';

      // ✅ If Final Payment is settled, show LUNAS regardless of remainingAmount
      if (isFinalPaymentSettled) {
        return {
          'label': 'Lunas',
          'icon': Icons.check_circle,
          'color': Colors.green,
        };
      }

      if (isDownPaymentPaid && remainingAmount > 0) {
        // If there's a pending Final Payment, show different status
        if (hasPendingFinalPayment) {
          return {
            'label': 'Menunggu Pelunasan di Kasir',
            'icon': Icons.hourglass_bottom,
            'color': Colors.amber,
          };
        }
        return {
          'label': 'DP Dibayar - Sisa Belum Lunas',
          'icon': Icons.schedule,
          'color': Colors.deepOrange,
        };
      } else if (isDownPaymentPaid && remainingAmount == 0) {
        return {
          'label': 'Lunas',
          'icon': Icons.check_circle,
          'color': Colors.green,
        };
      } else {
        return {
          'label': 'DP Belum Dibayar',
          'icon': Icons.pending,
          'color': Colors.red,
        };
      }
    }

    // Default payment status logic
    if (status == null) {
      return {
        'label': 'Status Tidak Diketahui',
        'icon': Icons.help_outline,
        'color': Colors.grey,
      };
    }

    switch (status.toLowerCase()) {
      case 'settlement':
      case 'capture':
      case 'paid':
        return {
          'label': 'Lunas',
          'icon': Icons.check_circle,
          'color': Colors.green,
        };
      case 'partial':
        return {
          'label': 'Menunggu Pelunasan',
          'icon': Icons.remove_circle,
          'color': Colors.amber,
        };
      case 'pending':
        // ✅ FIX: Special handling for Down Payment that is pending
        if (paymentDetails != null && 
           (paymentDetails['isDownPayment'] == true || paymentDetails['paymentType'] == 'Down Payment')) {
           return {
            'label': 'DP Belum Dibayar',
            'icon': Icons.pending,
            'color': Colors.red,
          };
        }
        return {
          'label': 'Menunggu Pembayaran',
          'icon': Icons.access_time,
          'color': Colors.orange,
        };
      case 'expire':
      case 'unpaid':
         // ✅ FIX: Don't show Kadaluarsa if it's a new order or manual DP that might look expired/unpaid
         if (paymentDetails != null && paymentDetails['paymentType'] == 'Down Payment') {
           return {
            'label': 'DP Belum Dibayar',
            'icon': Icons.pending,
            'color': Colors.red,
          };
         }
        return {
          'label': 'Kadaluarsa',
          'icon': Icons.timer_off,
          'color': Colors.red,
        };
      case 'cancel':
        return {
          'label': 'Dibatalkan',
          'icon': Icons.cancel,
          'color': Colors.red,
        };
      default:
        return {
          'label': 'Status Unknown: $status',
          'icon': Icons.help_outline,
          'color': Colors.grey,
        };
    }
  }

  // ✅ Helper untuk extract QR code dari actions array
  String? _getQrCodeFromActions(List? actions) {
    if (actions == null || actions.isEmpty) return null;
    
    for (var action in actions) {
      if (action is Map) {
        // Check for generate-qr-code action
        if (action['name'] == 'generate-qr-code' && action['url'] != null) {
          return action['url'].toString();
        }
      }
    }
    return null;
  }

  // ✅ Widget untuk menampilkan QR code pending final payment
  Widget _buildPendingFinalPaymentQR(Map<String, dynamic>? paymentDetails) {
    if (paymentDetails == null) return const SizedBox.shrink();
    
    final pendingDetails = paymentDetails['finalPaymentDetails'] as Map<String, dynamic>?;
    
    if (pendingDetails == null || pendingDetails['status'] != 'pending') {
      return const SizedBox.shrink();
    }
    
    final actions = pendingDetails['actions'] as List?;
    final qrCodeUrl = _getQrCodeFromActions(actions);
    final amount = _getNumericValue(pendingDetails['amount']);
    
    if (qrCodeUrl == null || !qrCodeUrl.startsWith('data:image')) {
      return const SizedBox.shrink();
    }
    
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.qr_code_2, color: Colors.amber.shade700, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'QR Code Pelunasan',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.amber.shade800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // QR Code
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Image.memory(
              base64Decode(qrCodeUrl.split(',').last),
              width: 180,
              height: 180,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.qr_code, size: 60, color: Colors.grey),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          
          // Amount
          Text(
            'Jumlah Pelunasan: ${formatCurrency(amount)}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.deepOrange,
            ),
          ),
          const SizedBox(height: 8),
          
          // Instruction
          Text(
            'Scan QR ini di kasir untuk konfirmasi pembayaran',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // Widget untuk menampilkan informasi down payment
  Widget _buildDownPaymentSection(Map<String, dynamic> orderData) {
    final paymentDetails = orderData['paymentDetails'] as Map<String, dynamic>?;

    // ✅ FIX: Juga tampilkan jika ada pending Final Payment
    final isDownPayment = paymentDetails?['isDownPayment'] == true;
    final hasPendingFinalPayment = paymentDetails?['hasPendingFinalPayment'] == true;
    
    if (paymentDetails == null || (!isDownPayment && !hasPendingFinalPayment)) {
      return const SizedBox.shrink();
    }

    final paidAmount = _getNumericValue(paymentDetails['paidAmount']);
    final remainingAmount = _getNumericValue(paymentDetails['remainingAmount']);
    final isDownPaymentPaid = paymentDetails['downPaymentPaid'] == true;
    
    // ✅ Get Final Payment details (renamed from pendingFinalPaymentDetails)
    final finalPaymentDetails = paymentDetails['finalPaymentDetails'] as Map<String, dynamic>?;
    // finalPaymentDetails.amount = Sisa pembayaran
    // finalPaymentDetails.totalAmount = Tambahan order
    final fpSisaPembayaran = _getNumericValue(finalPaymentDetails?['amount']);
    final fpTambahanOrder = _getNumericValue(finalPaymentDetails?['totalAmount']);
    
    // ✅ Get Down Payment details
    final dpDetails = paymentDetails['downPaymentDetails'] as Map<String, dynamic>?;
    final dpAmount = _getNumericValue(dpDetails?['amount']); // Jumlah DP dibayar
    final dpRemainingAmount = _getNumericValue(dpDetails?['remainingAmount']); // Sisa setelah DP
    final paymentType = paymentDetails['paymentType']?.toString() ?? '';
    
    // ✅ CLEAR: Sisa Pembayaran calculation
    // Jika ada Final Payment, gunakan finalPaymentDetails.amount
    // Jika tidak, gunakan downPaymentDetails.remainingAmount
    final sisaPembayaran = finalPaymentDetails != null 
        ? fpSisaPembayaran 
        : dpRemainingAmount;
    
    // ✅ FIX: Check if we have valid DP data to show
    // Show if manually flagged as down payment OR has remaining amount OR explicitly isDownPayment
    final shouldShow = isDownPayment || 
                       remainingAmount > 0 || 
                       hasPendingFinalPayment ||
                       paymentDetails['downPaymentAmount'] != null;

    if (!shouldShow) {
       return const SizedBox.shrink();
    }

    return Column(
      children: [
        // Down Payment Section Header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.account_balance_wallet,
                color: Colors.orange,
                size: 20,
              ),
            ),
        const SizedBox(width: 12),
            Text(
              hasPendingFinalPayment ? 'Informasi Pelunasan' : 'Informasi Down Payment',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // DP Details Container
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.orange.withOpacity(0.2),
            ),
          ),
          child: Column(
            children: [
              // DP Amount with Status
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDownPaymentPaid ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDownPaymentPaid ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isDownPaymentPaid ? Icons.check_circle : Icons.access_time,
                      size: 20,
                      color: isDownPaymentPaid ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Down Payment (DP)',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          Text(
                            isDownPaymentPaid ? 'Sudah Dibayar' : 'Belum Dibayar',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDownPaymentPaid ? Colors.green : Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      formatCurrency(paidAmount),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDownPaymentPaid ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              
              // ✅ Tambahan Order - show only when Final Payment exists and has additional order value
              if (finalPaymentDetails != null && fpTambahanOrder > 0)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.purple.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.add_shopping_cart,
                        size: 20,
                        color: Colors.purple,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tambahan Order',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            Text(
                              'Pesanan Tambahan',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.purple.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        formatCurrency(fpTambahanOrder), // Tambahan Order
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.purple,
                        ),
                      ),
                    ],
                  ),
                ),
              
              if (finalPaymentDetails != null && fpTambahanOrder > 0)
                const SizedBox(height: 8),

              // Remaining Amount
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.blue.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.pending_actions,
                      size: 20,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sisa Pembayaran',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          Text(
                            sisaPembayaran > 0
                                ? 'Belum Lunas'
                                : 'Lunas',
                            style: TextStyle(
                              fontSize: 12,
                              color: sisaPembayaran > 0
                                  ? Colors.orange
                                  : Colors.green,
                              fontWeight: FontWeight.w500,
                            ),
                          ),

                        ],
                      ),
                    ),
                    Text(
                      formatCurrency(sisaPembayaran), // Sisa Pembayaran
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: sisaPembayaran > 0 ? Colors.orange : Colors.green,
                      ),
                    ),

                  ],
                ),
              ),
            ],
          ),
        ),

        // Divider
        Container(
          height: 1,
          margin: const EdgeInsets.symmetric(horizontal: 0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                Colors.grey.shade200,
                Colors.transparent,
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }



  @override
  Widget build(BuildContext context) {
    final items = orderData['items'] as List? ?? [];
    final customAmountItems = orderData['customAmountItems'] as List? ?? [];
    final paymentDetails = orderData['paymentDetails'] as Map<String, dynamic>?;

    // Safe access untuk paymentStatus dengan support down payment
    final paymentStatusValue = orderData['paymentStatus']?.toString();
    final paymentStatus = _getPaymentStatus(paymentStatusValue, paymentDetails);

    // ✅ Check if both items and customAmountItems are empty
    final hasNoItems = items.isEmpty && customAmountItems.isEmpty;

    print('Payment Status Value: $paymentStatusValue');
    print('Payment Details: $paymentDetails');
    print('Items count: ${items.length}');
    print('Custom Amount Items count: ${customAmountItems.length}');
    
    // ✅ DEBUG: Additional logging for DP and Final Payment
    print('=== DEBUG PAYMENT INFO ===' );
    print('isDownPayment: ${paymentDetails?['isDownPayment']}');
    print('downPaymentPaid: ${paymentDetails?['downPaymentPaid']}');
    print('paidAmount: ${paymentDetails?['paidAmount']}');
    print('remainingAmount: ${paymentDetails?['remainingAmount']}');
    print('hasPendingFinalPayment: ${paymentDetails?['hasPendingFinalPayment']}');
    final pendingFPDetails = paymentDetails?['finalPaymentDetails'];
    print('finalPaymentDetails: $pendingFPDetails');
    if (pendingFPDetails != null) {
      print('  - status: ${pendingFPDetails['status']}');
      print('  - amount: ${pendingFPDetails['amount']}');
      print('  - actions: ${pendingFPDetails['actions']}');
    }
    print('=========================');

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 0,
            blurRadius: 20,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Header Info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            orderData['orderNumber']?.toString() ?? 'No Order Number',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF2E8B57),
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E8B57).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF2E8B57).withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          orderData['orderDate']?.toString() ?? 'No Date',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF2E8B57),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  // ✅ NEW: Customer/Creator Info Section
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        // Guest Name
                        _buildInfoRow(
                          icon: Icons.person,
                          label: 'Nama Tamu',
                          value: orderData['user']?.toString() ?? 
                                 orderData['reservation']?['guestName']?.toString() ?? 
                                 'Guest',
                          color: Colors.blue,
                        ),
                        const SizedBox(height: 8),
                        
                        // Order Type
                        _buildInfoRow(
                          icon: Icons.restaurant,
                          label: 'Tipe Order',
                          value: orderData['orderType']?.toString() ?? 'Unknown',
                          color: Colors.orange,
                        ),
                        const SizedBox(height: 8),
                        
                        // Source (Gro/Kasir/Customer)
                        _buildInfoRow(
                          icon: Icons.source,
                          label: 'Sumber Order',
                          value: orderData['source']?.toString() ?? 'Unknown',
                          color: Colors.purple,
                        ),
                        
                        // Creator Info (if available)
                        if (orderData['createdBy'] != null) ...[
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            icon: orderData['createdBy']?['role'] == 'GRO' 
                                ? Icons.support_agent 
                                : Icons.point_of_sale,
                            label: 'Dibuat Oleh',
                            value: '${orderData['createdBy']?['username'] ?? 'System'} (${orderData['createdBy']?['role'] ?? ''})',
                            color: orderData['createdBy']?['role'] == 'GRO' 
                                ? Colors.teal 
                                : Colors.indigo,
                          ),
                        ],
                        
                        // Reservation Info (if available)
                        if (orderData['reservation'] != null) ...[
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            icon: Icons.event,
                            label: 'Reservasi',
                            value: orderData['reservation']?['reservationCode']?.toString() ?? '-',
                            color: Colors.green,
                          ),
                          if (orderData['reservation']?['food_serving_time'] != null) ...[
                            const SizedBox(height: 8),
                            _buildInfoRow(
                              icon: Icons.schedule,
                              label: 'Penyajian Makanan',
                              value: _formatDateTime(orderData['reservation']?['food_serving_time']?.toString()),
                              color: Colors.deepOrange,
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ✅ Combined Items Section (Regular Items + Custom Amount Items)
            if (!hasNoItems) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E8B57).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.receipt_long,
                            color: Color(0xFF2E8B57),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Detail Pesanan',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Loop through all regular items
                    ...items.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF2E8B57).withOpacity(0.1),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item['name']?.toString() ?? 'Unknown Item',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'x${item['quantity']?.toString() ?? '0'}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  formatCurrency(_getNumericValue(item['price'])),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            if (item['notes'] != null && item['notes'].toString().isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.amber.withOpacity(0.3)),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.format_quote, size: 14, color: Colors.amber),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        item['notes'].toString(),
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontStyle: FontStyle.italic,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }),

                    // ✅ Loop through all custom amount items (tampilan sama dengan regular items)
                    ...customAmountItems.asMap().entries.map((entry) {
                      final item = entry.value;

                      final amount = _getNumericValue(item['amount']);
                      final name = item['name']?.toString() ?? 'Penyesuaian Pembayaran';
                      final description = item['description']?.toString() ?? '';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF2E8B57).withOpacity(0.1),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  formatCurrency(amount),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            if (description.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.amber.withOpacity(0.3)),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.format_quote, size: 14, color: Colors.amber),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        description,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontStyle: FontStyle.italic,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),

              // Divider
              Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.grey.shade200,
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // ✅ Show message if no items at all
            if (hasNoItems)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 48,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Belum ada item dalam pesanan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Add Order Button (jika showAddOrderButton = true)
            if (showAddOrderButton && onAddOrder != null)
              Padding(
                padding: const EdgeInsets.only(top: 3, left: 24, right: 24, bottom: 16),
                child: ElevatedButton.icon(
                  onPressed: onAddOrder,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: const Color(0xFF2E8B57),
                  ),
                  icon: const Icon(Icons.add_circle_rounded, color: Colors.white),
                  label: const Text(
                    'Tambah Pesanan',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),

            // Down Payment Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
              child: _buildDownPaymentSection(orderData),
            ),

            // Payment Detail Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.payment,
                          color: Color(0xFF10B981),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Rincian Pembayaran',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 1,
                    width: double.infinity,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),

                  // Subtotal (sudah termasuk customAmount dari backend)
                  PaymentRowWidget(
                    label: 'Subtotal',
                    value: formatCurrency(_getNumericValue(orderData['totalBeforeDiscount'])),
                    icon: Icons.calculate,
                    isTotal: false,
                  ),

                  // Voucher discount
                  if (orderData['voucher'] != null) ...[
                    const SizedBox(height: 8),
                        () {
                      final voucher = orderData['voucher'] as Map<String, dynamic>;
                      final voucherCode = voucher['code']?.toString() ?? '';
                      final discountType = voucher['discountType']?.toString() ?? 'fixed';
                      final discountAmount = _getNumericValue(voucher['discountAmount']);

                      final totalBeforeDiscount = _getNumericValue(orderData['totalBeforeDiscount']);
                      final actualDiscount = discountType == 'percentage'
                          ? (totalBeforeDiscount * discountAmount / 100).round()
                          : discountAmount.round();

                      final labelText = discountType == 'percentage'
                          ? 'Kupon Diskon ($voucherCode ${discountAmount.toStringAsFixed(0)}%)'
                          : 'Kupon Diskon ($voucherCode)';

                      return PaymentRowWidget(
                        label: labelText,
                        value: '-${formatCurrency(actualDiscount)}',
                        icon: Icons.local_offer,
                        isTotal: false,
                      );
                    }(),
                    const SizedBox(height: 8),
                    PaymentRowWidget(
                      label: 'Subtotal setelah diskon',
                      value: formatCurrency(_getNumericValue(orderData['totalAfterDiscount'])),
                      icon: Icons.price_check,
                      isTotal: false,
                    ),
                  ],

                  // Tax details
                  if (orderData['taxAndServiceDetails'] != null) ...[
                    const SizedBox(height: 8),
                    ...(orderData['taxAndServiceDetails'] as List).map<Widget>((taxDetail) {
                      final taxAmount = _getNumericValue(taxDetail['amount']);
                      final taxName = taxDetail['name']?.toString() ?? '';
                      final totalAfterDiscount = _getNumericValue(orderData['totalAfterDiscount']);

                      double percentage = 0.0;
                      if (totalAfterDiscount > 0) {
                        percentage = (taxAmount / totalAfterDiscount) * 100;
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: PaymentRowWidget(
                          label: '$taxName (${percentage.toStringAsFixed(0)}%)',
                          value: formatCurrency(taxAmount),
                          icon: Icons.account_balance,
                          isTotal: false,
                        ),
                      );
                    }),
                  ],

                  const SizedBox(height: 8),
                  PaymentRowWidget(
                    label: 'Total',
                    value: formatCurrency(_getNumericValue(orderData['grandTotal'])),
                    icon: Icons.receipt,
                    isTotal: true,
                  ),

                  if (paymentDetails?['isDownPayment'] != true || items.isNotEmpty || customAmountItems.isNotEmpty)
                    const SizedBox(height: 16),

                  PaymentRowWidget(
                    label: 'Metode Pembayaran',
                    // ✅ FIX: Improve payment method lookup
                    value: orderData['paymentMethod']?.toString() ?? 
                           paymentDetails?['method']?.toString() ??
                           paymentDetails?['paymentType']?.toString() ?? 
                           'Not specified',
                    icon: Icons.credit_card,
                    isTotal: false,
                  ),
                  const SizedBox(height: 12),

                  // Payment Status
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: paymentStatus['color'].withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: paymentStatus['color'].withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          paymentStatus['icon'],
                          size: 20,
                          color: paymentStatus['color'],
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Status',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: paymentStatus['color'],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            paymentStatus['label'],
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // ✅ FINAL PAYMENT BUTTON
                  if (onFinalPayment != null && 
                      paymentStatus['label'] == 'DP Dibayar - Sisa Belum Lunas') ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: onFinalPayment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepOrange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.payment, size: 18),
                        label: const Text(
                          'Pelunasan Pembayaran',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                  
                  // ✅ QR Code at the very bottom
                  _buildPendingFinalPaymentQR(paymentDetails),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods
  num _getNumericValue(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value;
    if (value is String) {
      return num.tryParse(value) ?? 0;
    }
    return 0;
  }

  // ✅ NEW: Helper to build info row
  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  // ✅ NEW: Helper to format datetime string
  String _formatDateTime(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '-';
    try {
      final date = DateTime.parse(dateString);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'];
      return '${date.day} ${months[date.month - 1]} ${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }
}