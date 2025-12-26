import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/gro_service.dart';
import '../models/reservation_data.dart';
import '../screens/menu_screen.dart';
import '../widgets/gro/gro_order_detail_widget.dart';
import '../screens/gro_final_payment_screen.dart';

class GroUnifiedOrderDetailSheet extends StatefulWidget {
  final String id;
  final bool isReservation;

  const GroUnifiedOrderDetailSheet({
    super.key,
    required this.id,
    required this.isReservation,
  });

  @override
  State<GroUnifiedOrderDetailSheet> createState() =>
      _GroUnifiedOrderDetailSheetState();
}

class _GroUnifiedOrderDetailSheetState
    extends State<GroUnifiedOrderDetailSheet> {
  final GROService _groService = GROService();
  Map<String, dynamic>? _data;
  Map<String, dynamic>? _orderDetail;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (widget.isReservation) {
        final result = await _groService.getReservationDetail(widget.id);
        if (!mounted) return;

        if (result['success']) {
          setState(() {
            _data = result['data'];
          });

          // ✅ PERBAIKAN: Handle order_id dengan benar
          final orderData = _data!['order_id'];
          if (orderData != null) {
            String? orderId;

            if (orderData is Map<String, dynamic>) {
              // Jika order_id adalah object populated, ambil _id-nya (ObjectId)
              orderId = orderData['_id']?.toString();
            } else if (orderData is String) {
              // Jika order_id adalah string ObjectId, gunakan langsung
              orderId = orderData;
            }

            if (orderId != null && orderId.isNotEmpty) {
              await _loadOrderDetail(orderId);
            }
          }
        } else {
          _errorMessage = result['error'];
        }
      } else {
        // Dine-in order - tetap sama
        final result = await _groService.getOrderDetailWithPayment(widget.id);
        if (!mounted) return;

        if (result['success'] && result['data'] is Map<String, dynamic>) {
          setState(() {
            _data = result['data'];
            _orderDetail = result['data'];
          });
        } else {
          _errorMessage = result['error'] ?? 'Gagal memuat data';
        }
      }
    } catch (e) {
      if (!mounted) return;
      _errorMessage = 'Error: $e';
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadOrderDetail(String orderId) async {
    try {
      final result = await _groService.getOrderDetailWithPayment(orderId);
      if (!mounted) return;

      if (result['success'] == true && result['data'] is Map<String, dynamic>) {
        setState(() {
          _orderDetail = result['data'];
        });
      } else {
        print('Failed to load order detail: ${result['error']}');
      }
    } catch (e) {
      print('Error loading order detail: $e');
    }
  }

  void _handleAddOrder() {
    if (_data == null) return;

    OpenBillData? openBillData;

    if (widget.isReservation) {
      final tables = _data!['table_id'] as List<dynamic>? ?? [];
      final tableNumbers = tables
          .map((t) => t['table_number']?.toString() ?? '')
          .where((n) => n.isNotEmpty)
          .join(', ');

      final area = _data!['area_id'];
      final areaId = area?['_id']?.toString() ?? '';
      final areaCode = area?['area_code']?.toString() ?? '';

      final orderData = _data!['order_id'];
      String? orderId;

      // ✅ PERBAIKAN: Ambil _id dari object order
      if (orderData is Map<String, dynamic>) {
        orderId = orderData['_id']?.toString();
      } else if (orderData is String) {
        orderId = orderData;
      }

      orderId ??= widget.id;

      DateTime reservationDate = DateTime.now();
      try {
        final dateStr = _data!['reservation_date'];
        if (dateStr != null) reservationDate = DateTime.parse(dateStr);
      // ignore: empty_catches
      } catch (e) {}

      TimeOfDay reservationTime = TimeOfDay.now();
      try {
        final timeStr = _data!['reservation_time'];
        if (timeStr != null && timeStr.toString().contains(':')) {
          final parts = timeStr.toString().split(':');
          reservationTime = TimeOfDay(
            hour: int.parse(parts[0]),
            minute: int.parse(parts[1]),
          );
        }
      // ignore: empty_catches
      } catch (e) {}

      openBillData = OpenBillData(
        reservationId: orderId,
        date: reservationDate,
        time: reservationTime,
        areaId: areaId,
        areaCode: areaCode,
        tableId: tables.isNotEmpty ? tables[0]['_id']?.toString() ?? '' : '',
        tableNumbers: tableNumbers,
      );
    } else {
      // Dine-in order - tetap sama
      final tableNumber = _data!['tableNumber']?.toString() ?? '';
      final orderId = _data!['orderId']?.toString() ??
          _data!['order_id']?.toString() ??
          widget.id;

      openBillData = OpenBillData(
        reservationId: orderId,
        date: DateTime.now(),
        time: TimeOfDay.now(),
        areaId: '',
        areaCode: 'Dine-in',
        tableId: '',
        tableNumbers: tableNumber,
      );
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MenuScreen(
          isOpenBill: true,
          openBillData: openBillData!,
          isGroMode: true, // ✅ PERBAIKAN: Tambahkan isGroMode
        ),
      ),
    ).then((_) {
      _loadData();
    });
  }

  bool _canAddOrder() {
    if (widget.isReservation) {
      if (_data == null) return false;

      final reservationStatus = (_data!['status'] as String?)?.toLowerCase();
      final hasOrder = _data!['order_id'] != null;

      // Reservasi TANPA order -> bisa buat order pertama
      if (!hasOrder) {
        return reservationStatus == 'pending' || reservationStatus == 'confirmed';
      }

      // Reservasi DENGAN order
      if (_orderDetail != null) {
        final orderStatus = (_orderDetail!['orderStatus'] ??
            _orderDetail!['order_status'])?.toString().toLowerCase();
        final paymentStatus = (_orderDetail!['paymentStatus'] ??
            _orderDetail!['payment_status'])?.toString().toLowerCase();

        final allowedReservationStatus = ['pending', 'confirmed'];
        final allowedOrderStatus = ['pending', 'waiting', 'reserved', 'onprocess'];
        final blockedPaymentStatus = ['paid']; // Hanya 'paid' yang memblokir

        return allowedReservationStatus.contains(reservationStatus) &&
            allowedOrderStatus.contains(orderStatus) &&
            !blockedPaymentStatus.contains(paymentStatus);
      }

      return false; // Jika orderDetail masih loading
    } else {
      // Dine-In Order
      if (_orderDetail == null) return false;

      final orderStatus = (_orderDetail!['orderStatus'] ??
          _orderDetail!['order_status'])?.toString().toLowerCase();
      final paymentStatus = (_orderDetail!['paymentStatus'] ??
          _orderDetail!['payment_status'])?.toString().toLowerCase();

      final allowedOrderStatus = ['pending', 'waiting', 'reserved', 'onprocess'];
      final blockedPaymentStatus = ['paid']; // Hanya 'paid' yang memblokir

      return allowedOrderStatus.contains(orderStatus) &&
          !blockedPaymentStatus.contains(paymentStatus);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? _buildErrorState()
                : _buildContent(),
          ),
        ],
      ),
    );
  }
  Widget _buildHeader() {
    String title =
        widget.isReservation ? 'Detail Reservasi' : 'Detail Dine-in Order';

    // ✅ Dynamic title based on order type if available
    if (!widget.isReservation) {
      final orderType = _orderDetail?['orderType'] ?? _data?['orderType'];
      if (orderType != null) {
        title = 'Detail $orderType';
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Row(
            children: [
              // ✅ TOMBOL EDIT (hanya muncul jika bisa edit)
              if (widget.isReservation && _canEditReservation())
                IconButton(
                  icon: const Icon(Icons.edit, color: Color(0xFF2E8B57)),
                  onPressed: _handleEditReservation,
                  splashRadius: 24,
                  tooltip: 'Edit Reservasi',
                ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
                splashRadius: 24,
              ),
            ],
          ),
        ],
      ),
    );
  }
  // Widget _buildHeader() {
  //   return Container(
  //     padding: const EdgeInsets.all(16),
  //     decoration: BoxDecoration(
  //       color: Colors.white,
  //       border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
  //     ),
  //     child: Row(
  //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //       children: [
  //         Text(
  //           widget.isReservation ? 'Detail Reservasi' : 'Detail Dine-in Order',
  //           style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
  //         ),
  //         IconButton(
  //           icon: const Icon(Icons.close),
  //           onPressed: () => Navigator.pop(context),
  //           splashRadius: 24,
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Terjadi kesalahan',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E8B57),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _canEditReservation() {
    if (!widget.isReservation || _data == null) return false;

    final reservationStatus = (_data!['status'] as String?)?.toLowerCase();
    final hasCheckedIn = _data!['check_in_time'] != null;

    // Hanya bisa edit jika:
    // 1. Belum check-in
    // 2. Status pending atau confirmed
    return !hasCheckedIn &&
        (reservationStatus == 'pending' || reservationStatus == 'confirmed');
  }

  void _handleEditReservation() {
    if (_data == null) return;

    // Navigate to edit screen
    Navigator.pop(context); // Close detail sheet first

    context.push('/gro/reservations/${widget.id}/edit', extra: {
      'reservationData': _data,
    }).then((result) {
      // Refresh data if edit was successful
      if (result == true) {
        _loadData();
      }
    });
  }

  void _handleFinalPayment() {
    if (_orderDetail == null) return;

    final paymentDetails = _orderDetail!['paymentDetails'] as Map<String, dynamic>?;
    if (paymentDetails == null) return;

    final remainingAmount = paymentDetails['remainingAmount'] ?? 0;
    // Backend expects orderId string format (e.g., ORD-19ST19-001)
    final orderId = _orderDetail!['orderId'] ?? _orderDetail!['_id'];
    final orderNumber = _orderDetail!['orderNumber'] ?? '-';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroFinalPaymentScreen(
          orderId: orderId.toString(),
          remainingAmount: remainingAmount is int ? remainingAmount : int.tryParse(remainingAmount.toString()) ?? 0,
          orderNumber: orderNumber.toString(),
        ),
      ),
    ).then((result) {
      // Refresh data if payment was successful
      if (result == true) {
        _loadData();
      }
    });
  }

  Widget _buildContent() {
    if (_orderDetail != null) {
      return SingleChildScrollView(
        child: GroOrderDetailWidget(
          orderData: _orderDetail!,
          showAddOrderButton: _canAddOrder(),
          onAddOrder: _canAddOrder() ? _handleAddOrder : null,
          onFinalPayment: _handleFinalPayment,
        ),
      );
    }

    // Tampilkan loading jika orderDetail sedang dimuat
    if (_data != null && _data!['order_id'] != null && _orderDetail == null && !_isLoading) {
      return const Center(child: Text('Memuat detail order...'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Text(
        widget.isReservation
            ? 'Reservasi belum memiliki order.'
            : 'Order detail tidak tersedia.',
        style: const TextStyle(color: Colors.grey),
      ),
    );
  }
}