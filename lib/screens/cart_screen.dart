import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../data/product_data.dart';
import '../models/cart_item.dart';
import '../providers/cart_provider.dart';
import '../widgets/cart_item_card.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  CartScreenState createState() => CartScreenState();
}

class CartScreenState extends State<CartScreen> {
  final NumberFormat currencyFormatter =
  NumberFormat.currency(locale: 'id_ID', symbol: 'Rp.', decimalDigits: 0);
  List<CartItem> cartItems = ProductData.allProducts.map((product) => CartItem(
    name: product.name,
    imageUrl: product.imageUrl,
    price: (product.discountPrice ?? 0).toInt(), // Ensures discountPrice is not null
    additional: (product.addons?.isNotEmpty ?? false) // Use ?.isNotEmpty to prevent null checks
        ? product.addons!.first.name
        : 'Tanpa Tambahan',
    topping: (product.toppings?.isNotEmpty ?? false) // Use ?.isNotEmpty to prevent null checks
        ? product.toppings!.first.name
        : 'Tanpa Topping',
  )).toList();




  int get totalPrice => cartItems.fold(0, (total, item) => total + (item.price * item.quantity));

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final cartItems = cartProvider.items; // Ambil item dari CartProvider

    return Scaffold(
      backgroundColor: Colors.white, // Warna body tetap putih
      extendBodyBehindAppBar: true,  // Agar transisi lebih halus
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            elevation: 4,
            shadowColor: Colors.grey.shade300,
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: const Text('Keranjang', style: TextStyle(color: Colors.black)),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final item = cartItems[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: CartItemCard(
                        item: item,
                        currencyFormatter: currencyFormatter,
                        // onIncrease: () {
                        //   setState(() => item.quantity++);
                        //   cartProvider.notifyListeners(); // Perbarui UI
                        // },
                        onIncrease: () {
                          final cartProvider = Provider.of<CartProvider>(context, listen: false);
                          int index = cartProvider.items.indexOf(item);
                          if (index != -1) {
                            cartProvider.increaseQuantity(index);
                          }
                        },
                        onDecrease: () {
                          setState(() {
                            if (item.quantity > 1) {
                              item.quantity--;
                            } else {
                              cartProvider.removeFromCart(index); // Hapus dari cart
                            }
                          });
                        },
                      ),
                    );
                  },
                  childCount: cartItems.length,
                ),
              ),
          ),
          // Tombol Tambah Pesanan di bawah item terakhir
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 3, left: 16, right: 16, bottom: 16),
              child: ElevatedButton.icon(
                onPressed: () {
                  context.push('/menu');
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Colors.green,
                ),
                icon: const Icon(Icons.add_circle_rounded, color: Colors.white), // Ikon Plus
                label: const Text(
                  'Tambah Pesanan',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),


      bottomNavigationBar: Material(
        elevation: 4, // Memberikan efek bayangan
        shadowColor: Colors.grey.shade300, // Warna bayangan lebih soft
        color: Colors.white,
        clipBehavior: Clip.none, // Pastikan bayangan tidak terpotong
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.4), // Warna bayangan lebih tegas
                spreadRadius: 1, // Lebar penyebaran bayangan
                blurRadius: 6, // Seberapa blur bayangannya
                offset: const Offset(0, -3), // Posisi bayangan ke atas (-Y)
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Harga', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(currencyFormatter.format(totalPrice), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),
          ElevatedButton(
            onPressed: cartItems.isEmpty ? null : () {
              // Navigasi ke CheckoutScreen
              context.push('/checkout'); // Pastikan Anda sudah menambahkan route ini di router Anda
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              backgroundColor: Colors.green,
            ),
            child: const Text('Lanjutkan Pesanan', style: TextStyle(color: Colors.white, fontSize: 16)),
          ),
            ],
          ),
        ),
      ),
    );
  }
}
