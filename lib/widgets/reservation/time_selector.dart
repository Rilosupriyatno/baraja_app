import 'package:flutter/material.dart';

class TimeSelector extends StatelessWidget {
  final TimeOfDay selectedTime;
  final Function(TimeOfDay) onTimeChanged;
  final VoidCallback selectTime;
  final DateTime selectedDate; // Tambahkan parameter selectedDate

  const TimeSelector({
    super.key,
    required this.selectedTime,
    required this.onTimeChanged,
    required this.selectTime,
    required this.selectedDate, // Required parameter
  });

  // Method untuk mengecek apakah waktu yang dipilih valid (minimal 5 menit dari sekarang)
  bool _isValidTime(TimeOfDay time, DateTime date) {
    final DateTime now = DateTime.now();
    final DateTime selectedDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    // Jika tanggal bukan hari ini, maka waktu apapun valid
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime selectedDateOnly = DateTime(date.year, date.month, date.day);

    if (selectedDateOnly.isAfter(today)) {
      return true;
    }

    // Jika tanggal adalah hari ini, cek apakah waktu minimal 5 menit dari sekarang
    if (selectedDateOnly.isAtSameMomentAs(today)) {
      final DateTime minimumTime = now.add(const Duration(minutes: 5));
      return selectedDateTime.isAfter(minimumTime) || selectedDateTime.isAtSameMomentAs(minimumTime);
    }

    // Jika tanggal sudah lewat, tidak valid
    return false;
  }

  // Method untuk mendapatkan waktu minimum yang bisa dipilih
  String _getMinimumTimeText() {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime selectedDateOnly = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);

    if (selectedDateOnly.isAtSameMomentAs(today)) {
      final DateTime minimumTime = now.add(const Duration(minutes: 5));
      return '${minimumTime.hour.toString().padLeft(2, '0')}:${minimumTime.minute.toString().padLeft(2, '0')}';
    }

    return '';
  }

  @override
  Widget build(BuildContext context) {
    final bool isTimeValid = _isValidTime(selectedTime, selectedDate);
    final String minimumTimeText = _getMinimumTimeText();

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
            'Pilih Jam Reservasi',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),

          // Tampilkan informasi waktu minimum jika diperlukan
          if (minimumTimeText.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Minimal jam $minimumTimeText (5 menit dari sekarang)',
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange.shade700,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Time selector
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 10),
              decoration: BoxDecoration(
                color: isTimeValid ? Colors.black : Colors.grey.shade400,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: selectTime,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          selectedTime.hour.toString().padLeft(2, '0'),
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: isTimeValid ? Colors.white : Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    ' : ',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: isTimeValid ? Colors.white : Colors.white70,
                    ),
                  ),
                  InkWell(
                    onTap: selectTime,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          selectedTime.minute.toString().padLeft(2, '0'),
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: isTimeValid ? Colors.white : Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Tampilkan peringatan jika waktu tidak valid
          if (!isTimeValid) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.red.shade600,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      minimumTimeText.isNotEmpty
                          ? 'Waktu harus minimal $minimumTimeText'
                          : 'Waktu yang dipilih sudah terlewat',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}