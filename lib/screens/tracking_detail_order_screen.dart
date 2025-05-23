import 'package:flutter/material.dart';
import '../widgets/tracking_detail/coffee_animation_widget.dart';
import '../widgets/tracking_detail/order_detail_widget.dart';
import '../widgets/tracking_detail/status_section_widget.dart';

class TrackingDetailOrderScreen extends StatefulWidget {
  const TrackingDetailOrderScreen({super.key});

  @override
  State<TrackingDetailOrderScreen> createState() => _TrackingDetailOrderScreenState();
}

class _TrackingDetailOrderScreenState extends State<TrackingDetailOrderScreen>
    with TickerProviderStateMixin {

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  String orderStatus = 'Pesananmu sedang dibuat';
  Color statusColor = const Color(0xFFF59E0B);
  IconData statusIcon = Icons.coffee_maker;

  // Order data
  final Map<String, dynamic> orderData = {
    'orderId': 'ORD-2024-001234',
    'orderNumber': '#1234',
    'orderDate': '22 Mei 2025, 14:30',
    'items': [
      {
        'name': 'Americano',
        'price': 12000,
        'quantity': 1,
        'size': 'Regular',
        'temperature': 'Hot',
        'addons': ['Extra Shot', 'Oat Milk'],
        'toppings': ['Cinnamon Powder'],
      }
    ],
    'subtotal': 12000,
    'addonPrice': 8000,
    'tax': 2000,
    'total': 22000,
    'paymentMethod': 'BCA',
    'paymentStatus': 'Lunas',
  };

  @override
  void initState() {
    super.initState();
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

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
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
              onPressed: () {
                // Refresh tracking
              },
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
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
            OrderDetailWidget(orderData: orderData),

            // Bottom padding for navigation bar
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}