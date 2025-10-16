import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../services/gro_service.dart';

class GroReservationManagementScreen extends StatefulWidget {
  final String? filter;
  const GroReservationManagementScreen({super.key, this.filter});

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
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.filter != null && widget.filter!.isNotEmpty) {
      _selectedFilter = widget.filter!;
    }
    _loadReservations();
  }

  Future<void> _loadReservations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _groService.getReservations(
        page: _currentPage,
        limit: 20,
        status: _selectedFilter == 'all' ? null : _selectedFilter,
        search: _searchController.text.isNotEmpty
            ? _searchController.text
            : null,
        date: 'all',
      );

      if (result['success']) {
        setState(() {
          _reservations = result['data'];
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: const Text(
          'Kelola Reservasi',
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
          _buildFilterSection(),
          _buildSearchBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? _buildErrorState()
                : _buildReservationsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('all', 'Semua'),
            const SizedBox(width: 8),
            _buildFilterChip('pending', 'Menunggu'),
            const SizedBox(width: 8),
            _buildFilterChip('confirmed', 'Dikonfirmasi'),
            const SizedBox(width: 8),
            _buildFilterChip('active', 'Berlangsung'),
            const SizedBox(width: 8),
            _buildFilterChip('completed', 'Selesai'),
            const SizedBox(width: 8),
            _buildFilterChip('cancelled', 'Dibatalkan'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedFilter = value;
            _currentPage = 1;
          });
          _loadReservations();
        }
      },
      selectedColor: const Color(0xFF2E8B57),
      backgroundColor: Colors.white,
      side: BorderSide(
        color: isSelected ? const Color(0xFF2E8B57) : Colors.grey.shade300,
      ),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        fontSize: 13,
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      color: Colors.white,
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Cari kode reservasi...',
          hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
            icon: Icon(Icons.clear, color: Colors.grey.shade600),
            onPressed: () {
              _searchController.clear();
              _loadReservations();
            },
          )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF2E8B57)),
          ),
          filled: true,
          fillColor: Colors.grey[50],
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 12),
        ),
        onSubmitted: (_) => _loadReservations(),
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
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Terjadi kesalahan',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadReservations,
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

  Widget _buildReservationsList() {
    if (_reservations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Tidak ada reservasi',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadReservations,
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
    final status = reservation['status'] ?? 'pending';
    final reservationCode = reservation['reservation_code'] ?? '';
    final date = reservation['reservation_date'];
    final time = reservation['reservation_time'] ?? '';
    final guestCount = reservation['guest_count'] ?? 0;
    final area = reservation['area_id'];
    final tables = reservation['table_id'] as List<dynamic>? ?? [];
    final order = reservation['order_id'];
    final checkInTime = reservation['check_in_time'];
    final checkOutTime = reservation['check_out_time'];

    String formattedDate = 'N/A';
    if (date != null) {
      try {
        final dateTime = DateTime.parse(date);
        formattedDate = DateFormat('dd MMM yyyy', 'id_ID').format(dateTime);
      } catch (e) {
        formattedDate = date.toString();
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: InkWell(
        onTap: () => _showReservationDetail(reservation),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
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
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getStatusText(status),
                      style: TextStyle(
                        color: _getStatusColor(status),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildInfoRow(Icons.calendar_today, formattedDate),
              const SizedBox(height: 8),
              _buildInfoRow(Icons.access_time, time),
              const SizedBox(height: 8),
              _buildInfoRow(Icons.people, '$guestCount orang'),
              const SizedBox(height: 8),
              _buildInfoRow(
                Icons.location_on,
                area != null ? area['area_name'] ?? 'N/A' : 'N/A',
              ),
              if (tables.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildInfoRow(
                  Icons.table_restaurant,
                  tables.map((t) => t['table_number']).join(', '),
                ),
              ],
              if (checkInTime != null) ...[
                const SizedBox(height: 8),
                _buildInfoRow(
                  Icons.login,
                  'Check-in: ${_formatDateTime(checkInTime)}',
                ),
              ],
              if (checkOutTime != null) ...[
                const SizedBox(height: 8),
                _buildInfoRow(
                  Icons.logout,
                  'Check-out: ${_formatDateTime(checkOutTime)}',
                ),
              ],
              if (order != null) ...[
                const SizedBox(height: 8),
                _buildInfoRow(
                  Icons.receipt,
                  'Order: ${order['order_id']}',
                ),
              ],
              const SizedBox(height: 12),
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

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(Map<String, dynamic> reservation) {
    final status = reservation['status'];
    final id = reservation['_id'];
    final checkInTime = reservation['check_in_time'];
    final checkOutTime = reservation['check_out_time'];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // Tombol Konfirmasi (hanya untuk status pending)
        if (status == 'pending')
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _confirmReservation(id),
              icon: const Icon(Icons.check, size: 16),
              label: const Text('Konfirmasi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),

        // Tombol Check-in (untuk status confirmed yang belum check-in)
        if (status == 'confirmed' && checkInTime == null)
          SizedBox(
            width: (MediaQuery
                .of(context)
                .size
                .width - 48) / 2 - 4,
            child: ElevatedButton.icon(
              onPressed: () => _checkInReservation(id),
              icon: const Icon(Icons.login, size: 16),
              label: const Text('Check-in'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),

        // Tombol Check-out (untuk yang sudah check-in tapi belum check-out)
        if (status == 'confirmed' && checkInTime != null &&
            checkOutTime == null)
          SizedBox(
            width: (MediaQuery
                .of(context)
                .size
                .width - 48) / 2 - 4,
            child: ElevatedButton.icon(
              onPressed: () => _checkOutReservation(id),
              icon: const Icon(Icons.logout, size: 16),
              label: const Text('Check-out'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),

        // Tombol Batalkan (untuk pending dan confirmed)
        if (status == 'pending' || status == 'confirmed')
          SizedBox(
            width: status == 'confirmed' && checkInTime != null &&
                checkOutTime == null
                ? (MediaQuery
                .of(context)
                .size
                .width - 48) / 2 - 4
                : status == 'confirmed' && checkInTime == null
                ? (MediaQuery
                .of(context)
                .size
                .width - 48) / 2 - 4
                : double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _cancelReservation(id),
              icon: const Icon(Icons.close, size: 16),
              label: const Text('Batalkan'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFEF4444),
                side: const BorderSide(color: Color(0xFFEF4444)),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),

        // Tombol Selesai (untuk confirmed yang sudah check-out atau belum)
        if (status == 'confirmed')
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _completeReservation(id, reservation),
              icon: const Icon(Icons.done_all, size: 16),
              label: const Text('Selesai'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
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
          IconButton(
            onPressed: _currentPage > 1
                ? () {
              setState(() => _currentPage--);
              _loadReservations();
            }
                : null,
            icon: const Icon(Icons.arrow_back),
            color: _currentPage > 1 ? const Color(0xFF2E8B57) : Colors.grey,
          ),
          Text(
            'Halaman $_currentPage dari $_totalPages',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          IconButton(
            onPressed: _currentPage < _totalPages
                ? () {
              setState(() => _currentPage++);
              _loadReservations();
            }
                : null,
            icon: const Icon(Icons.arrow_forward),
            color: _currentPage < _totalPages ? const Color(0xFF2E8B57) : Colors
                .grey,
          ),
        ],
      ),
    );
  }

  Future<void> _confirmReservation(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text('Konfirmasi Reservasi'),
            content: const Text(
                'Apakah Anda yakin ingin mengkonfirmasi reservasi ini?'),
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
          _loadReservations();
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

  Future<void> _checkInReservation(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text('Check-in Reservasi'),
            content: const Text(
                'Apakah tamu sudah datang dan siap untuk check-in?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
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
            ),
          );
          _loadReservations();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error'] ?? 'Gagal check-in'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _checkOutReservation(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text('Check-out Reservasi'),
            content: const Text(
                'Apakah tamu sudah selesai dan siap untuk check-out?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
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
            ),
          );
          _loadReservations();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error'] ?? 'Gagal check-out'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _completeReservation(String id,
      Map<String, dynamic> reservation) async {
    final order = reservation['order_id'];
    bool hasOpenBill = false;

    if (order != null) {
      hasOpenBill = true;
    }

    bool closeOpenBill = false;

    if (hasOpenBill) {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) =>
            AlertDialog(
              title: const Text('Selesaikan Reservasi'),
              content: const Text(
                'Reservasi ini memiliki open bill. Apakah Anda ingin menutup open bill?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, null),
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
        builder: (context) =>
            AlertDialog(
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
        _loadReservations();
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
      builder: (context) =>
          AlertDialog(
            title: const Text('Batalkan Reservasi'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                    'Apakah Anda yakin ingin membatalkan reservasi ini?'),
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
          _loadReservations();
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

  void _showReservationDetail(Map<String, dynamic> reservation) {
    final reservationId = reservation['_id'];
    context.push('/gro-reservation-detail/$reservationId').then((_) {
      _loadReservations();
    });
  }
}