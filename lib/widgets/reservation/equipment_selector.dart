// widgets/reservation/equipment_selector.dart
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class EquipmentSelector extends StatelessWidget {
  final List<String> selectedEquipment;
  final Function(List<String>) onEquipmentChanged;

  const EquipmentSelector({
    super.key,
    required this.selectedEquipment,
    required this.onEquipmentChanged,
  });

  void _toggleEquipment(String equipment) {
    List<String> updatedEquipment = List.from(selectedEquipment);
    if (updatedEquipment.contains(equipment)) {
      updatedEquipment.remove(equipment);
    } else {
      updatedEquipment.add(equipment);
    }
    onEquipmentChanged(updatedEquipment);
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> equipmentList = [
      {'icon': Icons.video_camera_front, 'label': 'Proyektor', 'value': 'Proyektor'},
      {'icon': Icons.mic, 'label': 'Microphone', 'value': 'Microphone'},
      {'icon': Icons.speaker, 'label': 'Sound System', 'value': 'Sound System'},
      {'icon': Icons.tv, 'label': 'TV/Monitor', 'value': 'TV/Monitor'},
      {'icon': Icons.meeting_room, 'label': 'Whiteboard', 'value': 'Whiteboard'},
      {'icon': Icons.local_florist, 'label': 'Dekorasi', 'value': 'Dekorasi'},
      {'icon': Icons.ac_unit, 'label': 'AC', 'value': 'AC'},
      {'icon': Icons.wifi, 'label': 'WiFi', 'value': 'WiFi'},
    ];

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Equipment Tambahan',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (selectedEquipment.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.barajaPrimary.primaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${selectedEquipment.length} dipilih',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Pilih equipment yang dibutuhkan (opsional)',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: equipmentList.map((equipment) {
              final isSelected = selectedEquipment.contains(equipment['value']);
              return InkWell(
                onTap: () => _toggleEquipment(equipment['value']),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.barajaPrimary.primaryColor
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.barajaPrimary.primaryColor
                          : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        equipment['icon'],
                        size: 16,
                        color: isSelected ? Colors.white : Colors.grey.shade700,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        equipment['label'],
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey.shade700,
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.check_circle,
                          size: 14,
                          color: Colors.white,
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          // Display selected equipment list
          if (selectedEquipment.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.barajaPrimary.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Equipment Dipilih:',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.barajaPrimary.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    selectedEquipment.join(', '),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}