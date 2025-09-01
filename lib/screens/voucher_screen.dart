import 'package:baraja_app/widgets/utils/classic_app_bar.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class VoucherScreen extends StatefulWidget {
  final String? appliedVoucherCode;

  const VoucherScreen({
    super.key,
    this.appliedVoucherCode,
  });

  @override
  State<VoucherScreen> createState() => _VoucherScreenState();
}

class _VoucherScreenState extends State<VoucherScreen> {
  String? selectedVoucherCode;
  final TextEditingController _voucherController = TextEditingController();

  // Sample voucher data
  final List<Voucher> _vouchers = [
    Voucher(
      code: 'DISC10',
      description: 'Disc 10% up to Rp20.000',
      additionalInfo: 'No minimum purchase',
      iconAsset: 'assets/images/voucher_icon.png',
    ),
    Voucher(
      code: 'DISC15',
      description: 'Disc 15% up to Rp25.000',
      additionalInfo: 'Minimum spend Rp20.000',
      iconAsset: 'assets/images/voucher_icon.png',
    ),
    Voucher(
      code: 'BCADISC',
      description: 'Disc Rp75.000',
      additionalInfo: 'Minimum spend Rp250.000',
      additionalRequirement: 'Spend another Rp180.000 to enjoy this voucher',
      iconAsset: 'assets/images/bca_icon.png',
      isDisabled: true,
    ),
    Voucher(
      code: 'BSIPROMO',
      description: 'Disc Rp20.000',
      additionalInfo: 'Minimum spend Rp80.000',
      additionalRequirement: 'Spend another Rp40.000 to enjoy this voucher',
      iconAsset: 'assets/images/bsi_icon.png',
      isDisabled: true,
    ),
    Voucher(
      code: 'COFFEE30',
      description: 'Disc 30% up to Rp30.000',
      additionalInfo: 'Minimum spend Rp40.000',
      additionalRequirement: 'Spend another Rp20.000 to enjoy this voucher',
      iconAsset: 'assets/images/voucher_icon.png',
      isDisabled: true,
    ),
    Voucher(
      code: 'PROMO35',
      description: 'Disc 35% up to Rp65.000',
      additionalInfo: 'Minimum spend Rp85.000',
      additionalRequirement: 'Spend another Rp45.000 to enjoy this voucher',
      iconAsset: 'assets/images/voucher_icon.png',
      isDisabled: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    selectedVoucherCode = widget.appliedVoucherCode;
  }

  @override
  void dispose() {
    _voucherController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const ClassicAppBar(title: 'Voucher'),
      body: SafeArea(
        child: Column(
          children: [
            // Voucher input field
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _voucherController,
                decoration: InputDecoration(
                  hintText: 'Enter the voucher code here',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
                ),
              ),
            ),

            // Voucher list
            Expanded(
              child: ListView.builder(
                itemCount: _vouchers.length,
                itemBuilder: (context, index) {
                  final voucher = _vouchers[index];
                  final isSelected = voucher.code == selectedVoucherCode;

                  return VoucherItem(
                    voucher: voucher,
                    isSelected: isSelected,
                    onTap: voucher.isDisabled
                        ? null
                        : () {
                      setState(() {
                        selectedVoucherCode = isSelected ? null : voucher.code;
                      });
                    },
                  );
                },
              ),
            ),

            // Bottom action area
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    offset: const Offset(0, -1),
                    blurRadius: 3,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Selection count text
                  const Text(
                    '1 promo dipilih',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Apply button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(selectedVoucherCode);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Gunakan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Voucher {
  final String code;
  final String description;
  final String additionalInfo;
  final String? additionalRequirement;
  final String iconAsset;
  final bool isDisabled;

  Voucher({
    required this.code,
    required this.description,
    required this.additionalInfo,
    this.additionalRequirement,
    required this.iconAsset,
    this.isDisabled = false,
  });
}

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
                  // Voucher icon
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.asset(
                      voucher.iconAsset,
                      width: 32,
                      height: 32,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.card_giftcard,
                          size: 32,
                          color: voucher.isDisabled ? Colors.grey : AppTheme.primaryColor,
                        );
                      },
                    ),
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
                            color: voucher.isDisabled ? Colors.grey : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          voucher.additionalInfo,
                          style: TextStyle(
                            fontSize: 12,
                            color: voucher.isDisabled ? Colors.grey : Colors.black87,
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

                  // Selection radio
                  if (!voucher.isDisabled)
                    Radio<bool>(
                      value: true,
                      groupValue: isSelected ? true : null,
                      onChanged: onTap != null
                          ? (value) {
                        onTap!();
                      }
                          : null,
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