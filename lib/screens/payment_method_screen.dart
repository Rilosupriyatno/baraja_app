import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/payment_methode_service.dart';
import '../widgets/utils/classic_app_bar.dart';

class PaymentMethodScreen extends StatefulWidget {
  final String? source; // 'checkout' atau 'event'
  final Map<String, dynamic>? eventData; // Data event untuk ticket purchase
  final bool isReservation; // ✅ NEW: For customer reservation
  final bool isGroMode; // ✅ NEW: For GRO mode

  const PaymentMethodScreen({
    super.key,
    this.source,
    this.eventData,
    this.isReservation = false, // ✅ NEW
    this.isGroMode = false, // ✅ NEW
  });

  @override
  State<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  List<Map<String, dynamic>> paymentMethods = [];
  Map<String, dynamic>? selectedMethod;

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
      
      // ✅ NEW: Filter out cash for ticket purchase and customer reservation
      List<Map<String, dynamic>> filteredMethods = methods;
      
      // Remove cash for ticket purchase
      if (widget.source == 'event') {
        filteredMethods = filteredMethods.where((method) {
          return method['payment_method']?.toString().toLowerCase() != 'cash';
        }).toList();
      }
      
      // Remove cash for customer reservation (not GRO)
      if (widget.isReservation && !widget.isGroMode) {
        filteredMethods = filteredMethods.where((method) {
          return method['payment_method']?.toString().toLowerCase() != 'cash';
        }).toList();
      }
      
      setState(() {
        paymentMethods = filteredMethods;
      });
    } catch (e) {
      print('Error fetching payment methods: $e');
    }
  }

  String get _getTitle {
    return widget.source == 'event' ? 'Pilih Metode Pembayaran Tiket' : 'Metode Pembayaran';
  }

  void _handleMethodSelection(Map<String, dynamic> method) {
    if (widget.source == 'event') {
      setState(() {
        selectedMethod = method;
      });
    } else {
      // Original behavior for checkout
      final result = {
        'payment_method': method['payment_method'],
        'payment_method_name': method['payment_method_name'],
        'name': method['name'],
        'bank_code': method['bank_code'] ?? '',
      };
      context.pop(result);
    }
  }

  void _proceedToTicketPayment() {
    if (selectedMethod == null) return;

    final paymentData = {
      'payment_method': selectedMethod!['payment_method'],
      'payment_method_name': selectedMethod!['payment_method_name'],
      'name': selectedMethod!['name'],
      'bank_code': selectedMethod!['bank_code'] ?? '',
    };

    // Navigate to ticket payment confirmation
    context.push('/ticketPaymentConfirmation', extra: {
      'eventData': widget.eventData,
      'paymentData': paymentData,
    });
  }

  @override
  Widget build(BuildContext context) {
    if (paymentMethods.isEmpty) {
      return Scaffold(
        appBar: ClassicAppBar(title: _getTitle),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: ClassicAppBar(title: _getTitle),
      body: Column(
        children: [
          // Info card for event ticket purchase
          if (widget.source == 'event' && widget.eventData != null) ...[
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.confirmation_number,
                    color: Colors.blue.shade600,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pembelian Tiket Event',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                        Text(
                          widget.eventData!['name'] ?? 'Event',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue.shade600,
                          ),
                        ),
                        Text(
                          'Harga: Rp ${widget.eventData!['price']?.toString() ?? '0'}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Pilih metode pembayaran untuk tiket Anda:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Payment methods list
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16.0),
              itemCount: paymentMethods.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final method = paymentMethods[index];
                final isSelected = widget.source == 'event' &&
                    selectedMethod?['payment_method'] == method['payment_method'];

                return Container(
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue.shade50 : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: isSelected ? Border.all(color: Colors.blue.shade300) : null,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: AssetImage('assets/icons/${method['icon']}'),
                    ),
                    title: Text(
                      method['name'],
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.blue.shade700 : Colors.black87,
                      ),
                    ),
                    subtitle: Text(
                      method['payment_method_name'],
                      style: TextStyle(
                        color: isSelected ? Colors.blue.shade600 : Colors.grey.shade600,
                      ),
                    ),
                    trailing: widget.source == 'event'
                        ? isSelected
                        ? Icon(Icons.check_circle, color: Colors.blue.shade600)
                        : const Icon(Icons.chevron_right)
                        : const Icon(Icons.chevron_right),
                    onTap: () => _handleMethodSelection(method),
                  ),
                );
              },
            ),
          ),
        ],
      ),

      // Bottom button for event ticket purchase
      bottomNavigationBar: widget.source == 'event'
          ? Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 6,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: selectedMethod != null ? _proceedToTicketPayment : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: selectedMethod != null ? Colors.blue.shade600 : Colors.grey.shade300,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: selectedMethod != null ? 2 : 0,
          ),
          child: const Text(
            'Lanjutkan Pembayaran',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      )
          : null,
    );
  }
}