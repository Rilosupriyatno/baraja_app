import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'qr_code_components.dart';

class CashPaymentWidget extends StatelessWidget {
  final String orderId;
  final String? qrCodeUrl;
  final Function(String, String) onCopyToClipboard;

  const CashPaymentWidget({
    super.key,
    required this.orderId,
    required this.qrCodeUrl,
    required this.onCopyToClipboard,
  });

  /// Convert data URL (base64) to Uint8List
  Uint8List? _dataUrlToBytes(String dataUrl) {
    try {
      final base64Str = dataUrl.split(',').last;
      return base64Decode(base64Str);
    } catch (e) {
      print('Error decoding data URL: $e');
      return null;
    }
  }

  /// Widget to display QR image from either data URL or HTTP URL
  Widget _buildQRCodeImage(String url) {
    if (url.startsWith('data:image')) {
      final bytes = _dataUrlToBytes(url);
      if (bytes != null) {
        return Image.memory(
          bytes,
          width: 200,
          height: 200,
          fit: BoxFit.contain,
        );
      } else {
        return const QRCodeError();
      }
    } else {
      return Image.network(
        url,
        width: 200,
        height: 200,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return const QRCodeError();
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const QRCodeLoading();
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    print('QR Code URL: $qrCodeUrl');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF00C896).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.payments_rounded,
                size: 14,
                color: Color(0xFF00C896),
              ),
              SizedBox(width: 6),
              Text(
                'Cash',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF00C896),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // QR Code Section
        Container(
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
                'QR Code untuk Pembayaran Cash',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1C1C1E),
                ),
              ),
              const SizedBox(height: 16),

              // QR Code Image
              Container(
                padding: const EdgeInsets.all(16),
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
                child: qrCodeUrl != null
                    ? _buildQRCodeImage(qrCodeUrl!)
                    : const QRCodeError(),
              ),

              const SizedBox(height: 16),

              // Order ID display
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF007AFF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.qr_code_scanner_rounded,
                      size: 16,
                      color: Color(0xFF007AFF),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'ID: $orderId',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF007AFF),
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Copy button
              InkWell(
                onTap: () => onCopyToClipboard(orderId, 'ID Pesanan'),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                        'Salin ID Pesanan',
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
        ),
        const SizedBox(height: 12),

        // Instructions
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF00C896).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: Color(0xFF00C896),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tunjukkan QR Code ini kepada kasir untuk menyelesaikan pembayaran cash',
                  style: TextStyle(
                    fontSize: 12,
                    color: const Color(0xFF00C896).withOpacity(0.8),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
