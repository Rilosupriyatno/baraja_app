import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';
import '../services/ticket_service.dart';

class TicketPaymentDetailScreen extends StatefulWidget {
  final Map<String, dynamic> ticket;

  const TicketPaymentDetailScreen({
    super.key,
    required this.ticket,
  });

  @override
  State<TicketPaymentDetailScreen> createState() => _TicketPaymentDetailScreenState();
}

class _TicketPaymentDetailScreenState extends State<TicketPaymentDetailScreen> {
  final TicketService _ticketService = TicketService();
  late Map<String, dynamic> _currentTicket;
  Timer? _statusTimer;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _currentTicket = widget.ticket;
    _startStatusCheck();
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }

  void _startStatusCheck() {
    final payment = _currentTicket['payment_id'] as Map<String, dynamic>?;
    final status = payment?['status']?.toString().toLowerCase();

    // Only check status for pending payments
    if (status == 'pending') {
      _statusTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        _refreshPaymentStatus();
      });
    }
  }

  Future<void> _refreshPaymentStatus() async {
    if (_isRefreshing) return;

    final payment = _currentTicket['payment_id'] as Map<String, dynamic>?;
    if (payment == null) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      final updatedStatus = await _ticketService.getTicketPaymentStatus(payment['_id']);

      if (mounted) {
        setState(() {
          // Update payment status in current ticket
          _currentTicket['payment_id']['status'] = updatedStatus['status'];
          if (updatedStatus['settlement_time'] != null) {
            _currentTicket['payment_id']['settlement_time'] = updatedStatus['settlement_time'];
          }
        });

        // Stop timer if payment is completed
        final newStatus = updatedStatus['status']?.toString().toLowerCase();
        if (newStatus != 'pending') {
          _statusTimer?.cancel();

          if (newStatus == 'settlement' || newStatus == 'paid') {
            _showPaymentSuccessDialog();
          }
        }
      }
    } catch (e) {
      debugPrint('Error refreshing payment status: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  void _showPaymentSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Pembayaran Berhasil!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Tiket Anda telah berhasil dibayar dan siap digunakan.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              setState(() {}); // Refresh the screen to show new status
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4AF37),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 45),
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'settlement':
      case 'capture':
      case 'paid':
        return Colors.green;
      case 'partial':
        return Colors.amber;
      case 'pending':
        return Colors.orange;
      case 'expire':
      case 'unpaid':
      case 'expired':
        return Colors.red;
      case 'cancel':
      case 'cancelled':
      case 'deny':
      case 'failure':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'settlement':
      case 'capture':
      case 'paid':
        return 'Lunas';
      case 'partial':
        return 'Menunggu Pelunasan';
      case 'pending':
        return 'Menunggu Pembayaran';
      case 'expire':
      case 'unpaid':
      case 'expired':
        return 'Kadaluarsa';
      case 'cancel':
      case 'cancelled':
        return 'Dibatalkan';
      case 'deny':
        return 'Ditolak';
      case 'failure':
        return 'Gagal';
      default:
        return status;
    }
  }

  String _formatCurrency(int amount) {
    return 'Rp ${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  String _formatDateTime(String dateString) {
    try {
      final DateTime date = DateTime.parse(dateString);
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }

  Duration? _getTimeRemaining(String? expiryTime) {
    if (expiryTime == null) return null;

    try {
      final expiry = DateTime.parse(expiryTime);
      final now = DateTime.now();
      final difference = expiry.difference(now);

      return difference.isNegative ? null : difference;
    } catch (e) {
      return null;
    }
  }

  Widget _buildCountdownTimer(String? expiryTime) {
    final timeRemaining = _getTimeRemaining(expiryTime);

    if (timeRemaining == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.access_time, color: Colors.red.shade600, size: 20),
            const SizedBox(width: 8),
            Text(
              'Waktu pembayaran telah habis',
              style: TextStyle(
                color: Colors.red.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return StreamBuilder<int>(
      stream: Stream.periodic(const Duration(seconds: 1), (i) => i),
      builder: (context, snapshot) {
        final currentTimeRemaining = _getTimeRemaining(expiryTime);

        if (currentTimeRemaining == null || currentTimeRemaining.isNegative) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.access_time_filled, color: Colors.red.shade600, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Waktu pembayaran telah habis',
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        final hours = currentTimeRemaining.inHours;
        final minutes = currentTimeRemaining.inMinutes % 60;
        final seconds = currentTimeRemaining.inSeconds % 60;

        MaterialColor timerColor = Colors.green;
        if (currentTimeRemaining.inMinutes < 5) {
          timerColor = Colors.red;
        } else if (currentTimeRemaining.inMinutes < 15) {
          timerColor = Colors.orange;
        }

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: timerColor.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: timerColor.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.timer, color: timerColor.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                'Sisa waktu: ${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                style: TextStyle(
                  color: timerColor.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _copyToClipboard(String text, String label) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$label berhasil disalin'),
          backgroundColor: const Color(0xFFD4AF37),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildQRPaymentSection(Map<String, dynamic> payment) {
    final actions = payment['actions'] as List<dynamic>?;
    String? qrUrl;

    if (actions != null) {
      for (var action in actions) {
        if (action['name'] == 'generate-qr-code') {
          qrUrl = action['url'];
          break;
        }
      }
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Scan QR Code untuk Pembayaran',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            if (qrUrl != null) ...[
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade300,
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: CachedNetworkImage(
                    imageUrl: qrUrl,
                    width: 250,
                    height: 250,
                    fit: BoxFit.contain,
                    placeholder: (context, url) => const SizedBox(
                      width: 250,
                      height: 250,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD4AF37)),
                            ),
                            SizedBox(height: 16),
                            Text('Memuat QR Code...'),
                          ],
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.qr_code, size: 64, color: Colors.grey),
                          SizedBox(height: 12),
                          Text(
                            'QR Code tidak tersedia',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cara Pembayaran:',
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '1. Buka aplikasi e-wallet atau mobile banking\n2. Pilih bayar dengan QRIS\n3. Scan kode QR di atas\n4. Konfirmasi pembayaran',
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.qr_code_scanner, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'QR Code sedang dimuat...',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVirtualAccountSection(Map<String, dynamic> payment) {
    final vaNumbers = payment['va_numbers'] as List<dynamic>?;
    final permataVa = payment['permata_va_number'];
    final billKey = payment['bill_key'];
    final billerCode = payment['biller_code'];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informasi Virtual Account',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            if (vaNumbers != null && vaNumbers.isNotEmpty) ...[
              for (var va in vaNumbers) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey.shade50,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            va['bank']?.toString().toUpperCase() ?? 'Bank',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          IconButton(
                            onPressed: () => _copyToClipboard(
                              va['va_number']?.toString() ?? '',
                              'Nomor Virtual Account',
                            ),
                            icon: const Icon(Icons.copy, size: 24),
                            tooltip: 'Salin nomor',
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Nomor Virtual Account:',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        va['va_number']?.toString() ?? '',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],

            if (permataVa != null) ...[
              Container(
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey.shade50,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'PERMATA BANK',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        IconButton(
                          onPressed: () => _copyToClipboard(
                            permataVa.toString(),
                            'Nomor Virtual Account',
                          ),
                          icon: const Icon(Icons.copy, size: 24),
                          tooltip: 'Salin nomor',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Nomor Virtual Account:',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      permataVa.toString(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (billKey != null && billerCode != null) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey.shade50,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'MANDIRI BILL PAYMENT',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Biller Code:',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              billerCode.toString(),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () => _copyToClipboard(
                            billerCode.toString(),
                            'Biller Code',
                          ),
                          icon: const Icon(Icons.copy, size: 24),
                          tooltip: 'Salin kode',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bill Key:',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              billKey.toString(),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () => _copyToClipboard(
                            billKey.toString(),
                            'Bill Key',
                          ),
                          icon: const Icon(Icons.copy, size: 24),
                          tooltip: 'Salin kode',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Transfer sesuai nominal yang tercantum. Pembayaran otomatis terverifikasi setelah transfer berhasil.',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 14,
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

  Widget _buildTicketDisplay() {
    final event = _currentTicket['event'] as Map<String, dynamic>?;

    if (event == null) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'E-Tiket Anda',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // QR Code placeholder or ticket code
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300, width: 2),
                borderRadius: BorderRadius.circular(16),
                color: Colors.white,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.qr_code,
                    size: 100,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Kode Tiket',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _currentTicket['_id']?.substring(0, 8).toUpperCase() ?? 'XXXXXXXX',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green.shade600, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Tiket ini telah lunas dan siap digunakan. Tunjukkan kode tiket pada saat masuk event.',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontSize: 14,
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

  Widget _buildPaymentInstructions(Map<String, dynamic> payment) {
    final method = payment['method']?.toString().toLowerCase();

    if (method == 'qris') {
      return _buildQRPaymentSection(payment);
    } else if (method == 'bank_transfer' ||
        payment['va_numbers'] != null ||
        payment['permata_va_number'] != null ||
        payment['bill_key'] != null) {
      return _buildVirtualAccountSection(payment);
    }

    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final event = _currentTicket['event'] as Map<String, dynamic>?;
    final payment = _currentTicket['payment_id'] as Map<String, dynamic>?;

    if (event == null || payment == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Detail Pembayaran'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
        ),
        body: const Center(
          child: Text('Data pembayaran tidak lengkap'),
        ),
      );
    }

    final status = payment['status']?.toString().toLowerCase() ?? '';
    final statusColor = _getStatusColor(status);
    final statusText = _getStatusText(status);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text(
          'Detail Pembayaran',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.grey.shade200,
                  Colors.grey.shade100,
                  Colors.grey.shade200,
                ],
              ),
            ),
          ),
        ),
        actions: [
          if (status == 'pending')
            IconButton(
              onPressed: _isRefreshing ? null : _refreshPaymentStatus,
              icon: _isRefreshing
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Icon(Icons.refresh),
              tooltip: 'Refresh status',
            ),
        ],
      ),
      body: RefreshIndicator(
        color: const Color(0xFFD4AF37),
        onRefresh: _refreshPaymentStatus,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          statusText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _formatCurrency(payment['totalAmount'] ?? 0),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFD4AF37),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Total Pembayaran',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Timer for pending payments
              if (status == 'pending' && payment['expiry_time'] != null) ...[
                _buildCountdownTimer(payment['expiry_time']),
                const SizedBox(height: 20),
              ],

              // Event Information
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Informasi Event',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      if (event['imageUrl'] != null && event['imageUrl'].toString().isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: event['imageUrl'],
                            height: 120,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorWidget: (context, url, error) => Container(
                              height: 120,
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.image_not_supported),
                            ),
                          ),
                        ),

                      if (event['imageUrl'] != null && event['imageUrl'].toString().isNotEmpty)
                        const SizedBox(height: 16),

                      Text(
                        event['name'] ?? 'Nama Event Tidak Tersedia',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _formatDateTime(event['date'] ?? ''),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              event['location'] ?? 'Lokasi Tidak Tersedia',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Jumlah Tiket',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                              ),
                            ),
                            Text(
                              '${_currentTicket['quantity'] ?? 1} tiket',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Payment Instructions (only for pending) or Ticket Display (for paid)
              if (status == 'pending') ...[
                _buildPaymentInstructions(payment),
                const SizedBox(height: 20),
              ] else if (status == 'settlement' || status == 'paid') ...[
                _buildTicketDisplay(),
                const SizedBox(height: 20),
              ],

              // Payment Information
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Informasi Pembayaran',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      _buildDetailRow('ID Pesanan', payment['order_id'] ?? '-'),
                      _buildDetailRow('ID Transaksi', payment['transaction_id'] ?? '-'),
                      _buildDetailRow('Metode Pembayaran', (payment['method'] ?? '-').toString().toUpperCase()),
                      _buildDetailRow('Status', statusText),
                      _buildDetailRow('Jumlah', _formatCurrency(payment['totalAmount'] ?? 0)),
                      _buildDetailRow('Waktu Transaksi', payment['transaction_time'] ?? '-'),

                      if (payment['settlement_time'] != null)
                        _buildDetailRow('Waktu Penyelesaian', payment['settlement_time']),

                      if (payment['expiry_time'] != null && status == 'pending')
                        _buildDetailRow('Berlaku Hingga', payment['expiry_time']),

                      if (payment['payment_code'] != null) ...[
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Kode Pembayaran',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  payment['payment_code'].toString(),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                            IconButton(
                              onPressed: () => _copyToClipboard(
                                payment['payment_code'].toString(),
                                'Kode pembayaran',
                              ),
                              icon: const Icon(Icons.copy),
                              tooltip: 'Salin kode',
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Action Buttons
              if (status == 'pending') ...[
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _isRefreshing ? null : _refreshPaymentStatus,
                    icon: _isRefreshing
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                        : const Icon(Icons.refresh),
                    label: Text(_isRefreshing ? 'Memeriksa Status...' : 'Periksa Status Pembayaran'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4AF37),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          title: const Text('Bantuan Pembayaran'),
                          content: const Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Jika mengalami kesulitan dalam pembayaran:'),
                              SizedBox(height: 8),
                              Text('• Pastikan koneksi internet stabil'),
                              Text('• Periksa saldo e-wallet atau rekening'),
                              Text('• Ikuti petunjuk pembayaran dengan benar'),
                              Text('• Hubungi customer service jika masalah berlanjut'),
                              SizedBox(height: 16),
                              Text(
                                'Status pembayaran akan otomatis terupdate setelah transaksi berhasil.',
                                style: TextStyle(fontStyle: FontStyle.italic),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Tutup'),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.help_outline),
                    label: const Text('Bantuan Pembayaran'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFD4AF37),
                      side: const BorderSide(color: Color(0xFFD4AF37)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ] else if (status == 'settlement' || status == 'paid') ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.green.shade600,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pembayaran Berhasil!',
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tiket Anda sudah aktif dan siap digunakan.',
                              style: TextStyle(
                                color: Colors.green.shade600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (status == 'expire' || status == 'expired') ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        color: Colors.red.shade600,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pembayaran Kadaluarsa',
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Waktu pembayaran telah habis. Silakan lakukan pemesanan ulang.',
                              style: TextStyle(
                                color: Colors.red.shade600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop(); // Return to ticket history
                    },
                    icon: const Icon(Icons.shopping_cart),
                    label: const Text('Pesan Ulang'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4AF37),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ] else if (status == 'cancel' || status == 'cancelled') ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.cancel,
                        color: Colors.orange.shade600,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pembayaran Dibatalkan',
                              style: TextStyle(
                                color: Colors.orange.shade700,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Transaksi pembayaran telah dibatalkan.',
                              style: TextStyle(
                                color: Colors.orange.shade600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (status == 'failure') ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error,
                        color: Colors.red.shade600,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pembayaran Gagal',
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Terjadi kesalahan dalam proses pembayaran. Silakan coba lagi.',
                              style: TextStyle(
                                color: Colors.red.shade600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop(); // Return to ticket history
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Coba Lagi'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4AF37),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Text(': '),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}