import 'package:baraja_app/screens/payment_detail_screen.dart';
import 'package:baraja_app/services/rating_service.dart';
import 'package:baraja_app/widgets/utils/classic_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/order.dart';
import '../providers/order_provider.dart';
import '../services/confirm_service.dart';
import '../services/socket_service.dart';
import '../widgets/tracking_detail/coffee_animation_widget.dart';
import '../widgets/tracking_detail/order_detail_widget.dart';
import '../widgets/tracking_detail/status_section_widget.dart';
import '../widgets/tracking_detail/action_button_widget.dart';
import '../widgets/tracking_detail/rating_display_widget.dart';
import '../widgets/tracking_detail/reservation_section_widget.dart';
import '../widgets/tracking_detail/tracking_states_widget.dart';
import '../services/order_service.dart';
import 'menu_rating_screen.dart';

class TrackingDetailOrderScreen extends StatefulWidget {
  final String id;
  const TrackingDetailOrderScreen({super.key, required this.id});

  @override
  State<TrackingDetailOrderScreen> createState() => _TrackingDetailOrderScreenState();
}

class _TrackingDetailOrderScreenState extends State<TrackingDetailOrderScreen>
    with TickerProviderStateMixin {

  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // State variables
  bool _isListeningForPayment = false;
  bool _hasPaymentDetails = false;
  String orderStatus = 'Memuat pesanan...';
  Color statusColor = const Color(0xFFF59E0B);
  IconData statusIcon = Icons.coffee_maker;

  Map<String, dynamic>? orderData;
  Map<String, dynamic>? existingRating;
  bool isLoading = true;
  bool isLoadingRating = false;
  String? errorMessage;

  final OrderService _orderService = OrderService();
  final SocketService _socketService = SocketService();

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeData();
  }

  void _setupAnimations() {
    _pulseController = AnimationController(duration: const Duration(seconds: 2), vsync: this);
    _fadeController = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);
    _slideController = AnimationController(duration: const Duration(milliseconds: 600), vsync: this);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _pulseController.repeat(reverse: true);
  }

  Future<void> _initializeData() async {
    await _checkPaymentDetails();
    await _fetchOrderData();
    _setupSocketConnection();
  }

  Future<void> _checkPaymentDetails() async {
    try {
      final result = await ConfirmService().getPayment(widget.id);
      print('ini adalah widget.id: ${widget.id}');
      print('Result: $result');

      if (result.success && result.data != null) {
        final paymentStatus = result.data!['status'];

        // Update logic to handle all payment statuses properly
        _hasPaymentDetails = paymentStatus == 'pending' ||
            paymentStatus == 'settlement' ||
            paymentStatus == 'expire' ||
            paymentStatus == 'cancel' ||
            paymentStatus == 'capture';

        print('Payment status: $paymentStatus');
        print('Has payment details: $_hasPaymentDetails');
      } else {
        _hasPaymentDetails = false;
      }

      if (mounted) setState(() {});
    } catch (e) {
      print('Error saat mengecek payment: $e');
      _hasPaymentDetails = false;
      if (mounted) setState(() {});
    }
  }


  Future<void> _fetchOrderData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await _orderService.getOrderForTracking(widget.id);

      if (result['success']) {
        setState(() {
          orderData = result['data'];
          isLoading = false;
          _updateOrderStatus();
        });

        _fadeController.forward();
        _slideController.forward();
        _checkExistingRating();
      } else {
        setState(() {
          isLoading = false;
          errorMessage = result['error'];
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Terjadi kesalahan: ${e.toString()}';
      });
    }
  }

  Future<void> _checkExistingRating() async {
    if (orderData?['items']?.isEmpty ?? true) return;

    setState(() => isLoadingRating = true);

    try {
      final firstItem = orderData!['items'][0] as Map<String, dynamic>;
      final menuItemId = firstItem['menuItemId']?.toString() ??
          firstItem['id']?.toString() ??
          firstItem['menu_item_id']?.toString();

      final orderId = orderData!['_id']?.toString() ??
          orderData!['id']?.toString() ??
          widget.id;

      if (menuItemId != null) {
        final rating = await RatingService.getExistingRating(
          menuItemId: menuItemId,
          id: orderId,
        );

        if (mounted) {
          setState(() {
            existingRating = rating;
            isLoadingRating = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => isLoadingRating = false);
    }
  }

  void _setupSocketConnection() {
    if (_isListeningForPayment) return;

    _isListeningForPayment = true;
    _socketService.connectToSocket(id: widget.id, onPaymentUpdate: _handlePaymentUpdate);
    Future.delayed(const Duration(seconds: 3), () => _socketService.joinOrderRoom(widget.id));
  }

  void _handlePaymentUpdate(Map<String, dynamic> data) {
    if (data['order_id'] != widget.id || !mounted) return;

    setState(() {
      if (orderData != null) {
        orderData!['paymentStatus'] = data['transaction_status'];
        orderData!['paymentDetails']?['status'] = data['transaction_status'];
        _updateOrderStatus();
      }
    });

    if (['settlement', 'capture'].contains(data['transaction_status'])) {
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      orderProvider.updateOrderStatus(widget.id, OrderStatus.pending);
    }
  }

  void _updateOrderStatus() {
    if (orderData == null) return;

    try {
      final statusInfo = _orderService.getOrderStatusInfo(orderData!);
      final paymentStatus = orderData!['paymentStatus'] ?? '';

      // Override status based on payment status for better UX
      String finalStatus = statusInfo['status'];
      Color finalColor = statusInfo['color'];
      IconData finalIcon = statusInfo['icon'];

      switch (paymentStatus) {
        case 'expire':
          finalStatus = 'Pembayaran Kadaluarsa';
          finalColor = Colors.red;
          finalIcon = Icons.timer_off;
          break;
        case 'pending':
          finalStatus = 'Menunggu Pembayaran';
          finalColor = Colors.orange;
          finalIcon = Icons.access_time;
          break;
        case 'cancel':
          finalStatus = 'Pesanan Dibatalkan';
          finalColor = Colors.red;
          finalIcon = Icons.cancel;
          break;
        case 'settlement':
        case 'capture':
        // Use original order status for successful payments
          break;
        default:
        // Use original order status
          break;
      }

      setState(() {
        orderStatus = finalStatus;
        statusColor = finalColor;
        statusIcon = finalIcon;
      });
    } catch (e) {
      setState(() {
        orderStatus = 'Status tidak dapat dimuat';
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
      });
    }
  }

  Future<void> _refreshData() async {
    _fadeController.reset();
    _slideController.reset();
    await _initializeData();
  }

  void _navigateToPaymentDetails() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PaymentDetailsScreen(id: widget.id)),
    );
  }

  void _navigateToRating() async {
    final firstItem = orderData?['items']?[0];
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MenuRatingPage(
          orderData: orderData,
          menuItemId: firstItem?['menuItemId'] ?? firstItem?['id'],
          id: orderData?['_id'] ?? orderData?['id'],
        ),
      ),
    );

    if (result == true) _refreshData();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const ClassicAppBar(title: 'Detail Pesanan'),
      body: isLoading
          ? TrackingStatesWidget.buildLoadingState(statusColor: statusColor)
          : errorMessage != null
          ? TrackingStatesWidget.buildErrorState(
        errorMessage: errorMessage,
        statusColor: statusColor,
        onRetry: _refreshData,
      )
          : FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    // Coffee Animation
                    SlideTransition(
                      position: _slideAnimation,
                      child: Container(
                        width: double.infinity,
                        color: Colors.white,
                        child: const CoffeeAnimationWidget(),
                      ),
                    ),

                    // Status Section
                    SlideTransition(
                      position: _slideAnimation,
                      child: Container(
                        width: double.infinity,
                        color: Colors.white,
                        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                        child: StatusSectionWidget(
                          orderStatus: orderStatus,
                          statusColor: statusColor,
                          statusIcon: statusIcon,
                          pulseAnimation: _pulseAnimation,
                          orderData: orderData, // Add this line
                        ),
                      ),
                    ),

                    // Order Details
                    if (orderData != null)
                      SlideTransition(
                        position: _slideAnimation,
                        child: Container(
                          width: double.infinity,
                          color: Colors.white,
                          child: OrderDetailWidget(orderData: orderData!),
                        ),
                      ),

                    // Reservation Section
                    if (orderData != null && orderData!['reservation'] != null)
                      SlideTransition(
                        position: _slideAnimation,
                        child: ReservationSectionWidget(orderData: orderData!),
                      ),

                    // Rating Display
                    if (existingRating != null)
                      SlideTransition(
                        position: _slideAnimation,
                        child: RatingDisplayWidget(existingRating: existingRating!),
                      ),

                    // Rating Loading Indicator
                    if (isLoadingRating)
                      TrackingStatesWidget.buildRatingLoadingIndicator(statusColor: statusColor),
                  ],
                ),
              ),
            ),

            // Action Button - Fixed at bottom
            ActionButtonWidget(
              orderData: orderData,
              existingRating: existingRating,
              hasPaymentDetails: _hasPaymentDetails,
              isLoadingRating: isLoadingRating,
              onNavigateToPayment: _navigateToPaymentDetails,
              onNavigateToRating: _navigateToRating,
            ),
          ],
        ),
      ),
    );
  }
}