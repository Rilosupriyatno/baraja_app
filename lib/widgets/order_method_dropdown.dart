import 'package:flutter/material.dart';

class OrderMethode extends StatelessWidget {
  final String paymentMethode;
  final Function(String) onMetodeChanged;

  const OrderMethode({
    super.key,
    required this.paymentMethode,
    required this.onMetodeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Kapan Anda ingin memesan?', style: TextStyle(fontWeight: FontWeight.bold)),
        DropdownButton<String>(
          isExpanded: true,
          value: paymentMethode,
          items: const [
            DropdownMenuItem(
              value: 'Pilih Metode',
              child: Text('Pilih Metode'),
            ),
            DropdownMenuItem(
              value: 'Pickup',
              child: Text('Pickup'),
            ),
            DropdownMenuItem(
              value: 'Delivery',
              child: Text('Delivery'),
            ),
            DropdownMenuItem(
              value: 'Dine In',
              child: Text('Dine In'),
            ),
          ],
          onChanged: (value) {
            if (value != null) {
              onMetodeChanged(value);
            }
          },
        ),
      ],
    );
  }
}