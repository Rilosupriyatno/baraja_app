import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/cart_item.dart';
import '../models/order.dart';
import '../models/order_type.dart';
import '../providers/order_provider.dart';
import '../services/confirm_service.dart';
import '../widgets/payment_confirm/payment_error_view.dart';
import '../widgets/payment_confirm/payment_loading_view.dart';
import '../widgets/payment_confirm/payment_success_view.dart';
import '../widgets/utils/classic_app_bar.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;


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
  late IO.Socket socket;

  @override
  void initState() {
    super.initState();
    _setupSocket();

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

  void _setupSocket() {
    socket = IO.io('https://1d3e-202-59-193-188.ngrok-free.app', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
      'secure': true,
    });
    socket.onConnectError((data) {
      print("Connection Error: $data");
    });
    socket.onError((data) {
      print("General Socket Error: $data");
    });

    socket.emit('join', widget.orderId);
    socket.onConnect((_) {

      print('Connected to socket server');
    });

    socket.on('payment_created', (data) {
      print('Payment created event received: $data');
      // Tampilkan notifikasi atau redirect ke halaman tertentu
    });

    socket.onDisconnect((_) => print('Disconnected from socket'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const ClassicAppBar(title: 'Konfirmasi Pembayaran'),
      body: SafeArea(
        child: _isLoading
            ? const PaymentLoadingView()
            : _errorMessage != null
            ? PaymentErrorView(
          errorMessage: _errorMessage,
          onRetry: () {
            _hasSentOrder = false;
            _sendOrderOnce();
          },
        )
            : PaymentSuccessView(
          order: newOrder,
          paymentResponse: _paymentResponse,
          paymentDetails: widget.paymentDetails,
          orderType: widget.orderType,
          tableNumber: widget.tableNumber,
          deliveryAddress: widget.deliveryAddress,
          pickupTime: widget.pickupTime,
          subtotal: widget.subtotal,
          discount: widget.discount,
          total: widget.total,
          voucherCode: widget.voucherCode,
          items: widget.items,
        ),
      ),
    );
  }
}