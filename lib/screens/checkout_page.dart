  import 'package:baraja_app/widgets/utils/classic_app_bar.dart';
    import 'package:flutter/material.dart';
    import 'package:go_router/go_router.dart';
    import 'package:provider/provider.dart';
    import '../models/cart_item.dart';
    import '../models/order_type.dart';
    import '../providers/cart_provider.dart';
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

      @override
      Widget build(BuildContext context) {
        // Gunakan CartProvider untuk mendapatkan data keranjang
        final cartProvider = Provider.of<CartProvider>(context);
        final List<CartItem> cartItems = cartProvider.items;

        // Calculate the current discount amount
        final int subtotal = cartProvider.totalPrice;
        final int discount = calculateDiscount(subtotal);

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: const ClassicAppBar(title: 'Pembayaran'),
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
                            // final result = await Navigator.push<String>(
                            //   context,
                            //   MaterialPageRoute(
                            //     builder: (context) => const PaymentMethodScreen(),
                            //   ),
                            // );
                            final result = await context.push<String>('/paymentMethod');

                            // If we get a result back from the payment method screen, use it
                            if (result != null) {
                              setState(() {
                                selectedPaymentMethod = result;
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
                                  voucherDescription = 'Voucher applied';
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
                onCheckoutPressed: () {
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
                  // Atau menggunakan go_router jika Anda menggunakan routing dengan go_router:
                  context.push('/paymentConfirmation', extra: {
                    'items': List.from(cartItems),
                    'orderType': selectedOrderType,
                    'tableNumber': tableNumber,
                    'deliveryAddress': deliveryAddress,
                    'pickupTime': pickupTime,
                    'paymentMethod': selectedPaymentMethod,
                    'subtotal': subtotal,
                    'discount': discount,
                    'total': subtotal - discount,
                    'voucherCode': selectedVoucherCode,
                  });
                  cartProvider.clearCart(); // Uncomment jika ingin mengosongkan keranjang
                },
              ),
            ],
          ),
        );
      }
    }