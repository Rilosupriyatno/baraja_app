import 'package:baraja_app/widgets/utils/classic_app_bar.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class PaymentMethodScreen extends StatefulWidget {
  const PaymentMethodScreen({super.key});

  @override
  State<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  // Payment method options
  final List<PaymentMethod> _paymentMethods = [
    PaymentMethod(
      id: 'gopay',
      name: 'GoPay',
      description: 'Saldo: Rp85.000',
      icon: Icons.account_balance_wallet,
      color: Colors.cyan,
    ),
    PaymentMethod(
      id: 'card',
      name: 'Credit or debit card',
      description: 'Visa, Mastercard, AMEX, and JCB',
      icon: Icons.credit_card,
      color: Colors.indigo,
    ),
    PaymentMethod(
      id: 'bank',
      name: 'Transfer Bank',
      description: '(Automatic Check)',
      icon: Icons.account_balance,
      color: AppTheme.primaryColor,
      isExpandable: true,
    ),
  ];

  // Currently selected payment method
  String _selectedPaymentMethodId = 'gopay';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const ClassicAppBar(title: 'Metode Pembayaran'),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 16),
        itemCount: _paymentMethods.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final method = _paymentMethods[index];
          return _buildPaymentMethodTile(method);
        },
      ),
    );
  }

  Widget _buildPaymentMethodTile(PaymentMethod method) {
    // ignore: unused_local_variable
    final isSelected = _selectedPaymentMethodId == method.id;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: method.color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          method.icon,
          color: Colors.white,
          size: 24,
        ),
      ),
      title: Text(
        method.name,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
      ),
      subtitle: Text(
        method.description,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 14,
        ),
      ),
      trailing: method.id == 'card'
          ? ElevatedButton(
        onPressed: () {
          // Handle adding a new card
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          minimumSize: const Size(60, 36),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: const Text('Add'),
      )
          : method.isExpandable
          ? const Icon(Icons.keyboard_arrow_down, color: Colors.grey)
          : Radio<String>(
        value: method.id,
        groupValue: _selectedPaymentMethodId,
        activeColor: Colors.cyan,
        onChanged: (value) {
          setState(() {
            _selectedPaymentMethodId = value!;
          });
        },
      ),
      onTap: () {
        if (method.isExpandable) {
          // Handle expandable section
        } else if (method.id != 'card') {
          setState(() {
            _selectedPaymentMethodId = method.id;
          });

          // Here's the new part: return the selected payment method name
          String paymentMethodText = '';
          if (method.id == 'gopay') {
            paymentMethodText = 'GoPay (Rp85.000)';
          } else if (method.id == 'card') {
            paymentMethodText = 'Credit Card';
          } else if (method.id == 'bank') {
            paymentMethodText = 'Bank Transfer';
          }

          Navigator.pop(context, paymentMethodText);
        }
      },
    );
  }
}

class PaymentMethod {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final bool isExpandable;

  PaymentMethod({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    this.isExpandable = false,
  });
}