import 'package:flutter/material.dart';
import 'package:baraja_app/theme/app_theme.dart';

class PaymentLoadingView extends StatelessWidget {
  const PaymentLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppTheme.primaryColor),
          SizedBox(height: 16),
          Text('Memproses pembayaran Anda...',
              style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}