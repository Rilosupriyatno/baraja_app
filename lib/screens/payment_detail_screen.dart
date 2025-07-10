import 'package:baraja_app/services/confirm_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart'; // Add this import
import '../widgets/utils/classic_app_bar.dart';
import 'package:intl/intl.dart';

class PaymentDetailsScreen extends StatefulWidget {
  final String id;

  const PaymentDetailsScreen({
    super.key,
    required this.id,
  });

  @override
  State<PaymentDetailsScreen> createState() => _PaymentDetailsScreenState();
}

class _PaymentDetailsScreenState extends State<PaymentDetailsScreen> {
  Map<String, dynamic>? paymentData;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPaymentDetails();
  }

  Future<void> _loadPaymentDetails() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Ganti dengan service API Anda
      final result = await ConfirmService().getPayment(widget.id);

      setState(() {
        if (result.success && result.data != null) {
          paymentData = result.data;
          isLoading = false;
        } else {
          isLoading = false;
          errorMessage = result.message;
        }
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Gagal memuat detail pembayaran: $e';
      });
    }
  }

  String _formatCurrency(dynamic amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    if (amount is String) {
      final numAmount = double.tryParse(amount) ?? 0;
      return formatter.format(numAmount);
    } else if (amount is num) {
      return formatter.format(amount);
    }
    return formatter.format(0);
  }

  String _formatDateTime(String? dateTimeStr) {
    if (dateTimeStr == null) return '-';

    try {
      DateTime dateTime;
      if (dateTimeStr.contains('T')) {
        dateTime = DateTime.parse(dateTimeStr);
      } else {
        dateTime = DateFormat('yyyy-MM-dd HH:mm:ss').parse(dateTimeStr);
      }
      return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(dateTime);
    } catch (e) {
      return dateTimeStr;
    }
  }

  String _getBankName(String? method) {
    switch (method?.toLowerCase()) {
      case 'bca':
        return 'BCA';
      case 'bni':
        return 'BNI';
      case 'bri':
        return 'BRI';
      case 'mandiri':
        return 'Mandiri';
      case 'permata':
        return 'Permata';
      case 'cimb':
        return 'CIMB Niaga';
      default:
        return method?.toUpperCase() ?? 'Virtual Account';
    }
  }

  String _getPaymentMethodName(String? method) {
    switch (method?.toLowerCase()) {
      case 'bank_transfer':
        return 'Transfer Bank';
      case 'gopay':
        return 'GoPay';
      case 'shopeepay':
        return 'ShopeePay';
      case 'dana':
        return 'DANA';
      case 'ovo':
        return 'OVO';
      case 'qris':
        return 'QRIS';
      case 'cash':
        return 'Cash';
      case 'bca_va':
      case 'bni_va':
      case 'bri_va':
      case 'mandiri_va':
      case 'permata_va':
      case 'cimb_va':
        return 'Virtual Account';
      default:
        return method ?? 'Tidak diketahui';
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'settlement':
      case 'capture':
        return const Color(0xFF00C896);
      case 'pending':
        return const Color(0xFFFF8A00);
      case 'expire':
      case 'cancel':
      case 'deny':
        return const Color(0xFFFF4757);
      default:
        return const Color(0xFF8E8E93);
    }
  }

  String _getStatusText(String? status) {
    switch (status?.toLowerCase()) {
      case 'settlement':
      case 'capture':
        return 'Pembayaran Berhasil';
      case 'pending':
        return 'Menunggu Pembayaran';
      case 'expire':
        return 'Kedaluwarsa';
      case 'cancel':
        return 'Dibatalkan';
      case 'deny':
        return 'Ditolak';
      default:
        return 'Status Tidak Diketahui';
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text('$label berhasil disalin'),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF00C896),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF007AFF)),
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Memuat detail pembayaran...',
            style: TextStyle(
              fontSize: 15,
              color: Color(0xFF8E8E93),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFFF4757).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: Color(0xFFFF4757),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Gagal Memuat Data',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1C1C1E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage ?? 'Terjadi kesalahan yang tidak diketahui',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF8E8E93),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadPaymentDetails,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF007AFF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Coba Lagi',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(String? status) {
    final statusColor = _getStatusColor(status);
    final statusText = _getStatusText(status);
    final isSuccess = status?.toLowerCase() == 'settlement' || status?.toLowerCase() == 'capture';
    final isPending = status?.toLowerCase() == 'pending';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [statusColor.withOpacity(0.1), statusColor.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSuccess
                    ? Icons.check_circle_rounded
                    : isPending
                    ? Icons.schedule_rounded
                    : Icons.error_rounded,
                color: statusColor,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              statusText,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: statusColor,
              ),
            ),
            if (paymentData?['transaction_time'] != null) ...[
              const SizedBox(height: 6),
              Text(
                _formatDateTime(paymentData!['transaction_time']),
                style: TextStyle(
                  fontSize: 14,
                  color: statusColor.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget child,
    EdgeInsets? padding,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1C1C1E),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentInfoCard() {
    final method = paymentData?['method'];
    final vaNumbers = paymentData?['va_numbers'] as List<dynamic>?;
    final qrString = paymentData?['qr_string'];
    final deeplinkUrl = paymentData?['deeplink_redirect_url'];

    return _buildCard(
      title: 'Informasi Pembayaran',
      icon: Icons.payment_rounded,
      iconColor: const Color(0xFF007AFF),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order ID Section
          const Text(
            'ID Pesanan',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF8E8E93),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: SelectableText(
                  paymentData?['order_id'] ?? '-',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'monospace',
                    color: Color(0xFF1C1C1E),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              InkWell(
                onTap: () => _copyToClipboard(
                  paymentData?['order_id'] ?? '',
                  'ID Pesanan',
                ),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF007AFF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.copy_rounded,
                    size: 16,
                    color: Color(0xFF007AFF),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          Container(
            height: 1,
            color: const Color(0xFFE5E5EA),
          ),
          const SizedBox(height: 20),

          // Payment Method Section
          const Text(
            'Metode Pembayaran',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF8E8E93),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),

          // Virtual Account Section
          if (vaNumbers != null && vaNumbers.isNotEmpty) ...[
            for (int i = 0; i < vaNumbers.length; i++) ...[
              _buildVirtualAccountItem(vaNumbers[i]),
              if (i < vaNumbers.length - 1) const SizedBox(height: 16),
            ],
          ]
          // Cash payment method
          else if (method?.toLowerCase() == 'cash') ...[
            _buildCashPaymentItem(),
          ]
          // E-wallet or QRIS Section
          else if (qrString != null || deeplinkUrl != null) ...[
              _buildEWalletItem(method, qrString, deeplinkUrl),
            ]
            // Other payment methods
            else ...[
                _buildGenericPaymentMethod(method),
              ],
        ],
      ),
    );
  }

  Widget _buildCashPaymentItem() {
    final orderId = paymentData?['order_id'] ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF00C896).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.payments_rounded,
                size: 14,
                color: const Color(0xFF00C896),
              ),
              const SizedBox(width: 6),
              Text(
                'Cash',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF00C896),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // QR Code Section
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFE5E5EA),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              const Text(
                'QR Code untuk Pembayaran Cash',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1C1C1E),
                ),
              ),
              const SizedBox(height: 16),

              // QR Code
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: QrImageView(
                  data: orderId,
                  version: QrVersions.auto,
                  size: 200,
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF1C1C1E),
                  errorStateBuilder: (context, error) {
                    return Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF4757).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Color(0xFFFF4757),
                            size: 32,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Gagal membuat QR Code',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFFFF4757),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Order ID display
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF007AFF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.qr_code_scanner_rounded,
                      size: 16,
                      color: Color(0xFF007AFF),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'ID: $orderId',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF007AFF),
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Copy button
              InkWell(
                onTap: () => _copyToClipboard(orderId, 'ID Pesanan'),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF007AFF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.copy_rounded,
                        size: 16,
                        color: Color(0xFF007AFF),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Salin ID Pesanan',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF007AFF),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Instructions
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF00C896).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: const Color(0xFF00C896),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tunjukkan QR Code ini kepada kasir untuk menyelesaikan pembayaran cash',
                  style: TextStyle(
                    fontSize: 12,
                    color: const Color(0xFF00C896).withOpacity(0.8),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVirtualAccountItem(Map<String, dynamic> va) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF007AFF).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _getBankName(va['bank']),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF007AFF),
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Nomor Virtual Account',
          style: TextStyle(
            fontSize: 13,
            color: Color(0xFF8E8E93),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: SelectableText(
                va['va_number']?.toString() ?? '',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace',
                  color: Color(0xFF1C1C1E),
                  letterSpacing: 1.5,
                ),
              ),
            ),
            const SizedBox(width: 12),
            InkWell(
              onTap: () => _copyToClipboard(
                va['va_number']?.toString() ?? '',
                'Nomor Virtual Account',
              ),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF007AFF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.copy_rounded,
                  color: Color(0xFF007AFF),
                  size: 16,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEWalletItem(String? method, String? qrString, String? deeplinkUrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF00C896).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _getPaymentMethodName(method),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF00C896),
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (qrString != null) ...[
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Scan QR Code untuk melakukan pembayaran',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF8E8E93),
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () => _copyToClipboard(qrString, 'QR Code'),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF007AFF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.qr_code,
                    color: Color(0xFF007AFF),
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ],
        if (deeplinkUrl != null) ...[
          if (qrString != null) const SizedBox(height: 8),
          const Text(
            'Atau buka aplikasi untuk melakukan pembayaran',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF8E8E93),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildGenericPaymentMethod(String? method) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF8E8E93).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _getPaymentMethodName(method),
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF8E8E93),
        ),
      ),
    );
  }

  Widget _buildAmountCard() {
    final total = paymentData?['amount'] ?? 0;
    final discount = paymentData?['discount'] ?? 0;
    final subtotal = total + discount; // Hitung subtotal dari total + discount

    return _buildCard(
      title: 'Rincian Pembayaran',
      icon: Icons.account_balance_wallet_rounded,
      iconColor: const Color(0xFFFF8A00),
      child: Column(
        children: [
          _buildAmountRow('Subtotal', subtotal),

          if (discount > 0) ...[
            const SizedBox(height: 12),
            _buildAmountRow('Diskon', -discount, isDiscount: true),
          ],

          const SizedBox(height: 16),
          Container(
            height: 1,
            color: const Color(0xFFE5E5EA),
          ),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Pembayaran',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1C1C1E),
                ),
              ),
              Text(
                _formatCurrency(total),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF007AFF),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAmountRow(String label, dynamic amount, {bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            color: Color(0xFF8E8E93),
          ),
        ),
        Text(
          _formatCurrency(amount),
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: isDiscount ? const Color(0xFF00C896) : const Color(0xFF1C1C1E),
          ),
        ),
      ],
    );
  }

  Widget _buildExpiryTimeCard() {
    if (paymentData?['expiry_time'] == null ||
        paymentData?['status']?.toLowerCase() != 'pending') {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFF8A00).withOpacity(0.1),
            const Color(0xFFFF8A00).withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFF8A00).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFFF8A00).withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.schedule_rounded,
              color: Color(0xFFFF8A00),
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Batas Waktu Pembayaran',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFBF6700),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDateTime(paymentData!['expiry_time']),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFBF6700),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: const ClassicAppBar(title: 'Detail Pembayaran'),
      body: isLoading
          ? _buildLoadingState()
          : errorMessage != null
          ? _buildErrorState()
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusCard(paymentData?['status']),
            _buildPaymentInfoCard(),
            _buildAmountCard(),
            _buildExpiryTimeCard(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}