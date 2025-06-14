import 'package:baraja_app/widgets/utils/classic_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/app_theme.dart';
import '../widgets/reservation/date_selector.dart';
import '../widgets/reservation/floor_selector.dart';
import '../widgets/reservation/person_counter.dart';
import '../widgets/reservation/time_selector.dart';
import '../models/reservation_data.dart';
import 'menu_screen.dart';

class ReservationScreen extends StatefulWidget {
  const ReservationScreen({super.key});

  @override
  State<ReservationScreen> createState() => _ReservationScreenState();
}

class _ReservationScreenState extends State<ReservationScreen> {
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = const TimeOfDay(hour: 8, minute: 0);
  int selectedFloor = 2;
  int personCount = 1;
  final int maxPersons = 30;

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

  // Fungsi untuk navigasi ke menu dengan data reservasi
  void _navigateToMenuWithReservation() {
    final String formattedDate = DateFormat('dd MMMM yyyy', 'id_ID').format(selectedDate);
    final String formattedTime = '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';

    final reservationData = ReservationData(
      date: selectedDate,
      time: selectedTime,
      floor: selectedFloor,
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

                // Floor selection
                FloorSelector(
                  selectedFloor: selectedFloor,
                  onFloorChanged: (floor) {
                    setState(() {
                      selectedFloor = floor;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Person count
                PersonCounter(
                  personCount: personCount,
                  maxPersons: maxPersons,
                  onPersonCountChanged: (count) {
                    setState(() {
                      personCount = count;
                    });
                  },
                ),
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

  Widget _buildReservationButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          // Navigasi ke menu dengan data reservasi
          _navigateToMenuWithReservation();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.barajaPrimary.primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const Text(
          'Lanjut Pilih Menu',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}