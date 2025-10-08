import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/jro_service.dart';

class CreateReservationScreen extends StatefulWidget {
  final Map<String, dynamic>? selectedTable;
  final DateTime? selectedDate;
  final String? selectedTime;

  const CreateReservationScreen({
    super.key,
    this.selectedTable,
    this.selectedDate,
    this.selectedTime,
  });

  @override
  State<CreateReservationScreen> createState() =>
      _CreateReservationScreenState();
}

class _CreateReservationScreenState extends State<CreateReservationScreen> {
  final _formKey = GlobalKey<FormState>();
  final JROService _jroService = JROService();

  // Form controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _guestCountController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String? _selectedTime;
  List<Map<String, dynamic>> _selectedTables = [];
  bool _isLoading = false;

  final List<String> _timeSlots = [
    '09:00', '10:00', '11:00', '12:00', '13:00', '14:00',
    '15:00', '16:00', '17:00', '18:00', '19:00', '20:00', '21:00'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.selectedTable != null) {
      _selectedTables = [widget.selectedTable!];
    }
    if (widget.selectedDate != null) {
      _selectedDate = widget.selectedDate!;
    }
    if (widget.selectedTime != null) {
      _selectedTime = widget.selectedTime;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _notesController.dispose();
    _guestCountController.dispose();
    super.dispose();
  }

  Future<void> _createReservation() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedTables.isEmpty) {
      _showErrorDialog('Silakan pilih minimal satu meja');
      return;
    }

    if (_selectedTime == null) {
      _showErrorDialog('Silakan pilih waktu reservasi');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final tableIds = _selectedTables.map((t) => t['_id'] as String).toList();
      final areaId = _selectedTables.first['area']['_id'] as String;

      final result = await _jroService.createReservation(
        guestName: _nameController.text.trim(),
        guestPhone: _phoneController.text.trim(),
        guestEmail: _emailController.text.trim(),
        guestCount: int.parse(_guestCountController.text.trim()),
        reservationDate: DateFormat('yyyy-MM-dd').format(_selectedDate),
        reservationTime: _selectedTime!,
        tableIds: tableIds,
        areaId: areaId,
        notes: _notesController.text.trim(),
      );

      setState(() => _isLoading = false);

      if (result['success']) {
        _showSuccessDialog(result['message'] ?? 'Reservasi berhasil dibuat');
      } else {
        _showErrorDialog(result['error'] ?? 'Gagal membuat reservasi');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog('Terjadi kesalahan: $e');
    }
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Color(0xFF10B981)),
            SizedBox(width: 8),
            Text('Berhasil'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(true); // Return to previous screen with success
            },
            child: const Text('OK'),
          ),
        ],
      ),
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

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      locale: const Locale('id', 'ID'),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
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
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSectionTitle('Informasi Tamu'),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _nameController,
              label: 'Nama Tamu',
              icon: Icons.person,
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
              icon: Icons.phone,
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
              controller: _emailController,
              label: 'Email (Opsional)',
              icon: Icons.email,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _guestCountController,
              label: 'Jumlah Tamu',
              icon: Icons.people,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Jumlah tamu harus diisi';
                }
                final number = int.tryParse(value);
                if (number == null || number < 1) {
                  return 'Jumlah tamu minimal 1';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('Waktu Reservasi'),
            const SizedBox(height: 12),
            InkWell(
              onTap: _selectDate,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Color(0xFF2E8B57)),
                    const SizedBox(width: 12),
                    Text(
                      DateFormat('EEEE, dd MMMM yyyy', 'id_ID')
                          .format(_selectedDate),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedTime,
              decoration: InputDecoration(
                labelText: 'Waktu',
                prefixIcon: const Icon(Icons.access_time, color: Color(0xFF2E8B57)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              items: _timeSlots.map((time) => DropdownMenuItem(
                value: time,
                child: Text(time),
              )).toList(),
              onChanged: (value) => setState(() => _selectedTime = value),
              validator: (value) {
                if (value == null) {
                  return 'Waktu harus dipilih';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('Meja Dipilih'),
            const SizedBox(height: 12),
            _buildSelectedTables(),
            const SizedBox(height: 24),
            _buildSectionTitle('Catatan (Opsional)'),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _notesController,
              label: 'Catatan',
              icon: Icons.note,
              maxLines: 3,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _createReservation,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E8B57),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
                  : const Text(
                'Buat Reservasi',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Color(0xFF2E8B57),
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
        prefixIcon: Icon(icon, color: const Color(0xFF2E8B57)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF2E8B57)),
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildSelectedTables() {
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

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _selectedTables.map((table) {
        return Chip(
          label: Text(
            '${table['table_number']} (${table['seats']} kursi)',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF2E8B57),
          deleteIcon: const Icon(Icons.close, color: Colors.white, size: 18),
          onDeleted: () {
            setState(() {
              _selectedTables.remove(table);
            });
          },
        );
      }).toList(),
    );
  }
}