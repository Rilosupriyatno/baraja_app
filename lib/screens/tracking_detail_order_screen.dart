import 'package:baraja_app/screens/payment_detail_screen.dart';
import 'package:baraja_app/services/rating_service.dart';
import 'package:baraja_app/utils/base_screen_wrapper.dart';
import 'package:baraja_app/widgets/utils/classic_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/order.dart';
import '../providers/order_provider.dart';
import '../services/socket_service.dart';
import '../widgets/tracking_detail/coffee_animation_widget.dart';
import '../widgets/tracking_detail/order_detail_widget.dart';
import '../widgets/tracking_detail/order_type_section_widget.dart';
import '../widgets/tracking_detail/status_section_widget.dart';
import '../widgets/tracking_detail/action_button_widget.dart';
import '../widgets/tracking_detail/rating_display_widget.dart';
import '../widgets/tracking_detail/reservation_section_widget.dart';
import '../widgets/tracking_detail/tracking_states_widget.dart';
import '../services/order_service.dart';
import 'final_payment_screen.dart';
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
  final bool _hasPaymentDetails = false;
  String orderStatus = 'Memuat pesanan...';
  Color statusColor = const Color(0xFFF59E0B);
  IconData statusIcon = Icons.coffee_maker;

  Map<String, dynamic>? orderData;
  Map<String, dynamic>? existingRating;
  bool isLoading = true;
  bool isLoadingRating = false;
  bool isRefreshing = false; // 🔄 Tambahan untuk refresh state
  String? errorMessage;

  // ✅ TAMBAHAN: Variable untuk menyimpan orderId
  String? orderId;

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
    // ✅ PERBAIKAN: Fetch order data dulu untuk mendapatkan orderId
    await _fetchOrderData();
    // await _checkPaymentDetails();
    _setupSocketConnection();
  }

  // ✅ MODIFIKASI: _fetchOrderData untuk menyimpan orderId
  Future<void> _fetchOrderData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      print('=== FETCH ORDER DATA ===');
      print('🔍 Request ID: ${widget.id}');

      final result = await _orderService.getOrderForTracking(widget.id);

      print('📦 API Result: $result');

      if (result['success']) {
        final data = result['data'];

        // ✅ EXTRACT dan SIMPAN orderId dari berbagai kemungkinan field
        orderId =
            data['orderId']?.toString() ??
                data['order_id']?.toString() ??
                widget.id; // fallback ke widget.id

        print('=== ORDER DATA EXTRACTED ===');
        print('📄 Raw Data: $data');
        print('🆔 Extracted orderId: $orderId');
        print('📊 Payment Status: ${data['paymentStatus']}');
        print('📋 Order Status: ${data['orderStatus']}');

        setState(() {
          orderData = data;
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
      print('❌ Error in _fetchOrderData: $e');
      setState(() {
        isLoading = false;
        errorMessage = 'Terjadi kesalahan: ${e.toString()}';
      });
    }
  }

  void _navigateToFinalPayment() async {
    final paymentDetails = orderData?['paymentDetails'] as Map<String, dynamic>?;
    final remainingAmount = paymentDetails?['remainingAmount'] ?? 0;

    if (remainingAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak ada sisa pembayaran'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Navigate to final payment selection screen
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FinalPaymentScreen(
          orderId: getOrderId(),
          remainingAmount: remainingAmount,
          orderNumber: orderData?['orderNumber'] ?? 'N/A',
        ),
      ),
    );

    // Refresh data jika payment berhasil
    if (result == true) {
      _refreshData();
    }
  }

  // ✅ MODIFIKASI: _checkPaymentDetails menggunakan orderId yang sudah disimpan
  // Future<void> _checkPaymentDetails() async {
  //   // ✅ Skip jika orderId belum tersedia
  //   if (orderId == null) {
  //     print('⚠️ orderId is null, skipping payment check');
  //     _hasPaymentDetails = false;
  //     return;
  //   }
  //
  //   try {
  //     print('=== DEBUG PAYMENT CHECK ===');
  //     print('🔍 Using orderId: $orderId');
  //     print('🔍 Original widget.id: ${widget.id}');
  //
  //     // ✅ GUNAKAN orderId yang sudah disimpan
  //     final result = await ConfirmService().getPayment(orderId!);
  //
  //     print('API Result success: ${result.success}');
  //     print('API Result data: ${result.data}');
  //
  //     if (result.success && result.data != null) {
  //       final paymentStatus = result.data!['status'];
  //       print('Payment Status from API: $paymentStatus');
  //
  //       _hasPaymentDetails = paymentStatus == 'pending' ||
  //           paymentStatus == 'settlement' ||
  //           paymentStatus == 'partial' ||
  //           paymentStatus == 'expire' ||
  //           paymentStatus == 'cancel' ||
  //           paymentStatus == 'capture';
  //
  //       print('_hasPaymentDetails set to: $_hasPaymentDetails');
  //     } else {
  //       print('API call failed or data is null');
  //       print('Error: ${result.error}');
  //       _hasPaymentDetails = false;
  //     }
  //   } catch (e) {
  //     print('Error in _checkPaymentDetails: $e');
  //     _hasPaymentDetails = false;
  //   }
  //
  //   // ✅ Update state setelah payment check selesai
  //   if (mounted) setState(() {});
  // }

  Future<void> _checkExistingRating() async {
    if (orderData?['items']?.isEmpty ?? true) return;

    setState(() => isLoadingRating = true);

    try {
      final firstItem = orderData!['items'][0] as Map<String, dynamic>;
      final menuItemId = firstItem['menuItemId']?.toString() ??
          firstItem['id']?.toString() ??
          firstItem['menu_item_id']?.toString();

      // ✅ GUNAKAN orderId yang sudah disimpan
      final orderIdForRating = orderId ?? widget.id;

      if (menuItemId != null) {
        final rating = await RatingService.getExistingRating(
          menuItemId: menuItemId,
          id: orderIdForRating,
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
    final socketId = orderId ?? widget.id;

    _socketService.connectToSocket(
      id: socketId,
      onPaymentUpdate: _handlePaymentUpdate,
      onOrderUpdate: _handleOrderUpdate, // ✅ handler baru
    );

    Future.delayed(const Duration(seconds: 3), () => _socketService.joinOrderRoom(socketId));
  }

  void _handleOrderUpdate(Map<String, dynamic> data) {
    final targetOrderId = orderId ?? widget.id;
    if (data['order_id'].toString() != targetOrderId.toString() || !mounted) return;

    print('🔔 Order update diterima: $data');

    setState(() {
      if (orderData != null) {
        // ✅ gunakan orderStatus dari socket, fallback ke status kalau ada API lama
        orderData!['orderStatus'] = data['orderStatus'] ?? data['status'];
        orderData!['paymentStatus'] = data['paymentStatus'] ?? orderData!['paymentStatus'];
        _updateOrderStatus();
      }
    });
  }

  void _handlePaymentUpdate(Map<String, dynamic> data) {
    final targetOrderId = orderId ?? widget.id;
    if (data['order_id'] != targetOrderId || !mounted) return;

    setState(() {
      if (orderData != null) {
        orderData!['paymentStatus'] = data['transaction_status'];
        orderData!['paymentDetails']?['orderStatus'] = data['transaction_status'];
        _updateOrderStatus();
      }
    });

    if (['settlement', 'capture'].contains(data['transaction_status'])) {
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      orderProvider.updateOrderStatus(targetOrderId, OrderStatus.pending);
    }
  }

  void _updateOrderStatus() {
    if (orderData == null) return;

    try {
      final paymentStatus = orderData!['paymentStatus'] ?? '';
      final orderStatusValue = orderData!['orderStatus'] ?? '';

      String finalStatus;
      Color finalColor;
      IconData finalIcon;

      // Prioritize order status if payment is successful
      if (paymentStatus == 'settlement' || paymentStatus == 'capture') {
        // Payment successful, show order status
        switch (orderStatusValue) {
          case 'Pending':
            finalStatus = 'Menunggu konfirmasi kasir';
            finalColor = const Color(0xFFF68F3B);
            finalIcon = Icons.alarm_outlined;
            break;
          case 'Waiting':
            finalStatus = 'Menunggu konfirmasi kitchen';
            finalColor = const Color(0xFF3B82F6);
            finalIcon = Icons.restaurant_menu;
            break;
          case 'OnProcess':
            finalStatus = 'Pesananmu sedang dibuat';
            finalColor = const Color(0xFFF59E0B);
            finalIcon = Icons.coffee_maker;
            break;
          case 'Ready':
            finalStatus = 'Pesanan siap diambil';
            finalColor = const Color(0xFF10B981);
            finalIcon = Icons.check_circle;
            break;
          case 'OnTheWay':
            finalStatus = 'Pesanan dalam perjalanan';
            finalColor = const Color(0xFF8B5CF6);
            finalIcon = Icons.local_shipping;
            break;
          case 'Completed':
            finalStatus = 'Selamat Menikmati';
            finalColor = const Color(0xFF10B981);
            finalIcon = Icons.done_all;
            break;
          case 'Canceled':
          case 'Cancelled':
            finalStatus = 'Pesanan dibatalkan';
            finalColor = const Color(0xFFEF4444);
            finalIcon = Icons.cancel;
            break;
          default:
            finalStatus = 'Status: $orderStatusValue';
            finalColor = const Color(0xFFF68F3B);
            finalIcon = Icons.info_outline;
            break;
        }
      } else {
        // Payment not successful, show payment status
        switch (paymentStatus) {
          case 'pending':
            finalStatus = 'Menunggu Pembayaran';
            finalColor = const Color(0xFFF59E0B);
            finalIcon = Icons.access_time;
            break;
          case 'partial':
            finalStatus = 'Menunggu Pelunasan';
            finalColor = const Color(0xFFF59E0B);
            finalIcon = Icons.access_time;
            break;
          case 'expire':
            finalStatus = 'Pembayaran Kadaluarsa';
            finalColor = const Color(0xFFEF4444);
            finalIcon = Icons.timer_off;
            break;
          case 'cancel':
            finalStatus = 'Pesanan Dibatalkan';
            finalColor = const Color(0xFFEF4444);
            finalIcon = Icons.cancel;
            break;
          default:
            finalStatus = 'Status pembayaran: $paymentStatus';
            finalColor = const Color(0xFF6B7280);
            finalIcon = Icons.help_outline;
            break;
        }
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

  // 🔄 ENHANCED: Method refresh dengan feedback visual
  Future<void> _refreshData() async {
    if (isRefreshing) return; // Prevent multiple refresh calls

    setState(() => isRefreshing = true);

    try {
      // Reset animations
      _fadeController.reset();
      _slideController.reset();

      // Show loading feedback
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Memperbarui data pesanan...'),
          duration: Duration(seconds: 1),
          backgroundColor: Colors.blue,
        ),
      );

      // Refresh all data
      await _initializeData();

      // Show success feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data berhasil diperbarui'),
            duration: Duration(seconds: 1),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Show error feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memperbarui data: ${e.toString()}'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isRefreshing = false);
      }
    }
  }

  // 🔄 BARU: Pull-to-refresh handler
  Future<void> _handleRefresh() async {
    await _refreshData();
  }

  void _navigateToPaymentDetails() {
    // ✅ GUNAKAN orderId jika tersedia
    final paymentId = orderId ?? widget.id;
    print('🔗 Navigating to payment with ID: $paymentId');

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PaymentDetailScreen(id: paymentId)),
    );
  }

  void _navigateToRating() async {
    final firstItem = orderData?['items']?[0];
    final ratingId = orderId ?? widget.id;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MenuRatingPage(
          orderData: orderData,
          menuItemId: firstItem?['menuItemId'] ?? firstItem?['id'],
          id: ratingId, // ✅ GUNAKAN orderId
        ),
      ),
    );

    if (result == true) _refreshData();
  }

  // ✅ HELPER METHOD: Mendapatkan orderId dengan fallback
  String getOrderId() {
    return orderId ?? widget.id;
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
    return BaseScreenWrapper(
      canPop: false,
      customBackRoute: '/history',
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: ClassicAppBar(
          title: 'Detail Pesanan',
          customBackRoute: '/history',
          // 🔄 TAMBAHAN: Refresh button di AppBar
          actions: [
            IconButton(
              onPressed: isRefreshing ? null : _refreshData,
              icon: isRefreshing
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
                  : const Icon(Icons.refresh, color: Colors.white),
              tooltip: 'Refresh',
            ),
          ],
        ),
        body: isLoading
            ? TrackingStatesWidget.buildLoadingState(statusColor: statusColor)
            : errorMessage != null
            ? TrackingStatesWidget.buildErrorState(
          errorMessage: errorMessage,
          statusColor: statusColor,
          onRetry: _refreshData,
        )
            : RefreshIndicator(
          // 🔄 TAMBAHAN: Pull-to-refresh wrapper
          onRefresh: _handleRefresh,
          color: statusColor,
          backgroundColor: Colors.white,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(), // Allows pull-to-refresh
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
                              orderData: orderData,
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
                        // OrderType Section detail
                        if (orderData != null)
                          SlideTransition(
                            position: _slideAnimation,
                            child: OrderTypeSectionWidget(orderData: orderData!),
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
                  onNavigateToFinalPayment: _navigateToFinalPayment,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}