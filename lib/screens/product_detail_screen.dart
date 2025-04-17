import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../utils/currency_formatter.dart'; // Import the currency formatter utility
import '../widgets/detail_product/checkout_button.dart';
import '../widgets/detail_product/quantity_selector.dart';
import '../widgets/utils/custom_app_bar.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  ProductDetailScreenState createState() => ProductDetailScreenState();
}

class ProductDetailScreenState extends State<ProductDetailScreen> {
  int quantity = 1;
  List<Topping> selectedToppings = [];
  Addon? selectedAddon;
  final Color primaryColor = const Color(0xFF076A3B);

  // Menghitung total harga berdasarkan produk, jumlah, topping dan add-on yang dipilih
  double calculateTotal() {
    double basePrice = widget.product.discountPrice ?? widget.product.originalPrice ?? 0;
    double toppingsTotal = selectedToppings.fold(
        0, (sum, topping) => sum + topping.price);
    double addonPrice = selectedAddon?.price ?? 0;

    return (basePrice + toppingsTotal + addonPrice) * quantity;
  }

  // Menangani penambahan/pengurangan jumlah produk
  void updateQuantity(int newQuantity) {
    setState(() {
      quantity = newQuantity;
    });
  }

  // Menangani perubahan pada pilihan topping
  void toggleTopping(Topping topping) {
    setState(() {
      if (selectedToppings.contains(topping)) {
        selectedToppings.remove(topping);
      } else {
        selectedToppings.add(topping);
      }
    });
  }

  // Menangani perubahan pada pilihan add-on
  void selectAddon(Addon? addon) {
    setState(() {
      selectedAddon = addon;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Product product = widget.product;
    // Removed NumberFormat declaration since we're now using formatCurrency

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(title: 'Detail Produk'),

      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Gambar produk
                  Container(
                    height: 200,
                    width: double.infinity,
                    color: product.imageColor ?? Colors.grey.shade300,
                    child: product.imageUrl.isNotEmpty
                        ? Image.network(
                      product.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Text(
                            'Gambar tidak tersedia',
                            style: TextStyle(color: Colors.white),
                          ),
                        );
                      },
                    )
                        : const Center(
                      child: Text(
                        'Gambar Produk',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),

                  // Informasi produk
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                product.name,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.favorite_border),
                              onPressed: () {},
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              formatCurrency((product.discountPrice ?? product.originalPrice ?? 0).toInt()),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (product.discountPrice != null && product.originalPrice != null)
                              Text(
                                formatCurrency(product.originalPrice!.toInt()),
                                style: const TextStyle(
                                  fontSize: 14,
                                  decoration: TextDecoration.lineThrough,
                                  color: Colors.grey,
                                ),
                              ),
                            const SizedBox(width: 8),
                            if (product.discountPercentage != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '-${product.discountPercentage}%',
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          product.description,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),

                        // Bagian Topping (Multiple Choice)
                        if (product.toppings != null && product.toppings!.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          const Text(
                            'Tambah Topping (Pilihan Ganda)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...product.toppings!.map((topping) => CheckboxListTile(
                            title: Text(topping.name),
                            subtitle: Text(
                              formatCurrency(topping.price.toInt()),
                              style: TextStyle(color: primaryColor),
                            ),
                            value: selectedToppings.contains(topping),
                            activeColor: primaryColor,
                            controlAffinity: ListTileControlAffinity.leading,
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            onChanged: (_) => toggleTopping(topping),
                          )),
                        ],

                        // Bagian Add-ons (Single Choice)
                        if (product.addons != null && product.addons!.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          const Text(
                            'Tambahan (Pilihan Tunggal)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...product.addons!.map((addon) => RadioListTile<Addon>(
                            title: Text(addon.name),
                            subtitle: Text(
                              formatCurrency(addon.price.toInt()),
                              style: TextStyle(color: primaryColor),
                            ),
                            value: addon,
                            groupValue: selectedAddon,
                            activeColor: primaryColor,
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            onChanged: (value) => selectAddon(value),
                          )),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: const CheckoutButton(),
      bottomNavigationBar:  SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05), // Using withOpacity instead of withValues
                spreadRadius: 1,
                blurRadius: 10,
              ),
            ],
          ),
          child: Row(
            children: [
              QuantitySelector(
                quantity: quantity,
                onChanged: updateQuantity,
                primaryColor: primaryColor,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Total:',
                      style: TextStyle(fontSize: 12),
                    ),
                    Text(
                      formatCurrency(calculateTotal().toInt()),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    final cartProvider = Provider.of<CartProvider>(context, listen: false);
                    final double totalPrice = calculateTotal();

                    // Gabungkan topping dan add-on menjadi string agar lebih mudah dibandingkan
                    String toppingsText = selectedToppings.isNotEmpty
                        ? selectedToppings.map((e) => e.name).join(', ')
                        : '-';
                    String addonText = selectedAddon != null ? selectedAddon!.name : '-';

                    CartItem newItem = CartItem(
                      name: widget.product.name,
                      imageUrl: widget.product.imageUrl,
                      price: totalPrice.toInt(),
                      additional: addonText,
                      topping: toppingsText,
                      quantity: quantity,
                    );
                    cartProvider.addToCart(newItem);
                  },
                  child: const Text(
                    'Tambah ke Keranjang',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      // Bottom bar dengan total harga dan tombol tambah ke keranjang
    );
  }
}