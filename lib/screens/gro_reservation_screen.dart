// gro_reservation_screen.dart - Updated with matching date/time selectors
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/gro_service.dart';
import '../providers/cart_provider.dart';
import '../models/reservation_data.dart';
import '../theme/app_theme.dart';
import '../widgets/reservation/date_selector.dart';
import '../widgets/reservation/time_selector.dart';
import 'menu_screen.dart';
import 'checkout_page.dart';

class CreateReservationScreen extends StatefulWidget {
  final Map<String, dynamic>? selectedTable;
  final DateTime? selectedDate;
  final String? selectedTime;
  final bool isGroMode; // NEW: Parameter untuk menandai akses dari GRO

  const CreateReservationScreen({
    super.key,
    this.selectedTable,
    this.selectedDate,
    this.selectedTime,
    this.isGroMode = false, // Default false untuk akses user biasa
  });

  @override
  State<CreateReservationScreen> createState() =>
      _CreateReservationScreenState();
}

class _CreateReservationScreenState extends State<CreateReservationScreen> {
  final _formKey = GlobalKey<FormState>();
  final GROService _groService = GROService();

  // Form controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _guestCountController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = const TimeOfDay(hour: 19, minute: 0);
  List<Map<String, dynamic>> _selectedTables = [];
  int personCount = 1;
  bool _isCheckingAvailability = false;

  @override
  void initState() {
    super.initState();
    if (widget.selectedTable != null) {
      _selectedTables = [widget.selectedTable!];
      // Set initial guest count based on table capacity
      personCount = widget.selectedTable!['seats'] ?? 1;
      _guestCountController.text = personCount.toString();
    }
    if (widget.selectedDate != null) {
      _selectedDate = widget.selectedDate!;
    }
    if (widget.selectedTime != null) {
      // Parse string time to TimeOfDay
      final timeParts = widget.selectedTime!.split(':');
      _selectedTime = TimeOfDay(
        hour: int.parse(timeParts[0]),
        minute: int.parse(timeParts[1]),
      );
    }
    _validateInitialDateTime();

    // Add listeners to update button state
    _nameController.addListener(() => setState(() {}));
    _phoneController.addListener(() => setState(() {}));
    _guestCountController.addListener(() => setState(() {}));
  }

  void _validateInitialDateTime() {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime currentSelectedDate = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);

    if (currentSelectedDate.isBefore(today)) {
      _selectedDate = now;
    }

    if (currentSelectedDate.isAtSameMomentAs(today) && !_isValidTime(_selectedTime, _selectedDate)) {
      final DateTime minimumTime = now.add(const Duration(minutes: 5));
      _selectedTime = TimeOfDay(hour: minimumTime.hour, minute: minimumTime.minute);
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
      return selectedDateTime.isAfter(minimumTime) || selectedDateTime.isAtSameMomentAs(minimumTime);
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
    final String minimumTimeText = '${minimumTime.hour.toString().padLeft(2, '0')}:${minimumTime.minute.toString().padLeft(2, '0')}';

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

  Future<void> _checkAvailabilityAndProceed() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedTables.isEmpty) {
      _showErrorDialog('Silakan pilih minimal satu meja');
      return;
    }

    if (!_isValidTime(_selectedTime, _selectedDate)) {
      _showErrorDialog('Waktu yang dipilih tidak valid. Silakan pilih waktu yang valid.');
      return;
    }
    // final tableIds = _selectedTables.map((t) => t['_id'] as String).toList();
    // final areaId = _selectedTables.first['area']['_id'] as String;
    // final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    // final timeStr = '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';

    setState(() => _isCheckingAvailability = true);

    try {
      // Check availability first

      // Simulate availability check (you may need to implement actual API call)
      await Future.delayed(const Duration(milliseconds: 500));

      setState(() => _isCheckingAvailability = false);

      // Show availability dialog with options
      _showAvailabilityDialog(true);
    } catch (e) {
      setState(() => _isCheckingAvailability = false);
      _showErrorDialog('Terjadi kesalahan: $e');
    }
  }

  void _showAvailabilityDialog(bool isAvailable) {
    final timeStr = '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                isAvailable ? Icons.check_circle : Icons.error,
                color: isAvailable ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 8),
              Text(
                isAvailable ? 'Meja Tersedia' : 'Meja Tidak Tersedia',
                style: TextStyle(
                  color: isAvailable ? Colors.green : Colors.red,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isAvailable
                    ? 'Meja yang Anda pilih tersedia untuk waktu yang dipilih.'
                    : 'Meja yang Anda pilih tidak tersedia untuk waktu yang dipilih.',
              ),
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
                    Text(
                      'Detail Informasi:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow('Nama Tamu', _nameController.text),
                    _buildInfoRow('No. Telepon', _phoneController.text),
                    _buildInfoRow('Jumlah Tamu', '${_guestCountController.text} orang'),
                    _buildInfoRow('Area', _selectedTables.first['area']['area_name'] ?? ''),
                    _buildInfoRow('Meja', _getSelectedTableNumbers()),
                    _buildInfoRow('Tanggal', DateFormat('dd MMMM yyyy', 'id_ID').format(_selectedDate)),
                    _buildInfoRow('Waktu', timeStr),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Batal',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            if (isAvailable) ...[
              // Tombol "Pesan Tanpa Menu" - langsung ke checkout
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
              // Tombol "Lanjut ke Menu"
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
          Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  void _proceedToCheckout() async {
    final result = await _createReservationAndProceed(false);
    if (result != null && result['success']) {
      // Navigate to checkout
      final reservationData = _buildReservationData();
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      cartProvider.setReservationData(true, reservationData);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => CheckoutPage(
            isReservation: true,
            reservationData: reservationData,
            isGroMode: widget.isGroMode, // ⭐ Pass isGroMode
          ),
        ),
      );
    }
  }

  void _proceedToMenu() async {
    final result = await _createReservationAndProceed(true);
    if (result != null && result['success']) {
      // Navigate to menu
      final reservationData = _buildReservationData();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MenuScreen(
            isReservation: true,
            reservationData: reservationData,
            isGroMode: widget.isGroMode, // ⭐ Pass isGroMode
          ),
        ),
      );
    }
  }

  ReservationData _buildReservationData() {
    final String formattedDate = DateFormat('dd MMMM yyyy', 'id_ID').format(_selectedDate);
    final String formattedTime = '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';
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
    );
  }

  Future<Map<String, dynamic>?> _createReservationAndProceed(bool withMenu) async {
    try {
      final tableIds = _selectedTables.map((t) => t['_id'] as String).toList();
      final areaId = _selectedTables.first['area']['_id'] as String;
      final timeStr = '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';

      final result = await _groService.createReservation(
        guestName: _nameController.text.trim(),
        guestPhone: _phoneController.text.trim(),
        guestCount: int.parse(_guestCountController.text.trim()),
        reservationDate: DateFormat('yyyy-MM-dd').format(_selectedDate),
        reservationTime: timeStr,
        tableIds: tableIds,
        areaId: areaId,
        notes: _notesController.text.trim(),
      );

      if (result['success']) {
        return result;
      } else {
        _showErrorDialog(result['error'] ?? 'Gagal membuat reservasi');
        return null;
      }
    } catch (e) {
      _showErrorDialog('Terjadi kesalahan: $e');
      return null;
    }
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
    return _selectedTables
        .map((table) => table['table_number'])
        .join(', ');
  }

  int _calculateTotalCapacity() {
    return _selectedTables.fold(0, (sum, table) => sum + (table['seats'] as int));
  }

  bool get _canProceed {
    // Check basic requirements without triggering form validation
    final hasName = _nameController.text.trim().isNotEmpty;
    final hasPhone = _phoneController.text.trim().isNotEmpty;
    final hasGuestCount = _guestCountController.text.trim().isNotEmpty;

    return hasName &&
        hasPhone &&
        hasGuestCount &&
        _selectedTables.isNotEmpty &&
        _isValidTime(_selectedTime, _selectedDate) &&
        !_isCheckingAvailability;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: const Text(
          'Buat Reservasi',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date selection - using DateSelector widget
              DateSelector(
                selectedDate: _selectedDate,
                onDateChanged: _onDateChanged,
              ),
              const SizedBox(height: 16),

              // Time selection - using TimeSelector widget
              TimeSelector(
                selectedTime: _selectedTime,
                selectedDate: _selectedDate,
                onTimeChanged: _onTimeChanged,
                selectTime: () => _selectTime(context),
              ),
              const SizedBox(height: 16),

              // Informasi Tamu
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
                      final capacity = _calculateTotalCapacity();
                      if (number > capacity) {
                        return 'Kapasitas meja hanya $capacity orang';
                      }
                      return null;
                    },
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Meja Dipilih
              _buildSectionCard(
                title: 'Meja Dipilih',
                icon: Icons.table_restaurant,
                children: [
                  _buildSelectedTablesInfo(),
                ],
              ),

              const SizedBox(height: 16),

              // Catatan
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

              // Button
              _buildProceedButton(),
            ],
          ),
        ),
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
              Icon(
                icon,
                color: AppTheme.barajaPrimary.primaryColor,
                size: 20,
              ),
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
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
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
          child: Text(
            'Belum ada meja dipilih',
            style: TextStyle(color: Colors.grey),
          ),
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
                  const Text(
                    'Area:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
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
                  const Text(
                    'Total Kapasitas:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
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
    String buttonText = 'Cek Ketersediaan & Lanjut';

    final hasName = _nameController.text.trim().isNotEmpty;
    final hasPhone = _phoneController.text.trim().isNotEmpty;
    final hasGuestCount = _guestCountController.text.trim().isNotEmpty;

    if (_selectedTables.isEmpty) {
      buttonText = 'Pilih Meja Terlebih Dahulu';
    } else if (!_isValidTime(_selectedTime, _selectedDate)) {
      buttonText = 'Waktu Tidak Valid (Minimal 5 Menit dari Sekarang)';
    } else if (!hasName) {
      buttonText = 'Masukkan Nama Tamu';
    } else if (!hasPhone) {
      buttonText = 'Masukkan No. Telepon';
    } else if (!hasGuestCount) {
      buttonText = 'Masukkan Jumlah Tamu';
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _canProceed ? _checkAvailabilityAndProceed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _canProceed
              ? AppTheme.barajaPrimary.primaryColor
              : Colors.grey.shade300,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: _isCheckingAvailability
            ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            strokeWidth: 2,
          ),
        )
            : Text(
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