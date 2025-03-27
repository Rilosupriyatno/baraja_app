import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class VoucherWidget extends StatelessWidget {
  final String voucherCode;
  final bool voucherApplied;
  final Function(String) onVoucherSelected; // Callback function

  const VoucherWidget({
    super.key,
    required this.voucherCode,
    required this.voucherApplied,
    required this.onVoucherSelected,
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
            final selectedVoucher = await context.push<String>(
              '/voucher',
              extra: voucherApplied ? voucherCode : null,
            );


            if (selectedVoucher != null) {
              onVoucherSelected(selectedVoucher); // Pass back to parent
            }
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  voucherApplied ? "Voucher: $voucherCode" : "Pilih Voucher",
                  style: TextStyle(
                    fontSize: 14,
                    color: voucherApplied ? Colors.green : Colors.grey,
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
