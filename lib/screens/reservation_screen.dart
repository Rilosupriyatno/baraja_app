import 'package:flutter/material.dart';
import '../widgets/reservation/date_selector.dart';
import '../widgets/reservation/floor_selector.dart';
import '../widgets/reservation/guest_counter.dart';
import '../widgets/reservation/notes_input.dart';
import '../widgets/reservation/time_selector.dart';


class ReservationScreen extends StatefulWidget {
  const ReservationScreen({super.key});

  @override
  State<ReservationScreen> createState() => _ReservationScreenState();
}

class _ReservationScreenState extends State<ReservationScreen> {
  // Selected values
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  int _guestCount = 2;
  int? _selectedFloor;
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _updateSelectedDate(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
  }

  void _updateSelectedTime(TimeOfDay time) {
    setState(() {
      _selectedTime = time;
    });
  }

  void _updateSelectedFloor(int floor) {
    setState(() {
      _selectedFloor = floor;
    });
  }

  void _updateGuestCount(int count) {
    setState(() {
      _guestCount = count;
    });
  }

  void _confirmReservation() {
    // In a real app, this would send the reservation to a backend
    final String reservationDetails = '''
    Date: ${_selectedDate?.toString().split(' ')[0]}
    Floor: $_selectedFloor
    Time: ${_selectedTime?.format(context)}
    Guests: $_guestCount
    Notes: ${_notesController.text}
    ''';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Reservation confirmed!\n$reservationDetails')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text('Reserve Table'),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date selector
              DateSelector(onDateSelected: _updateSelectedDate),
              const SizedBox(height: 24),

              // Floor selector
              FloorSelector(onFloorSelected: _updateSelectedFloor),
              const SizedBox(height: 24),

              // Time selector
              TimeSelector(onTimeSelected: _updateSelectedTime),
              const SizedBox(height: 24),

              // Guest counter
              GuestCounter(
                guestCount: _guestCount,
                onGuestCountChanged: _updateGuestCount,
              ),
              const SizedBox(height: 24),

              // Notes input
              NotesInput(controller: _notesController),
              const SizedBox(height: 32),

              // Confirm button
              ElevatedButton(
                onPressed: _confirmReservation,
                child: const Text('Confirm Reservation'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}