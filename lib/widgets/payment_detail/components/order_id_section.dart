import 'package:flutter/material.dart';

class OrderIdSection extends StatelessWidget {
  final String? orderId;
  final Function(String, String) onCopyToClipboard;

  const OrderIdSection({
    super.key,
    required this.orderId,
    required this.onCopyToClipboard,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ID Pesanan',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF8E8E93),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: SelectableText(
                orderId ?? '-',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'monospace',
                  color: Color(0xFF1C1C1E),
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(width: 12),
            InkWell(
              onTap: () => onCopyToClipboard(
                orderId ?? '',
                'ID Pesanan',
              ),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF007AFF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.copy_rounded,
                  size: 16,
                  color: Color(0xFF007AFF),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}