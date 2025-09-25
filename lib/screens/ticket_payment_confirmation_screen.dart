import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/ticket_service.dart';
import '../widgets/utils/classic_app_bar.dart';

class TicketPaymentConfirmationScreen extends StatefulWidget {
  final Map<String, dynamic> eventData;
  final Map<String, dynamic> paymentData;

  const TicketPaymentConfirmationScreen({
    super.key,
    required this.eventData,
    required this.paymentData,
  });

  @override
  State<TicketPaymentConfirmationScreen> createState() => _TicketPaymentConfirmationScreenState();
}

class _TicketPaymentConfirmationScreenState extends State<TicketPaymentConfirmationScreen> {
  bool _isProcessing = false;
  final TicketService _ticketService = TicketService();

  // Format currency helper
  String _formatCurrency(int amount) {
    return 'Rp ${NumberFormat('#,###', 'id_ID').format(amount)}';
  }

  Future<void> _processTicketPayment() async {
    setState(() => _isProcessing = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString('userId');

      if (userId == null || userId.isEmpty) {
        throw Exception('Anda harus login terlebih dahulu');
      }

      final eventPrice = widget.eventData['price'] ?? 0;

      // Create payment with Midtrans integration
      final result = await _ticketService.createTicketPayment(
        eventId: widget.eventData['id'],
        userId: userId,
        quantity: 1,
        totalAmount: eventPrice,
        paymentMethod: widget.paymentData['payment_method'],
        bankCode: widget.paymentData['bank_code'],
        paymentMethodName: widget.paymentData['name'],
      );

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Pembayaran tiket berhasil dibuat! Silakan selesaikan pembayaran.',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );

        // Navigate to payment instruction screen with payment details
        // You can create a payment instruction screen similar to your existing payment flow
        context.pushReplacement('/ticketPaymentInstructions', extra: {
          'paymentResult': result,
          'eventData': widget.eventData,
          'paymentData': widget.paymentData,
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    e.toString().replaceAll('Exception: ', ''),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventPrice = widget.eventData['price'] ?? 0;
    final eventName = widget.eventData['name'] ?? 'Event';
    final paymentMethodName = widget.paymentData['name'] ?? 'Payment Method';
    final paymentMethodDisplayName = widget.paymentData['payment_method_name'] ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const ClassicAppBar(title: 'Konfirmasi Pembayaran Tiket'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.confirmation_number,
                        color: Colors.blue.shade600,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Detail Tiket Event',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow('Nama Event', eventName),
                  _buildDetailRow('Jumlah Tiket', '1 tiket'),
                  _buildDetailRow('Harga Tiket', _formatCurrency(eventPrice)),
                  const Divider(color: Colors.blue),
                  _buildDetailRow('Total Pembayaran', _formatCurrency(eventPrice), isTotal: true),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Payment Method Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.payment,
                        color: Colors.grey.shade600,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Metode Pembayaran',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow('Metode', paymentMethodName),
                  if (paymentMethodDisplayName.isNotEmpty)
                    _buildDetailRow('Provider', paymentMethodDisplayName),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Payment Instructions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.orange.shade600,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Informasi Pembayaran',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Setelah konfirmasi, Anda akan mendapat instruksi pembayaran\n• Tiket akan dikirim setelah pembayaran berhasil\n• Simpan bukti pembayaran untuk verifikasi',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.orange.shade700,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Confirm Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _processTicketPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: _isProcessing
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : const Text(
                  'Konfirmasi dan Bayar',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              color: isTotal ? Colors.blue.shade700 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}