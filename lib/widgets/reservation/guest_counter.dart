import 'package:flutter/material.dart';

class GuestCounter extends StatelessWidget {
  final int guestCount;
  final Function(int) onGuestCountChanged;

  const GuestCounter({
    super.key,
    required this.guestCount,
    required this.onGuestCountChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Number of Guests',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildCounterButton(
              icon: Icons.remove,
              onPressed: guestCount > 1
                  ? () => onGuestCountChanged(guestCount - 1)
                  : null,
            ),
            Text(
              '$guestCount',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            _buildCounterButton(
              icon: Icons.add,
              onPressed: guestCount < 10
                  ? () => onGuestCountChanged(guestCount + 1)
                  : null,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCounterButton({
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          icon,
          size: 18,
          color: onPressed == null ? Colors.grey[400] : Colors.black,
        ),
      ),
    );
  }
}