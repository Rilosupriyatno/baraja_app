import 'package:baraja_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateSelector extends StatefulWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateChanged;

  const DateSelector({
    super.key,
    required this.selectedDate,
    required this.onDateChanged,
  });

  @override
  State<DateSelector> createState() => _DateSelectorState();
}

class _DateSelectorState extends State<DateSelector> {
  late DateTime _displayedMonth;

  @override
  void initState() {
    super.initState();
    _displayedMonth = DateTime(widget.selectedDate.year, widget.selectedDate.month);
  }

  void _previousMonth() {
    setState(() {
      _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1);
    });
  }

  // Helper method to check if a date is in the past
  bool _isPastDate(DateTime date) {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime compareDate = DateTime(date.year, date.month, date.day);
    return compareDate.isBefore(today);
  }

  // Menghasilkan daftar hari dalam bulan
  List<Widget> _generateDaysInMonth() {
    final DateTime firstDayOfMonth = DateTime(_displayedMonth.year, _displayedMonth.month, 1);
    final int daysInMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1, 0).day;

    // Menghitung offset berdasarkan hari pertama bulan (0 = Minggu, 1 = Senin, dst)
    final int firstWeekdayOfMonth = firstDayOfMonth.weekday % 7;

    List<Widget> dayWidgets = [];

    // Tambahkan placeholder untuk hari-hari sebelum hari pertama bulan
    for (int i = 0; i < firstWeekdayOfMonth; i++) {
      dayWidgets.add(
        Container(
          width: 36,
          height: 36,
          margin: const EdgeInsets.all(2),
        ),
      );
    }

    // Tambahkan widget untuk setiap hari dalam bulan
    for (int day = 1; day <= daysInMonth; day++) {
      final DateTime date = DateTime(_displayedMonth.year, _displayedMonth.month, day);
      final bool isToday = date.year == DateTime.now().year &&
          date.month == DateTime.now().month &&
          date.day == DateTime.now().day;
      final bool isSelected = date.year == widget.selectedDate.year &&
          date.month == widget.selectedDate.month &&
          date.day == widget.selectedDate.day;
      final bool isPast = _isPastDate(date);

      dayWidgets.add(
        GestureDetector(
          onTap: isPast ? null : () {
            widget.onDateChanged(date);
          },
          child: Container(
            width: 36,
            height: 36,
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isPast
                  ? Colors.grey.withOpacity(0.2)
                  : isSelected
                  ? AppTheme.barajaPrimary.primaryColor
                  : (isToday ? AppTheme.barajaPrimary.primaryColor.withOpacity(0.2) : null),
              shape: BoxShape.circle,
              border: isToday && !isSelected && !isPast
                  ? Border.all(color: AppTheme.barajaPrimary.primaryColor)
                  : null,
            ),
            child: Center(
              child: Text(
                day.toString(),
                style: TextStyle(
                  color: isPast
                      ? Colors.grey.withOpacity(0.5)
                      : isSelected
                      ? Colors.white
                      : Colors.black,
                  fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return dayWidgets;
  }

  Widget _dayLabel(String day) {
    return Container(
      padding: const EdgeInsets.all(4),
      width: 36,
      alignment: Alignment.center,
      child: Text(
        day,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          const Text(
            'Pilih Tanggal',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _previousMonth,
              ),
              Text(
                DateFormat('MMMM yyyy', 'id_ID').format(_displayedMonth),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _nextMonth,
              ),
            ],
          ),

          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _dayLabel('Min'),
              _dayLabel('Sen'),
              _dayLabel('Sel'),
              _dayLabel('Rab'),
              _dayLabel('Kam'),
              _dayLabel('Jum'),
              _dayLabel('Sab'),
            ],
          ),

          const SizedBox(height: 8),

          // Kalender
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            mainAxisSpacing: 2,
            crossAxisSpacing: 2,
            children: _generateDaysInMonth(),
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}