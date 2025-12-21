// ============================================================================
// FILE 1: gro_reservation_screen.dart
// UPDATED: Full multi-table support
// ============================================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../models/reservation_data.dart';
import '../theme/app_theme.dart';
import '../widgets/reservation/date_selector.dart';
import '../widgets/reservation/time_selector.dart';
import '../widgets/reservation/agenda_selector.dart';
import '../widgets/reservation/serving_type_selector.dart';
import '../widgets/reservation/equipment_selector.dart';
import '../widgets/reservation/food_serving_selector.dart';
import 'checkout_page.dart';

class CreateReservationScreen extends StatefulWidget {
  // ✅ UPDATED: Support both single and multiple tables
  final Map<String, dynamic>? selectedTable;
  final List<Map<String, dynamic>>? selectedTables;
  final DateTime? selectedDate;
  final String? selectedTime;
  final bool isGroMode;
  final int? totalSeats;

  const CreateReservationScreen({
    super.key,
    this.selectedTable,
    this.selectedTables,
    this.selectedDate,
    this.selectedTime,
    this.isGroMode = false,
    this.totalSeats,
  });

  @override
  State<CreateReservationScreen> createState() =>
      _CreateReservationScreenState();
}

class _CreateReservationScreenState extends State<CreateReservationScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _guestCountController = TextEditingController();
  String? get _areaCode {
    if (_selectedTables.isEmpty) return null;
    return _selectedTables.first['area']['area_code'] as String?;
  }

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = const TimeOfDay(hour: 19, minute: 0);

  // ✅ NEW: Working tables list
  late List<Map<String, dynamic>> _selectedTables;
  late int _totalCapacity;
  late bool _isMultiTable;

  int personCount = 1;

  // Optional reservation features
  String? selectedAgenda;
  String? selectedServingType;
  List<String> selectedEquipment = [];
  String? selectedFoodServingOption;
  DateTime? selectedFoodServingTime;

  DateTime get _selectedDateTime {
    return DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
  }

  @override
  void initState() {
    super.initState();

    // ✅ INITIALIZE: Setup tables based on input
    if (widget.selectedTables != null && widget.selectedTables!.isNotEmpty) {
      // Multi-table mode
      _selectedTables = widget.selectedTables!;
      _isMultiTable = true;
    } else if (widget.selectedTable != null) {
      // Single table mode (backward compatibility)
      _selectedTables = [widget.selectedTable!];
      _isMultiTable = false;
    } else {
      _selectedTables = [];
      _isMultiTable = false;
    }

    // ✅ CALCULATE: Total capacity
    _totalCapacity = widget.totalSeats ?? _calculateTotalCapacity();

    // Set initial person count to total capacity
    personCount = _totalCapacity;
    _guestCountController.text = personCount.toString();

    if (widget.selectedDate != null) {
      _selectedDate = widget.selectedDate!;
    }
    if (widget.selectedTime != null) {
      final timeParts = widget.selectedTime!.split(':');
      _selectedTime = TimeOfDay(
        hour: int.parse(timeParts[0]),
        minute: int.parse(timeParts[1]),
      );
    }
    _validateInitialDateTime();

    _nameController.addListener(() => setState(() {}));
    _phoneController.addListener(() => setState(() {}));
    _guestCountController.addListener(() => setState(() {}));
  }

  bool _shouldShowReservationType(String? areaCode) {
    return areaCode == 'I' || areaCode == 'F';
  }

  int _calculateTotalCapacity() {
    return _selectedTables.fold(
        0, (sum, table) => sum + (table['seats'] as int));
  }

  void _validateInitialDateTime() {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime currentSelectedDate =
        DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);

    if (currentSelectedDate.isBefore(today)) {
      _selectedDate = now;
    }

    if (currentSelectedDate.isAtSameMomentAs(today) &&
        !_isValidTime(_selectedTime, _selectedDate)) {
      final DateTime minimumTime = now.add(const Duration(minutes: 5));
      _selectedTime =
          TimeOfDay(hour: minimumTime.hour, minute: minimumTime.minute);
    }
  }

  bool _isValidTime(TimeOfDay time, DateTime date) {
    final DateTime now = DateTime.now();
    final DateTime selectedDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime selectedDateOnly = DateTime(date.year, date.month, date.day);

    if (selectedDateOnly.isAfter(today)) {
      return true;
    }

    if (selectedDateOnly.isAtSameMomentAs(today)) {
      final DateTime minimumTime = now.add(const Duration(minutes: 5));
      return selectedDateTime.isAfter(minimumTime) ||
          selectedDateTime.isAtSameMomentAs(minimumTime);
    }

    return false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    _guestCountController.dispose();
    super.dispose();
  }

  void _onDateChanged(DateTime newDate) {
    setState(() {
      _selectedDate = newDate;
    });
  }

  Future<void> _onTimeChanged(TimeOfDay newTime) async {
    if (_isValidTime(newTime, _selectedDate)) {
      setState(() {
        _selectedTime = newTime;
      });
    } else {
      _showTimeValidationDialog(newTime);
    }
  }

  void _showTimeValidationDialog(TimeOfDay attemptedTime) {
    final DateTime now = DateTime.now();
    final DateTime minimumTime = now.add(const Duration(minutes: 5));
    final String minimumTimeText =
        '${minimumTime.hour.toString().padLeft(2, '0')}:${minimumTime.minute.toString().padLeft(2, '0')}';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange),
              SizedBox(width: 8),
              Text('Waktu Tidak Valid'),
            ],
          ),
          content: Text(
            'Waktu ${attemptedTime.hour.toString().padLeft(2, '0')}:${attemptedTime.minute.toString().padLeft(2, '0')} tidak dapat dipilih.\n\n'
            'Untuk reservasi hari ini, minimal waktu yang dapat dipilih adalah $minimumTimeText (5 menit dari sekarang).',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _selectedTime = TimeOfDay(
                    hour: minimumTime.hour,
                    minute: minimumTime.minute,
                  );
                });
              },
              child: const Text('Gunakan Waktu Minimum'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );

    if (picked != null && picked != _selectedTime) {
      await _onTimeChanged(picked);
    }
  }

  void _checkFormAndProceed() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedTables.isEmpty) {
      _showErrorDialog('Silakan pilih minimal satu meja');
      return;
    }

    if (!_isValidTime(_selectedTime, _selectedDate)) {
      _showErrorDialog(
          'Waktu yang dipilih tidak valid. Silakan pilih waktu yang valid.');
      return;
    }

    _showConfirmationDialog();
  }

  void _showConfirmationDialog() {
    final timeStr =
        '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('Konfirmasi Reservasi', style: TextStyle(fontSize: 18)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Data reservasi yang akan dibuat:'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow('Nama Tamu', _nameController.text),
                      _buildInfoRow('No. Telepon', _phoneController.text),
                      _buildInfoRow(
                          'Jumlah Tamu', '${_guestCountController.text} orang'),
                      _buildInfoRow('Area',
                          _selectedTables.first['area']['area_name'] ?? ''),
                      _buildInfoRow(_isMultiTable ? 'Meja-meja' : 'Meja',
                          _getSelectedTableNumbers()),
                      if (_isMultiTable)
                        _buildInfoRow(
                            'Total Kapasitas', '$_totalCapacity orang'),
                      _buildInfoRow(
                          'Tanggal',
                          DateFormat('dd MMMM yyyy', 'id_ID')
                              .format(_selectedDate)),
                      _buildInfoRow('Waktu', timeStr),
                      if (selectedAgenda != null)
                        _buildInfoRow('Agenda', selectedAgenda!),
                      if (selectedServingType != null)
                        _buildInfoRow('Tipe Penyajian', selectedServingType!),
                      if (selectedEquipment.isNotEmpty)
                        _buildInfoRow(
                            'Equipment', selectedEquipment.join(', ')),
                      if (selectedFoodServingOption != null)
                        _buildInfoRow(
                            'Penyajian Makanan',
                            selectedFoodServingOption == 'immediate'
                                ? 'Segera saat tamu datang'
                                : 'Dijadwalkan ${selectedFoodServingTime != null ? DateFormat('HH:mm').format(selectedFoodServingTime!) : ''}'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _proceedToCheckout();
              },
              child: Text(
                'Pesan Tanpa Menu',
                style: TextStyle(color: Colors.blue.shade600),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _proceedToMenu();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.barajaPrimary.primaryColor,
              ),
              child: const Text(
                'Lanjut ke Menu',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  void _proceedToCheckout() {
    final reservationData = _buildReservationData();
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    cartProvider.setGuestData(
      guestName: _nameController.text.trim(),
      guestPhone: _phoneController.text.trim(),
      notes: _notesController.text.trim(),
    );

    cartProvider.setReservationData(true, reservationData);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => CheckoutPage(
          isReservation: true,
          reservationData: reservationData,
          isGroMode: widget.isGroMode,
        ),
      ),
    );
  }

  void _proceedToMenu() {
    final reservationData = _buildReservationData();
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    cartProvider.setGuestData(
      guestName: _nameController.text.trim(),
      guestPhone: _phoneController.text.trim(),
      notes: _notesController.text.trim(),
    );

    cartProvider.setReservationData(true, reservationData);

    // ✅ Use context.push instead of Navigator.pushReplacement for proper back navigation
    context.push('/menu', extra: {
      'isReservation': true,
      'reservationData': reservationData,
      'isGroMode': widget.isGroMode,
    });
  }

  ReservationData _buildReservationData() {
    final String formattedDate =
        DateFormat('dd MMMM yyyy', 'id_ID').format(_selectedDate);
    final String formattedTime =
        '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';
    final areaId = _selectedTables.first['area']['_id'] as String;
    final areaCode = _selectedTables.first['area']['area_code'] as String;
    final tableIds = _selectedTables.map((t) => t['_id'] as String).toList();

    return ReservationData(
      date: _selectedDate,
      time: _selectedTime,
      areaId: areaId,
      areaCode: areaCode,
      personCount: int.parse(_guestCountController.text),
      formattedDate: formattedDate,
      formattedTime: formattedTime,
      selectedTableIds: tableIds,
      agenda: selectedAgenda,
      servingType: selectedServingType,
      equipment: selectedEquipment,
      foodServingOption: selectedFoodServingOption,
      foodServingTime: selectedFoodServingTime,
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Color(0xFFEF4444)),
            SizedBox(width: 8),
            Text('Gagal'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _getSelectedTableNumbers() {
    return _selectedTables.map((table) => table['table_number']).join(', ');
  }

  bool get _canProceed {
    final hasName = _nameController.text.trim().isNotEmpty;
    final hasPhone = _phoneController.text.trim().isNotEmpty;
    final hasGuestCount = _guestCountController.text.trim().isNotEmpty;

    return hasName &&
        hasPhone &&
        hasGuestCount &&
        _selectedTables.isNotEmpty &&
        _isValidTime(_selectedTime, _selectedDate);
  }

  // ✅ NEW: Build multi-table info section
  Widget _buildMultiTableInfoSection() {
    if (_selectedTables.isEmpty) return const SizedBox();

    if (_selectedTables.length == 1) {
      // Single table display
      final table = _selectedTables.first;
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.barajaPrimary.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.barajaPrimary.primaryColor.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.barajaPrimary.primaryColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.table_restaurant,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Meja ${table['table_number']}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppTheme.barajaPrimary.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Kapasitas: ${table['seats']} orang',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    'Area: ${table['area']?['area_name'] ?? 'N/A'}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // ✅ MULTIPLE TABLES DISPLAY
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.barajaPrimary.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.barajaPrimary.primaryColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.barajaPrimary.primaryColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.table_restaurant,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_selectedTables.length} Meja Dipilih',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppTheme.barajaPrimary.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Total Kapasitas: $_totalCapacity orang',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.barajaPrimary.primaryColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$_totalCapacity 👤',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // List of selected tables
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedTables.map((table) {
              return Chip(
                avatar: CircleAvatar(
                  backgroundColor: AppTheme.barajaPrimary.primaryColor,
                  child: Text(
                    '${table['seats']}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                label: Text('Meja ${table['table_number']}'),
                backgroundColor: Colors.white,
                side: BorderSide(color: AppTheme.barajaPrimary.primaryColor),
              );
            }).toList(),
          ),

          const SizedBox(height: 8),

          // Area grouping info
          Builder(
            builder: (context) {
              final areas = _selectedTables
                  .map((t) => t['area']?['area_name'] ?? 'Unknown')
                  .toSet()
                  .toList();

              if (areas.length > 1) {
                return Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info, size: 16, color: Colors.orange[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Meja tersebar di ${areas.length} area: ${areas.join(", ")}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Text(
                'Area: ${areas.first}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ TABLET DETECTION
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 768;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: Text(
          _isMultiTable ? 'Reservasi Multi-Meja' : 'Buat Reservasi',
          style: const TextStyle(
              fontWeight: FontWeight.w600, fontSize: 20, color: Colors.black),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: isTablet ? _buildTabletLayout() : _buildMobileLayout(),
      ),
    );
  }

  // ==================== TABLET LAYOUT ====================
  Widget _buildTabletLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ Multi-table info banner at top
              _buildMultiTableInfoSection(),

              const SizedBox(height: 24),

              // ✅ LAYOUT SESUAI WIREFRAME

              // === MAIN ROW: Kalender (left) | Right Column ===
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // LEFT: Kalender/Tanggal (tinggi penuh)
                  Expanded(
                    child: _buildSectionCard(
                      title: 'Pilih Tanggal',
                      icon: Icons.calendar_today,
                      children: [
                        DateSelector(
                          selectedDate: _selectedDate,
                          onDateChanged: _onDateChanged,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  // RIGHT COLUMN: Jam + Info Tamu + Agenda
                  Expanded(
                    child: Column(
                      children: [
                        // Jam Reservasi - tanpa wrapper (TimeSelector sudah punya styling)
                        TimeSelector(
                          selectedTime: _selectedTime,
                          selectedDate: _selectedDate,
                          onTimeChanged: _onTimeChanged,
                          selectTime: () => _selectTime(context),
                        ),
                        const SizedBox(height: 16),
                        // Info Tamu (Nama, Nomor, Jumlah) | Catatan - side by side
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Nama, Nomor, Jumlah Tamu
                            Expanded(
                              child: _buildSectionCard(
                                title: 'Informasi Tamu',
                                icon: Icons.person,
                                children: [
                                  _buildTextField(
                                    controller: _nameController,
                                    label: 'Nama Tamu',
                                    icon: Icons.person_outline,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Nama tamu harus diisi';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  _buildTextField(
                                    controller: _phoneController,
                                    label: 'No. Telepon',
                                    icon: Icons.phone_outlined,
                                    keyboardType: TextInputType.phone,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'No. telepon harus diisi';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  _buildTextField(
                                    controller: _guestCountController,
                                    label: 'Jumlah Tamu',
                                    icon: Icons.people_outline,
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Jumlah tamu harus diisi';
                                      }
                                      final number = int.tryParse(value);
                                      if (number == null || number < 1) {
                                        return 'Jumlah tamu minimal 1';
                                      }
                                      if (number > _totalCapacity) {
                                        return 'Kapasitas meja hanya $_totalCapacity orang';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Catatan
                            Expanded(
                              child: _buildSectionCard(
                                title: 'Catatan',
                                icon: Icons.note_outlined,
                                children: [
                                  _buildTextField(
                                    controller: _notesController,
                                    label: 'Catatan (Opsional)',
                                    icon: Icons.note_outlined,
                                    maxLines: 5,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Agenda (full width in right column)
                        AgendaSelector(
                          selectedAgenda: selectedAgenda,
                          onAgendaChanged: (agenda) {
                            setState(() {
                              selectedAgenda = agenda;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // === BOTTOM ROW: Tipe Penyajian (left) | Waktu Penyajian (right) ===
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tipe Penyajian (A la carte, Buffet)
                  Expanded(
                    child: ServingTypeSelector(
                      selectedServingType: selectedServingType,
                      onServingTypeChanged: (type) {
                        setState(() {
                          selectedServingType = type;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 24),
                  // Waktu Penyajian (Segera, Dijadwalkan)
                  Expanded(
                    child: FoodServingSelector(
                      selectedServingOption: selectedFoodServingOption,
                      selectedServingTime:
                          selectedFoodServingOption == 'scheduled'
                              ? (selectedFoodServingTime ?? _selectedDateTime)
                              : null,
                      onServingChanged: (option, time) {
                        setState(() {
                          selectedFoodServingOption = option;
                          if (option == 'scheduled') {
                            selectedFoodServingTime = time ?? _selectedDateTime;
                          } else {
                            selectedFoodServingTime = null;
                          }
                        });
                      },
                    ),
                  ),
                ],
              ),

              // Equipment Selector (conditional) - Full Width
              if (_areaCode != null &&
                  _shouldShowReservationType(_areaCode)) ...[
                const SizedBox(height: 16),
                EquipmentSelector(
                  selectedEquipment: selectedEquipment,
                  onEquipmentChanged: (equipment) {
                    setState(() {
                      selectedEquipment = equipment;
                    });
                  },
                ),
              ],

              const SizedBox(height: 24),

              // ✅ PROCEED BUTTON - Full Width
              _buildProceedButton(),

              // ✅ Multi-table info banner
              if (_isMultiTable) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info, size: 16, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Anda akan mereservasi ${_selectedTables.length} meja sekaligus dengan total kapasitas $_totalCapacity orang.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[700],
                          ),
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
    );
  }

  // ==================== MOBILE LAYOUT (Original) ====================
  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ TAMPILKAN MULTI-TABLE INFO DI ATAS
          _buildMultiTableInfoSection(),

          // Date & Time Selectors
          DateSelector(
            selectedDate: _selectedDate,
            onDateChanged: _onDateChanged,
          ),
          const SizedBox(height: 16),

          TimeSelector(
            selectedTime: _selectedTime,
            selectedDate: _selectedDate,
            onTimeChanged: _onTimeChanged,
            selectTime: () => _selectTime(context),
          ),
          const SizedBox(height: 16),

          // Guest Information
          _buildSectionCard(
            title: 'Informasi Tamu',
            icon: Icons.person,
            children: [
              _buildTextField(
                controller: _nameController,
                label: 'Nama Tamu',
                icon: Icons.person_outline,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nama tamu harus diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _phoneController,
                label: 'No. Telepon',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'No. telepon harus diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _guestCountController,
                label: 'Jumlah Tamu',
                icon: Icons.people_outline,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Jumlah tamu harus diisi';
                  }
                  final number = int.tryParse(value);
                  if (number == null || number < 1) {
                    return 'Jumlah tamu minimal 1';
                  }
                  if (number > _totalCapacity) {
                    return 'Kapasitas meja hanya $_totalCapacity orang';
                  }
                  return null;
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Selected Tables Info (OLD VERSION - for reference)
          _buildSectionCard(
            title: 'Detail Meja',
            icon: Icons.table_restaurant,
            children: [_buildSelectedTablesInfo()],
          ),

          const SizedBox(height: 16),

          // Agenda Selector
          AgendaSelector(
            selectedAgenda: selectedAgenda,
            onAgendaChanged: (agenda) {
              setState(() {
                selectedAgenda = agenda;
              });
            },
          ),

          const SizedBox(height: 16),

          // Serving Type Selector
          ServingTypeSelector(
            selectedServingType: selectedServingType,
            onServingTypeChanged: (type) {
              setState(() {
                selectedServingType = type;
              });
            },
          ),

          const SizedBox(height: 16),

          // Equipment Selector
          if (_areaCode != null && _shouldShowReservationType(_areaCode)) ...[
            const SizedBox(height: 16),
            EquipmentSelector(
              selectedEquipment: selectedEquipment,
              onEquipmentChanged: (equipment) {
                setState(() {
                  selectedEquipment = equipment;
                });
              },
            ),
          ],

          const SizedBox(height: 16),

          // Food Serving Selector
          FoodServingSelector(
            selectedServingOption: selectedFoodServingOption,
            selectedServingTime: selectedFoodServingOption == 'scheduled'
                ? (selectedFoodServingTime ?? _selectedDateTime)
                : null,
            onServingChanged: (option, time) {
              setState(() {
                selectedFoodServingOption = option;
                if (option == 'scheduled') {
                  selectedFoodServingTime = time ?? _selectedDateTime;
                } else {
                  selectedFoodServingTime = null;
                }
              });
            },
          ),

          const SizedBox(height: 16),

          // Notes
          _buildSectionCard(
            title: 'Catatan (Opsional)',
            icon: Icons.note_outlined,
            children: [
              _buildTextField(
                controller: _notesController,
                label: 'Catatan',
                icon: Icons.note_outlined,
                maxLines: 3,
              ),
            ],
          ),

          const SizedBox(height: 24),

          _buildProceedButton(),

          // ✅ Multi-table info banner
          if (_isMultiTable) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, size: 16, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Text(
                        'Reservasi Multi-Meja',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Anda akan mereservasi ${_selectedTables.length} meja sekaligus '
                    'dengan total kapasitas $_totalCapacity orang.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.barajaPrimary.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.barajaPrimary.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.barajaPrimary.primaryColor),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppTheme.barajaPrimary.primaryColor),
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildSelectedTablesInfo() {
    if (_selectedTables.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: const Center(
          child: Text('Belum ada meja dipilih',
              style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    final totalCapacity = _calculateTotalCapacity();
    final areaName = _selectedTables.first['area']['area_name'] ?? '';

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.barajaPrimary.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Area:',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                  Text(
                    areaName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.barajaPrimary.primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Kapasitas:',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                  Text(
                    '$totalCapacity orang',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.barajaPrimary.primaryColor,
                    ),
                  ),
                ],
              ),
              if (_isMultiTable) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Jumlah Meja:',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w500)),
                    Text(
                      '${_selectedTables.length} meja',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.barajaPrimary.primaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _selectedTables.map((table) {
            return Chip(
              label: Text(
                '${table['table_number']} (${table['seats']} kursi)',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
              backgroundColor: AppTheme.barajaPrimary.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildProceedButton() {
    String buttonText = 'Lanjutkan';

    if (_selectedTables.isEmpty) {
      buttonText = 'Pilih Meja Terlebih Dahulu';
    } else if (!_isValidTime(_selectedTime, _selectedDate)) {
      buttonText = 'Waktu Tidak Valid (Minimal 5 Menit dari Sekarang)';
    } else if (_nameController.text.trim().isEmpty) {
      buttonText = 'Masukkan Nama Tamu';
    } else if (_phoneController.text.trim().isEmpty) {
      buttonText = 'Masukkan No. Telepon';
    } else if (_guestCountController.text.trim().isEmpty) {
      buttonText = 'Masukkan Jumlah Tamu';
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _canProceed ? _checkFormAndProceed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _canProceed
              ? AppTheme.barajaPrimary.primaryColor
              : Colors.grey.shade300,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          buttonText,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: _canProceed ? Colors.white : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }
}
