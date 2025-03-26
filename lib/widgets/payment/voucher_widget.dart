import 'package:flutter/material.dart';
import '../../screens/voucher_screen.dart';

class VoucherWidget extends StatelessWidget {
  final String voucherCode;
  final bool voucherApplied;
  final VoidCallback onTap;

  const VoucherWidget({
    super.key,
    required this.voucherCode,
    required this.voucherApplied,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Voucher",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),

        const SizedBox(height: 8),

        GestureDetector(
          onTap: () async {
            // Navigate to voucher selection screen
            final selectedVoucher = await Navigator.push<String>(
              context,
              MaterialPageRoute(
                builder: (context) => VoucherScreen(
                  appliedVoucherCode: voucherApplied ? voucherCode : null,
                ),
              ),
            );

            // Handle the selected voucher
            if (selectedVoucher != null) {
              // This would need to call a method in the parent widget
              // to update the voucher
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.confirmation_number_outlined,
                  color: Colors.grey,
                  size: 20,
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Text(
                    voucherApplied ? "Voucher applied: $voucherCode" : "Ketuk untuk menggunakan voucher",
                    style: TextStyle(
                      fontSize: 14,
                      color: voucherApplied ? Colors.black : Colors.grey,
                    ),
                  ),
                ),

                const Icon(
                  Icons.chevron_right,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}