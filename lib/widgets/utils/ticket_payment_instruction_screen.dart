import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'classic_app_bar.dart';

class TicketPaymentInstructionsScreen extends StatefulWidget {
  final Map<String, dynamic> paymentResult;
  final Map<String, dynamic> eventData;
  final Map<String, dynamic> paymentData;

  const TicketPaymentInstructionsScreen({
    super.key,
    required this.paymentResult,
    required this.eventData,
    required this.paymentData,
  });

  @override
  State<TicketPaymentInstructionsScreen> createState() => _TicketPaymentInstructionsScreenState();
}

class _TicketPaymentInstructionsScreenState extends State<TicketPaymentInstructionsScreen> {
  bool _isCheckingStatus = false;

  String _formatCurrency(int amount) {
    return 'Rp ${NumberFormat('#,###', 'id_ID').format(amount)}';
  }

  String _formatDateTime(String? dateTime) {
    if (dateTime == null) return '-';
    try {
      final dt = DateTime.parse(dateTime);
      return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(dt);
    } catch (e) {
      return dateTime;
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label berhasil disalin'),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _checkPaymentStatus() async {
    setState(() => _isCheckingStatus = true);

    // Simulate checking payment status
    await Future.delayed(const Duration(seconds: 2));

    setState(() => _isCheckingStatus = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Status pembayaran: Menunggu pembayaran'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _goToTickets() {
    // Navigate to user tickets screen
    context.go('/tickets');
  }

  Widget _buildVirtualAccountInstructions() {
    final vaNumbers = widget.paymentResult['va_numbers'] as List?;
    final permataVa = widget
        .paymentResult['data']['permata_va_number'] as String?;

    if (vaNumbers != null && vaNumbers.isNotEmpty) {
      final vaData = vaNumbers[0];
      final bank = vaData['bank'].toString().toUpperCase();
      final vaNumber = vaData['va_number'].toString();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInstructionCard(
            title: 'Nomor Virtual Account',
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      bank,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    IconButton(
                      onPressed: () => _copyToClipboard(vaNumber, 'Nomor VA'),
                      icon: const Icon(Icons.copy, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    vaNumber,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildInstructionCard(
            title: 'Cara Pembayaran',
            content: Text(
              '1. Buka aplikasi mobile banking atau internet banking $bank\n'
                  '2. Pilih menu Transfer atau Pembayaran\n'
                  '3. Pilih Virtual Account atau VA\n'
                  '4. Masukkan nomor VA di atas\n'
                  '5. Masukkan jumlah pembayaran\n'
                  '6. Ikuti instruksi selanjutnya\n'
                  '7. Simpan bukti pembayaran',
              style: const TextStyle(height: 1.5),
            ),
          ),
        ],
      );
    }

    if (permataVa != null) {
      return _buildInstructionCard(
        title: 'Nomor Virtual Account Permata',
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'PERMATA',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                IconButton(
                  onPressed: () => _copyToClipboard(permataVa, 'Nomor VA'),
                  icon: const Icon(Icons.copy, size: 20),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                permataVa,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildQRInstructions() {
    final qrString = widget.paymentResult['data']['qr_string'] as String?;

    if (qrString == null) return const SizedBox.shrink();

    return Column(
      children: [
        _buildInstructionCard(
          title: 'QR Code',
          content: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: const Text(
                  '[QR Code akan ditampilkan di sini]',
                  style: TextStyle(
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Scan QR Code di atas menggunakan aplikasi e-wallet Anda',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildConvenienceStoreInstructions() {
    final billKey = widget.paymentResult['data']['bill_key'] as String?;
    final billerCode = widget.paymentResult['data']['biller_code'] as String?;

    if (billKey == null || billerCode == null) return const SizedBox.shrink();

    return Column(
      children: [
        _buildInstructionCard(
          title: 'Kode Pembayaran',
          content: Column(
            children: [
              _buildCopyableField('Biller Code', billerCode),
              const SizedBox(height: 8),
              _buildCopyableField('Bill Key', billKey),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildInstructionCard(
          title: 'Cara Pembayaran di Indomaret/Alfamart',
          content: const Text(
            '1. Datang ke kasir Indomaret/Alfamart terdekat\n'
                '2. Berikan Biller Code dan Bill Key kepada kasir\n'
                '3. Kasir akan memproses pembayaran\n'
                '4. Bayar sesuai jumlah yang tertera\n'
                '5. Simpan struk pembayaran sebagai bukti',
            style: TextStyle(height: 1.5),
          ),
        ),
      ],
    );
  }

  Widget _buildCopyableField(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => _copyToClipboard(value, label),
          icon: const Icon(Icons.copy, size: 18),
        ),
      ],
    );
  }

  Widget _buildInstructionCard({
    required String title,
    required Widget content,
    Color? backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          content,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final paymentData = widget.paymentResult;
    final paymentMethod = paymentData['payment_type'] ?? '';
    final orderId = paymentData['order_id'] ?? '';
    final amount = int.tryParse(paymentData['gross_amount']?.toString() ?? '0') ?? 0;
    final expiryTime = paymentData['expiry_time'];

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: const ClassicAppBar(title: 'Instruksi Pembayaran'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Payment Summary
            _buildInstructionCard(
              title: 'Ringkasan Pembayaran',
              backgroundColor: Colors.blue.shade50,
              content: Column(
                children: [
                  _buildDetailRow('Event', widget.eventData['name'] ?? ''),
                  _buildDetailRow('Jumlah Tiket', '1 tiket'),
                  _buildDetailRow('Total Pembayaran', _formatCurrency(amount)),
                  _buildDetailRow('Metode Pembayaran',
                      widget.paymentData['name'] ?? paymentMethod),
                  _buildDetailRow('Order ID', orderId),
                  if (expiryTime != null)
                    _buildDetailRow('Batas Waktu', _formatDateTime(expiryTime)),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Payment Instructions based on method
            if (paymentMethod ==
                'bank_transfer') _buildVirtualAccountInstructions(),
            if (paymentMethod == 'qris' ||
                paymentMethod == 'gopay') _buildQRInstructions(),
            if (paymentMethod == 'cstore') _buildConvenienceStoreInstructions(),

            const SizedBox(height: 20),

            // Important Notes
            _buildInstructionCard(
              title: 'Catatan Penting',
              backgroundColor: Colors.orange.shade50,
              content: const Text(
                '• Pembayaran harus dilakukan sebelum batas waktu berakhir\n'
                    '• Tiket akan dikirim ke email Anda setelah pembayaran berhasil\n'
                    '• Simpan bukti pembayaran untuk keperluan verifikasi\n'
                    '• Hubungi customer service jika mengalami kendala',
                style: TextStyle(height: 1.5),
              ),
            ),

            const SizedBox(height: 32),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isCheckingStatus ? null : _checkPaymentStatus,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: Colors.blue.shade600),
                    ),
                    child: _isCheckingStatus
                        ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : const Text('Cek Status'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _goToTickets,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Tiket Saya'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}