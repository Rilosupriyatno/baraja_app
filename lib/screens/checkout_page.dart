import 'package:baraja_app/screens/payment_methode_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/cart_item.dart';
import '../models/order_type.dart';
import '../providers/cart_provider.dart';
import '../utils/currency_formatter.dart';
import '../widgets/payment/cart_item_widget.dart';
import '../widgets/payment/checkout_summary.dart';
import '../widgets/payment/order_type_selector.dart';
import '../widgets/payment/payment_method_widget.dart';
import '../widgets/payment/voucher_widget.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  // Pilihan tipe pesanan
  OrderType selectedOrderType = OrderType.dineIn;

  // Data meja untuk Dine-in
  String tableNumber = "";

  // Data untuk Delivery
  String deliveryAddress = "";

  // Data untuk Pickup
  TimeOfDay? pickupTime;

  // Metode Pembayaran
  String selectedPaymentMethod = "Gopay (Rp85.000)";

  // Data voucher
  String voucherCode = "";
  bool voucherApplied = false;

  @override
  Widget build(BuildContext context) {
    // Gunakan CartProvider untuk mendapatkan data keranjang
    final cartProvider = Provider.of<CartProvider>(context);
    final List<CartItem> cartItems = cartProvider.items;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text("Checkout"),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          // Konten utama dengan scroll
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Daftar Item Keranjang
                    if (cartItems.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: Text(
                            "Keranjang belanja kosong",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      )
                    else
                      ...cartItems.asMap().entries.map((entry) {
                        int index = entry.key;
                        CartItem item = entry.value;
                        return CartItemWidget(
                          item: item,
                          onIncrease: () {
                            cartProvider.increaseQuantity(index);
                          },
                          onDecrease: () {
                            cartProvider.decreaseQuantity(index);
                          },
                          onRemove: () {
                            cartProvider.removeFromCart(index);
                          },
                        );
                      }),

                    const SizedBox(height: 24),

                    // Pemilihan Tipe Pesanan
                    const Text(
                      "Mau pesan dimana?",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),

                    Text(
                      "*Kami buka 24 Jam",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Custom Order Type Selector
                    OrderTypeSelector(
                      selectedType: selectedOrderType,
                      onChanged: (type) {
                        setState(() {
                          selectedOrderType = type;
                        });
                      },
                      tableNumber: tableNumber,
                      onTableNumberChanged: (value) {
                        setState(() {
                          tableNumber = value;
                        });
                      },
                      deliveryAddress: deliveryAddress,
                      onDeliveryAddressChanged: (value) {
                        setState(() {
                          deliveryAddress = value;
                        });
                      },
                      pickupTime: pickupTime,
                      onPickupTimeChanged: (time) {
                        setState(() {
                          pickupTime = time;
                        });
                      },
                    ),

                    const SizedBox(height: 24),

                    // Metode Pembayaran
                    PaymentMethodWidget(
                      selectedMethod: selectedPaymentMethod,
                      onTap: () async {
                        // Navigate to the payment method screen
                        final result = await Navigator.push<String>(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PaymentMethodScreen(),
                          ),
                        );

                        // If we get a result back from the payment method screen, use it
                        if (result != null) {
                          setState(() {
                            selectedPaymentMethod = result;
                          });
                        }
                      },
                    ),

                    const SizedBox(height: 16),

                    // Voucher
                    VoucherWidget(
                      voucherCode: voucherCode,
                      voucherApplied: voucherApplied,
                      onTap: () {
                        // Navigasi ke halaman input voucher
                      },
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),

          // Ringkasan Pembayaran & Tombol Checkout
          CheckoutSummary(
            totalPrice: cartProvider.totalPrice,
            onCheckoutPressed: () {
              // Implementasi proses checkout
              // ignore: avoid_print
              print("Checkout with $selectedOrderType");
              if (selectedOrderType == OrderType.dineIn) {
                // ignore: avoid_print
                print("Nomor meja: $tableNumber");
              } else if (selectedOrderType == OrderType.delivery) {
                // ignore: avoid_print
                print("Alamat pengantaran: $deliveryAddress");
              } else {
                // ignore: avoid_print
                print("Waktu ambil: ${pickupTime?.format(context)}");
              }

              // Menampilkan informasi checkout
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      "Pesanan berhasil: ${cartProvider.totalItems} item, total ${formatCurrency(cartProvider.totalPrice)}"
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );

              // Bersihkan keranjang setelah checkout
              // cartProvider.clearCart(); // Uncomment jika ingin mengosongkan keranjang
            },
          ),
        ],
      ),
    );
  }
}