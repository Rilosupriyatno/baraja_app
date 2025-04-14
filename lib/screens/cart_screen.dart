import 'package:baraja_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../data/product_data.dart'; // You can keep this if it's still used
import '../models/cart_item.dart';
import '../providers/cart_provider.dart';
import '../widgets/cart/cart_item_card.dart';
import '../utils/currency_formatter.dart'; // Import fungsi format mata uang
import '../services/product_service.dart'; // Import ProductService

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  CartScreenState createState() => CartScreenState();
}

class CartScreenState extends State<CartScreen> {
  List<CartItem> cartItems = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  // Fetch products from the ProductService
  void _loadProducts() async {
    try {
      final fetchedProducts = await ProductService.fetchMenuItems();
      setState(() {
        cartItems = fetchedProducts.map((product) {
          return CartItem(
            name: product.name,
            imageUrl: product.imageUrl,
            price: (product.discountPrice ?? 0).toInt(),
            additional: (product.addons?.isNotEmpty ?? false)
                ? product.addons!.first.name
                : 'Tanpa Tambahan',
            topping: (product.toppings?.isNotEmpty ?? false)
                ? product.toppings!.first.name
                : 'Tanpa Topping',
          );
        }).toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      // Handle error here, maybe show a snackbar
      print('Failed to load products: $e');
    }
  }

  int get totalPrice => cartItems.fold(0, (total, item) => total + (item.price * item.quantity));

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final cartItems = cartProvider.items;

    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : CustomScrollView(
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
                      onIncrease: () {
                        final cartProvider = Provider.of<CartProvider>(context, listen: false);
                        int index = cartProvider.items.indexOf(item);
                        if (index != -1) {
                          cartProvider.increaseQuantity(index);
                        }
                      },
                      onDecrease: () {
                        final cartProvider = Provider.of<CartProvider>(context, listen: false);
                        int index = cartProvider.items.indexOf(item);
                        if (index != -1) {
                          if (item.quantity > 1) {
                            cartProvider.decreaseQuantity(index);
                          } else {
                            cartProvider.removeFromCart(index);
                          }
                        }
                      },
                    ),
                  );
                },
                childCount: cartItems.length,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 3, left: 16, right: 16, bottom: 16),
              child: ElevatedButton.icon(
                onPressed: () {
                  context.push('/menu');
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: AppTheme.primaryColor,
                ),
                icon: const Icon(Icons.add_circle_rounded, color: Colors.white),
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
        elevation: 4,
        shadowColor: Colors.grey.shade300,
        color: Colors.white,
        clipBehavior: Clip.none,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.4),
                spreadRadius: 1,
                blurRadius: 6,
                offset: const Offset(0, -3),
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
                  Text(formatCurrency(cartProvider.totalPrice), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: cartItems.isEmpty ? null : () {
                  context.push('/checkout');
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: AppTheme.primaryColor,
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
