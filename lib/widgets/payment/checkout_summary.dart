import 'package:baraja_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import '../../utils/currency_formatter.dart';

class CheckoutSummary extends StatelessWidget {
  final int totalPrice;
  final int discount;
  final String? voucherCode;
  final VoidCallback onCheckoutPressed;

  const CheckoutSummary({
    super.key,
    required this.totalPrice,
    this.discount = 0,
    this.voucherCode,
    required this.onCheckoutPressed,
  });

  @override
  Widget build(BuildContext context) {
    final int finalTotal = totalPrice - discount;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Ringkasan Pembayaran",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),

          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Subtotal"),
              Text(formatCurrency(totalPrice)),
            ],
          ),

          if (voucherCode != null && discount > 0) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Diskon Voucher ($voucherCode)",
                  style: const TextStyle(color: Colors.green),
                ),
                Text(
                  "- ${formatCurrency(discount)}",
                  style: const TextStyle(color: Colors.green),
                ),
              ],
            ),
            const Divider(),
          ],

          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Total",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                formatCurrency(finalTotal),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onCheckoutPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                "Checkout",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}