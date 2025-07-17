import 'package:flutter/material.dart';
import '../utils/payment_method_utils.dart';

class GenericPaymentWidget extends StatelessWidget {
  final String? method;

  const GenericPaymentWidget({
    super.key,
    required this.method,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF8E8E93).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        PaymentMethodUtils.getPaymentMethodName(method),
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF8E8E93),
        ),
      ),
    );
  }
}