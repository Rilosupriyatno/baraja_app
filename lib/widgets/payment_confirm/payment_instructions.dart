import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:baraja_app/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';
import 'instruction_step.dart';

class PaymentInstructions extends StatelessWidget {
  final Map<String, dynamic> paymentResponse;

  const PaymentInstructions({super.key, required this.paymentResponse});

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Nomor VA berhasil disalin'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  Future<void> _launchUrl(BuildContext context, String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak dapat membuka aplikasi GoPay'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final paymentType = paymentResponse['payment_type'] ?? '';

    if (paymentType == 'bank_transfer') {
      return _buildBankTransferInstructions(context);
    } else if (paymentType == 'gopay') {
      return _buildGopayInstructions(context);
    } else if (paymentType == 'qris') {
      return _buildQrisInstructions();
    } else if (paymentType == 'cash') {
      return _buildCashInstructions();
    }

    return const SizedBox.shrink();
  }

  Widget _buildBankTransferInstructions(BuildContext context) {
    String bankName = 'Bank';
    String vaNumber = '';

    // Check which bank is used
    if (paymentResponse.containsKey('permata_va_number')) {
      bankName = 'Permata Bank';
      vaNumber = paymentResponse['permata_va_number'];
    } else if (paymentResponse.containsKey('va_numbers')) {
      final vaNumbers = paymentResponse['va_numbers'] as List;
      if (vaNumbers.isNotEmpty) {
        bankName = vaNumbers[0]['bank'] ?? 'Bank';
        vaNumber = vaNumbers[0]['va_number'] ?? '';

        // Convert bank code to proper name
        if (bankName.toLowerCase() == 'bca') {
          bankName = 'Bank BCA';
        } else if (bankName.toLowerCase() == 'bni') {
          bankName = 'Bank BNI';
        } else if (bankName.toLowerCase() == 'bri') {
          bankName = 'Bank BRI';
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nomor Virtual Account',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    vaNumber,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => _copyToClipboard(context, vaNumber),
                  child: const Icon(
                    Icons.copy,
                    size: 18,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (paymentResponse.containsKey('expiry_time'))
          _buildInfoItem('Bayar Sebelum', paymentResponse['expiry_time']),

        const SizedBox(height: 16),
        const Text('Cara Pembayaran:',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        InstructionStep(number: 1, instruction: 'Gunakan mobile banking atau internet banking $bankName Anda'),
        const InstructionStep(number: 2, instruction: 'Pilih menu Transfer > Virtual Account'),
        InstructionStep(number: 3, instruction: 'Masukkan nomor Virtual Account: $vaNumber'),
        const InstructionStep(number: 4, instruction: 'Konfirmasi detail pembayaran dan selesaikan transaksi'),
        const InstructionStep(number: 5, instruction: 'Pembayaran Anda akan diproses secara otomatis'),
      ],
    );
  }

  Widget _buildGopayInstructions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (paymentResponse.containsKey('actions')) ...[
          const SizedBox(height: 16),
          (() {
            final actions = paymentResponse['actions'] as List;
            String? deeplinkUrl;

            for (final action in actions) {
              if (action['name'] == 'deeplink-redirect') {
                deeplinkUrl = action['url'];
              }
            }

            if (deeplinkUrl != null) {
              return ElevatedButton.icon(
                onPressed: () => _launchUrl(context, deeplinkUrl!),
                icon: const Icon(Icons.smartphone),
                label: const Text('Bayar dengan GoPay'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00ADD8), // GoPay color
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          })(),
        ],

        if (paymentResponse.containsKey('expiry_time'))
          _buildInfoItem('Bayar Sebelum', paymentResponse['expiry_time']),
      ],
    );
  }

  Widget _buildQrisInstructions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (paymentResponse.containsKey('actions')) ...[
          const SizedBox(height: 16),
          const Text(
            'QRIS:',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            alignment: Alignment.center,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              children: [
                const SizedBox(height: 16),
                (() {
                  final actions = paymentResponse['actions'] as List;
                  String? qrCodeUrl;

                  for (final action in actions) {
                    if (action['name'] == 'generate-qr-code') {
                      qrCodeUrl = action['url'];
                      break;
                    }
                  }

                  if (qrCodeUrl != null) {
                    return Image.network(
                      qrCodeUrl,
                      height: 200,
                      width: 200,
                      fit: BoxFit.cover,
                    );
                  }
                  return const SizedBox.shrink();
                })(),
                const SizedBox(height: 8),
                const Text(
                  'Scan QRIS dengan aplikasi e-wallet atau mobile banking',
                  style: TextStyle(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          if (paymentResponse.containsKey('expiry_time'))
            _buildInfoItem('Bayar Sebelum', paymentResponse['expiry_time']),
        ],
      ],
    );
  }

  Widget _buildCashInstructions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (paymentResponse.containsKey('actions')) ...[
          const SizedBox(height: 16),
          const Text(
            'Tunai:',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            alignment: Alignment.center,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              children: [
                const SizedBox(height: 16),
                (() {
                  final actions = paymentResponse['actions'] as List;
                  String? qrCodeUrl;

                  for (final action in actions) {
                    if (action['name'] == 'generate-qr-code') {
                      qrCodeUrl = action['url'];
                      break;
                    }
                  }

                  if (qrCodeUrl != null && qrCodeUrl.startsWith('data:image')) {
                    final base64Data = qrCodeUrl.split(',').last;
                    final Uint8List bytes = base64Decode(base64Data);

                    return Image.memory(
                      bytes,
                      height: 200,
                      width: 200,
                      fit: BoxFit.cover,
                    );
                  }
                  return const SizedBox.shrink();
                })(),
                const SizedBox(height: 8),
                const Text(
                  'Tunjukkan Qris kepada kasir untuk pembayaran tunai',
                  style: TextStyle(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          if (paymentResponse.containsKey('expiry_time'))
            _buildInfoItem('Bayar Sebelum', paymentResponse['expiry_time']),
        ],
      ],
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
          Text(value, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}