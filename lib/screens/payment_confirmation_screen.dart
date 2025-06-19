import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/payment_storage_service.dart';
import '../services/socket_service.dart';
import '../models/cart_item.dart';
import '../models/order.dart';
import '../models/order_type.dart';
import '../providers/order_provider.dart';
import '../services/confirm_service.dart';
import '../widgets/payment_confirm/payment_error_view.dart';
import '../widgets/payment_confirm/payment_loading_view.dart';
import '../widgets/payment_confirm/payment_success_view.dart';
import '../widgets/payment_confirm/cash_payment_view.dart';
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
  final String orderId;
  final String id;

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
    required this.id,
  });

  @override
  State<PaymentConfirmationScreen> createState() => _PaymentConfirmationScreenState();
}

class _PaymentConfirmationScreenState extends State<PaymentConfirmationScreen> {
  final SocketService _socketService = SocketService();
  late final Order newOrder;
  bool _hasSentOrder = false;
  bool _isLoading = true;
  Map<String, dynamic>? _paymentResponse;
  String? _errorMessage;
  bool _isListeningForPayment = false;
  bool _isCashPayment = false;

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

    // Defer the payment handling until after the build phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isCashPayment) {
        // For cash payment, just add to order provider and show QR code
        _handleCashPayment();
      } else {
        // For digital payments, setup socket and send order
        _setupSocketConnection();
        _sendOrderOnce();
      }
    });
  }

  bool _checkIfCashPayment() {
    final paymentType = widget.paymentDetails['methodName']?.toLowerCase();
    return paymentType == 'cash' || paymentType == 'tunai';
  }

  Future<void> _handleCashPayment() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Add order to provider - now safe to call after build phase
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      orderProvider.addOrder(newOrder);

      // Create mock payment response for cash
      _paymentResponse = {
        'status_code': '200',
        'transaction_status': 'pending',
        'payment_type': 'cash',
        'order_id': widget.orderId,
        'transaction_time': DateTime.now().toIso8601String(),
        'gross_amount': widget.total.toString(),
      };

      // Save payment details
      await _savePaymentDetails();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

      print('Cash payment processed for order: ${widget.orderId}');
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
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
          if (_paymentResponse != null) {
            _paymentResponse!['transaction_status'] = data['transaction_status'];

            // Update other fields if they exist in the update
            if (data.containsKey('fraud_status')) {
              _paymentResponse!['fraud_status'] = data['fraud_status'];
            }
            if (data.containsKey('status_message')) {
              _paymentResponse!['status_message'] = data['status_message'];
            }
          }
        });

        // Update stored payment details with new status
        _updateStoredPaymentStatus(data['transaction_status']);
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

  Future<void> _updateStoredPaymentStatus(String newStatus) async {
    try {
      await PaymentStorageService.updateTransactionStatus(widget.id, newStatus);
      print('Stored payment status updated to: $newStatus for order: ${widget.id}');
    } catch (e) {
      print('Error updating stored payment status: $e');
    }
  }

  Future<void> _savePaymentDetails() async {
    if (_paymentResponse != null) {
      try {
        await PaymentStorageService.savePaymentDetails(
          id: widget.id,
          orderId: widget.orderId,
          paymentResponse: _paymentResponse!,
          paymentDetails: widget.paymentDetails,
          subtotal: widget.subtotal,
          discount: widget.discount,
          total: widget.total,
          voucherCode: widget.voucherCode,
          items: widget.items,
          orderType: widget.orderType,
          tableNumber: widget.tableNumber,
          deliveryAddress: widget.deliveryAddress,
          pickupTime: widget.pickupTime,
        );
        print('Payment details saved successfully for order: ${widget.orderId}');

        // Log the saved payment response structure for debugging
        print('Saved payment response structure:');
        print('- Status Code: ${_paymentResponse!['status_code']}');
        print('- Transaction ID: ${_paymentResponse!['transaction_id']}');
        print('- Payment Type: ${_paymentResponse!['payment_type']}');
        print('- Transaction Status: ${_paymentResponse!['transaction_status']}');

        if (_paymentResponse!.containsKey('va_numbers')) {
          print('- VA Numbers available: ${_paymentResponse!['va_numbers']}');
        }
      } catch (e) {
        print('Error saving payment details: $e');
      }
    }
  }

  Future<void> debugPrintSavedPaymentData() async {
    try {
      final savedData = await PaymentStorageService.getPaymentDetails(widget.id);
      if (savedData != null) {
        print('=== DEBUG: Saved Payment Data ===');
        print('Order ID: ${savedData['orderId']}');
        print('Total: ${savedData['total']}');
        print('Saved At: ${savedData['savedAt']}');

        if (savedData.containsKey('paymentResponse')) {
          final paymentResponse = savedData['paymentResponse'];
          print('Payment Response:');
          print('- Transaction Status: ${paymentResponse['transaction_status']}');
          print('- Payment Type: ${paymentResponse['payment_type']}');
          print('- Transaction ID: ${paymentResponse['transaction_id']}');
          print('- Expiry Time: ${paymentResponse['expiry_time']}');

          if (paymentResponse.containsKey('va_numbers')) {
            print('- VA Numbers: ${paymentResponse['va_numbers']}');
          }
        }
        print('=== END DEBUG ===');
      } else {
        print('No saved payment data found for order: ${widget.orderId}');
      }
    } catch (e) {
      print('Error debugging saved payment data: $e');
    }
  }

  Future<void> _sendOrderOnce() async {
    if (!_hasSentOrder && mounted) {
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

          // Save payment details to SharedPreferences
          await _savePaymentDetails();

          // Make sure we're connected to socket after order is sent
          _setupSocketConnection();
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
  void dispose() {
    print('Disposing PaymentConfirmationScreen');
    if (!_isCashPayment) {
      _socketService.dispose();
    }
    super.dispose();
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
            if (_isCashPayment) {
              _handleCashPayment();
            } else {
              _hasSentOrder = false;
              _sendOrderOnce();
            }
          },
        )
            : _isCashPayment
            ? CashPaymentView(
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