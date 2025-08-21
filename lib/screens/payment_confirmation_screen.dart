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

class _PaymentConfirmationScreenState extends State<PaymentConfirmationScreen> {
  final SocketService _socketService = SocketService();
  late final Order newOrder;
  bool _isLoading = true;
  PaymentResult? _paymentResponse;
  String? _errorMessage;
  bool _isListeningForPayment = false;
  bool _isCashPayment = false;
  bool _isProcessing = false; // Add this flag to prevent duplicate processing

  @override
  void initState() {
    super.initState();

    // Check if payment method is cash
    _isCashPayment = _checkIfCashPayment();

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

    // Defer the payment handling until after the build phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _processPayment();
    });
  }

  bool _checkIfCashPayment() {
    final paymentType = widget.paymentDetails['methodName']?.toLowerCase();
    return paymentType == 'cash' || paymentType == 'tunai';
  }

  // Single method to handle all payment processing
  Future<void> _processPayment() async {
    if (_isProcessing || !mounted) return;

    setState(() {
      _isProcessing = true;
      _isLoading = true;
    });

    final confirmService = ConfirmService();

    try {
      // Send order (works for both cash and digital payments)
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
          // Add order to provider
          final orderProvider = Provider.of<OrderProvider>(context, listen: false);
          orderProvider.addOrder(newOrder);

          print('Payment processed successfully for order: ${widget.orderId}');

          // For non-cash payments, setup socket connection
          if (!_isCashPayment) {
            _setupSocketConnection();
          }
        } else {
          setState(() {
            _errorMessage = response.message;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _setupSocketConnection() {
    if (!_isListeningForPayment) {
      _isListeningForPayment = true;

      // Connect to socket and listen for payment updates
      _socketService.connectToSocket(
        id: widget.id,
        onPaymentUpdate: _handlePaymentUpdate,
        onOrderUpdate: (_) {}, // ✅ handler baru
      );

      // Add a delay before manually joining the room again
      Future.delayed(const Duration(seconds: 3), () {
        _socketService.joinOrderRoom(widget.id);
      });
    }
  }


  void _handlePaymentUpdate(Map<String, dynamic> data) {
    print('Payment update received in screen: $data');

    if (data['order_id'] == widget.orderId) {
      print('Payment update matches our order ID');

      if (mounted) {
        setState(() {
          // Update the payment response with new transaction status
          if (_paymentResponse != null && _paymentResponse!.data != null) {
            // Create a mutable copy of the data
            final updatedData = Map<String, dynamic>.from(_paymentResponse!.data!);

            updatedData['transaction_status'] = data['transaction_status'];

            // Update other fields if they exist in the update
            if (data.containsKey('fraud_status')) {
              updatedData['fraud_status'] = data['fraud_status'];
            }
            if (data.containsKey('status_message')) {
              updatedData['status_message'] = data['status_message'];
            }

            // Create new PaymentResult with updated data
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

      // Update order status based on transaction status
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

  // Helper method to get payment response data as Map for widget compatibility
  Map<String, dynamic>? get _paymentResponseData {
    return _paymentResponse?.data;
  }

  // Retry method for handling errors
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
    if (!_isCashPayment) {
      _socketService.dispose();
    }
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
              : UnifiedPaymentView(
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
            // Add reservation-specific parameters
            isReservation: widget.isReservation ?? false,
            paymentType: widget.paymentType,
            amountToPay: widget.amountToPay,
            remainingPayment: widget.remainingPayment,
            isDownPayment: widget.isDownPayment,
            reservationData: widget.reservationData,
          ),
        ),
      ),
    );
  }
}