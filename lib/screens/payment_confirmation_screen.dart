import 'dart:convert';

import 'package:baraja_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/cart_item.dart';
import '../models/order.dart';
import '../models/order_type.dart';
import '../providers/order_provider.dart';
import '../services/confirm_service.dart';
import '../utils/currency_formatter.dart';
import '../widgets/utils/classic_app_bar.dart';
import 'package:url_launcher/url_launcher.dart';

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
  final String orderId;

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
    required this.orderId,
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

    // Create new order instance
    newOrder = Order(
      id: widget.orderId,
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    // Optional: disconnect socket when leaving screen
    // Note: You might want to keep the connection if needed elsewhere
    // _socketService.disconnect();
    super.dispose();
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

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak dapat membuka aplikasi GoPay'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Nomor VA berhasil disalin'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
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
              Navigator.of(context).pushReplacementNamed('/orders'); // Updated to use navigator
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
          // Mengubah tampilan VA number dari Row menjadi Column
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nomor Virtual Account',
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      vaNumber,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => _copyToClipboard(vaNumber),
                    child: const Icon(
                      Icons.copy,
                      size: 18,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
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
            const SizedBox(height: 16),
            (() {
              final actions = _paymentResponse!['actions'] as List;
              String? deeplinkUrl;


              for (final action in actions) {
                if (action['name'] == 'deeplink-redirect') {
                  deeplinkUrl = action['url'];
                }
              }

              if (deeplinkUrl != null) {
                return ElevatedButton.icon(
                  onPressed: () => _launchUrl(deeplinkUrl!),
                  icon: const Icon(Icons.smartphone),
                  label: const Text('Bayar dengan GoPay'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00ADD8), // GoPay color
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            })(),
          ],

          if (_paymentResponse!.containsKey('expiry_time'))
            _buildInfoItem('Bayar Sebelum', _paymentResponse!['expiry_time']),
        ],
      );
    } else if (paymentType == 'qris') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_paymentResponse!.containsKey('actions')) ...[
            const SizedBox(height: 16),
            const Text(
              'QRIS:',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
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
                  const SizedBox(height: 16),
                  (() {
                    final actions = _paymentResponse!['actions'] as List;
                    String? qrCodeUrl;

                    for (final action in actions) {
                      if (action['name'] == 'generate-qr-code') {
                        qrCodeUrl = action['url'];
                        break; // Stop searching once we find the QR code URL
                      }
                    }

                    if (qrCodeUrl != null) {
                      return Image.network(
                        qrCodeUrl,
                        height: 200, // Atur tinggi sesuai kebutuhan
                        width: 200, // Atur lebar sesuai kebutuhan
                        fit: BoxFit.cover, // Atur cara gambar ditampilkan
                      );
                    }
                    return const SizedBox.shrink();
                  })(),
                  const SizedBox(height: 8),
                  const Text(
                    'Scan QRIS dengan aplikasi e-wallet atau mobile banking',
                    style: TextStyle(fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            if (_paymentResponse!.containsKey('expiry_time'))
              _buildInfoItem('Bayar Sebelum', _paymentResponse!['expiry_time']),
          ],
        ],
      );
    } else if (paymentType == 'cash') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_paymentResponse!.containsKey('actions')) ...[
            const SizedBox(height: 16),
            const Text(
              'Tunai:',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
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
                  const SizedBox(height: 16),
                  (() {
                    final actions = _paymentResponse!['actions'] as List;
                    String? qrCodeUrl;

                    for (final action in actions) {
                      if (action['name'] == 'generate-qr-code') {
                        qrCodeUrl = action['url'];
                        break; // Stop searching once we find the QR code URL
                      }
                    }

                    if (qrCodeUrl != null && qrCodeUrl.startsWith('data:image')) {
                      final base64Data = qrCodeUrl.split(',').last;
                      final Uint8List bytes = base64Decode(base64Data);

                      return Image.memory(
                        bytes,
                        height: 200,
                        width: 200,
                        fit: BoxFit.cover,
                      );
                    }
                    return const SizedBox.shrink();
                  })(),
                  const SizedBox(height: 8),
                  const Text(
                    'Tunjukkan Qris kepada kasir untuk pembayaran tunai',
                    style: TextStyle(fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            if (_paymentResponse!.containsKey('expiry_time'))
              _buildInfoItem('Bayar Sebelum', _paymentResponse!['expiry_time']),
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
            decoration: const BoxDecoration(
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
              const SizedBox(width: 12),
              // Tambahan (Addons) Section
              if (item.addons.isNotEmpty) ...[
                const Row(
                  children: [
                    Icon(Icons.add_circle_outline, size: 16, color: Colors.blue),
                    SizedBox(width: 4),
                    Text(
                      'Tambahan:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.only(left: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: item.addons.map((addon) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                const Icon(Icons.circle, size: 6, color: Colors.blue),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${addon["name"]}: ${addon["label"]}',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            formatCurrency(addon["price"]),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    )).toList(),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              const SizedBox(width: 12),
              // Topping Section
              if ((item.toppings is String && (item.toppings as String).isNotEmpty) ||
                  ((item.toppings as List).isNotEmpty)) ...[
                const Row(
                  children: [
                    Icon(Icons.cake, size: 16, color: Colors.deepOrange),
                    SizedBox(width: 4),
                    Text(
                      'Topping:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.only(left: 8),
                  decoration: BoxDecoration(
                    color: Colors.deepOrange.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.deepOrange.withOpacity(0.2)),
                  ),
                  child: item.toppings is List<Map<String, Object>>
                      ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: (item.toppings as List<Map<String, Object>>).map((topping) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                const Icon(Icons.circle, size: 6, color: Colors.deepOrange),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${topping["name"]}',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (topping.containsKey("price") && topping["price"] != null)
                            Text(
                              formatCurrency(topping["price"] as num),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.deepOrange,
                              ),
                            ),
                        ],
                      ),
                    )).toList(),
                  )
                      : Row(
                    children: [
                      const Icon(Icons.circle, size: 6, color: Colors.deepOrange),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.toppings is String
                              ? item.toppings as String
                          // ignore: unnecessary_type_check
                              : item.toppings is List
                              ? (item.toppings as List).join(', ')
                              : '',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
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