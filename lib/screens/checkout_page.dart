import 'package:baraja_app/widgets/utils/classic_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cart_item.dart';
import '../models/order_type.dart';
import '../providers/cart_provider.dart';
import '../services/order_service.dart' as serviceorder;
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

  // Data metode pembayaran
  String? selectedPaymentMethod;
  String? selectedPaymentMethodName;
  String? selectedBankName;
  String? selectedBankCode;

  // Data voucher - updated variables
  String? selectedVoucherCode;
  String voucherDescription = "";
  int discountAmount = 0;

  // Calculate the discount amount based on the selected voucher
  int calculateDiscount(int subtotal) {
    if (selectedVoucherCode == null) return 0;

    switch (selectedVoucherCode) {
      case 'DISC10':
      // 10% discount up to Rp20.000
        final discount = (subtotal * 0.1).round();
        return discount > 20000 ? 20000 : discount;
      case 'DISC15':
      // 15% discount up to Rp25.000 with minimum spend Rp20.000
        if (subtotal >= 20000) {
          final discount = (subtotal * 0.15).round();
          return discount > 25000 ? 25000 : discount;
        }
        return 0;
      default:
        return 0;
    }
  }

  // Format tampilan metode pembayaran
  String get displayedPaymentMethod {
    if (selectedPaymentMethodName == null || selectedPaymentMethodName!.isEmpty) {
      return "Pilih Pembayaran";
    }

    if (selectedBankName != null && selectedBankName!.isNotEmpty) {
      return "$selectedPaymentMethodName - $selectedBankName";
    }

    return selectedPaymentMethodName!;
  }

  @override
  Widget build(BuildContext context) {
    // Gunakan CartProvider untuk mendapatkan data keranjang
    final cartProvider = Provider.of<CartProvider>(context);
    final List<CartItem> cartItems = cartProvider.items;
// print(selectedBankCode);
    // Calculate the c urrent discount amount
    final int subtotal = cartProvider.totalPrice;
    final int discount = calculateDiscount(subtotal);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const ClassicAppBar(title: 'Pembayaran'),
      resizeToAvoidBottomInset: true,
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
                        CartItem item = entry.value;
                        return CartItemWidget(
                          item: item,
                          // onIncrease: () {
                          //   cartProvider.increaseQuantity(index);
                          // },
                          // onDecrease: () {
                          //   cartProvider.decreaseQuantity(index);
                          // },
                          // onRemove: () {
                          //   cartProvider.removeFromCart(index);
                          // },
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
                      selectedMethod: displayedPaymentMethod, // Menggunakan getter yang telah dibuat
                      onTap: () async {
                        // Navigasi ke layar pemilihan metode pembayaran
                        final result = await context.push<Map<String, dynamic>>('/paymentMethod');

                        // Jika hasilnya ada, gunakan nilai yang dipilih
                        if (result != null) {
                          setState(() {
                            // Simpan semua informasi yang relevan
                            selectedPaymentMethod = result['payment_method'];
                            selectedPaymentMethodName = result['payment_method_name'];

                            // Cek apakah ada informasi bank
                            if (result.containsKey('name')) {
                              selectedBankName = result['name'];
                            } else {
                              selectedBankName = null;
                            }

                            // Ambil bank_code juga
                            if (result.containsKey('bank_code')) {
                              selectedBankCode = result['bank_code'];
                            } else {
                              selectedBankCode = null;
                            }


                            // Debug print untuk verifikasi
                            print('Payment Method Selected: $selectedPaymentMethodName - $selectedBankName - $selectedBankCode - $selectedPaymentMethod');
                          });
                        }
                      },
                    ),

                    const SizedBox(height: 16),

                    VoucherWidget(
                      voucherCode: selectedVoucherCode ?? "",
                      voucherApplied: selectedVoucherCode != null,
                      onVoucherSelected: (String selectedCode) {
                        setState(() {
                          selectedVoucherCode = selectedCode;
                          discountAmount = calculateDiscount(subtotal);

                          switch (selectedCode) {
                            case 'DISC10':
                              voucherDescription = 'Disc 10% up to Rp20.000';
                              break;
                            case 'DISC15':
                              voucherDescription = 'Disc 15% up to Rp25.000';
                              break;
                            default:
                              voucherDescription = '';
                          }
                        });
                      },
                    ),

                    const SizedBox(height: 24),

                  ],
                ),
              ),
            ),
          ),

          // Updated Checkout Summary with discount
          CheckoutSummary(
            totalPrice: subtotal,
            discount: discount,
            voucherCode: selectedVoucherCode,
            onCheckoutPressed: () async {
              // Validasi input berdasarkan tipe pesanan
              bool isValid = true;
              String errorMessage = '';

              if (selectedOrderType == OrderType.dineIn && tableNumber.isEmpty) {
                isValid = false;
                errorMessage = 'Silakan masukkan nomor meja';
              } else if (selectedOrderType == OrderType.delivery && deliveryAddress.isEmpty) {
                isValid = false;
                errorMessage = 'Silakan masukkan alamat pengantaran';
              } else if (selectedOrderType == OrderType.pickup && pickupTime == null) {
                isValid = false;
                errorMessage = 'Silakan pilih waktu pengambilan';
              } else if (selectedPaymentMethod == null) {
                isValid = false;
                errorMessage = 'Silakan pilih metode pembayaran';
              }

              if (!isValid) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(errorMessage),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final prefs = await SharedPreferences.getInstance();
              final userId = prefs.getString('userId');
              final userName = prefs.getString('userName') ?? 'Guest';

              // Tampilkan loading indicator
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (BuildContext context) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                },
              );

              try {
                // Buat instance OrderService
                final orderService =  serviceorder.OrderService();
                final List<Map<String, dynamic>> items = cartItems.map((item) => {
                  'productId': item.id,
                  'productName': item.name,
                  'price': item.price,
                  'quantity': item.quantity,
                  'addons': item.addons,
                  'toppings': item.toppings,
                }).toList();


                // Buat map untuk paymentDetails
                final Map<String, String?> paymentDetails = {
                  'method':  selectedPaymentMethodName,
                  'methodName': selectedPaymentMethod,
                  'bankName': selectedBankName,
                  'bankCode': selectedBankCode,
                };

                // Kirim order ke API
                final orderResult = await orderService.createOrder(
                  items: items,
                  userId: userId ?? 'guest',
                  userName: userName,
                  orderType: selectedOrderType,
                  tableNumber: tableNumber,
                  pickupTime: pickupTime,
                  paymentDetails:paymentDetails,
                  subtotal: subtotal,
                  discount: discount,
                  voucherCode: selectedVoucherCode,
                );

                // Tutup loading dialog
                Navigator.of(context).pop();

                // Jika berhasil, lanjutkan ke halaman konfirmasi pembayaran
                context.push('/paymentConfirmation', extra: {
                  'items': List.from(cartItems),
                  'userId': userId,
                  'userName': userName,
                  'orderType': selectedOrderType,
                  'tableNumber': tableNumber,
                  'deliveryAddress': deliveryAddress,
                  'pickupTime': pickupTime,
                  'paymentDetails': paymentDetails,
                  'subtotal': subtotal,
                  'discount': discount,
                  'total': subtotal - discount,
                  'voucherCode': selectedVoucherCode,
                  'orderId': orderResult['order']?['_id'] ?? '', // Tambahkan orderId dari response
                });

                // Hapus cart setelah berhasil checkout
                cartProvider.clearCart();

              } catch (e) {
                // Tutup loading dialog
                Navigator.of(context).pop();

                // Tampilkan pesan error
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Gagal membuat pesanan: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
