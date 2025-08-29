import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../widgets/checkout/payment_method_widget.dart';

class PaymentMethodWithValidation extends StatelessWidget {
  final String displayedPaymentMethod;
  final Function(Map<String, dynamic>) onMethodSelected;
  final String? errorMessage;

  const PaymentMethodWithValidation({
    super.key,
    required this.displayedPaymentMethod,
    required this.onMethodSelected,
    this.errorMessage,
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
              final result = await context.push<Map<String, dynamic>>('/paymentMethod');
              if (result != null) {
                onMethodSelected(result);
              }
            },
          ),
        ),
        if (errorMessage != null)
          Text(errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 12)),
      ],
    );
  }
}
