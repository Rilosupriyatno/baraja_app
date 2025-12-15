import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../widgets/checkout/payment_method_widget.dart';

class PaymentMethodWithValidation extends StatelessWidget {
  final String displayedPaymentMethod;
  final Function(Map<String, dynamic>) onMethodSelected;
  final String? errorMessage;
  final bool isReservation; // ✅ NEW
  final bool isGroMode; // ✅ NEW

  const PaymentMethodWithValidation({
    super.key,
    required this.displayedPaymentMethod,
    required this.onMethodSelected,
    this.errorMessage,
    this.isReservation = false, // ✅ NEW
    this.isGroMode = false, // ✅ NEW
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: errorMessage != null
                ? Border.all(color: Colors.red.shade300, width: 2)
                : null,
          ),
          child: PaymentMethodWidget(
            selectedMethod: displayedPaymentMethod,
            onTap: () async {
              // ✅ NEW: Pass reservation and GRO mode context
              final result = await context.push<Map<String, dynamic>>(
                '/paymentMethod',
                extra: {
                  'isReservation': isReservation,
                  'isGroMode': isGroMode,
                },
              );
              if (result != null) {
                onMethodSelected(result);
              }
            },
          ),
        ),
        if (errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                errorMessage!,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
      ],
    );
  }
}