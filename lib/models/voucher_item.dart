import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../screens/voucher_screen.dart';

class VoucherItem extends StatelessWidget {
  final Voucher voucher;
  final bool isSelected;
  final VoidCallback? onTap;

  const VoucherItem({
    super.key,
    required this.voucher,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8.0),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.0),
              color: Colors.white,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon voucher
                  Icon(
                    Icons.card_giftcard,
                    size: 32,
                    color: voucher.isDisabled
                        ? Colors.grey
                        : AppTheme.primaryColor,
                  ),

                  const SizedBox(width: 12),

                  // Voucher details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          voucher.description,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: voucher.isDisabled
                                ? Colors.grey
                                : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          voucher.additionalInfo,
                          style: TextStyle(
                            fontSize: 12,
                            color: voucher.isDisabled
                                ? Colors.grey
                                : Colors.black87,
                          ),
                        ),
                        if (voucher.additionalRequirement != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            voucher.additionalRequirement!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Radio pilih voucher
                  if (!voucher.isDisabled)
                    Radio<bool>(
                      value: true,
                      groupValue: isSelected ? true : null,
                      onChanged: onTap != null ? (value) => onTap!() : null,
                      activeColor: Colors.green,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
