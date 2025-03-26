// File: lib/widgets/quantity_selector.dart
import 'package:flutter/material.dart';

/// Widget untuk memilih jumlah item yang akan dibeli
class QuantitySelector extends StatelessWidget {
  final int quantity;
  final Function(int) onChanged;
  final Color primaryColor;

  const QuantitySelector({
    super.key,
    required this.quantity,
    required this.onChanged,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildButton(
          icon: Icons.remove,
          onPressed: quantity > 1
              ? () => onChanged(quantity - 1)
              : null,
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            quantity.toString(),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        _buildButton(
          icon: Icons.add,
          onPressed: () => onChanged(quantity + 1),
        ),
      ],
    );
  }

  /// Membuat tombol untuk menambah atau mengurangi jumlah
  Widget _buildButton({required IconData icon, VoidCallback? onPressed}) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, size: 16),
        color: onPressed != null ? primaryColor : Colors.grey,
        onPressed: onPressed,
      ),
    );
  }
}