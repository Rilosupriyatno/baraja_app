import 'package:baraja_app/widgets/utils/classic_app_bar.dart';
import 'package:flutter/material.dart';
import '../services/voucher_service.dart';
import '../theme/app_theme.dart';

class VoucherScreen extends StatefulWidget {
  final String? appliedVoucherCode;
  final double orderAmount;
  final String? outletId;
  final String? customerType;

  const VoucherScreen({
    super.key,
    this.appliedVoucherCode,
    required this.orderAmount,
    this.outletId,
    this.customerType = 'all',
  });

  @override
  State<VoucherScreen> createState() => _VoucherScreenState();
}

class _VoucherScreenState extends State<VoucherScreen> {
  String? selectedVoucherCode;
  final TextEditingController _voucherController = TextEditingController();

  List<VoucherModel> _voucherModels = [];
  List<Voucher> _vouchers = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    selectedVoucherCode = widget.appliedVoucherCode;
    _loadVouchers();
  }

  Future<void> _loadVouchers() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final vouchers = await VoucherService.getAvailableVouchers(
        outletId: widget.outletId,
        customerType: widget.customerType,
      );

      _voucherModels = vouchers;
      _vouchers = vouchers
          .map((model) => model.toVoucherUI(
        orderAmount: widget.orderAmount,
        minimumSpend: _getMinimumSpend(model), // Implement sesuai kebutuhan
      ))
          .toList();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  double? _getMinimumSpend(VoucherModel voucher) {
    // Implementasi logic minimum spend berdasarkan voucher
    // Ini bisa disesuaikan dengan business logic aplikasi Anda
    if (voucher.discountType == 'percentage') {
      // Contoh: untuk percentage discount, minimum spend adalah 5x discount amount
      return voucher.discountAmount * 500; // 5x dalam rupiah
    } else {
      // Contoh: untuk fixed discount, minimum spend adalah 3x discount amount
      return voucher.discountAmount * 3;
    }
  }

  Future<void> _validateVoucherCode(String code) async {
    if (code.trim().isEmpty) return;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final result = await VoucherService.validateVoucher(
        code: code.trim().toUpperCase(),
        orderAmount: widget.orderAmount,
        outletId: widget.outletId,
        customerType: widget.customerType,
      );

      Navigator.pop(context); // Close loading dialog

      if (result.isValid && result.voucher != null) {
        // Tambahkan voucher yang valid ke list jika belum ada
        final existingIndex = _voucherModels.indexWhere(
              (v) => v.code == result.voucher!.code,
        );

        if (existingIndex == -1) {
          _voucherModels.insert(0, result.voucher!);
          _vouchers.insert(
            0,
            result.voucher!.toVoucherUI(
              orderAmount: widget.orderAmount,
              minimumSpend: _getMinimumSpend(result.voucher!),
            ),
          );
        }

        setState(() {
          selectedVoucherCode = result.voucher!.code;
        });

        _voucherController.clear();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Voucher ${result.voucher!.code} berhasil diterapkan!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
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
        child: Column(
          children: [
            // Voucher input field
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _voucherController,
                      textCapitalization: TextCapitalization.characters,
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
                      onSubmitted: _validateVoucherCode,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _validateVoucherCode(_voucherController.text),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Apply'),
                  ),
                ],
              ),
            ),

            // Content area
            Expanded(
              child: _buildContent(),
            ),

            // Bottom action area
            if (!_isLoading && _errorMessage == null)
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
                    Text(
                      selectedVoucherCode != null ? '1 promo dipilih' : '0 promo dipilih',
                      style: const TextStyle(
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

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load vouchers',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadVouchers,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_vouchers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.card_giftcard,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No vouchers available',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try entering a voucher code manually',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadVouchers,
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
    );
  }
}

// Voucher dan VoucherItem classes tetap sama seperti sebelumnya
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
              border: Border.all(
                color: isSelected ? Colors.green : Colors.grey.shade200,
                width: isSelected ? 2 : 1,
              ),
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