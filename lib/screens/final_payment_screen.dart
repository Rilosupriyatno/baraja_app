import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/confirm_service.dart';
import '../widgets/utils/classic_app_bar.dart';
import 'payment_detail_screen.dart';

class FinalPaymentScreen extends StatefulWidget {
  final String orderId;
  final num remainingAmount;
  final String orderNumber;

  const FinalPaymentScreen({
    super.key,
    required this.orderId,
    required this.remainingAmount,
    required this.orderNumber,
  });

  @override
  State<FinalPaymentScreen> createState() => _FinalPaymentScreenState();
}

class _FinalPaymentScreenState extends State<FinalPaymentScreen> {
  String selectedPaymentMethod = 'cash'; // Default dan satu-satunya pilihan
  bool isProcessing = false;

  // SEMENTARA HANYA CASH YANG TERSEDIA
  final List<Map<String, dynamic>> paymentMethods = [
    {
      'id': 'cash',
      'name': 'Tunai',
      'icon': Icons.money,
      'color': Colors.green,
      'description': 'Bayar tunai di kasir'
    },
    // Method lain di-comment sementara
    /*
    {
      'id': 'qris',
      'name': 'QRIS',
      'icon': Icons.qr_code,
      'color': Colors.blue,
      'description': 'Scan QR untuk pembayaran (Tidak tersedia)'
    },
    {
      'id': 'gopay',
      'name': 'GoPay',
      'icon': Icons.account_balance_wallet,
      'color': Colors.green,
      'description': 'Pembayaran dengan GoPay (Tidak tersedia)'
    },
    {
      'id': 'bank_transfer',
      'name': 'Transfer Bank',
      'icon': Icons.account_balance,
      'color': Colors.indigo,
      'description': 'Transfer via Virtual Account (Tidak tersedia)'
    }
    */
  ];

  String formatCurrency(num amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  Future<void> _processFinalPayment() async {
    // Selalu cash untuk sementara
    setState(() {
      isProcessing = true;
    });

    try {
      final confirmService = ConfirmService();
      final result = await confirmService.createFinalPayment(
        orderId: widget.orderId,
        paymentMethod: 'cash', // Selalu cash
      );

      if (result.success) {
        // Navigate to payment details screen
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  PaymentDetailsScreen(
                    id: widget.orderId,
                  ),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isProcessing = false;
        });
      }
    }
  }

  Widget _buildPaymentMethodCard(Map<String, dynamic> method) {
    final isSelected = selectedPaymentMethod == method['id'];
    final isAvailable = method['id'] == 'cash';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isAvailable ? Colors.white : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected && isAvailable ? method['color'] : Colors.grey.shade300,
          width: isSelected && isAvailable ? 2 : 1,
        ),
        boxShadow: [
          if (isSelected && isAvailable)
            BoxShadow(
              color: method['color'].withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: (isAvailable ? method['color'] : Colors.grey).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              method['icon'],
              color: isAvailable ? method['color'] : Colors.grey,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  method['name'],
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isAvailable
                        ? (isSelected ? method['color'] : Colors.black87)
                        : Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  method['description'],
                  style: TextStyle(
                    fontSize: 14,
                    color: isAvailable ? Colors.grey.shade600 : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          if (isSelected && isAvailable)
            Icon(
              Icons.check_circle,
              color: method['color'],
              size: 24,
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: const ClassicAppBar(title: 'Pelunasan Pembayaran'),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order Summary Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.receipt_long,
                                color: Colors.orange,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Detail Pelunasan',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Nomor Pesanan',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            Text(
                              widget.orderNumber,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          height: 1,
                          color: Colors.grey.shade200,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Sisa Pembayaran',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            Text(
                              formatCurrency(widget.remainingAmount),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.deepOrange,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Payment Methods Section
                  Text(
                    'Metode Pembayaran',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Info banner untuk sementara cash only
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.blue.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Sementara hanya tersedia pembayaran tunai untuk pelunasan',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Payment Method Cards
                  ...paymentMethods.map((method) => _buildPaymentMethodCard(method)),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Bottom Action Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isProcessing ? null : _processFinalPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green, // Ubah ke hijau karena cash
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isProcessing
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : Text(
                  'Bayar Tunai - ${formatCurrency(widget.remainingAmount)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}