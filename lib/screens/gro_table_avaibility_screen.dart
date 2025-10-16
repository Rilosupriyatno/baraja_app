import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/gro_service.dart';
import 'gro_reservation_screen.dart'; // ✅ Import screen baru

class GroTableAvailabilityScreen extends StatefulWidget {
  const GroTableAvailabilityScreen({super.key});

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

  final List<String> _timeSlots = [
    '09:00', '10:00', '11:00', '12:00', '13:00', '14:00',
    '15:00', '16:00', '17:00', '18:00', '19:00', '20:00', '21:00'
  ];

  @override
  void initState() {
    super.initState();
    _loadTableAvailability();
  }

  Future<void> _loadTableAvailability() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

      final result = await _groService.getTableAvailability(
        date: dateStr,
        time: _selectedTime,
        areaId: _selectedAreaId,
      );

      if (result['success']) {
        setState(() {
          _tables = result['data']['tables'] ?? [];
          _summary = result['data']['summary'] ?? {};
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
        _errorMessage = 'Error loading table availability: $e';
        _isLoading = false;
      });
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
          'Ketersediaan Meja',
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
            onPressed: _loadTableAvailability,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            splashRadius: 24,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
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
                      value: null,
                      child: Text('Semua Waktu'),
                    ),
                    ..._timeSlots.map((time) => DropdownMenuItem(
                      value: time,
                      child: Text(time),
                    )),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedTime = value);
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
      locale: const Locale('id', 'ID'),
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

    // Group tables by area
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
            return _buildTableCard(tables[index]); // ✅ PERBAIKAN: Pass table data
          },
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // ✅ PERBAIKAN: Method ini harus ada dan menerima parameter table
  Widget _buildTableCard(Map<String, dynamic> table) {
    final tableNumber = table['table_number'] ?? 'N/A';
    final seats = table['seats'] ?? 0;
    final isAvailable = table['is_available'] ?? false;
    final isActive = table['is_active'] ?? false;

    Color backgroundColor;
    Color textColor;
    IconData icon;

    if (!isActive) {
      backgroundColor = Colors.grey[300]!;
      textColor = Colors.grey[600]!;
      icon = Icons.block;
    } else if (isAvailable) {
      backgroundColor = const Color(0xFF10B981).withOpacity(0.1);
      textColor = const Color(0xFF10B981);
      icon = Icons.check_circle;
    } else {
      backgroundColor = const Color(0xFFEF4444).withOpacity(0.1);
      textColor = const Color(0xFFEF4444);
      icon = Icons.event_seat;
    }

    // ✅ PERBAIKAN: Wrap dengan InkWell untuk handle klik
    return InkWell(
      onTap: isActive && isAvailable
          ? () => _onTableTap(table) // ✅ PERBAIKAN: Pass table data
          : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: textColor.withOpacity(0.3),
            width: 2,
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
              isActive
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

  // ✅ PERBAIKAN: Method ini harus menerima parameter table
  void _onTableTap(Map<String, dynamic> table) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateReservationScreen(
          selectedTable: table,
          selectedDate: _selectedDate,
          selectedTime: _selectedTime,
        ),
      ),
    );

    // Refresh jika reservasi berhasil dibuat
    if (result == true) {
      _loadTableAvailability();
    }
  }
}