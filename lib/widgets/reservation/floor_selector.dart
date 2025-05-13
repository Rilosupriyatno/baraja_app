import 'package:flutter/material.dart';

class FloorSelector extends StatefulWidget {
  final Function(int) onFloorSelected;

  const FloorSelector({super.key, required this.onFloorSelected});

  @override
  State<FloorSelector> createState() => _FloorSelectorState();
}

class _FloorSelectorState extends State<FloorSelector> {
  int? _selectedFloor;

  void _selectFloor(int floor) {
    setState(() {
      _selectedFloor = floor;
    });
    widget.onFloorSelected(floor);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Floor',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [1, 2, 3].map((floor) {
            final isSelected = _selectedFloor == floor;

            return GestureDetector(
              onTap: () => _selectFloor(floor),
              child: Container(
                width: MediaQuery.of(context).size.width / 3.5,
                height: 60,
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
                      'Floor $floor',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}