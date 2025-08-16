import 'package:baraja_app/widgets/utils/classic_app_bar.dart';
import 'package:flutter/material.dart';
import '../widgets/tracking_detail/coffee_animation_widget.dart';
import '../widgets/tracking_detail/order_detail_widget.dart';
import '../widgets/tracking_detail/status_section_widget.dart';
import '../services/order_service.dart'; // Import OrderService

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
  late Animation<double> _pulseAnimation;

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
  }

  Future<void> _fetchOrderData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await _orderService.getOrderForTracking(widget.orderId);

      if (result['success']) {
        setState(() {
          orderData = result['data'];
          isLoading = false;
          _updateOrderStatus();
        });
      } else {
        setState(() {
          isLoading = false;
          errorMessage = result['error'];
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Terjadi kesalahan yang tidak terduga.';
      });
    }
  }

  void _updateOrderStatus() {
    if (orderData == null) return;

    final statusInfo = _orderService.getOrderStatusInfo(orderData!);

    setState(() {
      orderStatus = statusInfo['status'];
      statusColor = statusInfo['color'];
      statusIcon = statusInfo['icon'];
    });
  }

  Future<void> _refreshData() async {
    await _fetchOrderData();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(statusColor),
          ),
          const SizedBox(height: 16),
          Text(
            'Memuat data pesanan...',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Gagal Memuat Data',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage ?? 'Terjadi kesalahan yang tidak diketahui',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _refreshData,
              style: ElevatedButton.styleFrom(
                backgroundColor: statusColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const ClassicAppBar(title: 'Detail Pesanan'),
      body: isLoading
          ? _buildLoadingState()
          : errorMessage != null
          ? _buildErrorState()
          : SingleChildScrollView(
        child: Column(
          children: [
            // Coffee Animation Section
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: CoffeeAnimationWidget(),
            ),

            const SizedBox(height: 16),

            // Status Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: StatusSectionWidget(
                orderStatus: orderStatus,
                statusColor: statusColor,
                statusIcon: statusIcon,
                pulseAnimation: _pulseAnimation,
              ),
            ),

            const SizedBox(height: 16),

            // Order Details - Full width
            if (orderData != null)
              OrderDetailWidget(orderData: orderData!),

            // Bottom padding for navigation bar
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}