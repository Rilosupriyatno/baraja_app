import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/payment_storage_service.dart';
import '../services/socket_service.dart';
import '../models/cart_item.dart';
import '../models/order.dart';
import '../models/order_type.dart';
import '../models/reservation_data.dart';
import '../providers/order_provider.dart';
import '../services/confirm_service.dart';
import '../widgets/payment/payment_type_widget.dart';
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
  bool _hasSentOrder = false;
  bool _isLoading = true;
  PaymentResult? _paymentResponse;
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

    final confirmService = ConfirmService();

    try {
      // Send cash payment through the unified sendOrder method
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
          // Add order to provider - now safe to call after build phase
          final orderProvider = Provider.of<OrderProvider>(context, listen: false);
          orderProvider.addOrder(newOrder);

          // Save payment details
          await _savePaymentDetails();

          print('Cash payment processed for order: ${widget.orderId}');
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

        // Update stored payment status
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
    if (_paymentResponse != null && _paymentResponse!.success) {
      try {
        // Convert PaymentResult to Map for storage compatibility
        final paymentResponseMap = _paymentResponse!.data ?? {
          'status_code': _paymentResponse!.statusCode?.toString() ?? '200',
          'transaction_status': 'pending',
          'payment_type': widget.paymentDetails['methodName'],
          'order_id': widget.orderId,
          'transaction_time': DateTime.now().toIso8601String(),
          'gross_amount': widget.amountToPay.toString(), // Use amountToPay instead of total
        };

        // Add reservation-specific data if applicable
        if (widget.isReservation == true) {
          paymentResponseMap['is_reservation'] = true;
          paymentResponseMap['payment_type_enum'] = widget.paymentType?.toString() ?? PaymentType.fullPayment.toString();
          paymentResponseMap['is_down_payment'] = widget.isDownPayment;
          paymentResponseMap['remaining_payment'] = widget.remainingPayment;
          if (widget.downPaymentAmount != null) {
            paymentResponseMap['down_payment_amount'] = widget.downPaymentAmount!;
          }
        }

        await PaymentStorageService.savePaymentDetails(
          id: widget.id,
          orderId: widget.orderId,
          paymentResponse: paymentResponseMap,
          paymentDetails: widget.paymentDetails,
          subtotal: widget.subtotal,
          discount: widget.discount,
          total: widget.total,
          voucherCode: widget.voucherCode,
          items: widget.items,
          orderType: widget.orderType,
          tableNumber: widget.tableNumber ?? '',
          deliveryAddress: widget.deliveryAddress,
          pickupTime: widget.pickupTime,
        );
        print('Payment details saved successfully for order: ${widget.orderId}');

        // Log the saved payment response structure for debugging
        print('Saved payment response structure:');
        print('- Status Code: ${paymentResponseMap['status_code']}');
        print('- Transaction ID: ${paymentResponseMap['transaction_id']}');
        print('- Payment Type: ${paymentResponseMap['payment_type']}');
        print('- Transaction Status: ${paymentResponseMap['transaction_status']}');
        print('- Amount to Pay: ${widget.amountToPay}');

        if (widget.isReservation == true) {
          print('- Is Reservation: ${paymentResponseMap['is_reservation']}');
          print('- Payment Type Enum: ${paymentResponseMap['payment_type_enum']}');
          print('- Is Down Payment: ${paymentResponseMap['is_down_payment']}');
          print('- Remaining Payment: ${paymentResponseMap['remaining_payment']}');
        }

        if (paymentResponseMap.containsKey('va_numbers')) {
          print('- VA Numbers available: ${paymentResponseMap['va_numbers']}');
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
        print('Amount to Pay: ${widget.amountToPay}');
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

          if (widget.isReservation == true) {
            print('- Is Reservation: ${paymentResponse['is_reservation']}');
            print('- Is Down Payment: ${paymentResponse['is_down_payment']}');
            print('- Remaining Payment: ${paymentResponse['remaining_payment']}');
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

            // Save payment details to SharedPreferences
            await _savePaymentDetails();

            // Make sure we're connected to socket after order is sent
            _setupSocketConnection();
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
      }
    }
  }

  // Helper method to get payment response data as Map for widget compatibility
  Map<String, dynamic>? get _paymentResponseData {
    return _paymentResponse?.data;
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
            setState(() {
              _errorMessage = null;
            });
            if (_isCashPayment) {
              _handleCashPayment();
            } else {
              _hasSentOrder = false;
              _sendOrderOnce();
            }
          },
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
    );
  }
}