import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'package:intl/intl.dart';

class VoucherItem extends StatelessWidget {
  final Voucher voucher;
  final bool isSelected;
  final VoidCallback? onTap;
  final bool readonly;

  const VoucherItem({
    super.key,
    required this.voucher,
    required this.isSelected,
    this.onTap,
    this.readonly = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = !voucher.isActive;
    final dateFormat = DateFormat("dd MMM yyyy");
    final String validFrom = dateFormat.format(voucher.validFrom);
    final String validTo = dateFormat.format(voucher.validTo);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: (isDisabled || readonly) ? null : onTap,
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
                    color: isDisabled ? Colors.grey : AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 12),

                  // Voucher details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          voucher.name,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isDisabled ? Colors.grey : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          voucher.description,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDisabled ? Colors.grey : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              voucher.discountType == "percentage"
                                  ? "${voucher.discountAmount}%"
                                  : "Rp ${voucher.discountAmount}",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color:
                                isDisabled ? Colors.grey : Colors.green[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),

                        // Tanggal berlaku
                        Text(
                          "Berlaku: $validFrom - $validTo",
                          style: TextStyle(
                            fontSize: 12,
                            color: isDisabled ? Colors.grey : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Radio pilih voucher
                  if (!isDisabled && !readonly)
                    Radio<bool>(
                      value: true,
                      groupValue: isSelected ? true : null,
                      onChanged: (value) => onTap?.call(),
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

class Voucher {
  final String id;
  final String code;
  final String name;
  final String description;
  final int discountAmount;
  final String discountType; // "fixed" atau "percentage"
  final bool isActive;
  final DateTime validFrom;
  final DateTime validTo;

  Voucher({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    required this.discountAmount,
    required this.discountType,
    required this.isActive,
    required this.validFrom,
    required this.validTo,
  });

  factory Voucher.fromJson(Map<String, dynamic> json) {
    return Voucher(
      id: json['_id'],
      code: json['code'],
      name: json['name'],
      description: json['description'],
      discountAmount: json['discountAmount'],
      discountType: json['discountType'],
      isActive: json['isActive'] ?? true,
      validFrom: DateTime.parse(json['validFrom']),
      validTo: DateTime.parse(json['validTo']),
    );
  }
}
