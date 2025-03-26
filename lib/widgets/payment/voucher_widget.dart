import 'package:flutter/material.dart';

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
          onTap: onTap,
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
                    voucherApplied ? "Voucher digunakan: $voucherCode" : "Gunakan Voucher",
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