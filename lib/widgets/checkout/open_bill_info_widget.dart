import 'package:flutter/material.dart';
import '../../models/reservation_data.dart';

class OpenBillInfoWidget extends StatelessWidget {
  final OpenBillData openBillData;

  const OpenBillInfoWidget({super.key, required this.openBillData});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              Text(
                'Detail Open Bill',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  '📅 ${openBillData.date.toLocal().toIso8601String().split('T').first}',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              Text(
                '🕐 ${openBillData.time.hour}:${openBillData.time.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  '📍 Area: ${openBillData.areaCode}',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              Text(
                '🪑 Tabel: ${openBillData.tableNumbers}',
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }
}