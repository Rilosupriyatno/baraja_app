import 'package:baraja_app/pages/payment_methode_page.dart';
import 'package:baraja_app/pages/voucher_page.dart';
import 'package:baraja_app/widgets/classic_app_bar.dart';
import 'package:baraja_app/widgets/order_summary.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  CheckoutScreenState createState() => CheckoutScreenState();
}

class CheckoutScreenState extends State<CheckoutScreen> {
  String _orderMethod = 'Pilih Metode';
  String _paymentMethod = 'Gopay (Rp85.000)';
  String _voucher = 'No voucher added';
  double _shippingCost = 0;
  String _tableNumber = '';
  String _selectedTime = '';
  String _userAddress = 'Jl. Contoh No. 123, Jakarta';

  void _chooseOrderMethod(String? method) {
    if (method == null) return;
    setState(() {
      _orderMethod = method;
      _shippingCost = method == 'Kirim ke Tempat (Delivery)' ? 10000 : 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final totalPrice = cartProvider.totalPrice + _shippingCost;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const ClassicAppBar(title: 'Checkout'),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const OrderSummary(),
                    const Divider(height: 30, thickness: 1),
                    _buildOrderMethodDropdown(),
                    const Divider(height: 20, thickness: 0.5, color: Colors.grey),
                    _buildAdditionalFields(),
                    const Divider(height: 20, thickness: 0.5, color: Colors.grey),
                    _buildPaymentMethodTile(),
                    const Divider(height: 20, thickness: 0.5, color: Colors.grey),
                    _buildVoucherTile(),
                    const Divider(height: 20, thickness: 0.5, color: Colors.grey),
                    _buildPaymentDetails(cartProvider.totalPrice),
                  ],
                ),
              ),
            ),
            _buildBottomCheckoutBar(totalPrice),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderMethodDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Metode Pemesanan',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        DropdownButtonHideUnderline(
          child: DropdownButtonFormField<String>(
            isExpanded: true, // Mengatur agar dropdown mengisi ruang yang tersedia
            value: _orderMethod,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            items: const [
              'Pilih Metode',
              'Makan di Tempat (Dine In)',
              'Kirim ke Tempat (Delivery)',
              'Ambil di Tempat (Pickup)',
            ].map((method) => DropdownMenuItem(
              value: method,
              child: Text(method),
            )).toList(),
            onChanged: (String? method) {
              if (method != null) {
                _chooseOrderMethod(method);
              }
            },
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildAdditionalFields() {
    if (_orderMethod == 'Makan di Tempat (Dine In)') {
      return TextField(
        decoration: InputDecoration(
          labelText: 'Nomor Meja',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onChanged: (value) {
          setState(() {
            _tableNumber = value;
          });
        },
      );
    } else if (_orderMethod == 'Kirim ke Tempat (Delivery)') {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.location_on, color: Colors.brown),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _userAddress,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      );
    } else if (_orderMethod == 'Ambil di Tempat (Pickup)') {
      return TextField(
        decoration: InputDecoration(
          labelText: 'Pilih Jam',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          suffixIcon: const Icon(Icons.access_time),
        ),
        onTap: () async {
          TimeOfDay? pickedTime = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.now(),
          );
          if (pickedTime != null) {
            setState(() {
              _selectedTime = pickedTime.format(context);
            });
          }
        },
        readOnly: true,
        controller: TextEditingController(text: _selectedTime),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildPaymentMethodTile() {
    return ListTile(
      title: const Text('Metode Pembayaran', style: TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(_paymentMethod),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentMethodePage(
              selectedMethode: _paymentMethod,
              onSelectedMethode: (method) {
                setState(() {
                  _paymentMethod = method;
                });
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildVoucherTile() {
    return ListTile(
      title: const Text('Voucher', style: TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(_voucher),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VoucherPage(
              selectedVoucher: _voucher,
              onSelectedVoucher: (voucher) {
                setState(() {
                  _voucher = voucher;
                });
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaymentDetails(double subtotal) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Rincian Pembayaran',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        _buildPaymentDetailRow('Subtotal', 'Rp ${subtotal.toStringAsFixed(0)}'),
        _buildPaymentDetailRow('Biaya Pengiriman', 'Rp ${_shippingCost.toStringAsFixed(0)}'),
        _buildPaymentDetailRow('Potongan Voucher', 'Rp 0'),
      ],
    );
  }

  Widget _buildPaymentDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildBottomCheckoutBar(double totalPrice) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Text(
                'Rp ${totalPrice.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          ElevatedButton(
            onPressed: _orderMethod != 'Pilih Metode' ? () {
              // Logika checkout
            } : null,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(120, 50),
              backgroundColor: Colors.brown,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Checkout', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}