import 'dart:convert';
import 'package:baraja_app/widgets/utils/classic_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/voucher_item.dart';
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
  List<Voucher> _vouchers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    selectedVoucherCode = widget.appliedVoucherCode;
    fetchVouchers();
  }

  Future<void> fetchVouchers() async {
    try {
      final response =
      await http.get(Uri.parse("https://f3620ee67c10.ngrok-free.app/api/vouchers/available"));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> vouchersJson = data['vouchers'];

        setState(() {
          _vouchers = vouchersJson.map((e) => Voucher.fromJson(e)).toList();
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
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
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
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
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16.0),
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
                        selectedVoucherCode =
                        isSelected ? null : voucher.code;
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
                  Text(
                    selectedVoucherCode != null
                        ? '1 promo dipilih'
                        : 'Tidak ada promo dipilih',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(selectedVoucherCode);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding:
                        const EdgeInsets.symmetric(vertical: 14),
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
    this.iconAsset = 'assets/images/voucher_icon.png',
    this.isDisabled = false,
  });

  factory Voucher.fromJson(Map<String, dynamic> json) {
    return Voucher(
      code: json['code'] ?? '',
      description: json['name'] ?? '',
      additionalInfo: json['description'] ?? '',
      additionalRequirement:
      "Berlaku dari ${json['validFrom']} sampai ${json['validTo']}",
      iconAsset: 'assets/images/voucher_icon.png',
      isDisabled: !(json['isActive'] ?? false),
    );
  }
}
