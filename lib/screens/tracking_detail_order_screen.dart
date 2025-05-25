import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../widgets/tracking_detail/coffee_animation_widget.dart';
import '../widgets/tracking_detail/order_detail_widget.dart';
import '../widgets/tracking_detail/status_section_widget.dart';

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

  // API Configuration
  static const String baseUrl = 'https://b59d-103-166-9-228.ngrok-free.app'; // Ganti dengan URL API Anda

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
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
      // print("ini adalah order id anda = ${widget.orderId}");

      final response = await http.get(
        Uri.parse('$baseUrl/api/order/${widget.orderId}'),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
          // Tambahkan authorization header jika diperlukan
          // 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));
// print("ini adalah response dari api = ${response.body}");
      if (response.statusCode == 200) {
        print(response);
        final jsonData = json.decode(response.body);
        setState(() {
          orderData = jsonData['orderData'];
          isLoading = false;
          _updateOrderStatus();
        });
      } else {
        throw Exception('Failed to load order: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = e.toString().contains('TimeoutException')
            ? 'Koneksi timeout. Silakan coba lagi.'
            : 'Gagal memuat data pesanan. Silakan coba lagi.';
      });
    }
  }

  void _updateOrderStatus() {
    if (orderData == null) return;

    // Update status berdasarkan data dari API
    final paymentStatus = orderData!['paymentStatus']?.toString().toLowerCase() ?? '';

    if (paymentStatus == 'lunas') {
      setState(() {
        orderStatus = 'Pesananmu sedang dibuat';
        statusColor = const Color(0xFFF59E0B);
        statusIcon = Icons.coffee_maker;
      });
    } else if (paymentStatus == 'menunggu') {
      setState(() {
        orderStatus = 'Menunggu pembayaran';
        statusColor = const Color(0xFFEF4444);
        statusIcon = Icons.payment;
      });
    } else {
      setState(() {
        orderStatus = 'Status tidak diketahui';
        statusColor = const Color(0xFF6B7280);
        statusIcon = Icons.help_outline;
      });
    }
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: const Text(
          'Tracking Detail',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.refresh, color: Colors.black87, size: 20),
              onPressed: isLoading ? null : _refreshData,
            ),
          ),
        ],
      ),
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