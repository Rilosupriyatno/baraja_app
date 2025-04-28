import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/payment_methode_service.dart';
import '../widgets/utils/classic_app_bar.dart';

class PaymentMethodScreen extends StatefulWidget {
  const PaymentMethodScreen({super.key});

  @override
  State<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  List<Map<String, dynamic>> paymentMethods = [];

  @override
  void initState() {
    super.initState();
    fetchPaymentMethods();
  }

  // Fetch payment methods via service
  Future<void> fetchPaymentMethods() async {
    try {
      final service = PaymentMethodeService();
      final methods = await service.fetchPaymentMethods();
      setState(() {
        paymentMethods = methods;
      });
    } catch (e) {
      print('Error fetching payment methods: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (paymentMethods.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const ClassicAppBar(title: 'Metode Pembayaran'),
      body: ListView.separated(
        padding: const EdgeInsets.all(16.0),
        itemCount: paymentMethods.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final method = paymentMethods[index];

          Color color = Colors.grey;
          try {
            color = Color(int.parse(method['color'].substring(1, 7), radix: 16) + 0xFF000000);
          } catch (_) {}

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: color,
              child: Icon(
                _getIconData(method['icon']),
                color: Colors.white,
                size: 24,
              ),
            ),
            title: Text(
              method['name'],
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(method['payment_method_name']),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              final result = {
                'payment_method': method['payment_method'],
                'payment_method_name': method['payment_method_name'],
                'name': method['name'],
                'bank_code': method['bank_code'] ?? '',
              };

              context.pop(result);
            },
          );
        },
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'account_balance_wallet':
        return Icons.account_balance_wallet;
      case 'payments':
        return Icons.payments;
      case 'payment':
        return Icons.payment;
      case 'shopping_bag':
        return Icons.shopping_bag;
      case 'account_balance':
        return Icons.account_balance;
      case 'money':
        return Icons.money;
      default:
        return Icons.payment; // Default icon
    }
  }
}
