import 'package:baraja_app/widgets/utils/classic_app_bar.dart';
import 'package:flutter/material.dart';
import '../models/voucher_item.dart';
import '../theme/app_theme.dart';
import '../services/voucher_service.dart';
import 'package:collection/collection.dart';

import '../utils/base_screen_wrapper.dart';

class VoucherScreen extends StatefulWidget {
  final String? appliedVoucherCode;
  final bool readonly;

  const VoucherScreen({
    super.key,
    this.appliedVoucherCode,
    this.readonly = false,
  });

  @override
  State<VoucherScreen> createState() => _VoucherScreenState();
}

class _VoucherScreenState extends State<VoucherScreen> {
  String? selectedVoucherCode;
  Voucher? selectedVoucher;
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
      final vouchers = await VoucherService().fetchVouchers();
      setState(() {
        _vouchers = vouchers;
        _isLoading = false;
      });
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
    if (widget.readonly) {
      // 🔹 Mode readonly → custom wrapper
      return BaseScreenWrapper(
        canPop: false,
        customBackRoute: '/profile',
        child: _buildScaffold(), // scaffold dipisahkan ke method supaya DRY
      );
    }

    // 🔹 Mode normal → intercept tombol back Android
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop();
        return false;
      },
      child: _buildScaffold(),
    );
  }

  Widget _buildScaffold() {
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
                    readonly: widget.readonly,
                    onTap: widget.readonly || !voucher.isActive
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
            if (!widget.readonly)
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
                          if (selectedVoucherCode != null) {
                            final voucher =
                            _vouchers.firstWhereOrNull(
                                  (v) => v.code == selectedVoucherCode,
                            );
                            Navigator.of(context).pop(voucher);
                          } else {
                            Navigator.of(context).pop(null);
                          }
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
