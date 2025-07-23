import 'dart:convert';
import 'dart:typed_data';
import 'package:baraja_app/services/confirm_service.dart';
import 'package:flutter/material.dart';
import 'package:baraja_app/theme/app_theme.dart';
import 'package:go_router/go_router.dart';
import '../../models/cart_item.dart';
import '../../models/order.dart';
import '../../models/order_type.dart';
import '../../models/reservation_data.dart';
import '../../utils/currency_formatter.dart';
import '../payment/payment_type_widget.dart';
import '../payment_detail/components/qr_code_components.dart';
import 'payment_status_card.dart';
import 'payment_instructions.dart';

class UnifiedPaymentView extends StatefulWidget {
  final Order order;
  final Map<String, dynamic>? paymentResponse;
  final Map<String, String?> paymentDetails;
  final OrderType orderType;
  final String tableNumber;
  final String deliveryAddress;
  final TimeOfDay? pickupTime;
  final int subtotal;
  final int discount;
  final int total;
  final String? voucherCode;
  final List<CartItem> items;
  final bool isCashPayment;

  // Reservation-specific parameters
  final bool isReservation;
  final PaymentType? paymentType;
  final int amountToPay;
  final int remainingPayment;
  final bool isDownPayment;
  final ReservationData? reservationData;

  const UnifiedPaymentView({
    super.key,
    required this.order,
    required this.paymentResponse,
    required this.paymentDetails,
    required this.orderType,
    required this.tableNumber,
    required this.deliveryAddress,
    required this.pickupTime,
    required this.subtotal,
    required this.discount,
    required this.total,
    required this.voucherCode,
    required this.items,
    required this.isCashPayment,
    this.isReservation = false,
    this.paymentType,
    required this.amountToPay,
    this.remainingPayment = 0,
    this.isDownPayment = false,
    this.reservationData,
  });

  @override
  State<UnifiedPaymentView> createState() => _UnifiedPaymentViewState();
}

class _UnifiedPaymentViewState extends State<UnifiedPaymentView> {
  bool _isLoading = false;
  bool _apiCallCompleted = false;
  String? _errorMessage;
  Map<String, dynamic>? _paymentData;
  String? _qrCodeUrl;


  final ConfirmService _confirmService = ConfirmService();

  @override
  void initState() {
    super.initState();
    if (widget.isCashPayment) {
      _processCashPayment();
    } else {
      _apiCallCompleted = true; // Digital payment is already processed
    }
  }

  /// Process cash payment using ConfirmService
  Future<void> _processCashPayment() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _apiCallCompleted = false;
    });

    try {
      final result = await _confirmService.sendOrder(widget.order);

      setState(() {
        _isLoading = false;
        if (result.success) {
          _apiCallCompleted = true;
          _paymentData = result.data;
          _errorMessage = null;

          final actions = _paymentData?['actions'] as List<dynamic>?;
          if (actions != null && actions.isNotEmpty) {
            for (var action in actions) {
              if (action['name'] == 'generate-qr-code') {
                _qrCodeUrl = action['url'];
                break;
              }
            }
          }

          print('Payment data: ${_paymentData.toString()}');
          print('QR Code URL: $_qrCodeUrl');
        } else {
          _apiCallCompleted = false;
          _errorMessage = result.message;
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: result.success ? Colors.green : Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Terjadi kesalahan yang tidak terduga: ${error.toString()}';
      });
    }
  }

  /// Convert data URL (base64) to Uint8List
  Uint8List? _dataUrlToBytes(String dataUrl) {
    try {
      final base64Str = dataUrl.split(',').last;
      return base64Decode(base64Str);
    } catch (e) {
      print('Error decoding data URL: $e');
      return null;
    }
  }

  /// Widget to display QR image from either data URL or HTTP URL
  Widget _buildQRCodeImage(String url) {
    if (url.startsWith('data:image')) {
      final bytes = _dataUrlToBytes(url);
      if (bytes != null) {
        return Image.memory(
          bytes,
          width: 200,
          height: 200,
          fit: BoxFit.contain,
        );
      } else {
        return const QRCodeError();
      }
    } else {
      return Image.network(
        url,
        width: 200,
        height: 200,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return const QRCodeError();
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const QRCodeLoading();
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Status section (only for cash payments)
        if (widget.isCashPayment) _buildPaymentStatusSection(),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Payment status or QR code section
                if (widget.isCashPayment) ...[
                  _buildQRCodeSection(),
                  const SizedBox(height: 24),
                  _buildPaymentInstructions(),
                ] else ...[
                  PaymentStatusCard(
                      paymentResponse: widget.paymentResponse,
                      orderId: widget.order.orderId
                  ),
                ],

                const SizedBox(height: 24),

                // Payment Information
                _buildSectionTitle('Informasi Pembayaran'),
                _buildInfoItem(
                    'Metode Pembayaran',
                    widget.isCashPayment
                        ? 'Tunai'
                        : (widget.paymentDetails['bankName'] ?? 'Unknown')
                ),
                const SizedBox(height: 8),
                _buildInfoItem(
                    'Total Pembayaran',
                    formatCurrency(widget.isReservation ? widget.amountToPay : widget.total)
                ),

                // Additional payment info for reservations
                if (widget.isReservation) ...[
                  const SizedBox(height: 8),
                  _buildInfoItem(
                      'Jenis Pembayaran',
                      widget.isDownPayment ? 'Uang Muka' : 'Pembayaran Penuh'
                  ),
                  if (widget.isDownPayment) ...[
                    _buildInfoItem(
                        'Sisa Pembayaran',
                        formatCurrency(widget.remainingPayment)
                    ),
                  ],
                ],

                // Additional payment data from API response
                if (_paymentData != null) ...[
                  const SizedBox(height: 8),
                  if (_paymentData!.containsKey('transaction_id'))
                    _buildInfoItem('Transaction ID', _paymentData!['transaction_id'].toString()),
                  if (_paymentData!.containsKey('status'))
                    _buildInfoItem('Status', _paymentData!['status'].toString()),
                ],

                // Digital payment instructions
                if (!widget.isCashPayment && widget.paymentResponse != null) ...[
                  const SizedBox(height: 8),
                  PaymentInstructions(paymentResponse: widget.paymentResponse!),
                ],

                const Divider(height: 32),
                _buildSectionTitle('Informasi Pesanan'),
                _buildInfoItem('Tipe Pesanan', _getOrderTypeText(widget.orderType)),

                if (widget.orderType == OrderType.dineIn && widget.tableNumber.isNotEmpty)
                  _buildInfoItem('Nomor Meja', widget.tableNumber),
                if (widget.orderType == OrderType.delivery && widget.deliveryAddress.isNotEmpty)
                  _buildInfoItem('Alamat Pengantaran', widget.deliveryAddress),
                if (widget.orderType == OrderType.pickup && widget.pickupTime != null)
                  _buildInfoItem('Waktu Pengambilan',
                      '${widget.pickupTime!.hour}:${widget.pickupTime!.minute.toString().padLeft(2, '0')}'),

                // Reservation-specific information
                if (widget.isReservation && widget.reservationData != null) ...[
                  _buildInfoItem('Tanggal Reservasi', widget.reservationData!.formattedDate),
                  _buildInfoItem('Waktu Reservasi', widget.reservationData!.formattedTime),
                  _buildInfoItem('Jumlah Tamu', widget.reservationData!.personCount.toString()),
                  // if (widget.reservationData!.specialRequest.isNotEmpty)
                  //   _buildInfoItem('Permintaan Khusus', widget.reservationData!.specialRequest),
                ],

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
                _buildInfoItem(
                    'Total',
                    formatCurrency(widget.isReservation ? widget.amountToPay : widget.total),
                    isBold: true
                ),
              ],
            ),
          ),
        ),

        // Bottom button
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: () {
              context.go('/orderDetail', extra: widget.order.id);
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
        )
      ],
    );
  }

  /// Widget for payment status (cash payments only)
  Widget _buildPaymentStatusSection() {
    if (_isLoading) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          border: Border(bottom: BorderSide(color: Colors.blue.withOpacity(0.2))),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text(
              'Memproses pembayaran tunai...',
              style: TextStyle(fontSize: 14, color: Colors.blue, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          border: Border(bottom: BorderSide(color: Colors.red.withOpacity(0.2))),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _errorMessage!,
                style: const TextStyle(fontSize: 14, color: Colors.red),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.red, size: 20),
              onPressed: _processCashPayment,
              tooltip: 'Coba lagi',
            ),
          ],
        ),
      );
    }

    if (_apiCallCompleted) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          border: Border(bottom: BorderSide(color: Colors.green.withOpacity(0.2))),
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
            SizedBox(width: 12),
            Text(
              'Pembayaran tunai berhasil diproses',
              style: TextStyle(fontSize: 14, color: Colors.green, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildQRCodeSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.qr_code_2,
            size: 40,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(height: 16),
          const Text(
            'QR Code Pesanan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.withOpacity(0.3)),
            ),
            child: _qrCodeUrl != null
                ? _buildQRCodeImage(_qrCodeUrl!)
                : const QRCodeError(),
          ),
          const SizedBox(height: 16),
          Text(
            'Order ID: ${widget.order.orderId}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentInstructions() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.orange,
                size: 24,
              ),
              SizedBox(width: 8),
              Text(
                'Instruksi Pembayaran Tunai',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            '1. Tunjukkan QR Code ini kepada kasir',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 8),
          const Text(
            '2. Kasir akan melakukan scan QR Code untuk verifikasi pesanan',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            '3. Bayar total sebesar ${formatCurrency(widget.isReservation ? widget.amountToPay : widget.total)} secara tunai',
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 8),
          const Text(
            '4. Tunggu konfirmasi dari kasir bahwa pembayaran telah diterima',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.withOpacity(0.2)),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.warning_amber,
                  color: Colors.orange,
                  size: 20,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Pastikan Anda sudah menuju ke kasir untuk menyelesaikan pembayaran',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getOrderTypeText(OrderType type) {
    switch (type) {
      case OrderType.dineIn:
        return 'Makan di Tempat';
      case OrderType.delivery:
        return 'Pengantaran';
      case OrderType.pickup:
        return 'Ambil Sendiri';
      case OrderType.reservation:
        return 'Reservasi';
    }
  }

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

              // Addons Section
              if (item.addons.isNotEmpty) ...[
                const Row(
                  children: [
                    // Icon(Icons.add_circle_outline, size: 16, color: Colors.blue),
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

              // Toppings Section
              if ((item.toppings is String && (item.toppings as String).isNotEmpty) ||
                  ((item.toppings as List).isNotEmpty)) ...[
                const Row(
                  children: [
                    // Icon(Icons.cake, size: 16, color: Colors.deepOrange),
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

              // Notes Section
              if (item.notes != null && item.notes!.isNotEmpty) ...[
                const Row(
                  children: [
                    Icon(Icons.note_outlined, size: 16, color: Colors.amber),
                    SizedBox(width: 4),
                    Text(
                      'Catatan:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.only(left: 8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.withOpacity(0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.format_quote, size: 14, color: Colors.amber),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.notes!,
                          style: const TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: Colors.black87,
                          ),
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
}