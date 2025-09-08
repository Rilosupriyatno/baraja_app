import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/voucher_item.dart';

class VoucherWidget extends StatelessWidget {
  final String voucherCode;
  final bool voucherApplied;
  final Function(Voucher) onVoucherSelected; // ✅ terima Voucher, bukan String

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
            // Kirim ke VoucherScreen, return Voucher object
            final selectedVoucher = await context.push<Voucher>(
              '/voucher',
              extra: {
                'appliedVoucherCode': voucherApplied ? voucherCode : null,
                'readonly': false,
              },
            );


            if (selectedVoucher != null) {
              onVoucherSelected(selectedVoucher); // ✅ kirim object Voucher
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
