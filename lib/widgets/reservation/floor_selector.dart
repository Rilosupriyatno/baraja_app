import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class FloorSelector extends StatelessWidget {
  final int selectedFloor;
  final Function(int) onFloorChanged;

  const FloorSelector({
    super.key,
    required this.selectedFloor,
    required this.onFloorChanged,
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
            'Pilih Lantai',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildFloorOption(2),
              const SizedBox(width: 16),
              _buildFloorOption(3),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFloorOption(int floor) {
    final isSelected = selectedFloor == floor;

    return InkWell(
      onTap: () {
        onFloorChanged(floor);
      },
      child: Container(
        width: 120,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppTheme.barajaPrimary.primaryColor : Colors.grey.shade300,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(
              Icons.stairs,
              color: isSelected ? AppTheme.barajaPrimary.primaryColor : Colors.grey,
            ),
            const SizedBox(height: 4),
            Text(
              'Lantai $floor',
              style: TextStyle(
                color: isSelected ? AppTheme.barajaPrimary.primaryColor : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}