import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/gro_service.dart';
import '../widgets/utils/role_based_widget.dart';

class GroDashboardScreen extends StatefulWidget {
  const GroDashboardScreen({super.key});

  @override
  State<GroDashboardScreen> createState() => _GroDashboardScreenState();
}

class _GroDashboardScreenState extends State<GroDashboardScreen>
    with RoleCheckMixin {
  final GROService _groService = GROService();
  Map<String, dynamic> _dashboardStats = {};
  bool _isLoading = true;
  String? _errorMessage;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadDashboardStats();
  }

  Future<void> _loadDashboardStats() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

      // Pass date parameter to API
      final result = await _groService.getDashboardStats(date: dateStr);

      if (result['success']) {
        setState(() {
          _dashboardStats = result['data'];
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
        _errorMessage = 'Error loading dashboard: $e';
        _isLoading = false;
      });
    }
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
      });
      _loadDashboardStats();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: Consumer<AuthService>(
          builder: (context, authService, _) {
            return const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dashboard GRO',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 20,
                    color: Colors.black,
                  ),
                ),
                // ✅ TAMBAHKAN OUTLET INFO DI APPBAR
                // _buildAppBarOutletInfo(authService),
              ],
            );
          },
        ),
        centerTitle: false, // ✅ UBAH KE false agar rata kiri
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadDashboardStats,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            splashRadius: 24,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboardStats,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(
          color: Color(0xFF2E8B57),
        ))
            : _errorMessage != null
            ? _buildErrorState()
            : _buildDashboardContent(),
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
              onPressed: _loadDashboardStats,
              icon: const Icon(Icons.refresh),
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

  Widget _buildDashboardContent() {
    return Consumer<AuthService>(
      builder: (context, authService, _) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            // ✅ TAMBAHKAN OUTLET CARD DI ATAS WELCOME CARD
            _buildOutletCard(authService),
            const SizedBox(height: 16),
            _buildWelcomeCard(),
            const SizedBox(height: 24),
            _buildDateSelector(),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Statistik Reservasi',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E8B57).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF2E8B57).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: Color(0xFF2E8B57),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        DateFormat('dd MMM', 'id_ID').format(_selectedDate),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2E8B57),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildStatsGrid(),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

// Di gro_dashboard_screen.dart - perbaiki _buildOutletCard()
  Widget _buildOutletCard(AuthService authService) {
    final outlets = authService.getUserOutlets();

    // ✅ PERBAIKAN: Sembunyikan card jika user tidak memiliki outlet
    if (outlets.isEmpty) {
      print('ℹ️ User has no outlets, hiding outlet card');
      return const SizedBox(); // Sembunyikan card
    }

    final outlet = outlets.first;
    final outletName = outlet['name'] ?? 'Nama Outlet';
    final outletAddress = outlet['address'] ?? 'Alamat Outlet';
    final outletPhone = outlet['contactNumber'] ?? outlet['phone'] ?? 'No Telepon';
    final outletCity = outlet['city'] ?? 'Kota';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon Outlet
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF2E8B57).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.store,
              color: Color(0xFF2E8B57),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          // Informasi Outlet
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  outletName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  outletAddress,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '$outletCity • $outletPhone',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          // Status Buka/Tutup
          _buildOpenStatus(outlet),
        ],
      ),
    );
  }

// ✅ PERBAIKAN: Juga di appbar outlet info
  // ignore: unused_element
  Widget _buildAppBarOutletInfo(AuthService authService) {
    final outlets = authService.getUserOutlets();

    // ✅ PERBAIKAN: Sembunyikan jika tidak ada outlet
    if (outlets.isEmpty) {
      return const SizedBox();
    }

    final outlet = outlets.first;
    final outletName = outlet['name'] ?? 'Nama Outlet';
    final outletAddress = outlet['address'] ?? 'Alamat Outlet';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 2),
        Text(
          outletName,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          outletAddress,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // ✅ WIDGET BARU: Status buka/tutup outlet
  Widget _buildOpenStatus(Map<String, dynamic> outlet) {
    final now = DateTime.now();
    final currentTime = DateFormat('HH:mm').format(now);

    final openTime = outlet['openTime'] ?? '06:00';
    final closeTime = outlet['closeTime'] ?? '02:00';

    print('ℹ️ Outlet: $outlet');
    // print('ℹ️ Open Time: $openTime');
    // print('ℹ️ Close Time: $closeTime');
    print('ℹ️ Current Time: $currentTime');

    final isOpen = _isOutletOpen(openTime, closeTime, currentTime);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isOpen ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isOpen ? Colors.green.shade200 : Colors.red.shade200,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOpen ? Icons.circle : Icons.circle_outlined,
            size: 8,
            color: isOpen ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 4),
          Text(
            isOpen ? 'BUKA' : 'TUTUP',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isOpen ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  // ✅ METHOD BARU: Cek status buka/tutup outlet
  bool _isOutletOpen(String openTime, String closeTime, String currentTime) {
    try {
      final open = _timeToMinutes(openTime);
      final close = _timeToMinutes(closeTime);
      final current = _timeToMinutes(currentTime);

      // Jika waktu tutup lebih kecil dari waktu buka (contoh: buka 06:00, tutup 02:00)
      // berarti outlet buka sampai melewati tengah malam
      if (close < open) {
        // outlet buka jika current time >= open time ATAU current time <= close time
        return current >= open || current <= close;
      } else {
        // outlet buka jika current time antara open dan close time
        return current >= open && current <= close;
      }
    } catch (e) {
      print('Error checking outlet status: $e');
      return false;
    }
  }

  int _timeToMinutes(String time) {
    final parts = time.split(':');
    if (parts.length != 2) return 0;

    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;

    return hour * 60 + minute;
  }

  // Widget lainnya tetap sama...
  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2E8B57),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(
                Icons.restaurant_menu,
                color: Colors.white,
                size: 24,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'GRO Dashboard',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Kelola reservasi, meja, dan operasional restoran dengan efisien',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return InkWell(
      onTap: _selectDate,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF2E8B57).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.calendar_today,
                color: Color(0xFF2E8B57),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tanggal',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(_selectedDate),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_drop_down,
              color: Colors.grey.shade600,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.35,
      children: [
        _buildStatCard(
          title: 'Riwayat',
          value: '${_dashboardStats['allReservations'] ?? 0}',
          icon: Icons.history,
          color: const Color(0xFF6366F1),
          onTap: () => _navigateToReservations('all'),
        ),
        _buildStatCard(
          title: 'Menunggu',
          value: '${_dashboardStats['pendingReservations'] ?? 0}',
          icon: Icons.schedule,
          color: const Color(0xFFF59E0B),
          onTap: () => _navigateToReservations('pending'),
        ),
        _buildStatCard(
          title: 'Berlangsung',
          value: '${_dashboardStats['activeReservations'] ?? 0}',
          icon: Icons.dining,
          color: const Color(0xFF10B981),
          onTap: () => _navigateToReservations('active'),
        ),
        _buildStatCard(
          title: 'Selesai',
          value: '${_dashboardStats['completedReservations'] ?? 0}',
          icon: Icons.check_circle,
          color: const Color(0xFF059669),
          onTap: () => _navigateToReservations('completed'),
        ),
        _buildStatCard(
          title: 'Batal',
          value: '${_dashboardStats['cancelledReservations'] ?? 0}',
          icon: Icons.cancel,
          color: const Color(0xFFEF4444),
          onTap: () => _navigateToReservations('cancelled'),
        ),
        _buildStatCard(
          title: 'Meja Tersedia',
          value: '${_dashboardStats['availableTables'] ?? 0}',
          icon: Icons.table_restaurant,
          color: const Color(0xFF8B5CF6),
          onTap: () => _navigateToTableManagement(),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToReservations(String filter) {
    // Pass tanggal yang dipilih ke reservation management
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    context.push('/gro-reservation-management?filter=$filter&date=$dateStr').then((_) {
      // Refresh dashboard saat kembali
      _loadDashboardStats();
    });
  }

  void _navigateToTableManagement() {
    // Pass tanggal yang dipilih ke table availability
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    context.push('/gro-table-availability?date=$dateStr').then((_) {
      // Refresh dashboard saat kembali
      _loadDashboardStats();
    });
  }
}