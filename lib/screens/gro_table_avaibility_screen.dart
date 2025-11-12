// ============================================================================
// FILE: gro_table_availability_screen.dart
// FULL CODE dengan Multi-Select Table Feature
// ============================================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/gro_service.dart';
import 'gro_dinein_screen.dart';
import 'gro_reservation_screen.dart';

class GroTableAvailabilityScreen extends StatefulWidget {
  final bool isGroMode;

  const GroTableAvailabilityScreen({
    super.key,
    this.isGroMode = true,
  });

  @override
  State<GroTableAvailabilityScreen> createState() =>
      _GroTableAvailabilityScreenState();
}

class _GroTableAvailabilityScreenState
    extends State<GroTableAvailabilityScreen> {
  final GROService _groService = GROService();
  List<dynamic> _tables = [];
  Map<String, dynamic> _summary = {};
  bool _isLoading = true;
  String? _errorMessage;
  DateTime _selectedDate = DateTime.now();
  String? _selectedTime;
  String? _selectedAreaId;

  // ✅ MULTI-SELECT STATE
  bool _isMultiSelectMode = false;
  final List<Map<String, dynamic>> _selectedTables = [];
  int _totalSelectedSeats = 0;

  final List<String> _timeSlots = [
    '09:00', '10:00', '11:00', '12:00', '13:00', '14:00',
    '15:00', '16:00', '17:00', '18:00', '19:00', '20:00', '21:00'
  ];

  final String outletId = "67cbc9560f025d897d69f889";

  @override
  void initState() {
    super.initState();
    _loadTableAvailability();
  }

  Future<void> _loadTableAvailability({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _syncTableStatus();

      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

      final Map<String, String> queryParams = {
        'date': dateStr,
        'outletId': outletId,
        '_t': DateTime.now().millisecondsSinceEpoch.toString(),
      };

      if (_selectedTime != null && _selectedTime!.isNotEmpty) {
        queryParams['time'] = _selectedTime!;
      }
      if (_selectedAreaId != null) {
        queryParams['area_id'] = _selectedAreaId!;
      }

      final result = await _groService.getTableAvailability(
        date: dateStr,
        time: _selectedTime != null && _selectedTime!.isNotEmpty ? _selectedTime : null,
        areaId: _selectedAreaId,
        outletId: outletId,
      );

      if (result['success'] == true || result['data'] != null) {
        setState(() {
          _tables = result['data']['tables'] ?? [];
          _summary = result['data']['summary'] ?? {};
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = result['error'] ?? 'Gagal memuat data';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading table availability: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _syncTableStatus() async {
    try {
      final result = await _groService.syncTableStatus(outletId);
      if (result['success'] == true) {
        print('✅ Table status synced successfully');
      }
    } catch (e) {
      print('❌ Error syncing table status: $e');
    }
  }

  // ✅ MULTI-SELECT METHODS
  void _enterMultiSelectMode() {
    setState(() {
      _isMultiSelectMode = true;
      _selectedTables.clear();
      _totalSelectedSeats = 0;
    });
  }

  void _exitMultiSelectMode() {
    setState(() {
      _isMultiSelectMode = false;
      _selectedTables.clear();
      _totalSelectedSeats = 0;
    });
  }

  void _toggleTableSelection(Map<String, dynamic> table) {
    setState(() {
      final tableNumber = table['table_number'];
      final isAlreadySelected = _selectedTables.any(
              (t) => t['table_number'] == tableNumber
      );

      if (isAlreadySelected) {
        _selectedTables.removeWhere((t) => t['table_number'] == tableNumber);
      } else {
        _selectedTables.add(table);
      }

      _totalSelectedSeats = _selectedTables.fold(
          0,
              (sum, table) => sum + (table['seats'] as int? ?? 0)
      );
    });
  }

  void _proceedWithMultiTableReservation() async {
    if (_selectedTables.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih minimal 1 meja untuk reservasi'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Validasi: cek apakah semua meja dari area yang sama
    final areas = _selectedTables.map((t) => t['area']['_id']).toSet();
    if (areas.length > 1) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Peringatan'),
          content: const Text(
              'Anda memilih meja dari area yang berbeda. '
                  'Apakah Anda yakin ingin melanjutkan?'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E8B57),
              ),
              child: const Text('Lanjutkan'),
            ),
          ],
        ),
      );

      if (proceed != true) return;
    }

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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: Text(
          _isMultiSelectMode
              ? '${_selectedTables.length} Meja Dipilih'
              : 'Ketersediaan Meja',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        leading: _isMultiSelectMode
            ? IconButton(
          icon: const Icon(Icons.close),
          onPressed: _exitMultiSelectMode,
        )
            : null,
        actions: [
          if (!_isMultiSelectMode) ...[
            IconButton(
              onPressed: _enterMultiSelectMode,
              icon: const Icon(Icons.add_box_outlined),
              tooltip: 'Pilih Banyak Meja',
              splashRadius: 24,
            ),
            IconButton(
              onPressed: _loadTableAvailability,
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
              splashRadius: 24,
            ),
          ] else ...[
            if (_selectedTables.isNotEmpty)
              IconButton(
                onPressed: _proceedWithMultiTableReservation,
                icon: const Icon(Icons.check, color: Color(0xFF2E8B57)),
                tooltip: 'Lanjutkan Reservasi',
                splashRadius: 24,
              ),
          ],
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          if (_isMultiSelectMode) _buildMultiSelectBanner(),
          _buildFilters(),
          _buildSummaryCard(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? _buildErrorState()
                : _buildTableGrid(),
          ),
        ],
      ),
      floatingActionButton: _isMultiSelectMode && _selectedTables.isNotEmpty
          ? FloatingActionButton.extended(
        onPressed: _proceedWithMultiTableReservation,
        backgroundColor: const Color(0xFF2E8B57),
        icon: const Icon(Icons.check, color: Colors.white),
        label: Text(
          'Reservasi ${_selectedTables.length} Meja',
          style: const TextStyle(color: Colors.white),
        ),
      )
          : null,
    );
  }

  Widget _buildMultiSelectBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2E8B57).withOpacity(0.1),
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFF2E8B57).withOpacity(0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF2E8B57),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.touch_app,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mode Pilih Banyak Meja',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E8B57),
                  ),
                ),
                Text(
                  _selectedTables.isEmpty
                      ? 'Tap meja untuk memilih'
                      : 'Total kapasitas: $_totalSelectedSeats orang',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
          if (_selectedTables.isNotEmpty)
            Chip(
              label: Text(
                '$_totalSelectedSeats 👤',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E8B57),
                ),
              ),
              backgroundColor: Colors.white,
              side: const BorderSide(color: Color(0xFF2E8B57)),
            ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filter',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: InkWell(
                  onTap: _selectDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 20),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            DateFormat('dd MMM yyyy', 'id_ID')
                                .format(_selectedDate),
                            style: const TextStyle(fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
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
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.access_time, size: 20),
                  ),
                  isExpanded: true,
                  hint: const Text('Waktu'),
                  items: [
                    const DropdownMenuItem<String>(
                      value: '',
                      child: Text('Semua Waktu'),
                    ),
                    ..._timeSlots.map((time) => DropdownMenuItem(
                      value: time,
                      child: Text(time),
                    )),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedTime = (value == null || value.isEmpty) ? null : value;
                    });
                    _loadTableAvailability();
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
      _loadTableAvailability();
    }
  }

  Widget _buildSummaryCard() {
    if (_summary.isEmpty) return const SizedBox();

    final total = _summary['total'] ?? 0;
    final available = _summary['available'] ?? 0;
    final occupied = _summary['occupied'] ?? 0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryItem(
              'Total',
              total.toString(),
              const Color(0xFF3B82F6),
              Icons.table_restaurant,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.grey[300],
          ),
          Expanded(
            child: _buildSummaryItem(
              'Tersedia',
              available.toString(),
              const Color(0xFF10B981),
              Icons.check_circle,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.grey[300],
          ),
          Expanded(
            child: _buildSummaryItem(
              'Terisi',
              occupied.toString(),
              const Color(0xFFEF4444),
              Icons.cancel,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
      String label,
      String value,
      Color color,
      IconData icon,
      ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
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
            Text(
              _errorMessage ?? 'Terjadi kesalahan',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadTableAvailability,
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

  Widget _buildTableGrid() {
    if (_tables.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.table_restaurant, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'Tidak ada data meja',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    final Map<String, List<dynamic>> tablesByArea = {};
    for (var table in _tables) {
      final area = table['area'];
      if (area != null) {
        final areaName = area['area_name'] ?? 'Unknown Area';
        if (!tablesByArea.containsKey(areaName)) {
          tablesByArea[areaName] = [];
        }
        tablesByArea[areaName]!.add(table);
      }
    }

    return RefreshIndicator(
      onRefresh: _loadTableAvailability,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: tablesByArea.length,
        itemBuilder: (context, index) {
          final areaName = tablesByArea.keys.elementAt(index);
          final tables = tablesByArea[areaName]!;
          return _buildAreaSection(areaName, tables);
        },
      ),
    );
  }

  Widget _buildAreaSection(String areaName, List<dynamic> tables) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            areaName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E8B57),
            ),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemCount: tables.length,
          itemBuilder: (context, index) {
            return _buildTableCard(tables[index]);
          },
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildTableCard(Map<String, dynamic> table) {
    final tableNumber = table['table_number'] ?? 'N/A';
    final seats = table['seats'] ?? 0;
    final isAvailable = table['is_available'] ?? false;
    final isActive = table['is_active'] ?? false;

    final isSelected = _isMultiSelectMode &&
        _selectedTables.any((t) => t['table_number'] == tableNumber);

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

    return InkWell(
      onTap: isActive ? () => _onTableTap(table) : null,
      onLongPress: isActive && !isAvailable
          ? () => _checkAndShowTableOptions(table)
          : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF2E8B57)
                : textColor.withOpacity(0.3),
            width: isSelected ? 3 : 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor, size: 32),
            const SizedBox(height: 8),
            Text(
              tableNumber,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person, size: 14, color: textColor),
                const SizedBox(width: 4),
                Text(
                  '$seats',
                  style: TextStyle(
                    fontSize: 12,
                    color: textColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              isSelected
                  ? 'Dipilih'
                  : isActive
                  ? (isAvailable ? 'Tersedia' : 'Terisi')
                  : 'Nonaktif',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
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
        const SnackBar(
          content: Text('Meja ini sedang nonaktif'),
          backgroundColor: Colors.grey,
        ),
      );
      return;
    }

    if (_isMultiSelectMode && isAvailable) {
      _toggleTableSelection(table);
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

  void _checkAndShowTableOptions(Map<String, dynamic> table) async {
    final tableNumber = table['table_number'] ?? 'N/A';
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final result = await _groService.getTableOrderDetail(
        tableNumber: tableNumber,
        date: dateStr,
      );

      if (mounted) Navigator.pop(context);

      if (result['success'] && result['data'] != null) {
        final orderData = result['data'];
        _showCompleteOrderDialog(table, orderData: orderData);
      } else {
        _showNoOrderDialog(table);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showNoOrderDialog(table);
      }
    }
  }

  void _showOrderTypeDialog(Map<String, dynamic> table) {
    if (_isMultiSelectMode) {
      _toggleTableSelection(table);
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Meja ${table['table_number']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pilih jenis pesanan untuk meja ini:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 16),

            // Option Multi-Select
            InkWell(
              onTap: () {
                Navigator.pop(context);
                _enterMultiSelectMode();
                _toggleTableSelection(table);
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF8B5CF6).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.add_box,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Pilih Banyak Meja',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF8B5CF6),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Gabungkan beberapa meja untuk grup besar',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Color(0xFF8B5CF6),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Dine-In Option
            InkWell(
              onTap: () {
                Navigator.pop(context);
                _navigateToDineIn(table);
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF3B82F6).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.restaurant,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Dine-In',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF3B82F6),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Pesan langsung untuk meja ini',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Color(0xFF3B82F6),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Reservation Option
            InkWell(
              onTap: () {
                Navigator.pop(context);
                _navigateToReservation(table);
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E8B57).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF2E8B57).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E8B57),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.event_available,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Reservasi',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2E8B57),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Buat reservasi untuk meja ini',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Color(0xFF2E8B57),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
        ],
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
      if (result == true) {
        _loadTableAvailability();
      }
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

    if (result == true) {
      _loadTableAvailability();
    }
  }

  void _showTableOrderDetail(Map<String, dynamic> table) async {
    final tableNumber = table['table_number'] ?? 'N/A';
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final result = await _groService.getTableOrderDetail(
        tableNumber: tableNumber,
        date: dateStr,
      );

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
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
            const Icon(
              Icons.info_outline,
              size: 48,
              color: Colors.orange,
            ),
            const SizedBox(height: 16),
            const Text(
              'Tidak Ada Order Aktif',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sistem tidak menemukan order aktif untuk meja $tableNumber. '
                  'Status meja saat ini terdeteksi sebagai terisi, tetapi tidak ada data order.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
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
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _freeUpTable(table);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E8B57),
              foregroundColor: Colors.white,
            ),
            child: const Text('Bebaskan Meja'),
          ),
        ],
      ),
    );
  }

  void _showOrderDetailBottomSheet(
      Map<String, dynamic> orderData,
      Map<String, dynamic> table,
      ) {
    final hasActiveOrder = orderData['order_id'] != null;
    final tableNumber = table['table_number'] ?? 'N/A';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                border: Border(
                  bottom: BorderSide(color: Colors.grey[200]!),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Meja $tableNumber',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          orderData['order_id'] ?? 'N/A',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (!hasActiveOrder)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Tidak ada order aktif',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasActiveOrder) ...[
                      _buildInfoCard(
                        'Informasi Pelanggan',
                        [
                          _buildInfoRow(
                            Icons.person,
                            'Nama',
                            orderData['customerName'] ?? 'N/A',
                          ),
                          if (orderData['customerPhone'] != null)
                            _buildInfoRow(
                              Icons.phone,
                              'Telepon',
                              orderData['customerPhone'],
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      _buildInfoCard(
                        'Pesanan',
                        (orderData['items'] as List? ?? []).map((item) {
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFF2E8B57).withOpacity(0.1),
                              child: Text(
                                '${item['quantity']}x',
                                style: const TextStyle(
                                  color: Color(0xFF2E8B57),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              item['menuItem']?['name'] ?? 'N/A',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            subtitle: item['notes'] != null && item['notes'].toString().isNotEmpty
                                ? Text(
                              'Catatan: ${item['notes']}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            )
                                : null,
                            trailing: Text(
                              'Rp ${(item['subtotal'] ?? 0).toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      _buildInfoCard(
                        'Total Pembayaran',
                        [
                          _buildTotalRow(
                            'Subtotal',
                            orderData['totalBeforeDiscount'] ?? 0,
                          ),
                          if ((orderData['totalTax'] ?? 0) > 0)
                            _buildTotalRow('Pajak', orderData['totalTax']),
                          if ((orderData['totalServiceFee'] ?? 0) > 0)
                            _buildTotalRow('Service', orderData['totalServiceFee']),
                          const Divider(),
                          _buildTotalRow(
                            'Grand Total',
                            orderData['grandTotal'] ?? 0,
                            isBold: true,
                          ),
                        ],
                      ),
                    ] else ...[
                      _buildInfoCard(
                        'Status Meja',
                        [
                          _buildInfoRow(
                            Icons.info,
                            'Status',
                            'Tersedia (Tidak ada order aktif)',
                          ),
                          _buildInfoRow(
                            Icons.table_restaurant,
                            'Meja',
                            tableNumber,
                          ),
                          _buildInfoRow(
                            Icons.people,
                            'Kapasitas',
                            '${table['seats'] ?? 0} orang',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange[200]!),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.warning, size: 40, color: Colors.orange[600]),
                            const SizedBox(height: 8),
                            const Text(
                              'Tidak Ada Order Aktif',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.orange,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Sistem tidak menemukan order aktif untuk meja ini. '
                                  'Anda dapat membebaskan meja untuk mengatur statusnya menjadi tersedia.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  if (hasActiveOrder) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _transferOrderToNewTable(table, orderData);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF3B82F6),
                          side: const BorderSide(color: Color(0xFF3B82F6)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.swap_horiz, size: 18),
                            SizedBox(width: 8),
                            Text('Pindah Meja'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _showCompleteOrderDialog(table, orderData: orderData);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E8B57),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'Selesaikan Pesanan',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _freeUpTable(table);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E8B57),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.cleaning_services, size: 18),
                            SizedBox(width: 8),
                            Text('Bebaskan Meja'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E8B57),
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, dynamic value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isBold ? 16 : 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            'Rp ${(value ?? 0).toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: isBold ? 16 : 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showCompleteOrderDialog(
      Map<String, dynamic> table, {
        Map<String, dynamic>? orderData,
      }) async {
    final tableNumber = table['table_number'] ?? 'N/A';

    Map<String, dynamic>? data = orderData;
    if (data == null) {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final result = await _groService.getTableOrderDetail(
        tableNumber: tableNumber,
        date: dateStr,
      );

      if (!result['success'] || result['data'] == null) {
        _showNoOrderDialog(table);
        return;
      }
      data = result['data'];
    }

    if (data == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Selesaikan Pesanan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Apakah Anda yakin ingin menyelesaikan pesanan untuk:'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Meja: $tableNumber',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('Order ID: ${data!['order_id'] ?? 'N/A'}'),
                  Text('Customer: ${data['customerName'] ?? 'N/A'}'),
                  const SizedBox(height: 8),
                  Text(
                    'Total: Rp ${(data['grandTotal'] ?? 0).toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E8B57),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Meja akan menjadi tersedia setelah pesanan diselesaikan.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
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
              backgroundColor: const Color(0xFF2E8B57),
              foregroundColor: Colors.white,
            ),
            child: const Text('Ya, Selesaikan'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _completeOrder(data['_id']);
    }
  }

  void _freeUpTable(Map<String, dynamic> table) async {
    final tableNumber = table['table_number'] ?? 'N/A';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bebaskan Meja'),
        content: Text(
          'Apakah Anda yakin ingin membebaskan meja $tableNumber? '
              'Tindakan ini akan mengatur status meja menjadi tersedia meskipun sistem '
              'mendeteksi tidak ada order aktif untuk meja ini.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performFreeUpTable(table);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E8B57),
            ),
            child: const Text('Ya, Bebaskan Meja'),
          ),
        ],
      ),
    );
  }

  Future<void> _performFreeUpTable(Map<String, dynamic> table) async {
    final tableNumber = table['table_number'] ?? 'N/A';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final result = await _groService.forceResetTableStatus(tableNumber, outletId);

      if (mounted) Navigator.pop(context);

      if (result['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Meja berhasil dibebaskan'),
              backgroundColor: Colors.green,
            ),
          );
        }

        await Future.delayed(const Duration(seconds: 1));
        await _loadTableAvailability();

      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error'] ?? 'Gagal membebaskan meja'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _transferOrderToNewTable(Map<String, dynamic> table, Map<String, dynamic> orderData) async {
    final currentTableNumber = table['table_number'] ?? 'N/A';
    final orderId = orderData['_id'];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final result = await _groService.getAllAvailableTables(outletId: outletId);

      if (mounted) Navigator.pop(context);

      if (result['success'] == true) {
        final availableTables = result['data']['tables'] ?? [];
        final tablesByArea = result['data']['tablesByArea'] ?? {};

        if (availableTables.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Tidak ada meja tersedia saat ini'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }

        _showTableSelectionDialog(
          currentTableNumber,
          orderId,
          availableTables,
          tablesByArea,
          orderData,
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error'] ?? 'Gagal memuat meja tersedia'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showTableSelectionDialog(
      String currentTableNumber,
      String orderId,
      List<dynamic> availableTables,
      Map<String, dynamic> tablesByArea,
      Map<String, dynamic> orderData,
      ) {
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
                  Text(
                    'Memindahkan dari Meja: $currentTableNumber',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'Alasan Pemindahan:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    decoration: const InputDecoration(
                      hintText: 'Contoh: Hujan, AC rusak, request customer...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    maxLines: 2,
                    onChanged: (value) {
                      setState(() {
                        reason = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'Pilih Meja Tujuan:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  ...tablesByArea.entries.map((areaEntry) {
                    final areaName = areaEntry.key;
                    final tables = areaEntry.value as List<dynamic>;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          areaName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2E8B57),
                          ),
                        ),
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
                              onSelected: (selected) {
                                setState(() {
                                  selectedTable = selected ? tableNumber : null;
                                });
                              },
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
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: selectedTable != null
                    ? () async {
                  Navigator.pop(context);
                  await _performTableTransfer(
                    currentTableNumber,
                    selectedTable!,
                    orderId,
                    reason,
                    orderData,
                  );
                }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E8B57),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Pindahkan'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _performTableTransfer(
      String currentTable,
      String newTable,
      String orderId,
      String reason,
      Map<String, dynamic> orderData,
      ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

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
            SnackBar(
              content: Text(result['message'] ?? 'Order berhasil dipindahkan ke meja $newTable'),
              backgroundColor: Colors.green,
            ),
          );
        }
        _loadTableAvailability();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error'] ?? 'Gagal memindahkan order'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _completeOrder(String orderId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final result = await _groService.completeTableOrder(orderId);

      if (mounted) Navigator.pop(context);

      if (result['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result['message'] ?? 'Pesanan berhasil diselesaikan',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
        _loadTableAvailability();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error'] ?? 'Gagal menyelesaikan pesanan'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}