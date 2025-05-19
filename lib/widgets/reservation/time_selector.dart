import 'package:flutter/material.dart';

class TimeSelector extends StatelessWidget {
  final TimeOfDay selectedTime;
  final Function(TimeOfDay) onTimeChanged;
  final VoidCallback selectTime;

  const TimeSelector({
    super.key,
    required this.selectedTime,
    required this.onTimeChanged,
    required this.selectTime,
  });

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
            'Pilih Jam Reservasi',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Time selector
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black,
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
                        // const Icon(Icons.keyboard_arrow_up, color: Colors.white),
                        Text(
                          selectedTime.hour.toString().padLeft(2, '0'),
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        // const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                      ],
                    ),
                  ),
                  const Text(
                    ' : ',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  InkWell(
                    onTap: selectTime,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // const Icon(Icons.keyboard_arrow_up, color: Colors.white),
                        Text(
                          selectedTime.minute.toString().padLeft(2, '0'),
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        // const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}