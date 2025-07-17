import 'package:flutter/material.dart';
import '../utils/payment_method_utils.dart';

class EWalletPaymentWidget extends StatelessWidget {
  final String? method;
  final String? qrString;
  final String? deeplinkUrl;
  final Function(String, String) onCopyToClipboard;

  const EWalletPaymentWidget({
    super.key,
    required this.method,
    required this.qrString,
    required this.deeplinkUrl,
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
            color: const Color(0xFF00C896).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            PaymentMethodUtils.getPaymentMethodName(method),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF00C896),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // QR Code Section for QRIS
        if (method?.toLowerCase() == 'qris' && qrString != null) ...[
          _buildQRISSection(qrString!),
        ]
        // For other e-wallet methods (non-QRIS)
        else if (qrString != null) ...[
          _buildEWalletQRSection(qrString!),
        ],

        if (deeplinkUrl != null) ...[
          if (qrString != null) const SizedBox(height: 8),
          const Text(
            'Atau buka aplikasi untuk melakukan pembayaran',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF8E8E93),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildQRISSection(String qrString) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE5E5EA),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          const Text(
            'Scan QR Code untuk Pembayaran QRIS',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1C1C1E),
            ),
          ),
          const SizedBox(height: 16),

          // QR Code placeholder
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.qr_code_rounded,
                    size: 60,
                    color: Color(0xFF8E8E93),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'QR Code',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF8E8E93),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Payment method indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF00C896).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.qr_code_scanner_rounded,
                  size: 16,
                  color: Color(0xFF00C896),
                ),
                SizedBox(width: 8),
                Text(
                  'QRIS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF00C896),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Copy QR String button
          InkWell(
            onTap: () => onCopyToClipboard(qrString, 'QR Code String'),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF007AFF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.copy_rounded,
                    size: 16,
                    color: Color(0xFF007AFF),
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Salin QR Code',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF007AFF),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEWalletQRSection(String qrString) {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Scan QR Code untuk melakukan pembayaran',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF8E8E93),
                ),
              ),
            ],
          ),
        ),
        InkWell(
          onTap: () => onCopyToClipboard(qrString, 'QR Code'),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF007AFF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.qr_code,
              color: Color(0xFF007AFF),
              size: 16,
            ),
          ),
        ),
      ],
    );
  }
}