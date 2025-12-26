// ============================================================================
// FILE: gro_table_availability_screen.dart
// OPTIMIZED VERSION - Faster Loading & Better Performance
// COMPLETE VERSION
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:skeletonizer/skeletonizer.dart'; // ✅ NEW: Skeleton loading
import '../services/gro_service.dart';
import 'gro_dinein_screen.dart';
import 'gro_reservation_screen.dart';

class GroTableAvailabilityScreen extends StatefulWidget {
  final bool isGroMode;
  final Map<String, dynamic>? dashboardStats; // ✅ Optional, kept for backwards compatibility
  final DateTime? selectedDate; // ✅ Initial date from dashboard
  final Function(int)? onTableCountLoaded; // ✅ NEW: Callback to report count to dashboard

  const GroTableAvailabilityScreen({
    super.key,
    this.isGroMode = true,
    this.dashboardStats,
    this.selectedDate,
    this.onTableCountLoaded, // ✅ NEW
  });
  
  // ✅ STATIC CACHE: Accessible from outside for invalidation
  static List<dynamic>? _cachedTables;
  static Map<String, dynamic>? _cachedSummary;
  static DateTime? _cacheTime;
  static DateTime? _cachedDate;
  static const _cacheDuration = Duration(minutes: 2);
  
  // ✅ PUBLIC: Invalidate cache on socket events
  static void invalidateCache() {
    _cachedTables = null;
    _cachedSummary = null;
    _cacheTime = null;
    _cachedDate = null;
  }

  @override
  State<GroTableAvailabilityScreen> createState() =>
      _GroTableAvailabilityScreenState();
}

class _GroTableAvailabilityScreenState
    extends State<GroTableAvailabilityScreen> with TickerProviderStateMixin {
  final GROService _groService = GROService();
  List<dynamic> _tables = [];
  Map<String, dynamic> _summary = {};
  bool _isLoading = true;
  String? _errorMessage;
  DateTime _selectedDate = DateTime.now();
  String? _selectedTime;
  String? _selectedAreaId;

  bool _isMultiSelectMode = false;
  final List<Map<String, dynamic>> _selectedTables = [];
  int _totalSelectedSeats = 0;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  // ✅ Cache untuk menghindari rebuild berulang
  Map<String, List<dynamic>>? _cachedTablesByArea;

  // ✅ Debounce untuk filter
  DateTime? _lastFilterTime;
  static const _filterDebounceMs = 300;

  final ScrollController _scrollController = ScrollController();

  final List<String> _timeSlots = [
    '09:00', '10:00', '11:00', '12:00', '13:00', '14:00',
    '15:00', '16:00', '17:00', '18:00', '19:00', '20:00', '21:00'
  ];

  final String outletId = "67cbc9560f025d897d69f889";

  @override
  void initState() {
    super.initState();
    // ✅ Use selectedDate from dashboard if available
    _selectedDate = widget.selectedDate ?? DateTime.now();
    _loadTableAvailabilityOptimized();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  @override
  void didUpdateWidget(GroTableAvailabilityScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // ✅ Reload if date changes from parent (sidebar)
    if (widget.selectedDate != oldWidget.selectedDate) {
      setState(() {
        _selectedDate = widget.selectedDate ?? DateTime.now();
      });
      _loadTableAvailability(forceRefresh: true); // ✅ Force refresh on date change
    }
  }

  Future<bool> _handleBackButton() async {
    if (_isMultiSelectMode) {
      _exitMultiSelectMode();
      return false;
    }

    if (mounted) {
      context.go('/main', extra: {'initialTab': 0});
    }
    return false;
  }

  // ✅ OPTIMIZED: Load data lebih cepat dengan parallel execution + caching
  Future<void> _loadTableAvailabilityOptimized({bool forceRefresh = false}) async {
    // ✅ Return cached data if valid, same date, and no filter applied
    if (!forceRefresh && 
        GroTableAvailabilityScreen._cachedTables != null && 
        GroTableAvailabilityScreen._cachedSummary != null && 
        GroTableAvailabilityScreen._cacheTime != null &&
        GroTableAvailabilityScreen._cachedDate != null && // ✅ Must have cached date
        _selectedTime == null && 
        _selectedAreaId == null) {
      final cacheAge = DateTime.now().difference(GroTableAvailabilityScreen._cacheTime!);
      final isSameDate = GroTableAvailabilityScreen._cachedDate!.year == _selectedDate.year &&
          GroTableAvailabilityScreen._cachedDate!.month == _selectedDate.month &&
          GroTableAvailabilityScreen._cachedDate!.day == _selectedDate.day;
      
      if (cacheAge < GroTableAvailabilityScreen._cacheDuration && isSameDate) {
        setState(() {
          _tables = GroTableAvailabilityScreen._cachedTables!;
          _summary = Map.from(GroTableAvailabilityScreen._cachedSummary!);
          _cachedTablesByArea = null;
          _isLoading = false;
        });
        return;
      }
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

      // ✅ OPTIMIZED: Run sync in background - don't wait for it
      // Sync is just for keeping data fresh, not needed for display
      _syncTableStatus(); // Fire-and-forget, no await
      
      // ✅ FAST: Only wait for the actual data fetch
      final result = await _groService.getTableAvailability(
        date: dateStr,
        time: _selectedTime != null && _selectedTime!.isNotEmpty ? _selectedTime : null,
        areaId: _selectedAreaId,
        outletId: outletId,
      );

      if (result['success'] == true || result['data'] != null) {
        final tables = result['data']['tables'] ?? [];
        final summary = result['data']['summary'] ?? {};
        
        // ✅ Cache if no filter applied - include date
        if (_selectedTime == null && _selectedAreaId == null) {
          GroTableAvailabilityScreen._cachedTables = tables;
          GroTableAvailabilityScreen._cachedSummary = summary;
          GroTableAvailabilityScreen._cacheTime = DateTime.now();
          GroTableAvailabilityScreen._cachedDate = _selectedDate; // ✅ Store cached date
        }
        
        if (!mounted) return; // ✅ Prevent setState after dispose

        setState(() {
          _tables = tables;
          _summary = summary;
          _cachedTablesByArea = null;
          _isLoading = false;
        });
        
        // ✅ NEW: Report available count to parent dashboard
        final availableCount = tables.where((t) => t['is_available'] == true).length;
        widget.onTableCountLoaded?.call(availableCount);
      } else {
        if (!mounted) return; // ✅ Prevent setState after dispose
        setState(() {
          _errorMessage = result['error'] ?? 'Gagal memuat data';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return; // ✅ Prevent setState after dispose
      setState(() {
        _errorMessage = 'Error loading table availability: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadTableAvailability({bool forceRefresh = false}) async {
    return _loadTableAvailabilityOptimized(forceRefresh: forceRefresh);
  }

  Future<void> _syncTableStatus() async {
    try {
      final result = await _groService.syncTableStatus(outletId);
      if (result['success'] == true) {
        debugPrint('✅ Table status synced successfully');
      }
    } catch (e) {
      debugPrint('⚠️ Error syncing table status: $e');
    }
  }

  void _onFilterChanged() {
    final now = DateTime.now();
    _lastFilterTime = now;

    Future.delayed(const Duration(milliseconds: _filterDebounceMs), () {
      if (_lastFilterTime == now && mounted) {
        _loadTableAvailability();
      }
    });
  }

  void _enterMultiSelectMode() {
    setState(() {
      _isMultiSelectMode = true;
    });
    _animationController.forward();
    HapticFeedback.mediumImpact();
  }

  void _exitMultiSelectMode() {
    setState(() {
      _isMultiSelectMode = false;
      _selectedTables.clear();
      _totalSelectedSeats = 0;
    });
    _animationController.reverse();
  }

  void _toggleTableSelection(Map<String, dynamic> table) {
    setState(() {
      final tableNumber = table['table_number'];
      final isAlreadySelected = _selectedTables.any(
              (t) => t['table_number'] == tableNumber
      );

      if (isAlreadySelected) {
        _selectedTables.removeWhere((t) => t['table_number'] == tableNumber);
        HapticFeedback.lightImpact();

        if (_selectedTables.isEmpty) {
          _exitMultiSelectMode();
        }
      } else {
        _selectedTables.add(table);
        HapticFeedback.mediumImpact();
      }

      _totalSelectedSeats = _selectedTables.fold(
          0, (sum, table) => sum + (table['seats'] as int? ?? 0)
      );
    });
  }

  void _proceedWithMultiTableReservation() async {
    if (_selectedTables.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih minimal 1 meja'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final areas = _selectedTables.map((t) => t['area']['_id']).toSet();
    if (areas.length > 1) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
              ),
              const SizedBox(width: 12),
              const Text('Peringatan'),
            ],
          ),
          content: const Text('Anda memilih meja dari area yang berbeda. Apakah Anda yakin ingin melanjutkan?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E8B57),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Lanjutkan'),
            ),
          ],
        ),
      );

      if (proceed != true) return;
    }

    _showMultiTableOrderTypeDialog();
  }

  void _showMultiTableOrderTypeDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [const Color(0xFF2E8B57), const Color(0xFF2E8B57).withOpacity(0.8)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.table_restaurant, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Pilih Jenis Pesanan', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        Text('${_selectedTables.length} meja dipilih', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFF2E8B57).withOpacity(0.1), const Color(0xFF2E8B57).withOpacity(0.05)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2E8B57).withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.people, color: Color(0xFF2E8B57), size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Kapasitas', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey)),
                          Text('$_totalSelectedSeats orang', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2E8B57))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildDialogOption(
                icon: Icons.restaurant_menu,
                title: 'Dine-In',
                subtitle: 'Pesan langsung untuk ${_selectedTables.length} meja',
                color: const Color(0xFF3B82F6),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToMultiTableDineIn();
                },
              ),
              const SizedBox(height: 12),
              _buildDialogOption(
                icon: Icons.event_available,
                title: 'Reservasi',
                subtitle: 'Buat reservasi untuk ${_selectedTables.length} meja',
                color: const Color(0xFF2E8B57),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToMultiTableReservation();
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDialogOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color.withOpacity(0.1), color.withOpacity(0.05)]),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [color, color.withOpacity(0.8)]),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 20, color: color),
          ],
        ),
      ),
    );
  }

  void _navigateToMultiTableDineIn() async {
    final tableNumbers = _selectedTables.map((table) => table['table_number'] as String).toList();
    final firstTable = _selectedTables.first;
    final areaCode = firstTable['area']?['area_code'] ?? 'N/A';

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroDineInGuestFormScreen(
          tableNumbers: tableNumbers,
          areaCode: areaCode,
          totalSeats: _totalSelectedSeats,
          isMultiTable: true,
        ),
      ),
    );

    if (result == true) {
      _exitMultiSelectMode();
      _loadTableAvailability();
    }
  }

  void _navigateToMultiTableReservation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateReservationScreen(
          selectedTables: _selectedTables,
          selectedDate: _selectedDate,
          selectedTime: _selectedTime,
          isGroMode: true,
          totalSeats: _totalSelectedSeats,
        ),
      ),
    );

    if (result == true) {
      _exitMultiSelectMode();
      _loadTableAvailability();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 768;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (!didPop) await _handleBackButton();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: _isMultiSelectMode ? const Color(0xFF2E8B57) : Colors.white,
          foregroundColor: _isMultiSelectMode ? Colors.white : Colors.black,
          leading: IconButton(
            icon: Icon(_isMultiSelectMode ? Icons.close : Icons.arrow_back),
            onPressed: _handleBackButton,
          ),
          title: Text(
            _isMultiSelectMode ? '${_selectedTables.length} Meja Dipilih' : 'Ketersediaan Meja',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20, color: _isMultiSelectMode ? Colors.white : Colors.black),
          ),
          centerTitle: true,
          elevation: _isMultiSelectMode ? 4 : 0,
          actions: [
            if (_isMultiSelectMode && _selectedTables.isNotEmpty)
              IconButton(
                onPressed: _proceedWithMultiTableReservation,
                icon: const Icon(Icons.check_circle, color: Colors.white),
                tooltip: 'Lanjutkan Reservasi',
              ),
            const SizedBox(width: 8),
          ],
        ),
        body: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: _isMultiSelectMode ? 72 : 0,
              child: _isMultiSelectMode ? _buildModernMultiSelectBanner() : const SizedBox(),
            ),
            _buildFilters(),
            _buildSummaryCard(isTablet),
            Expanded(
              child: _errorMessage != null
                  ? _buildErrorState()
                  : Skeletonizer(
                      enabled: _isLoading, // ✅ Skeleton effect when loading
                      enableSwitchAnimation: true,
                      child: _buildTableGrid(isTablet),
                    ),
            ),
          ],
        ),
        floatingActionButton: _isMultiSelectMode && _selectedTables.isNotEmpty
            ? ScaleTransition(
          scale: _scaleAnimation,
          child: FloatingActionButton.extended(
            onPressed: _proceedWithMultiTableReservation,
            backgroundColor: const Color(0xFF2E8B57),
            icon: const Icon(Icons.event_available, color: Colors.white),
            label: Text('Order ${_selectedTables.length} Meja', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        )
            : null,
      ),
    );
  }

  Widget _buildModernMultiSelectBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [const Color(0xFF2E8B57).withOpacity(0.1), const Color(0xFF2E8B57).withOpacity(0.05)]),
        border: Border(bottom: BorderSide(color: const Color(0xFF2E8B57).withOpacity(0.3))),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFF2E8B57), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.touch_app, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Mode Pilih Banyak Meja', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2E8B57))),
                const SizedBox(height: 2),
                Text(
                  _selectedTables.isEmpty ? 'Tap meja untuk menambah/mengurangi' : 'Total kapasitas: $_totalSelectedSeats orang',
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
          if (_selectedTables.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: const Color(0xFF2E8B57), borderRadius: BorderRadius.circular(20)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.people, color: Colors.white, size: 18),
                  const SizedBox(width: 6),
                  Text('$_totalSelectedSeats', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 768;
    
    // ✅ Hide filters on tablet view (centralized in sidebar)
    if (isTablet) {
      return const SizedBox.shrink();
    }
    
    // Show filters on mobile view
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Filter', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: InkWell(
                  onTap: _selectDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 20),
                        const SizedBox(width: 8),
                        Flexible(child: Text(DateFormat('dd MMM yyyy', 'id_ID').format(_selectedDate), style: const TextStyle(fontSize: 14), overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: DropdownButtonFormField<String>(
                  value: _selectedTime,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    prefixIcon: const Icon(Icons.access_time, size: 20),
                  ),
                  isExpanded: true,
                  hint: const Text('Waktu'),
                  items: [
                    const DropdownMenuItem<String>(value: '', child: Text('Semua Waktu')),
                    ..._timeSlots.map((time) => DropdownMenuItem(value: time, child: Text(time))),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedTime = (value == null || value.isEmpty) ? null : value;
                    });
                    _onFilterChanged();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      _onFilterChanged();
    }
  }

  Widget _buildSummaryCard(bool isTablet) {
    // ✅ NEW LOGIC: Count based on is_available (occupancy) not is_active (orders)
    final total = _tables.length;
    final occupied = _tables.where((t) => t['is_available'] == false).length;
    final available = total - occupied;
    
    // ✅ Find tables that are occupied but have no active order
    final occupiedWithoutOrders = _tables.where((t) => 
      t['is_available'] == false && t['is_active'] == false
    ).toList();
    
    // 🔍 DEBUG: Show table status
    print('📊 TABLE AVAILABILITY:');
    print('   Total tables: $total');
    print('   Occupied (is_available=false): $occupied');
    print('   Available: $available');
    print('   Occupied without orders: ${occupiedWithoutOrders.length}');
    
    if (occupiedWithoutOrders.isNotEmpty) {
      print('   ⚠️ Tables occupied without active orders:');
      for (var table in occupiedWithoutOrders) {
        print('      - ${table['table_number']} (is_available: ${table['is_available']}, is_active: ${table['is_active']})');
      }
    }

    if (total == 0) return const SizedBox();

    return Container(
      margin: EdgeInsets.all(isTablet ? 12 : 16),
      padding: EdgeInsets.all(isTablet ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Expanded(child: _buildSummaryItem('Total', total.toString(), const Color(0xFF3B82F6), Icons.table_restaurant, isTablet)),
          Container(width: 1, height: isTablet ? 30 : 40, color: Colors.grey[300]),
          Expanded(child: _buildSummaryItem('Tersedia', available.toString(), const Color(0xFF10B981), Icons.check_circle, isTablet)),
          Container(width: 1, height: isTablet ? 30 : 40, color: Colors.grey[300]),
          Expanded(child: _buildSummaryItem('Terisi', occupied.toString(), const Color(0xFFEF4444), Icons.cancel, isTablet)),
          // ✅ Show alert icon if there are occupied tables without orders
          if (occupiedWithoutOrders.isNotEmpty) ...[
            Container(width: 1, height: isTablet ? 30 : 40, color: Colors.grey[300]),
            GestureDetector(
              onTap: () => _showOccupiedTablesWithoutOrdersDialog(occupiedWithoutOrders),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.orange, size: isTablet ? 20 : 24),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              occupiedWithoutOrders.length.toString(),
                              style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isTablet ? 2 : 4),
                    Text('No Order', style: TextStyle(fontSize: isTablet ? 9 : 10, color: Colors.orange, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  // ✅ NEW: Dialog to show occupied tables without active orders
  void _showOccupiedTablesWithoutOrdersDialog(List<dynamic> tables) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Meja Terisi Tanpa Order', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Meja berikut ditandai terisi (merah) tapi tidak memiliki orderan aktif:',
                style: TextStyle(color: Colors.grey[700]),
              ),
              const SizedBox(height: 16),
              Container(
                constraints: const BoxConstraints(maxHeight: 300),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: tables.length,
                  itemBuilder: (context, index) {
                    final table = tables[index];
                    final tableNumber = table['table_number'] ?? 'N/A';
                    final areaName = table['area']?['area_name'] ?? 'Unknown';
                    final seats = table['seats'] ?? 0;
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              tableNumber,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(areaName, style: const TextStyle(fontWeight: FontWeight.w600)),
                                Text('$seats kursi', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color, IconData icon, bool isTablet) {
    return Column(
      children: [
        Icon(icon, color: color, size: isTablet ? 20 : 24),
        SizedBox(height: isTablet ? 2 : 4),
        Text(value, style: TextStyle(fontSize: isTablet ? 16 : 20, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontSize: isTablet ? 10 : 12, color: Colors.grey)),
      ],
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
            Text(_errorMessage ?? 'Terjadi kesalahan', textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadTableAvailability,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E8B57), foregroundColor: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, List<dynamic>> _getTablesByArea() {
    if (_cachedTablesByArea != null) return _cachedTablesByArea!;

    final Map<String, List<dynamic>> tablesByArea = {};
    for (var table in _tables) {
      final area = table['area'];
      if (area != null) {
        final areaName = area['area_name'] ?? 'Unknown Area';
        tablesByArea.putIfAbsent(areaName, () => []).add(table);
      }
    }

    _cachedTablesByArea = tablesByArea;
    return tablesByArea;
  }

  Widget _buildTableGrid(bool isTablet) {
    if (_tables.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.table_restaurant, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text('Tidak ada data meja', style: TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
      );
    }

    final tablesByArea = _getTablesByArea();

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.fromLTRB(isTablet ? 12 : 16, isTablet ? 12 : 16, isTablet ? 12 : 16, 100),
      itemCount: tablesByArea.length,
      itemBuilder: (context, index) {
        final areaName = tablesByArea.keys.elementAt(index);
        final tables = tablesByArea[areaName]!;
        return _buildAreaSection(areaName, tables, isTablet);
      },
    );
  }

  Widget _buildAreaSection(String areaName, List<dynamic> tables, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: isTablet ? 6 : 8),
          child: Text(areaName, style: TextStyle(fontSize: isTablet ? 16 : 18, fontWeight: FontWeight.bold, color: const Color(0xFF2E8B57))),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isTablet ? 7 : 3,
            crossAxisSpacing: isTablet ? 10 : 12,
            mainAxisSpacing: isTablet ? 10 : 12,
            childAspectRatio: isTablet ? 0.95 : 0.85,
          ),
          itemCount: tables.length,
          itemBuilder: (context, index) => _buildTableCard(tables[index], isTablet),
        ),
        SizedBox(height: isTablet ? 16 : 24),
      ],
    );
  }

  Widget _buildTableCard(Map<String, dynamic> table, bool isTablet) {
    final tableNumber = table['table_number'] ?? 'N/A';
    final seats = table['seats'] ?? 0;
    final isAvailable = table['is_available'] ?? false;
    final isActive = table['is_active'] ?? false;
    final isSelected = _isMultiSelectMode && _selectedTables.any((t) => t['table_number'] == tableNumber);

    Color backgroundColor;
    Color textColor;
    IconData icon;

    if (!isActive) {
      backgroundColor = Colors.grey[300]!;
      textColor = Colors.grey[600]!;
      icon = Icons.block;
    } else if (isSelected) {
      backgroundColor = const Color(0xFF2E8B57);
      textColor = Colors.white;
      icon = Icons.check_circle;
    } else if (isAvailable) {
      backgroundColor = const Color(0xFF10B981).withOpacity(0.1);
      textColor = const Color(0xFF10B981);
      icon = Icons.check_circle;
    } else {
      backgroundColor = const Color(0xFFEF4444).withOpacity(0.1);
      textColor = const Color(0xFFEF4444);
      icon = Icons.event_seat;
    }

    return GestureDetector(
      onLongPress: isActive && isAvailable ? () {
        if (!_isMultiSelectMode) {
          _enterMultiSelectMode();
          _toggleTableSelection(table);
        }
      } : null,
      onTap: isActive ? () => _onTableTap(table) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(isTablet ? 10 : 12),
          border: Border.all(
            color: isSelected ? const Color(0xFF2E8B57) : textColor.withOpacity(0.3),
            width: isSelected ? 2.5 : 2,
          ),
          boxShadow: isSelected ? [
            BoxShadow(color: const Color(0xFF2E8B57).withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 3)),
          ] : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(icon, color: textColor, size: isTablet ? 24 : 32, key: ValueKey(isSelected)),
            ),
            SizedBox(height: isTablet ? 4 : 8),
            Text(tableNumber, style: TextStyle(fontSize: isTablet ? 14 : 18, fontWeight: FontWeight.bold, color: textColor)),
            SizedBox(height: isTablet ? 2 : 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person, size: isTablet ? 12 : 14, color: textColor),
                SizedBox(width: isTablet ? 2 : 4),
                Text('$seats', style: TextStyle(fontSize: isTablet ? 10 : 12, color: textColor)),
              ],
            ),
            SizedBox(height: isTablet ? 2 : 4),
            Text(
              isSelected ? 'Dipilih' : isActive ? (isAvailable ? 'Tersedia' : 'Terisi') : 'Nonaktif',
              style: TextStyle(fontSize: isTablet ? 9 : 11, fontWeight: FontWeight.w500, color: textColor),
            ),
          ],
        ),
      ),
    );
  }

  void _onTableTap(Map<String, dynamic> table) async {
    final isAvailable = table['is_available'] ?? false;
    final isActive = table['is_active'] ?? false;

    if (!isActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Meja ini sedang nonaktif'), backgroundColor: Colors.grey),
      );
      return;
    }

    if (_isMultiSelectMode) {
      if (isAvailable) {
        _toggleTableSelection(table);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hanya meja tersedia yang dapat dipilih'), backgroundColor: Colors.orange, duration: Duration(seconds: 2)),
        );
      }
      return;
    }

    if (isAvailable) {
      _showOrderTypeDialog(table);
    } else {
      try {
        _showTableOrderDetail(table);
      } catch (e) {
        _showNoOrderDialog(table);
      }
    }
  }

  void _showOrderTypeDialog(Map<String, dynamic> table) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360), // Limit width
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              // Header
              Text(
                'Meja ${table['table_number']}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Pilih jenis pesanan untuk meja ini:',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              
              // Tip box - gray theme
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey.shade600, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Tip: Tekan & tahan meja untuk memilih banyak meja sekaligus',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // Dine-In option - white/gray theme
              _buildCleanDialogOption(
                icon: Icons.restaurant,
                title: 'Dine-In',
                subtitle: 'Pesan langsung untuk meja ini',
                iconBgColor: const Color(0xFF2E8B57),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToDineIn(table);
                },
              ),
              const SizedBox(height: 12),
              
              // Reservasi option - white/gray theme
              _buildCleanDialogOption(
                icon: Icons.event_available,
                title: 'Reservasi',
                subtitle: 'Buat reservasi untuk meja ini',
                iconBgColor: Colors.grey.shade700,
                onTap: () {
                  Navigator.pop(context);
                  _navigateToReservation(table);
                },
              ),
              const SizedBox(height: 20),
              
              // Cancel button
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Batal',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
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
  
  // Clean dialog option with white/gray theme
  Widget _buildCleanDialogOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconBgColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 24, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  void _navigateToDineIn(Map<String, dynamic> table) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroDineInGuestFormScreen(
          tableNumber: table['table_number'],
          areaCode: table['area']?['area_code'] ?? 'N/A',
        ),
      ),
    ).then((result) {
      if (result == true) _loadTableAvailability();
    });
  }

  void _navigateToReservation(Map<String, dynamic> table) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateReservationScreen(
          selectedTable: table,
          selectedDate: _selectedDate,
          selectedTime: _selectedTime,
          isGroMode: true,
        ),
      ),
    );

    if (result == true) _loadTableAvailability();
  }

  void _showTableOrderDetail(Map<String, dynamic> table) async {
    final tableNumber = table['table_number'] ?? 'N/A';
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final result = await _groService.getTableOrderDetail(tableNumber: tableNumber, date: dateStr);

      if (mounted) Navigator.pop(context);

      if (result['success'] && result['data'] != null) {
        final orderData = result['data'];
        _showOrderDetailBottomSheet(orderData, table);
      } else {
        _showNoOrderDialog(table);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  void _showNoOrderDialog(Map<String, dynamic> table) {
    final tableNumber = table['table_number'] ?? 'N/A';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Meja $tableNumber'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline, size: 48, color: Colors.orange),
            const SizedBox(height: 16),
            const Text('Tidak Ada Order Aktif', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Text(
              'Sistem tidak menemukan order aktif untuk meja $tableNumber. Status meja saat ini terdeteksi sebagai terisi, tetapi tidak ada data order.',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: const Text(
                'Anda dapat membebaskan meja ini untuk mengatur statusnya menjadi tersedia.',
                style: TextStyle(fontSize: 12, color: Colors.orange),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _freeUpTable(table);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E8B57), foregroundColor: Colors.white),
            child: const Text('Bebaskan Meja'),
          ),
        ],
      ),
    );
  }

  void _showOrderDetailBottomSheet(Map<String, dynamic> orderData, Map<String, dynamic> table) {
    final tableNumber = table['table_number'] ?? 'N/A';
    final orderId = orderData['_id'];
    final guestName = orderData['guest_name'] ?? 'Tamu';
    final guestCount = orderData['guest_count'] ?? 0;
    final orderItems = orderData['items'] ?? [];
    final totalAmount = orderData['total_amount'] ?? 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(color: Color(0xFF2E8B57), borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
              child: SafeArea(
                bottom: false,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.restaurant, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Meja $tableNumber', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                          Text('$guestName • $guestCount orang', style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.9))),
                        ],
                      ),
                    ),
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white)),
                  ],
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Pesanan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    if (orderItems.isEmpty)
                      const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('Belum ada pesanan')))
                    else
                      ...orderItems.map((item) => Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item['name'] ?? 'Item', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                  if (item['notes'] != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(item['notes'], style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                    ),
                                ],
                              ),
                            ),
                            Text('${item['quantity']}x', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            const SizedBox(width: 12),
                            Text('Rp ${(item['price'] ?? 0).toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          ],
                        ),
                      )),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E8B57).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF2E8B57).withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text('Rp ${totalAmount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2E8B57))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -4))]),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _transferOrderToNewTable(table, orderData);
                        },
                        icon: const Icon(Icons.swap_horiz),
                        label: const Text('Pindah Meja'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: Color(0xFF3B82F6)),
                          foregroundColor: const Color(0xFF3B82F6),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _completeOrder(orderId);
                        },
                        icon: const Icon(Icons.check_circle),
                        label: const Text('Selesai'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E8B57),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _freeUpTable(Map<String, dynamic> table) async {
    final tableNumber = table['table_number'] ?? 'N/A';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bebaskan Meja'),
        content: Text('Apakah Anda yakin ingin membebaskan meja $tableNumber?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performFreeUpTable(table);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E8B57)),
            child: const Text('Ya, Bebaskan Meja'),
          ),
        ],
      ),
    );
  }

  Future<void> _performFreeUpTable(Map<String, dynamic> table) async {
    final tableNumber = table['table_number'] ?? 'N/A';

    showDialog(context: context, barrierDismissible: false, builder: (context) => const Center(child: CircularProgressIndicator()));

    try {
      final result = await _groService.forceResetTableStatus(tableNumber, outletId);

      if (mounted) Navigator.pop(context);

      if (result['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'Meja berhasil dibebaskan'), backgroundColor: Colors.green),
          );
        }
        await Future.delayed(const Duration(seconds: 1));
        await _loadTableAvailability();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['error'] ?? 'Gagal membebaskan meja'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  void _transferOrderToNewTable(Map<String, dynamic> table, Map<String, dynamic> orderData) async {
    final currentTableNumber = table['table_number'] ?? 'N/A';
    final orderId = orderData['_id'];

    showDialog(context: context, barrierDismissible: false, builder: (context) => const Center(child: CircularProgressIndicator()));

    try {
      final result = await _groService.getAllAvailableTables(outletId: outletId);

      if (mounted) Navigator.pop(context);

      if (result['success'] == true) {
        final availableTables = result['data']['tables'] ?? [];
        final tablesByArea = result['data']['tablesByArea'] ?? {};

        if (availableTables.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Tidak ada meja tersedia saat ini'), backgroundColor: Colors.orange),
            );
          }
          return;
        }

        _showTableSelectionDialog(currentTableNumber, orderId, availableTables, tablesByArea, orderData);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['error'] ?? 'Gagal memuat meja tersedia'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  void _showTableSelectionDialog(
      String currentTableNumber,
      String orderId,
      List<dynamic> availableTables,
      Map<String, dynamic> tablesByArea,
      Map<String, dynamic> orderData) {
    String? selectedTable;
    String reason = '';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Pindah ke Meja Lain'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Memindahkan dari Meja: $currentTableNumber', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 16),
                  const Text('Alasan Pemindahan:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    decoration: const InputDecoration(
                      hintText: 'Contoh: Hujan, AC rusak, request customer...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    maxLines: 2,
                    onChanged: (value) => setState(() => reason = value),
                  ),
                  const SizedBox(height: 16),
                  const Text('Pilih Meja Tujuan:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...tablesByArea.entries.map((areaEntry) {
                    final areaName = areaEntry.key;
                    final tables = areaEntry.value as List<dynamic>;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(areaName, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF2E8B57))),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: tables.map((table) {
                            final tableNumber = table['table_number'];
                            final seats = table['seats'];
                            final isSelected = selectedTable == tableNumber;

                            return ChoiceChip(
                              label: Text('$tableNumber ($seats)'),
                              selected: isSelected,
                              onSelected: (selected) => setState(() => selectedTable = selected ? tableNumber : null),
                              backgroundColor: Colors.grey[200],
                              selectedColor: const Color(0xFF2E8B57).withOpacity(0.2),
                              labelStyle: TextStyle(
                                color: isSelected ? const Color(0xFF2E8B57) : Colors.black,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                      ],
                    );
                  }),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
              ElevatedButton(
                onPressed: selectedTable != null
                    ? () async {
                  Navigator.pop(context);
                  await _performTableTransfer(currentTableNumber, selectedTable!, orderId, reason, orderData);
                }
                    : null,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E8B57), foregroundColor: Colors.white),
                child: const Text('Pindahkan'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _performTableTransfer(
      String currentTable, String newTable, String orderId, String reason, Map<String, dynamic> orderData) async {
    showDialog(context: context, barrierDismissible: false, builder: (context) => const Center(child: CircularProgressIndicator()));

    try {
      final result = await _groService.transferOrderToTable(
        orderId: orderId,
        newTableNumber: newTable,
        transferredBy: 'GRO Staff',
        reason: reason.isNotEmpty ? reason : 'Pemindahan meja oleh GRO',
      );

      if (mounted) Navigator.pop(context);

      if (result['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'Order berhasil dipindahkan ke meja $newTable'), backgroundColor: Colors.green),
          );
        }
        _loadTableAvailability();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['error'] ?? 'Gagal memindahkan order'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _completeOrder(String orderId) async {
    showDialog(context: context, barrierDismissible: false, builder: (context) => const Center(child: CircularProgressIndicator()));

    try {
      final result = await _groService.completeTableOrder(orderId);

      if (mounted) Navigator.pop(context);

      if (result['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'Pesanan berhasil diselesaikan'), backgroundColor: Colors.green),
          );
        }
        _loadTableAvailability();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['error'] ?? 'Gagal menyelesaikan pesanan'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }
}