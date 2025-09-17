import 'package:baraja_app/utils/base_screen_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/socket_service.dart';
import '../models/cart_item.dart';
import '../models/order.dart';
import '../models/order_type.dart';
import '../models/reservation_data.dart';
import '../providers/order_provider.dart';
import '../services/confirm_service.dart';
import '../widgets/checkout/payment_type_widget.dart';
import '../widgets/payment_confirm/payment_error_view.dart';
import '../widgets/payment_confirm/payment_loading_view.dart';
import '../widgets/payment_confirm/unified_payment_view.dart';
import '../widgets/utils/classic_app_bar.dart';
import 'package:flutter/foundation.dart';

class PaymentConfirmationScreen extends StatefulWidget {
  final List<CartItem> items;
  final String? userId;
  final String? userName;
  final OrderType orderType;
  final String? tableNumber;
  final String deliveryAddress;
  final TimeOfDay? pickupTime;
  final Map<String, String?> paymentDetails;
  final int subtotal;
  final int discount;
  final int total;
  final PaymentType? paymentType;
  final int amountToPay;
  final String? voucherCode;
  final String orderId;
  final String id;
  final ReservationData? reservationData;
  final bool? isReservation;
  final int? downPaymentAmount;
  final int remainingPayment;
  final bool isDownPayment;

  const PaymentConfirmationScreen({
    super.key,
    required this.items,
    this.userId,
    this.userName,
    required this.orderType,
    this.tableNumber,
    required this.deliveryAddress,
    required this.pickupTime,
    required this.paymentDetails,
    required this.subtotal,
    required this.discount,
    required this.total,
    this.paymentType,
    required this.amountToPay,
    this.voucherCode,
    required this.orderId,
    required this.id,
    this.reservationData,
    this.isReservation,
    this.downPaymentAmount,
    required this.remainingPayment,
    required this.isDownPayment,
  });

  @override
  State<PaymentConfirmationScreen> createState() => _PaymentConfirmationScreenState();
}

// PERBAIKAN untuk _PaymentConfirmationScreenState

class _PaymentConfirmationScreenState extends State<PaymentConfirmationScreen> {
  final SocketService _socketService = SocketService();
  late final Order newOrder;
  bool _isLoading = false;
  PaymentResult? _paymentResponse;
  String? _errorMessage;
  bool _isListeningForPayment = false;
  bool _isCashPayment = false;
  bool _isProcessing = false;

  // ✅ TAMBAHAN: Variable untuk tracking real-time updates
  String _currentOrderStatus = 'processing';
  String _currentPaymentStatus = 'pending';

  @override
  void initState() {
    super.initState();

    _isCashPayment = _checkIfCashPayment();

    // Log items untuk debugging
    for (var item in widget.items) {
      print("PaymentConfirmation item: ${item.name} "
          "| OutletId: ${item.outletId} "
          "| OutletName: ${item.outletName}");
    }

    // Create new order instance
    newOrder = Order(
      id: widget.id,
      orderId: widget.orderId,
      items: widget.items.map((item) => CartItem(
        id: item.id,
        name: item.name,
        price: item.price,
        totalprice: item.totalprice,
        quantity: item.quantity,
        addons: item.addons,
        toppings: item.toppings,
        imageUrl: item.imageUrl,
        notes: item.notes,
        outletId: item.outletId,
        outletName: item.outletName,
      )).toList(),
      orderType: widget.orderType,
      tableNumber: widget.tableNumber ?? '',
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      orderProvider.addOrder(newOrder);
      _processPayment();
    });
  }

  bool _checkIfCashPayment() {
    final paymentType = widget.paymentDetails['methodName']?.toLowerCase();
    return paymentType == 'cash' || paymentType == 'tunai';
  }

  Future<void> _processPayment() async {
    if (_isProcessing || !mounted) return;

    setState(() {
      _isProcessing = true;
      _isLoading = true;
    });

    final confirmService = ConfirmService();

    try {
      final response = await confirmService.sendOrder(
        newOrder,
        isDownPayment: widget.isDownPayment,
        downPaymentAmount: widget.downPaymentAmount,
        remainingPayment: widget.remainingPayment,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          _paymentResponse = response;
        });

        if (response.success) {
          final orderProvider = Provider.of<OrderProvider>(context, listen: false);
          orderProvider.addOrder(newOrder);

          print('Payment processed successfully for order: ${widget.orderId}');

          // ✅ PERBAIKAN: Setup socket connection untuk SEMUA jenis pembayaran
          _setupSocketConnection();
        } else {
          setState(() {
            _errorMessage = response.message;
          });

          print('Payment processing failed: ${response.message}');
          print('Status code: ${response.statusCode}');

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal memproses pembayaran: ${response.message}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      print('Exception during payment processing: $e');

      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Terjadi kesalahan sistem. Silakan coba lagi.'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Coba Lagi',
              onPressed: _retryPayment,
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  // ✅ PERBAIKAN: Setup socket connection untuk semua pembayaran
  void _setupSocketConnection() {
    if (!_isListeningForPayment) {
      _isListeningForPayment = true;

      print('Setting up socket connection for order: ${widget.id}');

      _socketService.connectToSocket(
        id: widget.id,
        onPaymentUpdate: _handlePaymentUpdate,
        onOrderUpdate: _handleOrderUpdate, // ✅ PERBAIKAN: Handler yang proper
      );

      Future.delayed(const Duration(seconds: 3), () {
        _socketService.joinOrderRoom(widget.id);
        print('Joined order room: ${widget.id}');
      });
    }
  }

  // ✅ TAMBAHAN: Handler untuk order update
  void _handleOrderUpdate(Map<String, dynamic> data) {
    print('Order update received in PaymentConfirmationScreen: $data');

    if (data['order_id']?.toString() == widget.orderId.toString()) {
      print('Order update matches our order ID');

      if (mounted) {
        setState(() {
          // Update order status
          if (data.containsKey('orderStatus')) {
            _currentOrderStatus = data['orderStatus'];
          }

          // Update payment status jika ada
          if (data.containsKey('paymentStatus')) {
            _currentPaymentStatus = data['paymentStatus'];
          }

          // Update provider jika diperlukan
          final orderProvider = Provider.of<OrderProvider>(context, listen: false);

          // Convert string status to OrderStatus enum
          OrderStatus? newStatus;
          switch (data['orderStatus']?.toLowerCase()) {
            case 'pending':
              newStatus = OrderStatus.pending;
              break;
            case 'waiting':
              newStatus = OrderStatus.waiting;
              break;
            case 'onprocess':
              newStatus = OrderStatus.processing;
              break;
            case 'ready':
              newStatus = OrderStatus.ready;
              break;
            case 'completed':
              newStatus = OrderStatus.completed;
              break;
            case 'cancelled':
            case 'canceled':
              newStatus = OrderStatus.cancelled;
              break;
          }

          if (newStatus != null) {
            orderProvider.updateOrderStatus(widget.id, newStatus);
          }
        });

        print('Order status updated to: ${data['orderStatus']}');
      }
    } else {
      print('Received order update for different order: ${data['order_id']}');
    }
  }

  void _handlePaymentUpdate(Map<String, dynamic> data) {
    print('Payment update received in PaymentConfirmationScreen: $data');

    if (data['order_id'] == widget.orderId) {
      print('Payment update matches our order ID');

      if (mounted) {
        setState(() {
          // Update current payment status
          _currentPaymentStatus = data['transaction_status'];

          // Update payment response jika ada
          if (_paymentResponse != null && _paymentResponse!.data != null) {
            final updatedData = Map<String, dynamic>.from(_paymentResponse!.data!);

            updatedData['transaction_status'] = data['transaction_status'];

            if (data.containsKey('fraud_status')) {
              updatedData['fraud_status'] = data['fraud_status'];
            }
            if (data.containsKey('status_message')) {
              updatedData['status_message'] = data['status_message'];
            }

            _paymentResponse = PaymentResult(
              success: _paymentResponse!.success,
              message: _paymentResponse!.message,
              data: updatedData,
              statusCode: _paymentResponse!.statusCode,
              error: _paymentResponse!.error,
            );
          }
        });
      }

      print('Payment status updated to: ${data['transaction_status']}');

      // Update order status di provider untuk settlement/capture
      if (data['transaction_status'] == 'settlement' ||
          data['transaction_status'] == 'capture') {
        if (mounted) {
          final orderProvider = Provider.of<OrderProvider>(context, listen: false);
          orderProvider.updateOrderStatus(widget.id, OrderStatus.pending);
        }
      }
    } else {
      print('Received payment update for different order: ${data['order_id']}');
    }
  }

  Map<String, dynamic>? get _paymentResponseData {
    return _paymentResponse?.data;
  }

  void _retryPayment() {
    setState(() {
      _errorMessage = null;
      _isProcessing = false;
    });
    _processPayment();
  }

  @override
  void dispose() {
    print('Disposing PaymentConfirmationScreen');
    // ✅ PERBAIKAN: Dispose socket untuk semua pembayaran
    _socketService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreenWrapper(
      customBackRoute: '/history',
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: const ClassicAppBar(
          title: 'Konfirmasi Pembayaran',
          customBackRoute: '/history',
        ),
        body: SafeArea(
          child: _isLoading
              ? const PaymentLoadingView()
              : _errorMessage != null
              ? PaymentErrorView(
            errorMessage: _errorMessage,
            onRetry: _retryPayment,
          )
              : Column(
            children: [
              Expanded(
                child: UnifiedPaymentView(
                  order: newOrder,
                  paymentResponse: _paymentResponseData,
                  paymentDetails: widget.paymentDetails,
                  orderType: widget.orderType,
                  tableNumber: widget.tableNumber ?? '',
                  deliveryAddress: widget.deliveryAddress,
                  pickupTime: widget.pickupTime,
                  subtotal: widget.subtotal,
                  discount: widget.discount,
                  total: widget.total,
                  voucherCode: widget.voucherCode,
                  items: widget.items,
                  isCashPayment: _isCashPayment,
                  isReservation: widget.isReservation ?? false,
                  paymentType: widget.paymentType,
                  amountToPay: widget.amountToPay,
                  remainingPayment: widget.remainingPayment,
                  isDownPayment: widget.isDownPayment,
                  reservationData: widget.reservationData,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}