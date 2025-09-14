import 'package:flutter/material.dart';
import '../../utils/currency_formatter.dart';

class DownPaymentInfoWidget extends StatelessWidget {
  final Map<String, dynamic> paymentDetails;

  const DownPaymentInfoWidget({
    super.key,
    required this.paymentDetails,
  });

  @override
  Widget build(BuildContext context) {
    final isDownPayment = paymentDetails['isDownPayment'] == true;
    final downPaymentPaid = paymentDetails['downPaymentPaid'] == true;
    final totalAmount = _getNumericValue(paymentDetails['totalAmount']);
    final paidAmount = _getNumericValue(paymentDetails['paidAmount']);
    final remainingAmount = _getNumericValue(paymentDetails['remainingAmount']);

    if (!isDownPayment) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            downPaymentPaid
                ? Colors.green.withOpacity(0.05)
                : Colors.amber.withOpacity(0.05),
            downPaymentPaid
                ? Colors.green.withOpacity(0.1)
                : Colors.amber.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: downPaymentPaid
              ? Colors.green.withOpacity(0.3)
              : Colors.amber.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: downPaymentPaid
                      ? Colors.green.withOpacity(0.2)
                      : Colors.amber.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  downPaymentPaid ? Icons.verified : Icons.schedule,
                  color: downPaymentPaid ? Colors.green : Colors.amber.shade700,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sistem Down Payment',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: downPaymentPaid ? Colors.green.shade700 : Colors.amber.shade700,
                      ),
                    ),
                    Text(
                      downPaymentPaid
                          ? 'DP sudah dibayar'
                          : 'Menunggu pembayaran DP',
                      style: TextStyle(
                        fontSize: 12,
                        color: downPaymentPaid ? Colors.green.shade600 : Colors.amber.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Payment Breakdown
          _buildPaymentRow(
            'Total Pesanan',
            totalAmount,
            Icons.receipt_long_outlined,
            Colors.grey.shade700,
          ),

          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: downPaymentPaid
                  ? Colors.green.withOpacity(0.1)
                  : Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: downPaymentPaid
                    ? Colors.green.withOpacity(0.2)
                    : Colors.amber.withOpacity(0.2),
              ),
            ),
            child: Column(
              children: [
                _buildPaymentRow(
                  'Down Payment',
                  paidAmount,
                  downPaymentPaid ? Icons.check_circle : Icons.payment,
                  downPaymentPaid ? Colors.green : Colors.amber.shade700,
                  isHighlighted: true,
                ),

                if (downPaymentPaid && remainingAmount > 0) ...[
                  const SizedBox(height: 8),
                  Container(
                    height: 1,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 8),
                  _buildPaymentRow(
                    'Sisa Pembayaran',
                    remainingAmount,
                    Icons.schedule_outlined,
                    Colors.red.shade600,
                    isHighlighted: true,
                  ),
                ],
              ],
            ),
          ),

          if (remainingAmount > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.blue.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue.shade600,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      downPaymentPaid
                          ? 'Silakan lakukan pelunasan untuk melanjutkan pesanan'
                          : 'Lakukan pembayaran down payment terlebih dahulu',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
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
  }

  Widget _buildPaymentRow(
      String label,
      num amount,
      IconData icon,
      Color color,
      {bool isHighlighted = false}
      ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: color,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: isHighlighted ? 15 : 14,
              fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ),
        Text(
          formatCurrency(amount),
          style: TextStyle(
            fontSize: isHighlighted ? 15 : 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  num _getNumericValue(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value;
    if (value is String) {
      return num.tryParse(value) ?? 0;
    }
    return 0;
  }
}