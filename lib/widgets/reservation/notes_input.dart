import 'package:flutter/material.dart';

class NotesInput extends StatelessWidget {
  final TextEditingController controller;

  const NotesInput({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Additional Notes',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: controller,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Any special requests?',
              contentPadding: EdgeInsets.all(12),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }
}