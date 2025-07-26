import 'package:flutter/material.dart';
import '../../utils/currency_formatter.dart';

enum PaymentType {
  fullPayment,
  downPayment,
}

class ReservationPaymentTypeWidget extends StatelessWidget {
  final PaymentType selectedType;
  final Function(PaymentType) onChanged;
  final int totalAmount;
  final int downPaymentAmount;

  const ReservationPaymentTypeWidget({
    super.key,
    required this.selectedType,
    required this.onChanged,
    required this.totalAmount,
    required this.downPaymentAmount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pilih Jenis Pembayaran',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Pilih apakah ingin membayar penuh atau down payment terlebih dahulu',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 16),

        // Full Payment Option
        _buildPaymentTypeCard(
          type: PaymentType.fullPayment,
          title: 'Pembayaran Penuh',
          subtitle: 'Bayar seluruh tagihan sekarang',
          amount: totalAmount,
          icon: Icons.payment,
          iconColor: Colors.green,
          context: context,
        ),

        const SizedBox(height: 12),

        // Down Payment Option
        _buildPaymentTypeCard(
          type: PaymentType.downPayment,
          title: 'Down Payment',
          subtitle: 'Bayar sebagian, sisanya saat di restoran',
          amount: downPaymentAmount,
          icon: Icons.account_balance_wallet,
          iconColor: Colors.orange,
          context: context,
        ),

        const SizedBox(height: 12),

        // Info box for down payment
        if (selectedType == PaymentType.downPayment)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.blue.shade600,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sisa pembayaran: ${formatCurrency(totalAmount - downPaymentAmount)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Akan dibayar saat Anda tiba di restoran',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildPaymentTypeCard({
    required PaymentType type,
    required String title,
    required String subtitle,
    required int amount,
    required IconData icon,
    required Color iconColor,
    required BuildContext context,
  }) {
    final bool isSelected = selectedType == type;

    return GestureDetector(
      onTap: () => onChanged(type),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.orange : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          color: isSelected ? Colors.orange.shade50 : Colors.white,
        ),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 24,
              ),
            ),

            const SizedBox(width: 16),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.orange.shade700 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    formatCurrency(amount),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.orange.shade700 : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),

            // Radio button
            Radio<PaymentType>(
              value: type,
              groupValue: selectedType,
              onChanged: (PaymentType? value) {
                if (value != null) {
                  onChanged(value);
                }
              },
              activeColor: Colors.orange,
            ),
          ],
        ),
      ),
    );
  }
}