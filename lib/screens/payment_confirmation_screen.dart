import 'package:baraja_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/cart_item.dart';
import '../models/order.dart';
import '../models/order_type.dart';
import '../providers/order_provider.dart';
import '../services/confirm_service.dart';
import '../utils/currency_formatter.dart';
import '../widgets/utils/classic_app_bar.dart';

class PaymentConfirmationScreen extends StatefulWidget {
  final List<CartItem> items;
  final OrderType orderType;
  final String tableNumber;
  final String deliveryAddress;
  final TimeOfDay? pickupTime;
  final Map<String, String?> paymentDetails;
  final int subtotal;
  final int discount;
  final int total;
  final String? voucherCode;

  const PaymentConfirmationScreen({
    super.key,
    required this.items,
    required this.orderType,
    required this.tableNumber,
    required this.deliveryAddress,
    required this.pickupTime,
    required this.paymentDetails,
    required this.subtotal,
    required this.discount,
    required this.total,
    this.voucherCode,
  });

  @override
  State<PaymentConfirmationScreen> createState() => _PaymentConfirmationScreenState();
}

class _PaymentConfirmationScreenState extends State<PaymentConfirmationScreen> {
  late final Order newOrder;
  bool _hasSentOrder = false;
  bool _isLoading = true;
  Map<String, dynamic>? _paymentResponse;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    // Generate a unique order ID (using timestamp)
    final String orderId = 'ORD${DateTime.now().millisecondsSinceEpoch}';

    // Create new order instance
    newOrder = Order(
      id: orderId,
      items: widget.items.map((item) => CartItem(
        id: item.id,
        name: item.name,
        price: item.price,
        totalprice: item.totalprice,
        quantity: item.quantity,
        addons: item.addons,
        toppings: item.toppings,
        imageUrl: item.imageUrl,
      )).toList(),
      orderType: widget.orderType,
      tableNumber: widget.tableNumber,
      deliveryAddress: widget.deliveryAddress,
      pickupTime: widget.pickupTime,
      paymentDetails: widget.paymentDetails,
      subtotal: widget.subtotal,
      discount: widget.discount,
      total: widget.total,
      voucherCode: widget.voucherCode,
      orderTime: DateTime.now(),
      status: OrderStatus.processing,
    );

    // Kirim order hanya sekali saat init
    _sendOrderOnce();
  }

  Future<void> _sendOrderOnce() async {
    if (!_hasSentOrder) {
      setState(() {
        _isLoading = true;
      });

      _hasSentOrder = true;
      final confirmService = ConfirmService();

      try {
        final response = await confirmService.sendOrder(newOrder);
        if (mounted) {
          setState(() {
            _isLoading = false;
            _paymentResponse = response;
          });

          final orderProvider = Provider.of<OrderProvider>(context, listen: false);
          orderProvider.addOrder(newOrder);
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = e.toString();
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const ClassicAppBar(title: 'Konfirmasi Pembayaran'),
      body: SafeArea(
        child: _isLoading
            ? _buildLoadingView()
            : _errorMessage != null
            ? _buildErrorView()
            : _buildSuccessView(),
      ),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppTheme.primaryColor),
          SizedBox(height: 16),
          Text('Memproses pembayaran Anda...',
              style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 64),
            const SizedBox(height: 16),
            const Text('Gagal memproses pembayaran',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(_errorMessage ?? 'Terjadi kesalahan, silakan coba lagi',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                _hasSentOrder = false;
                _sendOrderOnce();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(200, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Coba Lagi',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessView() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPaymentStatusCard(),
                const SizedBox(height: 24),

                _buildSectionTitle('Informasi Pembayaran'),
                _buildInfoItem('Metode Pembayaran', widget.paymentDetails['bankName'] ?? 'Unknown'),
                const SizedBox(height: 8),
                _buildInfoItem('Total Pembayaran', formatCurrency(widget.total)),

                if (_paymentResponse != null) ...[
                  const SizedBox(height: 8),
                  _buildPaymentInstructions(),
                ],

                const Divider(height: 32),
                _buildSectionTitle('Informasi Pesanan'),
                _buildInfoItem('Tipe Pesanan', _getOrderTypeText()),

                if (widget.orderType == OrderType.dineIn && widget.tableNumber.isNotEmpty)
                  _buildInfoItem('Nomor Meja', widget.tableNumber),
                if (widget.orderType == OrderType.delivery && widget.deliveryAddress.isNotEmpty)
                  _buildInfoItem('Alamat Pengantaran', widget.deliveryAddress),
                if (widget.orderType == OrderType.pickup && widget.pickupTime != null)
                  _buildInfoItem('Waktu Pengambilan',
                      '${widget.pickupTime!.hour}:${widget.pickupTime!.minute.toString().padLeft(2, '0')}'),

                const Divider(height: 32),
                _buildSectionTitle('Detail Pesanan'),
                ...widget.items.map((item) => _buildOrderItem(item)),

                const Divider(height: 32),
                _buildSectionTitle('Rincian Biaya'),
                _buildInfoItem('Subtotal', formatCurrency(widget.subtotal)),
                if (widget.discount > 0) ...[
                  _buildInfoItem('Diskon', '- ${formatCurrency(widget.discount)}'),
                  if (widget.voucherCode != null && widget.voucherCode!.isNotEmpty)
                    _buildInfoItem('Voucher', widget.voucherCode!),
                ],
                const Divider(height: 16),
                _buildInfoItem('Total', formatCurrency(widget.total), isBold: true),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: () {
              // Navigasi ke halaman sukses atau halaman pesanan saya
              // context.go('/orderSuccess?id=${newOrder.id}');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Lihat Pesanan Saya',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentStatusCard() {
    final status = _paymentResponse?['transaction_status'] ?? 'unknown';
    final isSuccess = status == 'settlement';
    final isPending = status == 'pending';

    Color statusColor = Colors.grey;
    IconData statusIcon = Icons.info_outline;
    String statusText = 'Unknown Status';

    if (isSuccess) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
      statusText = 'Pembayaran Berhasil';
    } else if (isPending) {
      statusColor = Colors.orange;
      statusIcon = Icons.pending_outlined;
      statusText = 'Menunggu Pembayaran';
    } else {
      statusColor = Colors.red;
      statusIcon = Icons.error_outline;
      statusText = 'Pembayaran Gagal';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor, width: 1),
      ),
      child: Column(
        children: [
          Icon(statusIcon, color: statusColor, size: 48),
          const SizedBox(height: 8),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
          if (_paymentResponse != null) ...[
            const SizedBox(height: 8),
            Text(
              'Order ID: ${_paymentResponse!['order_id'] ?? newOrder.id}',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            if (_paymentResponse!['transaction_time'] != null)
              Text(
                'Waktu: ${_paymentResponse!['transaction_time']}',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentInstructions() {
    final paymentType = _paymentResponse?['payment_type'] ?? '';

    if (paymentType == 'bank_transfer') {
      String bankName = 'Bank';
      String vaNumber = '';

      // Check which bank is used
      if (_paymentResponse!.containsKey('permata_va_number')) {
        bankName = 'Permata Bank';
        vaNumber = _paymentResponse!['permata_va_number'];
      } else if (_paymentResponse!.containsKey('va_numbers')) {
        final vaNumbers = _paymentResponse!['va_numbers'] as List;
        if (vaNumbers.isNotEmpty) {
          bankName = vaNumbers[0]['bank'] ?? 'Bank';
          vaNumber = vaNumbers[0]['va_number'] ?? '';

          // Convert bank code to proper name
          if (bankName.toLowerCase() == 'bca') {
            bankName = 'Bank BCA';
          } else if (bankName.toLowerCase() == 'bni') {
            bankName = 'Bank BNI';
          } else if (bankName.toLowerCase() == 'bri') {
            bankName = 'Bank BRI';
          }
        }
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoItem('Nomor Virtual Account', vaNumber, isBold: true),
          if (_paymentResponse!.containsKey('expiry_time'))
            _buildInfoItem('Bayar Sebelum', _paymentResponse!['expiry_time']),

          const SizedBox(height: 16),
          const Text('Cara Pembayaran:',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildInstructionStep(1, 'Gunakan mobile banking atau internet banking $bankName Anda'),
          _buildInstructionStep(2, 'Pilih menu Transfer > Virtual Account'),
          _buildInstructionStep(3, 'Masukkan nomor Virtual Account: $vaNumber'),
          _buildInstructionStep(4, 'Konfirmasi detail pembayaran dan selesaikan transaksi'),
          _buildInstructionStep(5, 'Pembayaran Anda akan diproses secara otomatis'),
        ],
      );
    } else if (paymentType == 'gopay') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_paymentResponse!.containsKey('actions')) ...[
            const Text('QR Code:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              alignment: Alignment.center,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                children: [
                  const Icon(Icons.qr_code, size: 120),
                  const SizedBox(height: 8),
                  const Text('Scan QR Code menggunakan aplikasi Gojek',
                      style: TextStyle(fontSize: 14)),
                ],
              ),
            ),
          ],
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildInstructionStep(int step, String instruction) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$step',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              instruction,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
  );

  Widget _buildInfoItem(String label, String value, {bool isBold = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
      ],
    ),
  );

  Widget _buildOrderItem(CartItem item) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${item.quantity}x', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              if (item.addons != '-') Text('Additional: ${item.addons}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              if (item.toppings != '-') Text('Topping: ${item.toppings}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ],
          ),
        ),
        Text(formatCurrency(item.price * item.quantity), style: const TextStyle(fontSize: 14)),
      ],
    ),
  );

  String _getOrderTypeText() {
    switch (widget.orderType) {
      case OrderType.dineIn:
        return 'Makan di Tempat';
      case OrderType.delivery:
        return 'Pengantaran';
      case OrderType.pickup:
        return 'Ambil Sendiri';
    }
  }
}