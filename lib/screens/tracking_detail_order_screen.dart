import 'package:baraja_app/screens/payment_detail_screen.dart';
import 'package:baraja_app/widgets/utils/classic_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/order.dart';
import '../providers/order_provider.dart';
import '../services/paymentStorageService.dart';
import '../services/socket_service.dart';
import '../widgets/tracking_detail/coffee_animation_widget.dart';
import '../widgets/tracking_detail/order_detail_widget.dart';
import '../widgets/tracking_detail/status_section_widget.dart';
import '../services/order_service.dart';
import 'menu_rating_screen.dart';

class TrackingDetailOrderScreen extends StatefulWidget {
  final String orderId;

  const TrackingDetailOrderScreen({
    super.key,
    required this.orderId,
  });

  @override
  State<TrackingDetailOrderScreen> createState() => _TrackingDetailOrderScreenState();
}

class _TrackingDetailOrderScreenState extends State<TrackingDetailOrderScreen>
    with TickerProviderStateMixin {

  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late AnimationController _slideController;

  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isListeningForPayment = false;
  Map<String, dynamic>? _paymentResponse;
  bool _hasPaymentDetails = false;

  String orderStatus = 'Memuat pesanan...';
  Color statusColor = const Color(0xFFF59E0B);
  IconData statusIcon = Icons.coffee_maker;

  // State management
  Map<String, dynamic>? orderData;
  bool isLoading = true;
  String? errorMessage;

  // OrderService instance
  final OrderService _orderService = OrderService();
  final SocketService _socketService = SocketService();

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _checkPaymentDetails();
    _fetchOrderData();
    // First setup socket connection
    _setupSocketConnection();
  }

  Future<void> _checkPaymentDetails() async {
    final hasDetails = await PaymentStorageService.hasPaymentDetails(widget.orderId);
    setState(() {
      _hasPaymentDetails = hasDetails;
    });
  }

  void _setupSocketConnection() {
    if (!_isListeningForPayment) {
      _isListeningForPayment = true;

      // Connect to socket and listen for payment updates
      _socketService.connectToSocket(
        orderId: widget.orderId,
        onPaymentUpdate: _handlePaymentUpdate,
      );

      // Add a delay before manually joining the room again
      Future.delayed(const Duration(seconds: 3), () {
        _socketService.joinOrderRoom(widget.orderId);
      });
    }
  }

  void _handlePaymentUpdate(Map<String, dynamic> data) {
    print('Payment update received in screen: $data');

    if (data['order_id'] == widget.orderId) {
      print('Payment update matches our order ID');

      if (mounted) {
        setState(() {
          // Update payment response
          _paymentResponse = {
            ...?_paymentResponse,
            'transaction_status': data['transaction_status'],
          };

          // Update order data payment status directly
          if (orderData != null) {
            orderData!['paymentStatus'] = data['transaction_status'];
            // Also update paymentDetails if it exists
            if (orderData!['paymentDetails'] != null) {
              orderData!['paymentDetails']['status'] = data['transaction_status'];
            }

            // Update order status based on payment status
            _updateOrderStatus();
          }
        });
      }

      print('Payment status updated to: ${data['transaction_status']}');

      // Update order status in provider based on transaction status
      if (data['transaction_status'] == 'settlement' ||
          data['transaction_status'] == 'capture') {
        if (mounted) {
          final orderProvider = Provider.of<OrderProvider>(context, listen: false);
          orderProvider.updateOrderStatus(widget.orderId, OrderStatus.pending);
        }
      }
    } else {
      print('Received payment update for different order: ${data['order_id']}');
    }
  }

  void _setupAnimations() {
    // Pulse animation for status
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    _pulseController.repeat(reverse: true);

    // Fade animation for content
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    // Slide animation for cards
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
  }

  Future<void> _fetchOrderData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      print('🔍 Fetching order data for ID: ${widget.orderId}');

      final result = await _orderService.getOrderForTracking(widget.orderId);

      print('📦 Raw result: $result');
      print('📦 Result success: ${result['success']}');
      print('📦 Result data: ${result['data']}');
      print('📦 Result error: ${result['error']}');

      if (result['success']) {
        final data = result['data'];

        print('📋 Order data keys: ${data?.keys}');
        if (data != null) {
          print('📋 Payment status: ${data['paymentDetails']?['status']}');
          print('📋 Order status: ${data['status']}');
          print('📋 Order items count: ${data['items']?.length}');
        }

        setState(() {
          orderData = data;
          isLoading = false;
          _updateOrderStatus();
        });

        // Start animations when data is loaded
        _fadeController.forward();
        _slideController.forward();
      } else {
        print('❌ Failed to fetch order: ${result['error']}');
        setState(() {
          isLoading = false;
          errorMessage = result['error'];
        });
      }
    } catch (e, stackTrace) {
      print('❌ Exception in _fetchOrderData: $e');
      print('❌ Stack trace: $stackTrace');
      setState(() {
        isLoading = false;
        errorMessage = 'Terjadi kesalahan: ${e.toString()}';
      });
    }
  }

  void _updateOrderStatus() {
    if (orderData == null) {
      print('⚠️ orderData is null in _updateOrderStatus');
      return;
    }

    try {
      print('🔄 Updating order status...');
      print('🔄 Order data before status update: $orderData');

      final statusInfo = _orderService.getOrderStatusInfo(orderData!);

      print('📊 Status info result: $statusInfo');

      setState(() {
        orderStatus = statusInfo['status'];
        statusColor = statusInfo['color'];
        statusIcon = statusInfo['icon'];
      });

      print('✅ Status updated successfully: $orderStatus');
    } catch (e, stackTrace) {
      print('❌ Error in _updateOrderStatus: $e');
      print('❌ Stack trace: $stackTrace');

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
    await _checkPaymentDetails();
    await _fetchOrderData();
  }

  void _navigateToPaymentDetails() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentDetailsScreen(orderId: widget.orderId),
      ),
    );
  }

  // Di tracking screen, saat navigasi ke rating:
  void _navigateToRating() {
    final firstItem = orderData?['items']?[0];
    print(firstItem);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MenuRatingPage(
          orderData: orderData,
          // Pass data eksplisit jika ada
          menuItemId: firstItem?['menuItemId'] ?? firstItem?['id'],
          orderId: orderData?['_id'] ?? orderData?['id'],
          // outletId: orderData?['outletId'] ?? orderData?['outlet_id'],
        ),
      ),
    );
  }

// Ganti method _shouldShowActionButton() dengan ini:
  bool _shouldShowActionButton() {
    print('🔍 _shouldShowActionButton called');
    print('🔍 _hasPaymentDetails: $_hasPaymentDetails');
    print('🔍 _isOrderCompleted(): ${_isOrderCompleted()}');

    // Jika order sudah completed, selalu tampilkan tombol rating
    if (_isOrderCompleted()) {
      print('✅ Order completed, showing rating button');
      return true;
    }

    // Untuk status lain, cek payment details
    if (!_hasPaymentDetails) {
      print('❌ No payment details, hiding button');
      return false;
    }

    final paymentStatus = orderData?['paymentStatus'] ??
        orderData?['paymentDetails']?['status'];

    print('🔍 Payment status: $paymentStatus');

    // Show button for any payment-related status
    bool shouldShow = paymentStatus == 'pending' ||
        paymentStatus == 'settlement' ||
        paymentStatus == 'capture' ||
        _hasPaymentDetails;

    print('🔍 Should show button: $shouldShow');
    return shouldShow;
  }

// Perbaiki method _isOrderCompleted() untuk konsistensi:
  bool _isOrderCompleted() {
    // Coba kedua kemungkinan nama field
    final orderStatus = orderData?['orderStatus'] ?? orderData?['status'];

    print('🔍 Checking order completion status: $orderStatus');
    print('🔍 Order data keys: ${orderData?.keys}');

    return orderStatus == 'Completed';
  }

  Widget _buildActionButton() {
    if (!_shouldShowActionButton()) return const SizedBox.shrink();

    final isOrderCompleted = _isOrderCompleted();

    if (isOrderCompleted) {
      // Show rating button
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: ElevatedButton(
          onPressed: _navigateToRating,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.star_rate_rounded, size: 20),
              SizedBox(width: 8),
              Text(
                'Kasih Rating Dong',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // Show payment button
      final paymentStatus = orderData?['paymentStatus'] ??
          orderData?['paymentDetails']?['status'];

      final isPending = paymentStatus == 'pending';
      final buttonColor = isPending ? Colors.orange : Colors.blue;
      final buttonText = isPending ? 'Bayar Sekarang' : 'Lihat Detail Pembayaran';
      final buttonIcon = isPending ? Icons.payment : Icons.receipt_long;

      return Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: ElevatedButton(
          onPressed: _navigateToPaymentDetails,
          style: ElevatedButton.styleFrom(
            backgroundColor: buttonColor,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(buttonIcon, size: 20),
              const SizedBox(width: 8),
              Text(
                buttonText,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _socketService.dispose();
    super.dispose();
  }

  Widget _buildLoadingState() {
    return Container(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Minimal loading indicator
            Stack(
              alignment: Alignment.center,
              children: [
                // Subtle outer glow
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: statusColor.withOpacity(0.05),
                  ),
                ),
                // Loading indicator
                SizedBox(
                  width: 50,
                  height: 50,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                    backgroundColor: Colors.grey[100],
                  ),
                ),
                // Center icon
                Icon(
                  Icons.coffee_rounded,
                  color: statusColor,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 32),
            Text(
              'Memuat data pesanan...',
              style: TextStyle(
                color: Colors.grey[800],
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Mohon tunggu sebentar',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      color: Colors.white,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Minimal error icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  size: 36,
                  color: Colors.red[400],
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Gagal Memuat Data',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                errorMessage ?? 'Terjadi kesalahan yang tidak diketahui',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              // Clean retry button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _refreshData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: statusColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.refresh_rounded, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Coba Lagi',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const ClassicAppBar(title: 'Detail Pesanan'),
      body: isLoading
          ? _buildLoadingState()
          : errorMessage != null
          ? _buildErrorState()
          : FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    // Coffee Animation Section - Full width immersive
                    SlideTransition(
                      position: _slideAnimation,
                      child: Container(
                        width: double.infinity,
                        color: Colors.white,
                        child: const CoffeeAnimationWidget(),
                      ),
                    ),

                    // Status Section - Full width with top spacing
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
                        ),
                      ),
                    ),

                    // Order Details - Full width
                    if (orderData != null)
                      SlideTransition(
                        position: _slideAnimation,
                        child: Container(
                          width: double.infinity,
                          color: Colors.white,
                          child: OrderDetailWidget(orderData: orderData!),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Action Button - Fixed at bottom (Payment or Rating)
            _buildActionButton(),
          ],
        ),
      ),
    );
  }
}