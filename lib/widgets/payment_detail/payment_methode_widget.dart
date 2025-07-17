import 'package:flutter/material.dart';
import 'components/order_id_section.dart';
import 'components/virtual_account_widget.dart';
import 'components/cash_payment_widget.dart';
import 'components/ewallet_payment_widget.dart';
import 'components/generic_payment_widget.dart';

class PaymentMethodDetail extends StatelessWidget {
  final Map<String, dynamic> paymentData;
  final Function(String, String) onCopyToClipboard;

  const PaymentMethodDetail({
    super.key,
    required this.paymentData,
    required this.onCopyToClipboard,
  });

  Widget _buildPaymentMethodCard() {
    final method = paymentData['method'];
    final vaNumbers = paymentData['va_numbers'] as List<dynamic>?;
    final deeplinkUrl = paymentData['deeplink_redirect_url'];

    // Get QR code URL from actions
    String? qrCodeUrl;
    final actions = paymentData['actions'] as List<dynamic>?;
    if (actions != null && actions.isNotEmpty) {
      for (var action in actions) {
        if (action['name'] == 'generate-qr-code') {
          qrCodeUrl = action['url'];
          break;
        }
      }
    }
    // print('QR Code URL: $qrCodeUrl');

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF007AFF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.payment_rounded,
                    color: Color(0xFF007AFF),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Informasi Pembayaran',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1C1C1E),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Order ID Section
            OrderIdSection(
              orderId: paymentData['order_id'],
              onCopyToClipboard: onCopyToClipboard,
            ),

            const SizedBox(height: 20),
            Container(
              height: 1,
              color: const Color(0xFFE5E5EA),
            ),
            const SizedBox(height: 20),

            // Payment Method Section
            const Text(
              'Metode Pembayaran',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF8E8E93),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),

            // Payment Method Content
            _buildPaymentMethodContent(
              method,
              vaNumbers,
              deeplinkUrl,
              qrCodeUrl,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodContent(
      String? method,
      List<dynamic>? vaNumbers,
      String? deeplinkUrl,
      String? qrCodeUrl,
      ) {
    // Virtual Account Section
    if (vaNumbers != null && vaNumbers.isNotEmpty) {
      return Column(
        children: [
          for (int i = 0; i < vaNumbers.length; i++) ...[
            VirtualAccountWidget(
              vaData: vaNumbers[i],
              onCopyToClipboard: onCopyToClipboard,
            ),
            if (i < vaNumbers.length - 1) const SizedBox(height: 16),
          ],
        ],
      );
    }
    // Cash payment method
    else if (method?.toLowerCase() == 'cash') {
      return CashPaymentWidget(
        orderId: paymentData['order_id'] ?? '',
        qrCodeUrl: qrCodeUrl,
        onCopyToClipboard: onCopyToClipboard,
      );
    }
    // E-wallet or QRIS Section
    else if (qrCodeUrl != null || deeplinkUrl != null) {
      return EWalletPaymentWidget(
        method: method,
        qrString: qrCodeUrl,
        deeplinkUrl: deeplinkUrl,
        onCopyToClipboard: onCopyToClipboard,
      );
    }
    // Other payment methods
    else {
      return GenericPaymentWidget(method: method);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildPaymentMethodCard();
  }
}