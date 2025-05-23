import 'package:flutter/material.dart';

class PaymentRowWidget extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isTotal;
  final bool isSuccess;

  const PaymentRowWidget({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.isTotal,
    this.isSuccess = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isTotal ? const Color(0xFFF8F9FF) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isTotal ? const Color(0xFF8B5CF6).withOpacity(0.2) : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isSuccess ? const Color(0xFF10B981).withOpacity(0.1) :
              isTotal ? const Color(0xFF8B5CF6).withOpacity(0.1) : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 16,
              color: isSuccess ? const Color(0xFF10B981) :
              isTotal ? const Color(0xFF8B5CF6) : Colors.grey.shade600,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w600,
              color: isSuccess ? const Color(0xFF10B981) :
              isTotal ? const Color(0xFF8B5CF6) : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}