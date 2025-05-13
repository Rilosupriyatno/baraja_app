import 'package:flutter/material.dart';

class TimeSelector extends StatefulWidget {
  final Function(TimeOfDay) onTimeSelected;

  const TimeSelector({super.key, required this.onTimeSelected});

  @override
  State<TimeSelector> createState() => _TimeSelectorState();
}

class _TimeSelectorState extends State<TimeSelector> {
  final List<TimeOfDay> _availableTimes = [
    const TimeOfDay(hour: 9, minute: 0),
    const TimeOfDay(hour: 10, minute: 0),
    const TimeOfDay(hour: 11, minute: 0),
    const TimeOfDay(hour: 13, minute: 0),
    const TimeOfDay(hour: 14, minute: 0),
    const TimeOfDay(hour: 15, minute: 0),
  ];

  TimeOfDay? _selectedTime;

  void _selectTime(TimeOfDay time) {
    setState(() {
      _selectedTime = time;
    });
    widget.onTimeSelected(time);
  }

  String _formatTime(TimeOfDay time) {
    final int hour = time.hour;
    final String minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Time',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 2.5,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: _availableTimes.length,
          itemBuilder: (context, index) {
            final time = _availableTimes[index];
            final isSelected = _selectedTime != null &&
                _selectedTime!.hour == time.hour &&
                _selectedTime!.minute == time.minute;

            return GestureDetector(
              onTap: () => _selectTime(time),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF0A1A33) : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF0A1A33) : Colors.grey[300]!,
                  ),
                ),
                child: Center(
                  child: Text(
                    _formatTime(time),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}