import 'package:baraja_app/widgets/utils/classic_app_bar.dart';
import 'package:flutter/material.dart';
import '../widgets/tracking_detail/coffee_animation_widget.dart';
import '../widgets/tracking_detail/order_detail_widget.dart';
import '../widgets/tracking_detail/status_section_widget.dart';
import '../services/order_service.dart';

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

  String orderStatus = 'Memuat pesanan...';
  Color statusColor = const Color(0xFFF59E0B);
  IconData statusIcon = Icons.coffee_maker;

  // State management
  Map<String, dynamic>? orderData;
  bool isLoading = true;
  String? errorMessage;

  // OrderService instance
  final OrderService _orderService = OrderService();

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _fetchOrderData();
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
    await _fetchOrderData();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
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

              // Subtle divider
              // Container(
              //   height: 8,
              //   color: Colors.grey[50],
              // ),

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
    );
  }
}