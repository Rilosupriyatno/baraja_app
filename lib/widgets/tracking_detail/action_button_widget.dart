import 'package:flutter/material.dart';

class ActionButtonWidget extends StatelessWidget {
  final Map<String, dynamic>? orderData;
  final Map<String, dynamic>? existingRating;
  final bool hasPaymentDetails;
  final bool isLoadingRating;
  final VoidCallback onNavigateToPayment;
  final VoidCallback onNavigateToRating;
  final VoidCallback? onNavigateToFinalPayment; // NEW: Callback untuk final payment

  const ActionButtonWidget({
    super.key,
    required this.orderData,
    required this.existingRating,
    required this.hasPaymentDetails,
    required this.isLoadingRating,
    required this.onNavigateToPayment,
    required this.onNavigateToRating,
    this.onNavigateToFinalPayment, // NEW: Optional callback
  });

  bool get _hasRating => existingRating != null;

  bool get _isOrderCompleted =>
      ['Completed'].contains(orderData?['orderStatus'] ?? orderData?['status']);

  // NEW: Check if needs final payment
  bool get _needsFinalPayment {
    final paymentDetails = orderData?['paymentDetails'] as Map<String, dynamic>?;

    if (paymentDetails == null) return false;

    final isDownPayment = paymentDetails['isDownPayment'] == true;
    final downPaymentPaid = paymentDetails['downPaymentPaid'] == true;
    final remainingAmount = paymentDetails['remainingAmount'] ?? 0;
    final isFullyPaid = paymentDetails['isFullyPaid'] == true;

    // Butuh final payment jika:
    // - Ada down payment yang sudah dibayar
    // - Masih ada remaining amount
    // - Belum fully paid
    return isDownPayment && downPaymentPaid && remainingAmount > 0 && !isFullyPaid;
  }

  bool get _shouldShowActionButton {
    print('=== DEBUG ACTION BUTTON ===');
    print('isLoadingRating: $isLoadingRating');
    print('_isOrderCompleted: $_isOrderCompleted');
    print('_hasRating: $_hasRating');
    print('_needsFinalPayment: $_needsFinalPayment');
    print('hasPaymentDetails: $hasPaymentDetails');
    print('orderData paymentStatus: ${orderData?['paymentStatus']}');
    print('orderData paymentDetails: ${orderData?['paymentDetails']}');

    if (isLoadingRating) {
      print('Returning false: isLoadingRating = true');
      return false;
    }

    // Priority 1: Show rating button if order completed and no rating
    if (_isOrderCompleted && !_hasRating) {
      print('Returning true: order completed and no rating');
      return true;
    }

    // Priority 2: Show final payment button if needed
    if (_needsFinalPayment && onNavigateToFinalPayment != null) {
      print('Returning true: needs final payment');
      return true;
    }

    // Priority 3: Show payment button for regular payment scenarios
    final paymentStatus = orderData?['paymentStatus'] ?? orderData?['orderStatus'];
    bool shouldShow = ['pending', 'settlement', 'capture'].contains(paymentStatus) || hasPaymentDetails;

    print('Payment status: $paymentStatus');
    print('Should show button: $shouldShow');

    return shouldShow;
  }

  Widget _buildButton({
    required VoidCallback onPressed,
    required Color backgroundColor,
    required IconData icon,
    required String text,
    String? subtitle,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 8),
                Text(
                    text,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)
                ),
              ],
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.8),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_shouldShowActionButton) return const SizedBox.shrink();

    // Priority 1: Rating button for completed orders
    if (_isOrderCompleted && !_hasRating) {
      return _buildButton(
        onPressed: onNavigateToRating,
        backgroundColor: Colors.green,
        icon: Icons.star_rate_rounded,
        text: 'Kasih Rating Dong',
      );
    }

    // Priority 2: Final payment button
    if (_needsFinalPayment && onNavigateToFinalPayment != null) {
      final paymentDetails = orderData?['paymentDetails'] as Map<String, dynamic>?;
      final remainingAmount = paymentDetails?['remainingAmount'] ?? 0;

      return _buildButton(
        onPressed: onNavigateToFinalPayment!,
        backgroundColor: Colors.deepOrange,
        icon: Icons.payment,
        text: 'Lunasi Pembayaran',
        subtitle: 'Sisa: Rp ${_formatCurrency(remainingAmount)}',
      );
    }

    // Priority 3: Regular payment button
    final paymentStatus = orderData?['paymentStatus'] ?? orderData?['paymentDetails']?['orderStatus'];
    final isPending = paymentStatus == 'pending';

    return _buildButton(
      onPressed: onNavigateToPayment,
      backgroundColor: isPending ? Colors.orange : Colors.blue,
      icon: isPending ? Icons.payment : Icons.receipt_long,
      text: isPending ? 'Bayar Sekarang' : 'Lihat Detail Pembayaran',
    );
  }

  // Helper method untuk format currency
  String _formatCurrency(dynamic amount) {
    if (amount == null) return '0';

    final numAmount = amount is String ? double.tryParse(amount) ?? 0 : amount;
    return numAmount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
    );
  }
}