import 'package:flutter/material.dart';
import '../utils/payment_method_utils.dart';

class VirtualAccountWidget extends StatelessWidget {
  final Map<String, dynamic> vaData;
  final Function(String, String) onCopyToClipboard;

  const VirtualAccountWidget({
    super.key,
    required this.vaData,
    required this.onCopyToClipboard,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF007AFF).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            PaymentMethodUtils.getBankName(vaData['bank']),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF007AFF),
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Nomor Virtual Account',
          style: TextStyle(
            fontSize: 13,
            color: Color(0xFF8E8E93),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: SelectableText(
                vaData['va_number']?.toString() ?? '',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace',
                  color: Color(0xFF1C1C1E),
                  letterSpacing: 1.5,
                ),
              ),
            ),
            const SizedBox(width: 12),
            InkWell(
              onTap: () => onCopyToClipboard(
                vaData['va_number']?.toString() ?? '',
                'Nomor Virtual Account',
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
                  color: Color(0xFF007AFF),
                  size: 16,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}