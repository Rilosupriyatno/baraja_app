import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateSelector extends StatefulWidget {
  final Function(DateTime) onDateSelected;

  const DateSelector({super.key, required this.onDateSelected});

  @override
  State<DateSelector> createState() => _DateSelectorState();
}

class _DateSelectorState extends State<DateSelector> {
  final List<DateTime> _availableDates = [];
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _generateAvailableDates();
  }

  void _generateAvailableDates() {
    // Generate dates for the next 7 days
    final DateTime now = DateTime.now();
    for (int i = 0; i < 7; i++) {
      _availableDates.add(DateTime(now.year, now.month, now.day + i));
    }
  }

  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
    widget.onDateSelected(date);
  }

  String _getDayName(DateTime date) {
    return DateFormat('EEE').format(date).toUpperCase();
  }

  String _getDayNumber(DateTime date) {
    return DateFormat('d').format(date);
  }

  bool _isSelected(DateTime date) {
    return _selectedDate != null &&
        date.year == _selectedDate!.year &&
        date.month == _selectedDate!.month &&
        date.day == _selectedDate!.day;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Date',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 70,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _availableDates.length,
            itemBuilder: (context, index) {
              final date = _availableDates[index];
              final isSelected = _isSelected(date);

              return GestureDetector(
                onTap: () => _selectDate(date),
                child: Container(
                  width: 60,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF0A1A33) : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF0A1A33) : Colors.grey[300]!,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _getDayName(date),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isSelected ? Colors.white : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getDayNumber(date),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}