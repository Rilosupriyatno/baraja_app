import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/gro_service.dart';
import '../models/reservation_data.dart';
import '../screens/menu_screen.dart';
import '../widgets/reservation/transfer_table_dialog.dart';
import '../widgets/gro/gro_order_detail_widget.dart';

class GroReservationDetailScreen extends StatefulWidget {
  final String reservationId;

  const GroReservationDetailScreen({
    super.key,
    required this.reservationId,
  });

  @override
  State<GroReservationDetailScreen> createState() =>
      _GroReservationDetailScreenState();
}

class _GroReservationDetailScreenState
    extends State<GroReservationDetailScreen> {
  final GROService _groService = GROService();
  Map<String, dynamic>? _reservation;
  Map<String, dynamic>? _orderDetail;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadReservationDetail(widget.reservationId);
  }

  Future<void> _loadReservationDetail(String id) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _groService.getReservationDetail(id);

      if (!mounted) return;

      if (result['success']) {
        setState(() {
          _reservation = result['data'];
        });

        // ✅ Load order detail jika ada order_id
        final order = _reservation!['order_id'];
        if (order != null && order is Map<String, dynamic>) {
          final orderId = order['order_id'] ?? order['_id'];
          if (orderId != null) {
            await _loadOrderDetail(orderId);
          }
        }

        setState(() {
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = result['error'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Error loading reservation detail: $e';
        _isLoading = false;
      });
    }
  }

  // ✅ Load order detail lengkap
  Future<void> _loadOrderDetail(String orderId) async {
    try {
      final result = await _groService.getOrderDetailWithPayment(orderId);

      if (!mounted) return;

      print('Load order detail result: $result');

      if (result['success'] == true && result['data'] is Map<String, dynamic>) {
        setState(() {
          _orderDetail = result['data'] as Map<String, dynamic>;
        });
      }
    } catch (e) {
      print('Exception in _loadOrderDetail: $e');
    }
  }

  // ✅ Handler untuk tambah pesanan (OpenBill)
  void _handleAddOrder() {
    if (_reservation == null) return;

    // Extract data yang dibutuhkan
    final tables = _reservation!['table_id'] as List<dynamic>? ?? [];
    final tableNumbers = tables
        .map((t) => t['table_number']?.toString() ?? '')
        .where((n) => n.isNotEmpty)
        .join(', ');

    final area = _reservation!['area_id'];
    final areaId = area != null ? area['_id']?.toString() ?? '' : '';
    final areaCode = area != null ? area['area_code']?.toString() ?? '' : '';

    final order = _reservation!['order_id'];
    final orderId = order is Map<String, dynamic>
        ? (order['order_id'] ?? order['_id'])?.toString() ?? widget.reservationId
        : widget.reservationId;

    // Parse date and time
    DateTime reservationDate = DateTime.now();
    try {
      final dateStr = _reservation!['reservation_date'];
      if (dateStr != null) {
        reservationDate = DateTime.parse(dateStr);
      }
    } catch (e) {
      print('Error parsing date: $e');
    }

    TimeOfDay reservationTime = TimeOfDay.now();
    try {
      final timeStr = _reservation!['reservation_time'];
      if (timeStr != null && timeStr.toString().contains(':')) {
        final parts = timeStr.toString().split(':');
        reservationTime = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
    } catch (e) {
      print('Error parsing time: $e');
    }

    // Buat OpenBillData
    final openBillData = OpenBillData(
      reservationId: orderId,
      date: reservationDate,
      time: reservationTime,
      areaId: areaId,
      areaCode: areaCode,
      tableId: tables.isNotEmpty ? tables[0]['_id']?.toString() ?? '' : '',
      tableNumbers: tableNumbers,
    );

    print('📌 Opening menu for additional order');
    print('  Reservation ID: ${widget.reservationId}');
    print('  Order ID: $orderId');
    print('  Table: $tableNumbers');
    print('  Area: $areaCode');

    // Navigate ke MenuScreen dengan OpenBill mode
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MenuScreen(
          isOpenBill: true,
          openBillData: openBillData,
        ),
      ),
    ).then((_) {
      // Refresh data setelah kembali dari menu
      _loadReservationDetail(widget.reservationId);
    });
  }

  // ✅ Check apakah order masih bisa ditambah pesanan
  bool _canAddOrder() {
    if (_reservation == null) {
      print('📋 Can Add Order: false (reservation is null)');
      return false;
    }

    final reservationStatus = _reservation!['status']?.toString().toLowerCase();

    // Cek apakah ada order
    final hasOrder = _reservation!['order_id'] != null;

    if (!hasOrder) {
      print('📋 Can Add Order: false (no order)');
      return false;
    }

    // Jika ada orderDetail, cek payment status juga
    if (_orderDetail != null) {
      final orderStatus = (_orderDetail!['orderStatus'] ??
          _orderDetail!['order_status'])?.toString().toLowerCase();
      final paymentStatus = (_orderDetail!['paymentStatus'] ??
          _orderDetail!['payment_status'])?.toString().toLowerCase();

      print('📋 Can Add Order Check:');
      print('  Reservation Status: $reservationStatus');
      print('  Order Status: $orderStatus');
      print('  Payment Status: $paymentStatus');

      final canAdd = reservationStatus != 'completed' &&
          reservationStatus != 'cancelled' &&
          orderStatus != 'completed' &&
          orderStatus != 'cancelled' &&
          paymentStatus != 'settlement' &&
          paymentStatus != 'capture';

      print('  ✅ Can Add Order Result: $canAdd');
      return canAdd;
    }

    // Fallback: hanya cek reservation status
    final canAdd = reservationStatus == 'confirmed';
    print('📋 Can Add Order (fallback): $canAdd');
    return canAdd;
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'confirmed':
        return const Color(0xFF3B82F6);
      case 'completed':
        return const Color(0xFF10B981);
      case 'cancelled':
        return const Color(0xFFEF4444);
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Menunggu';
      case 'confirmed':
        return 'Dikonfirmasi';
      case 'completed':
        return 'Selesai';
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: const Text(
          'Detail Reservasi',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          if (_reservation != null)
            PopupMenuButton<String>(
              onSelected: (value) {
                final id = _reservation!['_id'];

                if (value == 'close_bill') {
                  _closeOpenBill(id);
                } else if (value == 'transfer_table') {
                  _showTransferTableDialog();
                }
              },
              itemBuilder: (context) {
                final status = _reservation!['status'];
                final hasOrder = _reservation!['order_id'] != null;

                return [
                  if (hasOrder)
                    const PopupMenuItem(
                      value: 'close_bill',
                      child: Row(
                        children: [
                          Icon(Icons.receipt_long, size: 20),
                          SizedBox(width: 8),
                          Text('Tutup Open Bill'),
                        ],
                      ),
                    ),
                  if (status == 'confirmed' || status == 'pending')
                    const PopupMenuItem(
                      value: 'transfer_table',
                      child: Row(
                        children: [
                          Icon(Icons.swap_horiz, size: 20),
                          SizedBox(width: 8),
                          Text('Pindah Meja'),
                        ],
                      ),
                    ),
                ];
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? _buildErrorState()
          : _buildDetailContent(),
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
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E8B57),
                foregroundColor: Colors.white,
              ),
              child: const Text('Kembali'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailContent() {
    if (_reservation == null) return const SizedBox();

    final status = _reservation!['status'] ?? 'pending';
    final reservationCode = _reservation!['reservation_code'] ?? '';
    final date = _reservation!['reservation_date'];
    final time = _reservation!['reservation_time'] ?? '';
    final guestCount = _reservation!['guest_count'] ?? 0;
    final area = _reservation!['area_id'];
    final tables = _reservation!['table_id'] as List<dynamic>? ?? [];
    final order = _reservation!['order_id'];
    final notes = _reservation!['notes'] ?? '';

    String formattedDate = 'N/A';
    if (date != null) {
      try {
        final dateTime = DateTime.parse(date);
        formattedDate = DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(dateTime);
      } catch (e) {
        formattedDate = date.toString();
      }
    }

    final canAddOrder = _canAddOrder();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusCard(status, reservationCode),
          const SizedBox(height: 24),
          const Text(
            'Informasi Reservasi',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            formattedDate,
            time,
            guestCount,
            area,
            tables,
            notes,
          ),
          if (order != null) ...[
            const SizedBox(height: 24),
            const Text(
              'Informasi Order',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            // ✅ Gunakan GroOrderDetailWidget jika ada orderDetail lengkap
            if (_orderDetail != null)
              GroOrderDetailWidget(
                orderData: _orderDetail!,
                showAddOrderButton: canAddOrder,
                onAddOrder: canAddOrder ? _handleAddOrder : null,
              )
            else
              _buildOrderCard(order),
          ],
          const SizedBox(height: 24),
          _buildActionButtons(status),
        ],
      ),
    );
  }

  Widget _buildStatusCard(String status, String code) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _getStatusColor(status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _getStatusText(status),
              style: TextStyle(
                color: _getStatusColor(status),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            code,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
      String date,
      String time,
      int guestCount,
      Map<String, dynamic>? area,
      List<dynamic> tables,
      String notes,
      ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow(Icons.calendar_today, 'Tanggal', date),
          const SizedBox(height: 16),
          _buildDetailRow(Icons.access_time, 'Waktu', time),
          const SizedBox(height: 16),
          _buildDetailRow(Icons.people, 'Jumlah Tamu', '$guestCount orang'),
          const SizedBox(height: 16),
          _buildDetailRow(
            Icons.location_on,
            'Area',
            area != null
                ? '${area['area_name']} (${area['area_code']})'
                : 'N/A',
          ),
          if (tables.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildDetailRow(
              Icons.table_restaurant,
              'Meja',
              tables
                  .map((t) => '${t['table_number']} (${t['seats']} kursi)')
                  .join(', '),
            ),
          ],
          if (notes.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildDetailRow(Icons.notes, 'Catatan', notes),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: const Color(0xFF2E8B57)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final orderId = order['order_id'] ?? '';
    final grandTotal = order['grandTotal'] ?? 0;
    final items = order['items'] as List<dynamic>? ?? [];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Order ID',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  orderId,
                  style: const TextStyle(
                    color: Color(0xFF3B82F6),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          if (items.isNotEmpty) ...[
            const SizedBox(height: 16),
            ...items.map((item) {
              final menuItem = item['menuItem'];
              final quantity = item['quantity'] ?? 1;
              final name = menuItem != null ? menuItem['name'] : 'N/A';
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Text('$quantity x ',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        )),
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                NumberFormat.currency(
                  locale: 'id_ID',
                  symbol: 'Rp ',
                  decimalDigits: 0,
                ).format(grandTotal),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E8B57),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(String status) {
    final id = _reservation!['_id'];

    if (status == 'completed' || status == 'cancelled') {
      return const SizedBox();
    }

    return Column(
      children: [
        if (status == 'pending')
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _confirmReservation(id),
              icon: const Icon(Icons.check),
              label: const Text('Konfirmasi Reservasi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        if (status == 'confirmed') ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _completeReservation(id),
              icon: const Icon(Icons.done_all),
              label: const Text('Selesaikan Reservasi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
        if (status == 'pending' || status == 'confirmed') ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _cancelReservation(id),
              icon: const Icon(Icons.close),
              label: const Text('Batalkan Reservasi'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFEF4444),
                side: const BorderSide(color: Color(0xFFEF4444)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _showTransferTableDialog() async {
    final tables = _reservation!['table_id'] as List<dynamic>? ?? [];
    final area = _reservation!['area_id'];
    final areaId = area != null ? area['_id'] : null;

    if (areaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Area tidak ditemukan'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => TableTransferDialog(
        reservationId: _reservation!['_id'],
        currentTables: tables,
        areaId: areaId,
      ),
    );

    if (result == true) {
      _loadReservationDetail(widget.reservationId);
    }
  }

  Future<void> _confirmReservation(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Reservasi'),
        content: const Text('Apakah Anda yakin ingin mengkonfirmasi reservasi ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
            ),
            child: const Text('Konfirmasi'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final result = await _groService.confirmReservation(id);
      if (mounted) {
        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Reservasi dikonfirmasi'),
              backgroundColor: Colors.green,
            ),
          );
          _loadReservationDetail(id);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error'] ?? 'Gagal konfirmasi reservasi'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _completeReservation(String id) async {
    bool closeOpenBill = false;
    bool hasOrder = _reservation!['order_id'] != null;

    if (hasOrder) {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Selesaikan Reservasi'),
          content: const Text(
            'Reservasi ini memiliki order. Apakah Anda ingin menutup open bill?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            OutlinedButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Selesai Tanpa Tutup Bill'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
              ),
              child: const Text('Selesai & Tutup Bill'),
            ),
          ],
        ),
      );

      if (result == null) return;
      closeOpenBill = result;
    } else {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Selesaikan Reservasi'),
          content: const Text(
            'Apakah Anda yakin ingin menyelesaikan reservasi ini?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
              ),
              child: const Text('Selesaikan'),
            ),
          ],
        ),
      );

      if (confirm != true) return;
    }

    final result = await _groService.completeReservation(
      id,
      closeOpenBill: closeOpenBill,
    );

    if (mounted) {
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Reservasi diselesaikan'),
            backgroundColor: Colors.green,
          ),
        );
        _loadReservationDetail(id);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Gagal menyelesaikan reservasi'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _cancelReservation(String id) async {
    final reasonController = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Batalkan Reservasi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Apakah Anda yakin ingin membatalkan reservasi ini?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Alasan pembatalan (opsional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            child: const Text('Batalkan Reservasi'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final result = await _groService.cancelReservation(
        id,
        reason: reasonController.text.isNotEmpty ? reasonController.text : null,
      );

      if (mounted) {
        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Reservasi dibatalkan'),
              backgroundColor: Colors.orange,
            ),
          );
          _loadReservationDetail(id);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error'] ?? 'Gagal membatalkan reservasi'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _closeOpenBill(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tutup Open Bill'),
        content: const Text(
          'Apakah Anda yakin ingin menutup status open bill untuk reservasi ini?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
            ),
            child: const Text('Tutup Open Bill'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final result = await _groService.closeOpenBill(id);

      if (mounted) {
        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Open bill ditutup'),
              backgroundColor: Colors.green,
            ),
          );
          _loadReservationDetail(id);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error'] ?? 'Gagal menutup open bill'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}