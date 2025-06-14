import 'package:flutter/material.dart';

class ExistingRatingInfo extends StatelessWidget {
  const ExistingRatingInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Anda sudah memberikan rating untuk pesanan ini. Anda dapat mengubahnya di bawah.',
              style: TextStyle(
                color: Colors.blue.shade700,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}