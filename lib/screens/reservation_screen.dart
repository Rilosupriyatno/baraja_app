// screens/reservation_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/table.dart';
import '../widgets/utils/classic_app_bar.dart';
import '../theme/app_theme.dart';
import '../widgets/reservation/date_selector.dart';
import '../widgets/reservation/area_selector.dart';
import '../widgets/reservation/person_counter.dart';
import '../widgets/reservation/time_selector.dart';
import '../models/reservation_data.dart';
import '../models/area.dart';
import '../services/reservation_service.dart';
import 'menu_screen.dart';

class ReservationScreen extends StatefulWidget {
  const ReservationScreen({super.key});

  @override
  State<ReservationScreen> createState() => _ReservationScreenState();
}

class _ReservationScreenState extends State<ReservationScreen> {
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = const TimeOfDay(hour: 19, minute: 0);
  Area? selectedArea;
  int personCount = 1;
  List<TableModel> tables = [];
  bool isLoadingTables = false;


  List<Area> areas = [];
  bool isLoadingAreas = true;
  bool isCheckingAvailability = false;
  Map<String, dynamic>? availabilityResult;

  @override
  void initState() {
    super.initState();
    _loadAreas();
  }

  Future<void> _loadAreas() async {
    try {
      final loadedAreas = await ReservationService.getAreas();
      setState(() {
        areas = loadedAreas.where((area) => area.isActive).toList();
        isLoadingAreas = false;
      });
    } catch (e) {
      setState(() {
        isLoadingAreas = false;
      });
      _showErrorDialog('Gagal memuat data area: $e');
    }
  }

  Future<void> _loadTablesForArea(String areaId) async {
    setState(() {
      isLoadingTables = true;
      tables = [];
    });

    try {
      final result = await ReservationService.getAreaTables(areaId);
      setState(() {
        tables = result['tables'];
        isLoadingTables = false;
      });
    } catch (e) {
      setState(() {
        isLoadingTables = false;
      });
      _showErrorDialog('Gagal memuat meja untuk area: $e');
    }
  }


  Future<void> _checkAvailability() async {
    if (selectedArea == null) return;

    setState(() {
      isCheckingAvailability = true;
      availabilityResult = null;
    });

    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
    final timeStr = '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';

    try {
      final result = await ReservationService.checkAvailability(
        date: dateStr,
        time: timeStr,
        areaId: selectedArea!.id,
        guestCount: personCount,
      );

      setState(() {
        isCheckingAvailability = false;
        availabilityResult = result;
      });

      if (result['available'] == true) {
        // Show success dialog before navigating
        _showAvailabilityDialog(result, true);
      } else {
        // Show error dialog
        _showAvailabilityDialog(result, false);
      }
    } catch (e) {
      setState(() {
        isCheckingAvailability = false;
        availabilityResult = {
          'available': false,
          'message': 'Gagal memeriksa ketersediaan: $e',
          'reason': 'error'
        };
      });
    }
  }

  void _showAvailabilityDialog(Map<String, dynamic> result, bool isAvailable) {
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
                isAvailable ? 'Area Tersedia' : 'Area Tidak Tersedia',
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
              Text(result['message'] ?? ''),
              if (result['data'] != null) ...[
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
                      _buildInfoRow('Area', result['data']['area_name']),
                      _buildInfoRow('Jumlah Tamu', '${result['data']['guest_count']} orang'),
                      _buildInfoRow('Kapasitas Area', '${result['data']['capacity']} orang'),
                      _buildInfoRow('Total Meja', '${result['data']['total_tables']}'),
                      _buildInfoRow('Meja Tersedia', '${result['data']['available_tables']}'),
                      if (result['data']['required_tables'] != null)
                        _buildInfoRow('Meja Dibutuhkan', '${result['data']['required_tables']}'),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                isAvailable ? 'Batal' : 'OK',
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            if (isAvailable)
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _navigateToMenuWithReservation();
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
          Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToMenuWithReservation() {
    if (selectedArea == null) return;

    final String formattedDate = DateFormat('dd MMMM yyyy', 'id_ID').format(selectedDate);
    final String formattedTime = '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';

    final reservationData = ReservationData(
      date: selectedDate,
      time: selectedTime,
      areaId: selectedArea!.id,
      areaCode: selectedArea!.areaCode,
      personCount: personCount,
      formattedDate: formattedDate,
      formattedTime: formattedTime,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MenuScreen(
          isReservation: true,
          reservationData: reservationData,
        ),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.error, color: Colors.red),
              SizedBox(width: 8),
              Text('Error'),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  bool get _canMakeReservation {
    return selectedArea != null &&
        personCount <= (selectedArea?.capacity ?? 0) &&
        !isCheckingAvailability;
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );
    if (picked != null && picked != selectedTime) {
      setState(() {
        selectedTime = picked;
      });
    }
  }

  Widget _buildReservationButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _canMakeReservation ? _checkAvailability : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _canMakeReservation
              ? AppTheme.barajaPrimary.primaryColor
              : Colors.grey.shade300,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: isCheckingAvailability
            ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            strokeWidth: 2,
          ),
        )
            : Text(
          selectedArea == null
              ? 'Pilih Area Terlebih Dahulu'
              : 'Cek Ketersediaan & Lanjut',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: _canMakeReservation ? Colors.white : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }
  Widget _buildTableList() {
    if (selectedArea == null) return const SizedBox();

    if (isLoadingTables) {
      return const Center(child: CircularProgressIndicator());
    }

    if (tables.isEmpty) {
      return const Center(
        child: Text(
          'Tidak ada meja tersedia untuk area ini',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nomor Meja Tersedia',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tables.map((table) {
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                decoration: BoxDecoration(
                  color: table.isAvailable ? Colors.green.shade100 : Colors.red.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  table.tableNumber,
                  style: TextStyle(
                    color: table.isAvailable ? Colors.green.shade800 : Colors.red.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          )
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const ClassicAppBar(title: 'Reservasi'),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date selection
                DateSelector(
                  selectedDate: selectedDate,
                  onDateChanged: (date) {
                    setState(() {
                      selectedDate = date;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Time selection
                TimeSelector(
                  selectedTime: selectedTime,
                  onTimeChanged: (time) {
                    setState(() {
                      selectedTime = time;
                    });
                  },
                  selectTime: () => _selectTime(context),
                ),
                const SizedBox(height: 16),

                // Area selection
                AreaSelector(
                  areas: areas,
                  selectedAreaId: selectedArea?.id,
                  onAreaChanged: (area) {
                    setState(() {
                      selectedArea = area;
                      if (personCount > area.capacity) {
                        personCount = area.capacity;
                      }
                    });
                    _loadTablesForArea(area.id); // Load table list
                  },

                  isLoading: isLoadingAreas,
                ),
                const SizedBox(height: 16),

                // Person count
                PersonCounter(
                  personCount: personCount,
                  maxPersons: selectedArea?.capacity ?? 30,
                  onPersonCountChanged: (count) {
                    setState(() {
                      personCount = count;
                    });
                  },
                ),
                _buildTableList(),
                const SizedBox(height: 24),


                // Reservation button
                _buildReservationButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}