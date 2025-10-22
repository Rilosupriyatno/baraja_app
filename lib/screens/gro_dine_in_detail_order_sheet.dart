import 'package:flutter/material.dart';
// ignore: unused_import
import 'package:intl/intl.dart';
import '../services/gro_service.dart';
import '../models/reservation_data.dart';
import '../screens/menu_screen.dart';
import '../widgets/gro/gro_order_detail_widget.dart';

class DineInOrderDetailSheet extends StatefulWidget {
  final String orderId;

  const DineInOrderDetailSheet({
    super.key,
    required this.orderId,
  });

  @override
  State<DineInOrderDetailSheet> createState() => _DineInOrderDetailSheetState();
}

class _DineInOrderDetailSheetState extends State<DineInOrderDetailSheet> {
  final GROService _groService = GROService();
  Map<String, dynamic>? _orderDetail;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadOrderDetail();
  }

  Future<void> _loadOrderDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _groService.getOrderDetailWithPayment(widget.orderId);

      if (!mounted) return;

      print('Load order detail result: $result');

      if (result['success'] == true) {
        if (result['data'] is! Map<String, dynamic>) {
          setState(() {
            _errorMessage = 'Invalid data format: ${result['data'].runtimeType}';
            _isLoading = false;
          });
          return;
        }

        setState(() {
          _orderDetail = result['data'] as Map<String, dynamic>;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = result['error'] ?? 'Gagal memuat detail order';
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      print('Exception in _loadOrderDetail: $e');
      print('Stack trace: $stackTrace');

      if (!mounted) return;

      setState(() {
        _errorMessage = 'Error loading order detail: $e';
        _isLoading = false;
      });
    }
  }

  void _handleAddOrder() {
    if (_orderDetail == null) return;

    final tableNumber = _orderDetail!['tableNumber']?.toString() ?? '';
    final orderId = _orderDetail!['orderId']?.toString() ??
        _orderDetail!['order_id']?.toString() ??
        widget.orderId;

    final openBillData = OpenBillData(
      reservationId: orderId,
      date: DateTime.now(),
      time: TimeOfDay.now(),
      areaId: '',
      areaCode: 'Dine-in', //
      tableId: '',
      tableNumbers: tableNumber,
    );

    print('🔷 Opening menu for additional dine-in order');
    print('  Order ID: $orderId');
    print('  Table: $tableNumber');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MenuScreen(
          isOpenBill: true,
          openBillData: openBillData,
        ),
      ),
    ).then((_) {
      _loadOrderDetail();
    });
  }

  bool _canAddOrder() {
    if (_orderDetail == null) {
      print('🔍 Can Add Order: false (orderDetail is null)');
      return false;
    }

    final orderStatus = (_orderDetail!['orderStatus'] ??
        _orderDetail!['order_status'])?.toString().toLowerCase();
    final paymentStatus = (_orderDetail!['paymentStatus'] ??
        _orderDetail!['payment_status'])?.toString().toLowerCase();

    print('🔍 Can Add Order Check:');
    print('  Order Status: $orderStatus');
    print('  Payment Status: $paymentStatus');
    print('  Order Detail Keys: ${_orderDetail!.keys.toList()}');

    final canAdd = orderStatus != 'completed' &&
        orderStatus != 'cancelled' &&
        paymentStatus != 'settlement' &&
        paymentStatus != 'capture';

    print('  ✅ Can Add Order Result: $canAdd');
    return canAdd;
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
                : _buildOrderContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Detail Dine-in Order', // ✅ Perbarui label
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
            splashRadius: 24,
          ),
        ],
      ),
    );
  }

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
              onPressed: _loadOrderDetail,
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

  Widget _buildOrderContent() {
    if (_orderDetail == null) return const SizedBox();

    final canAddOrder = _canAddOrder();

    return SingleChildScrollView(
      child: Column(
        children: [
          GroOrderDetailWidget(
            orderData: _orderDetail!,
            showAddOrderButton: canAddOrder,
            onAddOrder: canAddOrder ? _handleAddOrder : null,
          ),
        ],
      ),
    );
  }
}