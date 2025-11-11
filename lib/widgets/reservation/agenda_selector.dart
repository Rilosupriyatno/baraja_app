// widgets/reservation/agenda_selector.dart
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class AgendaSelector extends StatelessWidget {
  final String? selectedAgenda;
  final Function(String) onAgendaChanged;

  const AgendaSelector({
    super.key,
    required this.selectedAgenda,
    required this.onAgendaChanged,
  });

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> agendas = [
      {'icon': Icons.celebration, 'label': 'Meeting', 'value': 'Meeting'},
      {'icon': Icons.cake, 'label': 'Ulang Tahun', 'value': 'Ulang Tahun'},
      {'icon': Icons.favorite, 'label': 'Anniversary', 'value': 'Anniversary'},
      {'icon': Icons.groups, 'label': 'Keluarga', 'value': 'Keluarga'},
      {'icon': Icons.more_horiz, 'label': 'Lainnya', 'value': 'Lainnya'},
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
            'Agenda',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: agendas.map((agenda) {
              final isSelected = selectedAgenda == agenda['value'];
              return InkWell(
                onTap: () => onAgendaChanged(agenda['value']),
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
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        agenda['icon'],
                        size: 16,
                        color: isSelected ? Colors.white : Colors.grey.shade700,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        agenda['label'],
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey.shade700,
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
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