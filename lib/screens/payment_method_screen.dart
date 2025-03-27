import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/utils/classic_app_bar.dart';

class PaymentMethodScreen extends StatelessWidget {
  const PaymentMethodScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // List metode pembayaran yang tersedia
    final List<Map<String, dynamic>> paymentMethods = [
      {
        'name': 'Gopay',
        'logo': 'assets/icons/gopay.png',
        'balance': 85000,
      },
      {
        'name': 'OVO',
        'logo': 'assets/icons/ovo.png',
        'balance': 50000,
      },
      {
        'name': 'DANA',
        'logo': 'assets/icons/dana.png',
        'balance': 100000,
      },
      {
        'name': 'ShopeePay',
        'logo': 'assets/icons/shopeepay.png',
        'balance': 75000,
      },
      {
        'name': 'BCA',
        'logo': 'assets/icons/bca.png',
        'isBank': true,
      },
      {
        'name': 'Mandiri',
        'logo': 'assets/icons/mandiri.png',
        'isBank': true,
      },
      {
        'name': 'Tunai',
        'logo': 'assets/icons/cash.png',
        'isCash': true,
      },
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const ClassicAppBar(title: 'Metode Pembayaran'),
      body: ListView.separated(
        padding: const EdgeInsets.all(16.0),
        itemCount: paymentMethods.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final method = paymentMethods[index];
          final bool isBank = method['isBank'] ?? false;
          final bool isCash = method['isCash'] ?? false;
          final int? balance = method['balance'];

          String displayText = method['name'];
          if (balance != null) {
            displayText += ' (Rp${balance.toString()})';
          }

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.grey[200],
              child: Icon(
                _getPaymentMethodIcon(method['name']),
                color: Colors.grey[700],
              ),
              // You can use Image.asset if you have actual logos
              // child: Image.asset(
              //   method['logo'],
              //   width: 24,
              //   height: 24,
              // ),
            ),
            title: Text(displayText),
            subtitle: isBank
                ? const Text('Transfer Bank')
                : isCash
                ? const Text('Bayar di tempat')
                : const Text('E-wallet'),
            onTap: () {
              // Return the selected payment method back to the checkout screen
              context.pop(displayText);
            },
          );
        },
      ),
    );
  }

  // Helper to get icons for payment methods
  IconData _getPaymentMethodIcon(String methodName) {
    switch (methodName.toLowerCase()) {
      case 'gopay':
      case 'ovo':
      case 'dana':
      case 'shopeepay':
        return Icons.account_balance_wallet;
      case 'bca':
      case 'mandiri':
        return Icons.account_balance;
      case 'tunai':
        return Icons.money;
      default:
        return Icons.payment;
    }
  }
}