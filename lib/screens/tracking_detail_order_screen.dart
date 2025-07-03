import 'package:baraja_app/screens/payment_detail_screen.dart';
import 'package:baraja_app/services/rating_service.dart';
import 'package:baraja_app/widgets/utils/classic_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/order.dart';
import '../providers/order_provider.dart';
import '../services/payment_storage_service.dart';
import '../services/socket_service.dart';
import '../widgets/tracking_detail/coffee_animation_widget.dart';
import '../widgets/tracking_detail/order_detail_widget.dart';
import '../widgets/tracking_detail/status_section_widget.dart';
import '../services/order_service.dart';
import 'menu_rating_screen.dart';
class TrackingDetailOrderScreen extends StatefulWidget {
  final String id;

  const TrackingDetailOrderScreen({
    super.key,
    required this.id,
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

  // Rating state
  Map<String, dynamic>? existingRating;
  bool isLoadingRating = false;

  // OrderService instance
  final OrderService _orderService = OrderService();
  final SocketService _socketService = SocketService();

  // Add your API base URL here
// Replace with your actual base URL


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
    final hasDetails = await PaymentStorageService.hasPaymentDetails(widget.id);
    print('🔍 Payment details check for order ${widget.id}: $hasDetails');
    setState(() {
      _hasPaymentDetails = hasDetails;
    });
  }

  // Perbaikan untuk method _fetchOrderData
  Future<void> _fetchOrderData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      print('🔍 Fetching order data for ID: ${widget.id}');

      final result = await _orderService.getOrderForTracking(widget.id);

      print('📦 Raw result: $result');

      if (result['success']) {
        final data = result['data'];

        setState(() {
          orderData = data;
          isLoading = false;
          _updateOrderStatus();
        });

        // PERBAIKAN: Panggil _checkExistingRating setelah setState selesai
        // dengan menggunakan Future.microtask untuk memastikan UI sudah terupdate
        Future.microtask(() async {
          await _checkExistingRating();
        });

        // Start animations when data is loaded
        _fadeController.forward();
        _slideController.forward();
      } else {
        setState(() {
          isLoading = false;
          errorMessage = result['error'];
        });
      }
    } catch (e) {
      print('❌ Exception in _fetchOrderData: $e');
      setState(() {
        isLoading = false;
        errorMessage = 'Terjadi kesalahan: ${e.toString()}';
      });
    }
  }

// Perbaikan untuk method _checkExistingRating
  Future<void> _checkExistingRating() async {
    print('🔍 Starting _checkExistingRating');

    if (orderData == null) {
      print('❌ orderData is null');
      return;
    }

    if (orderData!['items'] == null || orderData!['items'].isEmpty) {
      print('❌ No items in order');
      return;
    }

    setState(() {
      isLoadingRating = true;
    });

    try {
      final items = orderData!['items'] as List;
      final firstItem = items[0] as Map<String, dynamic>;

      // PERBAIKAN: Lebih robust dalam mengekstrak ID
      String? menuItemId;
      String? id;

      // Coba berbagai kemungkinan nama field untuk menuItemId
      menuItemId = firstItem['menuItemId']?.toString() ??
          firstItem['id']?.toString() ??
          firstItem['menu_item_id']?.toString();

      // Coba berbagai kemungkinan nama field untuk id
      id = orderData!['_id']?.toString() ??
          orderData!['id']?.toString() ??
          widget.id;

      print('🔍 MenuItemId: $menuItemId');
      print('🔍 OrderId: $id');
      print('🔍 First item structure: ${firstItem.keys}');
      print('🔍 Order data structure: ${orderData!.keys}');

      if (menuItemId != null) {
        print('🔍 Calling API with menuItemId: $menuItemId, id: $id');

        final rating = await RatingService.getExistingRating(
          menuItemId: menuItemId,
          id: id,
        );

        print('🔍 Rating result: $rating');

        if (mounted) {
          setState(() {
            existingRating = rating;
            isLoadingRating = false;
          });
        }
      } else {
        print('❌ Missing required IDs - menuItemId: $menuItemId, id: $id');
        if (mounted) {
          setState(() {
            isLoadingRating = false;
          });
        }
      }
    } catch (e, stackTrace) {
      print('❌ Error in _checkExistingRating: $e');
      print('❌ Stack trace: $stackTrace');

      if (mounted) {
        setState(() {
          isLoadingRating = false;
        });
      }
    }
  }
  // Tambahkan widget ini ke tracking_detail_order_screen.dart

  // Replace your existing _buildReservationSection() method with this fixed version:

  Widget _buildReservationSection() {
    if (orderData == null || orderData!['reservation'] == null) {
      return const SizedBox.shrink();
    }

    final reservation = orderData!['reservation'] as Map<String, dynamic>;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Add this to prevent overflow
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header reservasi
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.08),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.event_seat_rounded,
                    color: Colors.blue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min, // Add this
                    children: [
                      Text(
                        'Informasi Reservasi',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue[700],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        reservation['reservationCode'] ?? '-',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.blue[600],
                        ),
                      ),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getReservationStatusColor(reservation['status']).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _getReservationStatusColor(reservation['status']).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _getReservationStatusText(reservation['status']),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _getReservationStatusColor(reservation['status']),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Detail reservasi
          Flexible( // Wrap this in Flexible to prevent overflow
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min, // Add this
                children: [
                  // Tanggal dan waktu
                  _buildReservationDetailRow(
                    icon: Icons.calendar_today_rounded,
                    iconColor: Colors.orange,
                    title: 'Tanggal & Waktu',
                    value: '${reservation['reservationDate']} • ${reservation['reservationTime']}',
                  ),

                  const SizedBox(height: 16),

                  // Jumlah tamu
                  _buildReservationDetailRow(
                    icon: Icons.people_rounded,
                    iconColor: Colors.green,
                    title: 'Jumlah Tamu',
                    value: '${reservation['guestCount']} orang',
                  ),

                  const SizedBox(height: 16),

                  // Area
                  _buildReservationDetailRow(
                    icon: Icons.location_on_rounded,
                    iconColor: Colors.purple,
                    title: 'Area',
                    value: reservation['area']?['name'] ?? 'Area tidak tersedia',
                  ),

                  const SizedBox(height: 16),

                  // Tipe reservasi
                  _buildReservationDetailRow(
                    icon: Icons.bookmark_rounded,
                    iconColor: Colors.indigo,
                    title: 'Tipe Reservasi',
                    value: _getReservationTypeText(reservation['reservationType']),
                  ),

                  // Notes jika ada
                  if (reservation['notes'] != null && reservation['notes'].toString().isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildReservationDetailRow(
                      icon: Icons.note_rounded,
                      iconColor: Colors.amber,
                      title: 'Catatan',
                      value: reservation['notes'],
                    ),
                  ],

                  // Tables section
                  if (reservation['tables'] != null && (reservation['tables'] as List).isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Divider(height: 1, color: Colors.grey),
                    const SizedBox(height: 20),
                    _buildTablesSection(reservation['tables'] as List),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

// Also fix the _buildTablesSection method:
  Widget _buildTablesSection(List tables) {
    return Column(
      mainAxisSize: MainAxisSize.min, // Add this
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.table_restaurant_rounded,
                size: 16,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Meja yang Dipesan',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${tables.length} meja',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Grid meja - Fix the constraint issues
        ConstrainedBox(
          constraints: const BoxConstraints(
            maxHeight: 200, // Limit the height of the grid
          ),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.5,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: tables.length,
            itemBuilder: (context, index) {
              final table = tables[index] as Map<String, dynamic>;
              return _buildTableCard(table);
            },
          ),
        ),

        const SizedBox(height: 12),

        // Total kapasitas
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.green.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min, // Add this
            children: [
              const Icon(
                Icons.event_seat_rounded,
                size: 16,
                color: Colors.green,
              ),
              const SizedBox(width: 8),
              Text(
                'Total Kapasitas: ${_calculateTotalSeats(tables)} kursi',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReservationDetailRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            size: 16,
            color: iconColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTableCard(Map<String, dynamic> table) {
    final isAvailable = table['isAvailable'] ?? true;
    final isActive = table['isActive'] ?? true;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isAvailable && isActive
            ? Colors.green.withOpacity(0.05)
            : Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isAvailable && isActive
              ? Colors.green.withOpacity(0.2)
              : Colors.grey.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min, // Add this line
        children: [
          Flexible( // Wrap the Row in Flexible
            child: Row(
              children: [
                Icon(
                  Icons.table_restaurant_rounded,
                  size: 16,
                  color: isAvailable && isActive ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    table['tableNumber'] ?? 'Unknown',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isAvailable && isActive
                          ? Colors.green[700]
                          : Colors.grey[600],
                    ),
                    overflow: TextOverflow.ellipsis, // Add overflow handling
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Flexible( // Wrap the second Text in Flexible
            child: Text(
              '${table['seats'] ?? 0} kursi • ${_getTableTypeText(table['tableType'])}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              overflow: TextOverflow.ellipsis, // Add overflow handling
              maxLines: 1, // Limit to 1 line
            ),
          ),
        ],
      ),
    );
  }

// Helper methods
  Color _getReservationStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getReservationStatusText(String? status) {
    switch (status?.toLowerCase()) {
      case 'confirmed':
        return 'Dikonfirmasi';
      case 'pending':
        return 'Menunggu';
      case 'cancelled':
        return 'Dibatalkan';
      case 'completed':
        return 'Selesai';
      default:
        return 'Unknown';
    }
  }

  String _getReservationTypeText(String? type) {
    switch (type?.toLowerCase()) {
      case 'non-blocking':
        return 'Non-Blocking';
      case 'blocking':
        return 'Blocking';
      default:
        return type ?? 'Unknown';
    }
  }

  String _getTableTypeText(String? type) {
    switch (type?.toLowerCase()) {
      case 'regular':
        return 'Regular';
      case 'vip':
        return 'VIP';
      case 'outdoor':
        return 'Outdoor';
      default:
        return type ?? 'Regular';
    }
  }

  int _calculateTotalSeats(List tables) {
    return tables.fold(0, (total, table) {
      final seats = table['seats'] as int? ?? 0;
      return total + seats;
    });
  }

// Perbaikan untuk method _shouldShowActionButton dengan logging yang lebih baik
  bool _shouldShowActionButton() {
    print('🔍 === _shouldShowActionButton Debug ===');
    print('🔍 isLoadingRating: $isLoadingRating');
    print('🔍 existingRating: $existingRating');
    print('🔍 _hasRating(): ${_hasRating()}');
    print('🔍 _isOrderCompleted(): ${_isOrderCompleted()}');
    print('🔍 _hasPaymentDetails: $_hasPaymentDetails');

    if (orderData != null) {
      print('🔍 orderData keys: ${orderData!.keys}');
      print('🔍 orderStatus: ${orderData!['orderStatus']}');
      print('🔍 status: ${orderData!['status']}');
      print('🔍 paymentStatus: ${orderData!['paymentStatus']}');
      print('🔍 paymentDetails: ${orderData!['paymentDetails']}');
    }

    // Don't show button while loading rating
    if (isLoadingRating) {
      print('✅ Hiding button: Still loading rating');
      return false;
    }

    // If order is completed and user hasn't rated yet, show rating button
    if (_isOrderCompleted() && !_hasRating()) {
      print('✅ Showing rating button: Order completed, no rating');
      return true;
    }

    // If user has already rated, don't show rating button
    if (_hasRating()) {
      print('✅ Hiding button: Already has rating');
      return false;
    }

    // For other statuses, check payment details
    if (!_hasPaymentDetails) {
      print('✅ Hiding button: No payment details');
      return false;
    }

    final paymentStatus = orderData?['paymentStatus'] ??
        orderData?['paymentDetails']?['status'];

    print('🔍 Final payment status: $paymentStatus');

    // Show button for any payment-related status
    bool shouldShow = paymentStatus == 'pending' ||
        paymentStatus == 'settlement' ||
        paymentStatus == 'capture' ||
        _hasPaymentDetails;

    print('✅ Final decision - shouldShow: $shouldShow');
    print('🔍 =====================================');

    return shouldShow;
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

    if (data['order_id'] == widget.id) {
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
          orderProvider.updateOrderStatus(widget.id, OrderStatus.pending);
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
        builder: (context) => PaymentDetailsScreen(id: widget.id),
      ),
    );
  }

  // Di tracking screen, saat navigasi ke rating:
  void _navigateToRating() async {
    final firstItem = orderData?['items']?[0];
    print(firstItem);

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MenuRatingPage(
          orderData: orderData,
          // Pass data eksplisit jika ada
          menuItemId: firstItem?['menuItemId'] ?? firstItem?['id'],
          id: orderData?['_id'] ?? orderData?['id'],
          // outletId: orderData?['outletId'] ?? orderData?['outlet_id'],
        ),
      ),
    );

    // Refresh data setelah kembali dari rating screen
    if (result == true) {
      await _refreshData();
    }
  }

  // Check if user has already rated (from API)
  bool _hasRating() {
    return existingRating != null;
  }

  // Check if should show action button
  // bool _shouldShowActionButton() {
  //   print('🔍 _shouldShowActionButton called');
  //   print('🔍 _hasPaymentDetails: $_hasPaymentDetails');
  //   print('🔍 _isOrderCompleted(): ${_isOrderCompleted()}');
  //   print('🔍 _hasRating(): ${_hasRating()}');
  //   print('🔍 isLoadingRating: $isLoadingRating');
  //
  //   // Don't show button while loading rating
  //   if (isLoadingRating) {
  //     return false;
  //   }
  //
  //   // If order is completed and user hasn't rated yet, show rating button
  //   if (_isOrderCompleted() && !_hasRating()) {
  //     print('✅ Order completed but no rating, showing rating button');
  //     return true;
  //   }
  //
  //   // If user has already rated, don't show rating button
  //   if (_hasRating()) {
  //     print('✅ Already has rating, hiding rating button');
  //     return false;
  //   }
  //
  //   // For other statuses, check payment details
  //   if (!_hasPaymentDetails) {
  //     print('❌ No payment details, hiding button');
  //     return false;
  //   }
  //
  //   final paymentStatus = orderData?['paymentStatus'] ??
  //       orderData?['paymentDetails']?['status'];
  //
  //   print('🔍 Payment status: $paymentStatus');
  //
  //   // Show button for any payment-related status
  //   bool shouldShow = paymentStatus == 'pending' ||
  //       paymentStatus == 'settlement' ||
  //       paymentStatus == 'capture' ||
  //       _hasPaymentDetails;
  //
  //   print('🔍 Should show button: $shouldShow');
  //   return shouldShow;
  // }

  // Check if order is completed
  bool _isOrderCompleted() {
    // Try both possible field names
    final orderStatus = orderData?['orderStatus'] ?? orderData?['status'];

    print('🔍 Checking order completion status: $orderStatus');
    print('🔍 Order data keys: ${orderData?.keys}');

    return orderStatus == 'Completed';
  }

  // Widget to display existing rating
  Widget _buildRatingDisplay() {
    if (!_hasRating() || existingRating == null) return const SizedBox.shrink();

    final rating = (existingRating!['rating'] ?? 0).toDouble();
    final comment = existingRating!['comment'] ?? '';
    final ratingDate = existingRating!['createdAt'] ?? existingRating!['date'];

    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header rating
          Row(
            children: [
              const Icon(
                Icons.star_rounded,
                color: Colors.green,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Rating Anda',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Rating stars
          Row(
            children: List.generate(5, (index) {
              return Icon(
                index < rating ? Icons.star_rounded : Icons.star_border_rounded,
                color: Colors.amber,
                size: 28,
              );
            }),
          ),
          const SizedBox(height: 8),

          // Rating score
          Text(
            '${rating.toStringAsFixed(1)} dari 5',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),

          // Rating date if available
          if (ratingDate != null) ...[
            const SizedBox(height: 8),
            Text(
              'Diberikan pada: ${_formatDate(ratingDate)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],

          // Comment if available
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Komentar:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              comment,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
          ],

          // Thank you message
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.favorite_rounded,
                  color: Colors.green,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Terima kasih atas rating dan feedback Anda!',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.green[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to format date
  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  Widget _buildActionButton() {
    if (!_shouldShowActionButton()) return const SizedBox.shrink();

    final isOrderCompleted = _isOrderCompleted();

    if (isOrderCompleted && !_hasRating()) {
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
  // Update bagian build method di tracking_detail_order_screen.dart

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

                    // *** TAMBAHAN BARU: Reservation Section ***
                    if (orderData != null && orderData!['reservation'] != null)
                      SlideTransition(
                        position: _slideAnimation,
                        child: _buildReservationSection(),
                      ),

                    // Rating Display - Show rating if exists
                    if (_hasRating())
                      SlideTransition(
                        position: _slideAnimation,
                        child: _buildRatingDisplay(),
                      ),

                    // Loading indicator for rating check
                    if (isLoadingRating)
                      Container(
                        margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Mengecek rating...',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
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
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     backgroundColor: Colors.white,
  //     appBar: const ClassicAppBar(title: 'Detail Pesanan'),
  //     body: isLoading
  //         ? _buildLoadingState()
  //         : errorMessage != null
  //         ? _buildErrorState()
  //         : FadeTransition(
  //       opacity: _fadeAnimation,
  //       child: Column(
  //         children: [
  //           // Scrollable content
  //           Expanded(
  //             child: SingleChildScrollView(
  //               physics: const BouncingScrollPhysics(),
  //               child: Column(
  //                 children: [
  //                   // Coffee Animation Section - Full width immersive
  //                   SlideTransition(
  //                     position: _slideAnimation,
  //                     child: Container(
  //                       width: double.infinity,
  //                       color: Colors.white,
  //                       child: const CoffeeAnimationWidget(),
  //                     ),
  //                   ),
  //
  //                   // Status Section - Full width with top spacing
  //                   SlideTransition(
  //                     position: _slideAnimation,
  //                     child: Container(
  //                       width: double.infinity,
  //                       color: Colors.white,
  //                       padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
  //                       child: StatusSectionWidget(
  //                         orderStatus: orderStatus,
  //                         statusColor: statusColor,
  //                         statusIcon: statusIcon,
  //                         pulseAnimation: _pulseAnimation,
  //                       ),
  //                     ),
  //                   ),
  //
  //                   // Order Details - Full width
  //                   if (orderData != null)
  //                     SlideTransition(
  //                       position: _slideAnimation,
  //                       child: Container(
  //                         width: double.infinity,
  //                         color: Colors.white,
  //                         child: OrderDetailWidget(orderData: orderData!),
  //                       ),
  //                     ),
  //
  //                   // Rating Display - Show rating if exists
  //                   if (_hasRating())
  //                     SlideTransition(
  //                       position: _slideAnimation,
  //                       child: _buildRatingDisplay(),
  //                     ),
  //
  //                   // Loading indicator for rating check
  //                   if (isLoadingRating)
  //                     Container(
  //                       margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
  //                       padding: const EdgeInsets.all(20),
  //                       child: Row(
  //                         mainAxisAlignment: MainAxisAlignment.center,
  //                         children: [
  //                           SizedBox(
  //                             width: 16,
  //                             height: 16,
  //                             child: CircularProgressIndicator(
  //                               strokeWidth: 2,
  //                               valueColor: AlwaysStoppedAnimation<Color>(statusColor),
  //                             ),
  //                           ),
  //                           const SizedBox(width: 12),
  //                           Text(
  //                             'Mengecek rating...',
  //                             style: TextStyle(
  //                               fontSize: 14,
  //                               color: Colors.grey[600],
  //                             ),
  //                           ),
  //                         ],
  //                       ),
  //                     ),
  //                 ],
  //               ),
  //             ),
  //           ),
  //
  //           // Action Button - Fixed at bottom (Payment or Rating)
  //           _buildActionButton(),
  //         ],
  //       ),
  //     ),
  //   );
  // }
}