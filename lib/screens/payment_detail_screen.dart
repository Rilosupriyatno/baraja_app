import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/order_service.dart';
import '../services/socket_service.dart'; // ✅ tambahkan import

class PaymentDetailScreen extends StatefulWidget {
  final String id;

  const PaymentDetailScreen({
    super.key,
    required this.id,
  });

  @override
  State<PaymentDetailScreen> createState() => _PaymentDetailScreenState();
}

class _PaymentDetailScreenState extends State<PaymentDetailScreen> {
  final OrderService _orderService = OrderService();
  final SocketService _socketService = SocketService(); // ✅ socket instance

  Map<String, dynamic>? paymentData;
  bool isLoading = true;
  String? errorMessage;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _loadPaymentStatus();
    _setupSocket(); // ✅ pasang socket
  }

  void _setupSocket() {
    if (_isListening) return;
    _isListening = true;

    _socketService.connectToSocket(
      id: widget.id,
      onPaymentUpdate: _handlePaymentUpdate,
      onOrderUpdate: (data) {
        debugPrint("Order update di PaymentDetailScreen: $data");
      },
    );

    Future.delayed(
      const Duration(seconds: 2),
          () => _socketService.joinOrderRoom(widget.id),
    );
  }

  void _handlePaymentUpdate(Map<String, dynamic> data) {
    final orderId = paymentData?['order_id']?.toString() ?? widget.id;

    if (data['order_id'].toString() != orderId) return;

    debugPrint("🔔 Payment update diterima: $data");

    if (mounted) {
      setState(() {
        paymentData?['status'] = data['transaction_status'];
      });
    }
  }

  Future<void> _loadPaymentStatus() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await _orderService.getPaymentStatus(widget.id);

      if (result['success'] == true) {
        final outerData = result['data'];
        if (outerData != null && outerData['data'] != null) {
          setState(() {
            paymentData = outerData['data'];
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage = 'Payment data structure is invalid';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = result['error'] ?? 'Failed to load payment data';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
        isLoading = false;
      });
    }
  }

  bool _isPaid() {
    final status = paymentData?['status']?.toLowerCase() ?? '';
    return status == 'settlement' || status == 'paid' || status == 'capture';
  }

  String _formatCurrency(int amount) {
    return 'Rp${amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
    )}';
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Belum Lunas';
      case 'settlement':
      case 'paid':
      case 'capture':
        return 'Sudah Dibayar';
      case 'expire':
      case 'Unpaid':
        return 'Kadaluarsa';
      case 'cancel':
        return 'Dibatalkan';
      case 'partial':
        return 'Belum Lunas';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
      case 'partial':
        return const Color(0xFFF59E0B);
      case 'settlement':
      case 'paid':
      case 'capture':
        return const Color(0xFF077A4B);
      case 'expire':
      case 'cancel':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF6B7280);
    }
  }

  Color _getExpiryTimeColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
      case 'partial':
        return Colors.deepOrange;
      case 'settlement':
      case 'paid':
      case 'capture':
        return const Color(0xFF077A4B);
      default:
        return Colors.deepOrange;
    }
  }

  String _getPaymentMethodText(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return 'Cash';
      case 'bank_transfer':
        return 'Bank Transfer';
      case 'qris':
        return 'QRIS';
      case 'credit_card':
        return 'Credit Card';
      case 'e_wallet':
        return 'E-Wallet';
      default:
        return method;
    }
  }

  Widget _buildPaymentInstructions() {
    final method = paymentData?['method']?.toLowerCase() ?? '';
    String title = '';
    List<String> instructions = [];

    switch (method) {
      case 'qris':
        title = 'Cara Bayar dengan QRIS';
        instructions = [
          '1. Buka aplikasi mobile banking atau e-wallet Anda',
          '2. Pilih menu Scan QR atau QRIS',
          '3. Arahkan kamera ke QR Code di atas',
          '4. Pastikan nominal sudah sesuai',
          '5. Konfirmasi pembayaran',
          '6. Simpan bukti pembayaran'
        ];
        break;
      case 'bank_transfer':
        title = 'Cara Bayar dengan VA';
        instructions = [
          '1. Buka aplikasi mobile banking Anda',
          '2. Pilih menu Transfer > Virtual Account',
          '3. Masukkan nomor Virtual Account di atas',
          '4. Masukkan nominal pembayaran',
          '5. Konfirmasi detail transaksi',
          '6. Selesaikan pembayaran',
          '7. Simpan bukti transfer'
        ];
        break;
      case 'e_wallet':
        title = 'Cara Bayar dengan E-Wallet';
        instructions = [
          '1. Buka aplikasi e-wallet Anda',
          '2. Pilih menu Bayar atau Scan QR',
          '3. Scan QR Code yang tersedia',
          '4. Periksa detail pembayaran',
          '5. Masukkan PIN atau konfirmasi biometrik',
          '6. Pembayaran selesai'
        ];
        break;
      case 'credit_card':
        title = 'Cara Bayar dengan Credit Card';
        instructions = [
          '1. Masukkan nomor kartu kredit',
          '2. Isi tanggal expired dan CVV',
          '3. Masukkan nama pemegang kartu',
          '4. Periksa detail transaksi',
          '5. Klik tombol Bayar',
          '6. Masukkan OTP dari bank',
          '7. Pembayaran berhasil'
        ];
        break;
      case 'cash':
        title = 'Cara Bayar dengan Cash';
        instructions = [
          '1. Datang ke lokasi pembayaran',
          '2. Berikan Order ID kepada kasir',
          '3. Sebutkan nominal pembayaran',
          '4. Bayar dengan uang tunai',
          '5. Terima struk pembayaran',
          '6. Simpan struk sebagai bukti'
        ];
        break;
      default:
        return const SizedBox.shrink();
    }

    if (instructions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF077A4B).withOpacity(0.08),
                const Color(0xFF077A4B).withOpacity(0.03),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF077A4B).withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF077A4B).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.help_outline,
                      color: Color(0xFF077A4B),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF077A4B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...instructions.map((instruction) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  instruction,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF374151),
                    height: 1.5,
                  ),
                ),
              )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQRCode() {
    if (paymentData?['actions'] == null) return const SizedBox.shrink();

    final actions = paymentData!['actions'] as List;
    final qrAction = actions.firstWhere(
          (action) => action['name'] == 'generate-qr-code' || action['name'] == 'generate-qr-code-v2',
      orElse: () => null,
    );

    if (qrAction == null || qrAction['url'] == null) {
      return const SizedBox.shrink();
    }

    final qrImageData = qrAction['url'] as String;

    Widget qrWidget;

    if (qrImageData.startsWith('data:image/')) {
      qrWidget = Image.memory(
        Uri.parse(qrImageData).data!.contentAsBytes(),
        width: 180,
        height: 180,
        fit: BoxFit.contain,
      );
    } else {
      qrWidget = Image.network(
        qrImageData,
        width: 180,
        height: 180,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.grey, size: 32),
                SizedBox(height: 8),
                Text('Gagal memuat QR Code', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          );
        },
      );
    }

    return Column(
      children: [
        const SizedBox(height: 24),
        const Text(
          'Scan QR Code untuk Pembayaran',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF077A4B).withOpacity(0.2)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF077A4B).withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: qrWidget,
          ),
        ),
      ],
    );
  }

  Widget _buildBankTransferInfo() {
    if (paymentData?['method']?.toLowerCase() != 'bank_transfer') {
      return const SizedBox.shrink();
    }

    String? bankName;
    String? vaNumber;

    if (paymentData?['va_numbers'] != null) {
      final vaNumbers = paymentData!['va_numbers'] as List;
      if (vaNumbers.isNotEmpty) {
        final firstVa = vaNumbers.first;
        bankName = firstVa['bank']?.toString().toUpperCase();
        vaNumber = firstVa['va_number']?.toString();
      }
    }

    if ((vaNumber == null || vaNumber.isEmpty) &&
        paymentData?['permata_va_number'] != null) {
      vaNumber = paymentData!['permata_va_number'].toString();
      bankName = 'PERMATA';
    }

    if (bankName == null && vaNumber == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF077A4B).withOpacity(0.1),
                const Color(0xFF077A4B).withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF077A4B).withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.account_balance, color: Color(0xFF077A4B), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Detail Transfer',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF077A4B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (bankName != null) ...[
                _buildInfoRow('Bank', bankName),
                const SizedBox(height: 12),
              ],
              if (vaNumber != null) ...[
                const Text(
                  'Virtual Account',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF077A4B).withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          vaNumber,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937),
                            fontFamily: 'monospace',
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: vaNumber!));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Nomor VA disalin'),
                              backgroundColor: const Color(0xFF077A4B),
                              duration: const Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF077A4B),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.copy,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildThankYouMessage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF077A4B),
            const Color(0xFF077A4B).withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF077A4B).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Terima Kasih!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pembayaran Anda telah berhasil diproses.\nPesanan sedang dalam persiapan.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.9),
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF6B7280),
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F2937),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _socketService.disconnect(); // ✅ jangan lupa disconnect
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Detail Pembayaran',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black,
            fontSize: 18,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF077A4B),
          strokeWidth: 2.5,
        ),
      )
          : errorMessage != null
          ? Center(child: Text(errorMessage!))
          : paymentData == null
          ? const Center(child: Text('Data pembayaran tidak tersedia'))
          : RefreshIndicator(
        onRefresh: _loadPaymentStatus,
        color: const Color(0xFF077A4B),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // === Thank You Message (jika sudah dibayar) atau Expiry Time ===
              _isPaid()
                  ? _buildThankYouMessage()
                  : (paymentData!['expiry_time'] != null
                  ? Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _getExpiryTimeColor(paymentData!['status'] ?? ''),
                      _getExpiryTimeColor(paymentData!['status'] ?? '')
                          .withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: _getExpiryTimeColor(paymentData!['status'] ?? '')
                          .withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.schedule,
                            color: Colors.white.withOpacity(0.9), size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Batas Waktu Pembayaran',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      paymentData!['expiry_time'],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              )
                  : const SizedBox.shrink()),

              const SizedBox(height: 24),

              // === Main Payment Info Card ===
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Amount & Status
                    Center(
                      child: Column(
                        children: [
                          Text(
                            _formatCurrency(paymentData!['totalAmount'] ?? 0),
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF077A4B),
                              letterSpacing: -1,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: _getStatusColor(paymentData!['status'] ?? '')
                                  .withOpacity(0.15),
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(
                                color: _getStatusColor(paymentData!['status'] ?? '')
                                    .withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              _getStatusText(paymentData!['status'] ?? 'N/A'),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _getStatusColor(paymentData!['status'] ?? ''),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Order ID
                    _buildInfoRow('Order ID', paymentData!['order_id'] ?? 'N/A'),

                    const SizedBox(height: 16),

                    // Payment Method
                    _buildInfoRow(
                      'Metode Pembayaran',
                      _getPaymentMethodText(paymentData!['method'] ?? 'N/A'),
                    ),

                    // QR Code
                    _buildQRCode(),

                    // Bank Transfer Info
                    _buildBankTransferInfo(),

                    // Payment Instructions
                    _buildPaymentInstructions(),
                  ],
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}