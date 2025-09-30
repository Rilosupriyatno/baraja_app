import 'package:baraja_amphitheater_app/theme/app_theme.dart';
import 'package:baraja_amphitheater_app/widgets/checkout/reservation_payment_type_widget.dart';
import 'package:flutter/material.dart';
import '../../utils/currency_formatter.dart';
import '../../services/tax_service.dart'; // Import TaxCalculationResult from here

class CheckoutSummary extends StatelessWidget {
  final int totalPrice;
  final int discount;
  final String? voucherCode;
  final VoidCallback onCheckoutPressed;
  final bool isReservation;
  final bool isOpenBill;
  final PaymentType? selectedPaymentType;
  final String? discountType;
  final TaxCalculationResult? taxCalculation; // Now uses the class from tax_service.dart

  const CheckoutSummary({
    super.key,
    required this.totalPrice,
    this.discount = 0,
    this.voucherCode,
    required this.onCheckoutPressed,
    this.isReservation = false,
    this.isOpenBill = false,
    this.selectedPaymentType,
    this.discountType,
    this.taxCalculation,
  });

  @override
  Widget build(BuildContext context) {
    final int finalTotal = totalPrice - discount;
    final int taxAmount = taxCalculation?.totalTaxAmount.round() ?? 0;
    final int grandTotal = finalTotal + taxAmount;
    final int downPaymentAmount = (grandTotal * 0.5).round();

    int amountToPay = grandTotal;
    if (isReservation && selectedPaymentType == PaymentType.downPayment) {
      amountToPay = downPaymentAmount;
    }

    return SafeArea(
      child: Container(
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

            // Subtotal
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Subtotal"),
                Text(formatCurrency(totalPrice)),
              ],
            ),

            // Voucher discount (if applicable)
            if (voucherCode != null && discount > 0) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    discountType == "percentage"
                        ? "Kupon Diskon ($voucherCode%)"
                        : "Kupon Diskon ($voucherCode)",
                    style: const TextStyle(color: Colors.green),
                  ),
                  Text(
                    "- ${formatCurrency(discount)}",
                    style: const TextStyle(color: Colors.green),
                  ),
                ],
              ),
            ],

            // Tax details (if applicable)
            if (taxCalculation != null && taxCalculation!.taxDetails.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...taxCalculation!.taxDetails.map((tax) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${tax['name']} (${tax['percentage'].toStringAsFixed(0)}%)",
                      style: const TextStyle(color: Colors.orange),
                    ),
                    Text(
                      "+ ${formatCurrency(tax['amount'].round())}",
                      style: const TextStyle(color: Colors.orange),
                    ),
                  ],
                ),
              )),
            ],

            const Divider(),
            const SizedBox(height: 8),

            // Total after discount and tax
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isReservation && selectedPaymentType == PaymentType.downPayment
                      ? "Total Keseluruhan"
                      : "Total",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  formatCurrency(grandTotal),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),

            // Down payment amount (for reservations)
            if (isReservation && selectedPaymentType == PaymentType.downPayment) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Bayar Sekarang",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    formatCurrency(amountToPay),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 16),

            // Checkout button
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
                child: Text(
                  isReservation && selectedPaymentType == PaymentType.downPayment
                      ? "Bayar Down Payment ${formatCurrency(amountToPay)}"
                      : isOpenBill
                      ? "Bayar Open Bill ${formatCurrency(amountToPay)}"
                      : "Bayar ${formatCurrency(amountToPay)}",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}