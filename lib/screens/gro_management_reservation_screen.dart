import 'package:baraja_app/screens/gro_dine_in_detail_order_sheet.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../services/gro_service.dart';

class GroReservationManagementScreen extends StatefulWidget {
  final String? filter;
  final String? initialDate;
  const GroReservationManagementScreen({
    super.key,
    this.filter,
    this.initialDate,
  });

  @override
  State<GroReservationManagementScreen> createState() =>
      _GroReservationManagementScreenState();
}

class _GroReservationManagementScreenState
    extends State<GroReservationManagementScreen> {
  final GROService _groService = GROService();
  List<dynamic> _reservations = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedFilter = 'all';
  int _currentPage = 1;
  int _totalPages = 1;
  late DateTime _selectedDate;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialDate != null && widget.initialDate!.isNotEmpty) {
      try {
        _selectedDate = DateTime.parse(widget.initialDate!);
      } catch (e) {
        _selectedDate = DateTime.now();
      }
    } else {
      _selectedDate = DateTime.now();
    }
    if (widget.filter != null && widget.filter!.isNotEmpty) {
      _selectedFilter = widget.filter!;
    }
    _loadReservations();
  }

  // ✅ FIXED: Return null untuk pending agar bisa difilter di frontend
  String? _mapFilterToApiStatus(String filter) {
    switch (filter) {
      case 'pending':
        return null; // ✅ Akan difilter di frontend untuk include Pending, Waiting, Reserved
      case 'ongoing':
        return 'active'; // backend uses 'active' for ongoing
      case 'completed':
        return 'completed';
      case 'cancelled':
        return 'cancelled';
      default:
        return null; // 'all'
    }
  }

  // ✅ FIXED: Filter frontend untuk status pending (Menunggu)
  Future<void> _loadReservations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

      // ✅ Untuk filter pending, ambil semua data dulu
      final apiStatus = _selectedFilter == 'pending'
          ? null
          : _mapFilterToApiStatus(_selectedFilter);

      final result = await _groService.getReservations(
        page: _currentPage,
        limit: 20,
        status: apiStatus,
        search: _searchController.text.isNotEmpty
            ? _searchController.text
            : null,
        date: dateStr,
      );

      if (result['success']) {
        List<dynamic> reservations = result['data'];

        // ✅ Filter di frontend untuk "pending" (Menunggu)
        if (_selectedFilter == 'pending') {
          reservations = reservations.where((item) {
            final type = item['type'] ?? 'reservation';
            final status = item['status'] ?? '';

            if (type == 'dine-in-order') {
              // Untuk Dine-In Order: Pending, Waiting, atau Reserved = Menunggu
              return status == 'Pending' ||
                  status == 'Waiting' ||
                  status == 'Reserved';
            } else {
              // Untuk Reservation: pending atau confirmed tapi belum check-in
              return status == 'pending' ||
                  (status == 'confirmed' && item['check_in_time'] == null);
            }
          }).toList();
        }

        setState(() {
          _reservations = reservations;
          _totalPages = result['pagination']['total_pages'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = result['error'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading reservations: $e';
        _isLoading = false;
      });
    }
  }

  // ✅ TAMBAHAN: Check-in untuk Dine-In Order (Reserved → OnProcess)
  Future<void> _checkInDineInOrder(String orderId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Check-in Customer'),
        content: const Text('Apakah customer sudah datang dan siap untuk check-in?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Check-in'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final result = await _groService.checkInDineInOrder(orderId);
      if (mounted) {
        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Customer berhasil check-in'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
          _loadReservations();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error'] ?? 'Gagal check-in customer'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    }
  }

  // ✅ TAMBAHAN: Cancel untuk Dine-In Order (Reserved → Canceled)
  Future<void> _cancelDineInOrder(String orderId) async {
    final reasonController = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Batalkan Order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Apakah Anda yakin ingin membatalkan order ini?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: 'Alasan pembatalan (opsional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              maxLines: 2,
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Batalkan Order'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final result = await _groService.cancelDineInOrder(
        orderId,
        reason: reasonController.text.isNotEmpty ? reasonController.text : null,
      );
      if (mounted) {
        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Order berhasil dibatalkan'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
          _loadReservations();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error'] ?? 'Gagal membatalkan order'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    }
  }

  // ✅ FIXED: Display status yang konsisten
  String _getDisplayStatus(Map<String, dynamic> item) {
    final type = item['type'] ?? 'reservation';
    final status = item['status'] ?? 'pending';

    if (type == 'dine-in-order') {
      // Untuk Dine-In Order, gunakan status dari Order
      if (status == 'Pending' || status == 'Waiting' || status == 'Reserved') {
        return 'Menunggu'; // ✅ Pending, Waiting, dan Reserved = Menunggu
      } else if (status == 'OnProcess') {
        return 'Berlangsung';
      } else if (status == 'Completed') {
        return 'Selesai';
      } else if (status == 'Canceled') {
        return 'Dibatalkan';
      }
      return status;
    } else {
      // Untuk Reservation
      if (status == 'pending') {
        return 'Menunggu';
      } else if (status == 'confirmed') {
        if (item['check_in_time'] != null && item['check_out_time'] == null) {
          return 'Berlangsung'; // Sudah check-in tapi belum check-out
        } else {
          return 'Menunggu'; // ✅ Confirmed tapi belum check-in = Menunggu
        }
      } else if (status == 'completed') {
        return 'Selesai';
      } else if (status == 'cancelled') {
        return 'Dibatalkan';
      }
    }
    return status;
  }

  Color _getDisplayStatusColor(String displayStatus) {
    switch (displayStatus) {
      case 'Menunggu':
        return const Color(0xFFF59E0B);
      case 'Berlangsung':
        return const Color(0xFF10B981);
      case 'Selesai':
        return const Color(0xFF059669);
      case 'Dibatalkan':
        return const Color(0xFFEF4444);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: const Text(
          'Kelola Meja',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadReservations,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            splashRadius: 24,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: Column(
              children: [
                _buildSearchBar(),
                _buildFilterSection(),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF2E8B57),
              ),
            )
                : _errorMessage != null
                ? _buildErrorState()
                : _buildReservationsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        children: [
          InkWell(
            onTap: _selectDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    color: Color(0xFF2E8B57),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      DateFormat('dd MMMM yyyy', 'id_ID').format(_selectedDate),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_drop_down,
                    color: Colors.grey.shade600,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari kode reservasi...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                prefixIcon: Icon(Icons.search, color: Colors.grey.shade600, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey.shade600, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    _loadReservations();
                  },
                )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              onSubmitted: (_) => _loadReservations(),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 90)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2E8B57),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _currentPage = 1;
      });
      _loadReservations();
    }
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('all', 'Semua', Icons.list_alt),
            const SizedBox(width: 8),
            _buildFilterChip('pending', 'Menunggu', Icons.schedule),
            const SizedBox(width: 8),
            _buildFilterChip('ongoing', 'Berlangsung', Icons.dining),
            const SizedBox(width: 8),
            _buildFilterChip('completed', 'Selesai', Icons.check_circle),
            const SizedBox(width: 8),
            _buildFilterChip('cancelled', 'Dibatalkan', Icons.cancel),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, IconData icon) {
    final isSelected = _selectedFilter == value;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedFilter = value;
          _currentPage = 1;
        });
        _loadReservations();
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2E8B57) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF2E8B57) : Colors.grey.shade300,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: const Color(0xFF2E8B57).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.grey.shade700,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
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
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _errorMessage ?? 'Terjadi kesalahan',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadReservations,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E8B57),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReservationsList() {
    if (_reservations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.event_busy,
                size: 48,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Tidak ada reservasi',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Belum ada data untuk filter ini',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadReservations,
      color: const Color(0xFF2E8B57),
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: _reservations.length,
              itemBuilder: (context, index) {
                final reservation = _reservations[index];
                return _buildReservationCard(reservation);
              },
            ),
          ),
          if (_totalPages > 1) _buildPagination(),
        ],
      ),
    );
  }

  Widget _buildReservationCard(Map<String, dynamic> reservation) {
    final displayStatus = _getDisplayStatus(reservation);
    final statusColor = _getDisplayStatusColor(displayStatus);
    final reservationCode = reservation['reservation_code'] ?? reservation['order_id'] ?? '';
    final date = reservation['reservation_date'] ?? reservation['createdAt'];
    final time = reservation['reservation_time'] ?? '';
    final guestCount = reservation['guest_count'] ?? 1;
    final area = reservation['area_id'];
    final tables = reservation['table_id'] as List<dynamic>? ?? [];
    final order = reservation['order_id'];
    final checkInTime = reservation['check_in_time'];
    final checkOutTime = reservation['check_out_time'];

    String formattedDate = 'N/A';
    if (date != null) {
      try {
        final dateTime = DateTime.parse(date.toString());
        formattedDate = DateFormat('dd MMM yyyy', 'id_ID').format(dateTime);
      } catch (e) {
        formattedDate = date.toString();
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showReservationDetail(reservation),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.receipt_long,
                            size: 20,
                            color: statusColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            reservationCode,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: statusColor.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      displayStatus,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    _buildInfoRow(Icons.calendar_today, formattedDate, const Color(0xFF6366F1)),
                    const SizedBox(height: 10),
                    _buildInfoRow(Icons.access_time, time, const Color(0xFF8B5CF6)),
                    const SizedBox(height: 10),
                    _buildInfoRow(Icons.people, '$guestCount orang', const Color(0xFF10B981)),
                    const SizedBox(height: 10),
                    _buildInfoRow(
                      Icons.location_on,
                      area != null ? area['area_name'] ?? 'N/A' : 'N/A',
                      const Color(0xFFEF4444),
                    ),
                    if (tables.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _buildInfoRow(
                        Icons.table_restaurant,
                        tables.map((t) => t['table_number']).join(', '),
                        const Color(0xFFF59E0B),
                      ),
                    ],
                    if (checkInTime != null) ...[
                      const SizedBox(height: 10),
                      _buildInfoRow(
                        Icons.login,
                        'Check-in: ${_formatDateTime(checkInTime)}',
                        const Color(0xFF059669),
                      ),
                    ],
                    // if (checkOutTime != null) ...[
                    //   const SizedBox(height: 10),
                    //   _buildInfoRow(
                    //     Icons.logout,
                    //     'Check-out: ${_formatDateTime(checkOutTime)}',
                    //     const Color(0xFFF97316),
                    //   ),
                    // ],
                    if (order != null) ...[
                      const SizedBox(height: 10),
                      _buildInfoRow(
                        Icons.receipt,
                        'Order: ${order['order_id']}',
                        const Color(0xFF3B82F6),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildActionButtons(reservation),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateTime(String? dateTimeStr) {
    if (dateTimeStr == null) return 'N/A';
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(dateTime);
    } catch (e) {
      return dateTimeStr;
    }
  }

  Widget _buildInfoRow(IconData icon, String text, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // ✅ FIXED: Action buttons untuk reservasi Reserved
  Widget _buildActionButtons(Map<String, dynamic> reservation) {
    final type = reservation['type'];
    final id = reservation['_id'];

    // === DINE-IN ORDER ACTIONS ===
    if (type == 'dine-in-order') {
      final status = reservation['status'];

      // Status Reserved: Tombol Check-in dan Batalkan
      if (status == 'Reserved') {
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            SizedBox(
              width: (MediaQuery.of(context).size.width - 64) / 2 - 4,
              child: ElevatedButton.icon(
                onPressed: () => _checkInDineInOrder(id),
                icon: const Icon(Icons.login, size: 16),
                label: const Text('Check-in', style: TextStyle(fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            SizedBox(
              width: (MediaQuery.of(context).size.width - 64) / 2 - 4,
              child: OutlinedButton.icon(
                onPressed: () => _cancelDineInOrder(id),
                icon: const Icon(Icons.close, size: 16),
                label: const Text('Batalkan', style: TextStyle(fontSize: 13)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFEF4444),
                  side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        );
      }

      // Status OnProcess: Tombol Selesai
      if (status == 'OnProcess') {
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _completeDineIn(id),
            icon: const Icon(Icons.done_all, size: 16),
            label: const Text('Selesai'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        );
      }

      // Jika status Pending/Waiting (Menunggu), tidak ada tombol action
      return const SizedBox.shrink();
    }

    // === RESERVATION ACTIONS ===
    final status = reservation['status'];
    final checkInTime = reservation['check_in_time'];
    final checkOutTime = reservation['check_out_time'];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // STATUS: PENDING (Menunggu)
        // Tombol: Konfirmasi, Batalkan
        if (status == 'pending') ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _confirmReservation(id),
              icon: const Icon(Icons.check, size: 16),
              label: const Text('Konfirmasi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _cancelReservation(id),
              icon: const Icon(Icons.close, size: 16),
              label: const Text('Batalkan'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFEF4444),
                side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],

        // STATUS: CONFIRMED & BELUM CHECK-IN (Menunggu - sudah dikonfirmasi)
        // Tombol: Check-in, Batalkan
        if (status == 'confirmed' && checkInTime == null) ...[
          SizedBox(
            width: (MediaQuery.of(context).size.width - 64) / 2 - 4,
            child: ElevatedButton.icon(
              onPressed: () => _checkInReservation(id),
              icon: const Icon(Icons.login, size: 16),
              label: const Text('Check-in', style: TextStyle(fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          SizedBox(
            width: (MediaQuery.of(context).size.width - 64) / 2 - 4,
            child: OutlinedButton.icon(
              onPressed: () => _cancelReservation(id),
              icon: const Icon(Icons.close, size: 16),
              label: const Text('Batalkan', style: TextStyle(fontSize: 13)),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFEF4444),
                side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],

        // STATUS: CONFIRMED & SUDAH CHECK-IN & BELUM CHECK-OUT (Berlangsung)
        // Tombol: Check-out, Batalkan
        if (status == 'confirmed' && checkInTime != null && checkOutTime == null) ...[
          SizedBox(
            width: (MediaQuery.of(context).size.width - 64) / 2 - 4,
            child: ElevatedButton.icon(
              onPressed: () => _checkOutReservation(id),
              icon: const Icon(Icons.logout, size: 16),
              label: const Text('Check-out', style: TextStyle(fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          SizedBox(
            width: (MediaQuery.of(context).size.width - 64) / 2 - 4,
            child: OutlinedButton.icon(
              onPressed: () => _cancelReservation(id),
              icon: const Icon(Icons.close, size: 16),
              label: const Text('Batalkan', style: TextStyle(fontSize: 13)),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFEF4444),
                side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPagination() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              color: _currentPage > 1 ? const Color(0xFF2E8B57).withOpacity(0.1) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              onPressed: _currentPage > 1
                  ? () {
                setState(() => _currentPage--);
                _loadReservations();
              }
                  : null,
              icon: const Icon(Icons.arrow_back),
              color: _currentPage > 1 ? const Color(0xFF2E8B57) : Colors.grey,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Halaman $_currentPage dari $_totalPages',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                fontSize: 14,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: _currentPage < _totalPages ? const Color(0xFF2E8B57).withOpacity(0.1) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              onPressed: _currentPage < _totalPages
                  ? () {
                setState(() => _currentPage++);
                _loadReservations();
              }
                  : null,
              icon: const Icon(Icons.arrow_forward),
              color: _currentPage < _totalPages ? const Color(0xFF2E8B57) : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  // --- Dine-In Actions ---
  Future<void> _completeDineIn(String orderId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Selesaikan Order'),
        content: const Text('Apakah Anda yakin ingin menyelesaikan order ini? Meja akan menjadi tersedia.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Selesaikan'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final result = await _groService.completeDineInOrder(orderId);
      if (mounted) {
        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Order berhasil diselesaikan'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
          _loadReservations();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error'] ?? 'Gagal menyelesaikan order'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    }
  }

  // --- Reservation Actions ---
  Future<void> _confirmReservation(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
              content: Text(result['message'] ?? 'Reservasi berhasil dikonfirmasi'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
          _loadReservations();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error'] ?? 'Gagal mengkonfirmasi reservasi'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    }
  }

  Future<void> _checkInReservation(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Check-in Reservasi'),
        content: const Text('Apakah tamu sudah datang dan siap untuk check-in?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Check-in'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final result = await _groService.checkInReservation(id);
      if (mounted) {
        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Check-in berhasil'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
          _loadReservations();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error'] ?? 'Gagal check-in'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    }
  }

  Future<void> _checkOutReservation(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Check-out Reservasi'),
        content: const Text('Apakah tamu sudah selesai dan siap untuk check-out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Check-out'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final result = await _groService.checkOutReservation(id);
      if (mounted) {
        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Check-out berhasil'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
          _loadReservations();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error'] ?? 'Gagal check-out'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    }
  }

  Future<void> _cancelReservation(String id) async {
    final reasonController = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Batalkan Reservasi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Apakah Anda yakin ingin membatalkan reservasi ini?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: 'Alasan pembatalan (opsional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              maxLines: 2,
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
              content: Text(result['message'] ?? 'Reservasi berhasil dibatalkan'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
          _loadReservations();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error'] ?? 'Gagal membatalkan reservasi'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    }
  }

  void _showReservationDetail(Map<String, dynamic> reservation) {
    final type = reservation['type'];
    if (type == 'dine-in-order') {
      final orderId = reservation['_id'];
      _showDineInOrderDetail(orderId);
    } else {
      final reservationId = reservation['_id'];
      context.push('/gro-reservation-detail/$reservationId').then((_) {
        _loadReservations();
      });
    }
  }

  Future<void> _showDineInOrderDetail(String orderId) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DineInOrderDetailSheet(orderId: orderId),
    );
  }
}