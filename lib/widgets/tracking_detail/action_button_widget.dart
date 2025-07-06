import 'package:flutter/material.dart';

class ActionButtonWidget extends StatelessWidget {
  final Map<String, dynamic>? orderData;
  final Map<String, dynamic>? existingRating;
  final bool hasPaymentDetails;
  final bool isLoadingRating;
  final VoidCallback onNavigateToPayment;
  final VoidCallback onNavigateToRating;

  const ActionButtonWidget({
    super.key,
    required this.orderData,
    required this.existingRating,
    required this.hasPaymentDetails,
    required this.isLoadingRating,
    required this.onNavigateToPayment,
    required this.onNavigateToRating,
  });

  bool get _hasRating => existingRating != null;

  bool get _isOrderCompleted =>
      ['Completed'].contains(orderData?['orderStatus'] ?? orderData?['status']);

  bool get _shouldShowActionButton {
    if (isLoadingRating) return false;
    if (_isOrderCompleted && !_hasRating) return true;
    if (_hasRating || !hasPaymentDetails) return false;

    final paymentStatus = orderData?['paymentStatus'] ?? orderData?['paymentDetails']?['status'];
    return ['pending', 'settlement', 'capture'].contains(paymentStatus) || hasPaymentDetails;
  }

  Widget _buildButton({
    required VoidCallback onPressed,
    required Color backgroundColor,
    required IconData icon,
    required String text,
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 8),
            Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_shouldShowActionButton) return const SizedBox.shrink();

    if (_isOrderCompleted && !_hasRating) {
      return _buildButton(
        onPressed: onNavigateToRating,
        backgroundColor: Colors.green,
        icon: Icons.star_rate_rounded,
        text: 'Kasih Rating Dong',
      );
    }

    final paymentStatus = orderData?['paymentStatus'] ?? orderData?['paymentDetails']?['status'];
    final isPending = paymentStatus == 'pending';

    return _buildButton(
      onPressed: onNavigateToPayment,
      backgroundColor: isPending ? Colors.orange : Colors.blue,
      icon: isPending ? Icons.payment : Icons.receipt_long,
      text: isPending ? 'Bayar Sekarang' : 'Lihat Detail Pembayaran',
    );
  }
}