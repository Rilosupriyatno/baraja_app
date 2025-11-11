// widgets/reservation/serving_type_selector.dart
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class ServingTypeSelector extends StatelessWidget {
  final String? selectedServingType;
  final Function(String) onServingTypeChanged;

  const ServingTypeSelector({
    super.key,
    required this.selectedServingType,
    required this.onServingTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> servingTypes = [
      {
        'icon': Icons.restaurant_menu,
        'label': 'A La Carte',
        'value': 'ala carte',
        'description': 'Pesan per menu'
      },
      {
        'icon': Icons.dining,
        'label': 'Buffet',
        'value': 'buffet',
        'description': 'Prasmanan'
      },
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
          const Text(
            'Tipe Penyajian Makanan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: servingTypes.map((servingType) {
              final isSelected = selectedServingType == servingType['value'];
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: InkWell(
                    onTap: () => onServingTypeChanged(servingType['value']),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.barajaPrimary.primaryColor
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.barajaPrimary.primaryColor
                              : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            servingType['icon'],
                            size: 32,
                            color: isSelected ? Colors.white : Colors.grey.shade700,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            servingType['label'],
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.grey.shade700,
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            servingType['description'],
                            style: TextStyle(
                              color: isSelected ? Colors.white70 : Colors.grey.shade600,
                              fontSize: 10,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}