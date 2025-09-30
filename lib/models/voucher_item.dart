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
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                voucher.name,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: isDisabled ? Colors.grey : Colors.black,
                                ),
                              ),
                            ),
                            // Badge untuk oneTimeUse
                            if (voucher.oneTimeUse)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: Colors.orange.shade300,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  'Sekali Pakai',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.orange.shade700,
                                  ),
                                ),
                              ),
                          ],
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
                                  : "Rp ${NumberFormat('#,###', 'id_ID').format(voucher.discountAmount)}",
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
  final bool oneTimeUse; // 🆕 Field baru untuk one-time use
  final List<dynamic> applicableOutlets;

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
    this.oneTimeUse = false, // Default false
    this.applicableOutlets = const [],
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
      oneTimeUse: json['oneTimeUse'] ?? false, // 🆕 Parse dari JSON
      applicableOutlets: json['applicableOutlets'] ?? [],
    );
  }
}