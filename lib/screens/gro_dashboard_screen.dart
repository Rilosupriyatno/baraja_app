import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/gro_service.dart'; // ✅ Needed for mobile layout stats
import '../providers/cart_provider.dart';
import '../widgets/utils/role_based_widget.dart';
import 'gro_order_management_screen.dart';
import 'gro_table_avaibility_screen.dart';

class GroDashboardScreen extends StatefulWidget {
  const GroDashboardScreen({super.key});

  @override
  State<GroDashboardScreen> createState() => _GroDashboardScreenState();
}

class _GroDashboardScreenState extends State<GroDashboardScreen>
    with RoleCheckMixin {
  final GROService _groService = GROService(); // ✅ Needed for mobile layout
  
  // ✅ TABLET: Child screens report their data via callbacks
  int? _orderCount;       // Updated by GroOrderManagementScreen
  int? _availableTables;  // Updated by GroTableAvailabilityScreen
  
  // ✅ MOBILE: Needs full stats for stats grid
  Map<String, dynamic> _mobileStats = {};
  bool _isLoadingMobileStats = true;
  
  String? _errorMessage;
  DateTime _selectedDate = DateTime.now();
  String _selectedMenu = 'orders';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      cartProvider.setGroMode(true);
      
      final size = MediaQuery.of(context).size;
      final isTablet = size.width >= 768;
      
      if (isTablet) {
        // ✅ TABLET: Fetch table count immediately for sidebar badge
        // Don't wait for Table Availability screen to mount
        _loadTableBadgeCount();
      } else {
        // ✅ MOBILE: Load full stats for stats grid
        _loadMobileStats();
      }
    });
  }
  
  // ✅ NEW: Lightweight fetch just for table badge on tablet
  Future<void> _loadTableBadgeCount() async {
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final result = await _groService.getTableAvailability(
        date: dateStr,
        outletId: "67cbc9560f025d897d69f889",
      );
      
      if (mounted && result['success'] == true && result['data'] != null) {
        final tables = result['data']['tables'] as List? ?? [];
        final available = tables.where((t) => t['is_available'] == true).length;
        setState(() => _availableTables = available);
      }
    } catch (e) {
      // Silently fail - badge will show loading
      debugPrint('⚠️ Error loading table badge: $e');
    }
  }
  
  // ✅ NEW: Lightweight fetch just for order badge on tablet
  // This is called when date changes while on tables page (order screen not visible)
  Future<void> _loadOrderBadgeCount() async {
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final result = await _groService.getReservations(
        date: dateStr,
        page: 1,
        limit: 1, // We only need total_records, not actual data
      );
      
      if (mounted && result['success'] == true && result['pagination'] != null) {
        final totalRecords = result['pagination']['total_records'] ?? 0;
        setState(() => _orderCount = totalRecords);
      }
    } catch (e) {
      // Silently fail - badge will show loading
      debugPrint('⚠️ Error loading order badge: $e');
    }
  }
  
  // ✅ MOBILE ONLY: Load full stats for mobile dashboard cards
  Future<void> _loadMobileStats() async {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    
    setState(() {
      _isLoadingMobileStats = true;
      _errorMessage = null;
    });

    try {
      // Get reservations with stats
      final result = await _groService.getReservations(
        page: 1, limit: 1, date: dateStr,
      );

      if (result['success'] == true) {
        final filtered = result['filtered'] ?? {};
        final pagination = result['pagination'] ?? {};
        
        setState(() {
          _mobileStats = {
            'allReservations': pagination['total_records'] ?? 0,
            'pendingReservations': filtered['pending'] ?? 0,
            'activeReservations': filtered['active'] ?? 0,
            'completedReservations': filtered['completed'] ?? 0,
            'cancelledReservations': filtered['cancelled'] ?? 0,
          };
        });
      }
      
      // Get table availability
      final tableResult = await _groService.getTableAvailability(
        date: dateStr, outletId: "67cbc9560f025d897d69f889",
      );
      
      if (tableResult['success'] == true && tableResult['data'] != null) {
        final tables = tableResult['data']['tables'] as List? ?? [];
        final available = tables.where((t) => t['is_available'] == true).length;
        
        setState(() {
          _mobileStats['availableTables'] = available;
          _isLoadingMobileStats = false;
        });
      } else {
        setState(() => _isLoadingMobileStats = false);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal memuat data: $e';
        _isLoadingMobileStats = false;
      });
    }
  }
  
  // ✅ TABLET CALLBACKS: Child screens call these to update badges
  void _onOrderCountLoaded(int count) {
    if (mounted && _orderCount != count) {
      setState(() => _orderCount = count);
    }
  }
  
  void _onTableCountLoaded(int availableCount) {
    if (mounted && _availableTables != availableCount) {
      setState(() => _availableTables = availableCount);
    }
  }
  
  // ✅ MANUAL REFRESH: Forces child screens to reload via key change
  int _refreshKey = 0;
  
  void _refreshData() {
    setState(() {
      _refreshKey++;
      _orderCount = null;
      _availableTables = null;
      _isLoadingMobileStats = true;
    });
    
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 768;
    
    if (isTablet) {
      // ✅ TABLET: Reload BOTH badges
      _loadTableBadgeCount();
      _loadOrderBadgeCount(); // ✅ NEW: Also load order count on refresh
    } else {
      // ✅ MOBILE: Reload full stats
      _loadMobileStats();
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
        // ✅ Reset counts when date changes
        _orderCount = null;
        _availableTables = null;
        _refreshKey++;
      });
      
      // ✅ TABLET: Reload BOTH badges immediately (child screen will also reload its own data)
      final size = MediaQuery.of(context).size;
      if (size.width >= 768) {
        _loadTableBadgeCount();
        _loadOrderBadgeCount(); // ✅ NEW: Also load order count when date changes
      }
    }
  }

  void _navigateToGroCart() {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    debugPrint('🛒 GRO Cart Navigation - isGroMode: ${cartProvider.isGroMode}');

    context.push('/menu', extra: {
      'isGroMode': true,
    });
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.logout,
                color: Colors.red,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Keluar'),
          ],
        ),
        content: const Text('Apakah Anda yakin ingin keluar dari akun GRO?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await Provider.of<AuthService>(context, listen: false).logout();
      if (mounted) {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Deteksi ukuran layar
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 768;

    if (isTablet) {
      return _buildTabletLayout();
    } else {
      return _buildMobileLayout();
    }
  }

  // ==================== TABLET LAYOUT ====================
  Widget _buildTabletLayout() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          // SIDEBAR (Dashboard Stats)
          Container(
            width: 320,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(2, 0),
                ),
              ],
            ),
            child: _buildSidebarContent(),
          ),

          // MAIN CONTENT (Reservation List / Table Availability)
          Expanded(
            child: _buildMainContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarContent() {
    return Consumer<AuthService>(
      builder: (context, authService, _) {
        return Column(
          children: [
            // Header dengan Gradient
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2E8B57), Color(0xFF25704B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.restaurant_menu,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'GRO Dashboard',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Kelola Restoran',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Cart Icon
                      Consumer<CartProvider>(
                        builder: (context, cartProvider, child) {
                          final totalItems = cartProvider.totalItems;
                          return Stack(
                            clipBehavior: Clip.none,
                            children: [
                              IconButton(
                                onPressed: _navigateToGroCart,
                                icon: const Icon(Icons.shopping_cart),
                                color: Colors.white,
                                tooltip: 'Lihat Keranjang GRO',
                              ),
                              if (totalItems > 0)
                                Positioned(
                                  right: 6,
                                  top: 6,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 18,
                                      minHeight: 18,
                                    ),
                                    child: Text(
                                      totalItems.toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Outlet Info Compact
                  _buildOutletInfoCompact(authService),
                ],
              ),
            ),

            // Date Selector
            Padding(
              padding: const EdgeInsets.all(16),
              child: InkWell(
                onTap: _selectDate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(12),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Tanggal',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              DateFormat('dd MMM yyyy', 'id_ID')
                                  .format(_selectedDate),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
                    ],
                  ),
                ),
              ),
            ),

            // Stats Menu Items - ✅ FIXED: Flexible allows shrinking when keyboard appears
            Flexible(
              fit: FlexFit.loose, // ✅ Allows shrinking instead of forcing expansion
              child: _errorMessage != null
                  ? _buildErrorStateSidebar()
                  : ListView(
                shrinkWrap: true, // ✅ Only take needed space
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildStatMenuItem(
                    'Kelola Order',
                    _orderCount, // ✅ SIMPLIFIED: null = loading, number = value
                    Icons.restaurant,
                    const Color(0xFF2E8B57),
                    'orders',
                    subtitle: 'Semua Pesanan',
                  ),
                  const SizedBox(height: 8),
                  _buildStatMenuItem(
                    'Ketersediaan Meja',
                    _availableTables, // ✅ SIMPLIFIED: null = loading, number = value
                    Icons.table_restaurant,
                    const Color(0xFF2E8B57),
                    'tables',
                    subtitle: 'Meja Tersedia',
                  ),
                ],
              ),
            ),

            // Refresh Button
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _refreshData, // ✅ Use new refresh method
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Refresh Data'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF2E8B57),
                        side: const BorderSide(color: Color(0xFF2E8B57)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _handleLogout,
                      icon: const Icon(Icons.logout, size: 18),
                      label: const Text('Keluar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOutletInfoCompact(AuthService authService) {
    final outlets = authService.getUserOutlets();
    if (outlets.isEmpty) return const SizedBox();

    final outlet = outlets.first;
    final outletName = outlet['name'] ?? 'Nama Outlet';
    final outletCity = outlet['city'] ?? 'Kota';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.store, color: Colors.white70, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  outletName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  outletCity,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatMenuItem(
      String title,
      int? value, // ✅ CHANGED: nullable for loading state
      IconData icon,
      Color color,
      String menuKey, {
        String? subtitle,
      }) {
    final isSelected = _selectedMenu == menuKey;
    final isLoading = value == null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedMenu = menuKey;
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? color.withOpacity(0.3) : Colors.transparent,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? color : Colors.black87,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                ),
                // ✅ BADGE: Show loading spinner or value
                isLoading
                    ? Container(
                        width: 40,
                        height: 28,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Center(
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      )
                    : Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          value.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildErrorStateSidebar() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Terjadi kesalahan',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _refreshData, // ✅ Use new refresh method
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E8B57),
                foregroundColor: Colors.white,
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    if (_selectedMenu == 'tables') {
      return GroTableAvailabilityScreen(
        key: ValueKey('tables_$_refreshKey'), // ✅ Force rebuild when refresh
        isGroMode: true,
        selectedDate: _selectedDate,
        onTableCountLoaded: _onTableCountLoaded, // ✅ NEW: Callback to update badge
      );
    }

    return GroOrderManagementScreen(
      key: ValueKey('orders_$_refreshKey'), // ✅ Force rebuild when refresh
      filter: 'all',
      initialDate: DateFormat('yyyy-MM-dd').format(_selectedDate),
      onOrderCountLoaded: _onOrderCountLoaded, // ✅ NEW: Callback to update badge
    );
  }

  // ==================== MOBILE LAYOUT ====================
  Widget _buildMobileLayout() {
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
              ],
            );
          },
        ),
        centerTitle: false,
        elevation: 0,
        actions: [
          Consumer<CartProvider>(
            builder: (context, cartProvider, child) {
              final totalItems = cartProvider.totalItems;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    onPressed: _navigateToGroCart,
                    icon: const Icon(Icons.shopping_cart),
                    color: Colors.black,
                    tooltip: 'Lihat Keranjang GRO',
                    splashRadius: 24,
                  ),
                  if (totalItems > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          totalItems.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            onPressed: _refreshData, // ✅ FIXED: Use new refresh method
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            splashRadius: 24,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refreshData(),
        child: _isLoadingMobileStats // ✅ FIXED: Use mobile loading state
            ? const Center(
            child: CircularProgressIndicator(color: Color(0xFF2E8B57)))
            : _errorMessage != null
            ? _buildErrorState()
            : _buildDashboardContent(),
      ),
    );
  }

  Widget _buildDashboardContent() {
    return Consumer<AuthService>(
      builder: (context, authService, _) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
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
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
            _buildGroCartCard(),
          ],
        );
      },
    );
  }

  Widget _buildOutletCard(AuthService authService) {
    final outlets = authService.getUserOutlets();
    if (outlets.isEmpty) return const SizedBox();

    final outlet = outlets.first;
    final outletName = outlet['name'] ?? 'Nama Outlet';
    final outletAddress = outlet['address'] ?? 'Alamat Outlet';
    final outletPhone =
        outlet['contactNumber'] ?? outlet['phone'] ?? 'No Telepon';
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
          _buildOpenStatus(outlet),
        ],
      ),
    );
  }

  Widget _buildOpenStatus(Map<String, dynamic> outlet) {
    final now = DateTime.now();
    final currentTime = DateFormat('HH:mm').format(now);
    final openTime = outlet['openTime'] ?? '06:00';
    final closeTime = outlet['closeTime'] ?? '02:00';
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

  bool _isOutletOpen(String openTime, String closeTime, String currentTime) {
    try {
      final open = _timeToMinutes(openTime);
      final close = _timeToMinutes(closeTime);
      final current = _timeToMinutes(currentTime);

      if (close < open) {
        return current >= open || current <= close;
      } else {
        return current >= open && current <= close;
      }
    } catch (e) {
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
              Icon(Icons.restaurant_menu, color: Colors.white, size: 24),
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
                    DateFormat('EEEE, dd MMMM yyyy', 'id_ID')
                        .format(_selectedDate),
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
          value: '${_mobileStats['allReservations'] ?? 0}',
          icon: Icons.history,
          color: const Color(0xFF6366F1),
          onTap: () => _navigateToReservations('all'),
        ),
        _buildStatCard(
          title: 'Menunggu',
          value: '${_mobileStats['pendingReservations'] ?? 0}',
          icon: Icons.schedule,
          color: const Color(0xFFF59E0B),
          onTap: () => _navigateToReservations('pending'),
        ),
        _buildStatCard(
          title: 'Berlangsung',
          value: '${_mobileStats['activeReservations'] ?? 0}',
          icon: Icons.dining,
          color: const Color(0xFF10B981),
          onTap: () => _navigateToReservations('active'),
        ),
        _buildStatCard(
          title: 'Selesai',
          value: '${_mobileStats['completedReservations'] ?? 0}',
          icon: Icons.check_circle,
          color: const Color(0xFF059669),
          onTap: () => _navigateToReservations('completed'),
        ),
        _buildStatCard(
          title: 'Batal',
          value: '${_mobileStats['cancelledReservations'] ?? 0}',
          icon: Icons.cancel,
          color: const Color(0xFFEF4444),
          onTap: () => _navigateToReservations('cancelled'),
        ),
        _buildStatCard(
          title: 'Meja Tersedia',
          value: '${_mobileStats['availableTables'] ?? 0}',
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

  Widget _buildGroCartCard() {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, child) {
        final totalItems = cartProvider.totalItems;
        final totalPrice = cartProvider.totalPrice;

        return GestureDetector(
          onTap: _navigateToGroCart,
          child: Container(
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
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF076A3B).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(
                        Icons.shopping_cart,
                        color: Color(0xFF076A3B),
                        size: 24,
                      ),
                      if (totalItems > 0)
                        Positioned(
                          right: -4,
                          top: -4,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              totalItems.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Keranjang GRO',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        totalItems > 0
                            ? '$totalItems item • ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(totalPrice)}'
                            : 'Keranjang kosong',
                        style: TextStyle(
                          fontSize: 14,
                          color: totalItems > 0
                              ? Colors.green.shade700
                              : Colors.grey.shade600,
                          fontWeight: totalItems > 0
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF076A3B),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.arrow_forward,
                        color: Colors.white,
                        size: 16,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Lihat',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
              onPressed: _loadMobileStats, // ✅ FIXED: Use mobile stats method
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E8B57),
                foregroundColor: Colors.white,
                padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _navigateToGroCart,
              icon: const Icon(Icons.shopping_cart),
              label: const Text('Lihat Keranjang'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF076A3B),
                foregroundColor: Colors.white,
                padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToReservations(String filter) {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    context.push(
      '/gro-reservation-management?filter=$filter&date=$dateStr',
      extra: {
        'dashboardStats': _mobileStats, // ✅ Use mobile stats
      },
    ).then((_) {
      _loadMobileStats(); // ✅ Reload mobile stats on return
    });
  }

  void _navigateToTableManagement() {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    context.push('/gro-table-availability', extra: {
      'date': dateStr,
      'selectedDate': _selectedDate,
    }).then((_) {
      _loadMobileStats(); // ✅ Reload mobile stats on return
    });
  }
}