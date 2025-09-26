import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class PaymentMethodWidget extends StatelessWidget {
  final String selectedMethod;
  final VoidCallback onTap;

  const PaymentMethodWidget({
    super.key,
    required this.selectedMethod,
    required this.onTap,
  });

  // Add this logic to your existing payment method screen

// In your payment method screen's onPaymentMethodSelected callback:
  void onPaymentMethodSelected(
      BuildContext context,
      Map<String, dynamic> selectedPaymentData,
      ) {
    try {
      final routeState = GoRouterState.of(context);
      final extraData = routeState.extra as Map<String, dynamic>?;

      if (extraData?.containsKey('source') == true) {
        final source = extraData!['source'] as String?;

        if (source == 'event') {
          final eventData = extraData['eventData'] as Map<String, dynamic>?;
          if (eventData != null) {
            context.pushReplacement('/ticketPaymentConfirmation', extra: {
              'eventData': eventData,
              'paymentData': selectedPaymentData,
            });
            return;
          }
        }
      }

      // Fallback: return to previous screen
      context.pop(selectedPaymentData);

    } catch (e) {
      debugPrint('Navigation error: $e');
      context.pop(selectedPaymentData);
    }
  }


// Alternative approach using a more explicit method:
  void handlePaymentMethodSelection(
      BuildContext context,
      Map<String, dynamic> selectedPaymentData,
      ) async {
    final routeState = GoRouterState.of(context);
    final extraData = routeState.extra as Map<String, dynamic>?;

    if (extraData?['source'] == 'event') {
      final eventData = extraData!['eventData'] as Map<String, dynamic>;

      final shouldProceed = await _showPaymentConfirmationDialog(
        context: context,
        eventName: eventData['name'],
        price: eventData['price'],
        paymentMethod: selectedPaymentData['name'],
      );

      if (shouldProceed) {
        context.pushReplacement('/ticketPaymentConfirmation', extra: {
          'eventData': eventData,
          'paymentData': selectedPaymentData,
        });
      }
    } else {
      context.pop(selectedPaymentData);
    }
  }


// Helper method for confirmation dialog
  Future<bool> _showPaymentConfirmationDialog({
    required BuildContext context,
    required String eventName,
    required int price,
    required String paymentMethod,
  }) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Pembayaran'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Event: $eventName'),
              const SizedBox(height: 8),
              Text('Harga: Rp ${NumberFormat('#,###', 'id_ID').format(price)}'),
              const SizedBox(height: 8),
              Text('Metode Pembayaran: $paymentMethod'),
              const SizedBox(height: 16),
              const Text('Lanjutkan ke pembayaran?'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Lanjutkan'),
            ),
          ],
        );
      },
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Metode Pembayaran",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  selectedMethod,
                  style: TextStyle(
                    color: selectedMethod == "Pilih Pembayaran"
                        ? Colors.grey
                        : Colors.black,
                  ),
                ),
              ],
            ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }
}