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
  Map<String, AddonOption?> selectedAddonOptions = {};
  final TextEditingController notesController = TextEditingController(); // Added notes controller
  final Color primaryColor = const Color(0xFF076A3B);

  @override
  void initState() {
    super.initState();
    // Initialize default addon options if available
    if (widget.product.addons != null) {
      for (var addon in widget.product.addons!) {
        // Find default option if any
        AddonOption? defaultOption;
        try {
          defaultOption =
              addon.options.firstWhere((option) => option.isDefault);
        } catch (e) {
          // No default option found, use first option if available
          if (addon.options.isNotEmpty) {
            defaultOption = addon.options.first;
          }
        }

        if (defaultOption != null) {
          selectedAddonOptions[addon.id] = defaultOption;
        }
      }
    }
  }

  @override
  void dispose() {
    notesController.dispose(); // Added dispose for notes controller
    super.dispose();
  }

  // Menghitung total harga berdasarkan produk, jumlah, topping dan add-on yang dipilih
  double calculateTotal() {
    double basePrice =
        widget.product.discountPrice ?? widget.product.originalPrice ?? 0;
    double toppingsTotal =
    selectedToppings.fold(0, (sum, topping) => sum + topping.price);

    // Calculate addon options price
    double addonOptionsTotal = 0;
    selectedAddonOptions.forEach((addonId, option) {
      if (option != null) {
        addonOptionsTotal += option.price;
      }
    });

    return (basePrice + toppingsTotal + addonOptionsTotal) * quantity;
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

  // Menangani perubahan pada pilihan add-on option
  void selectAddonOption(String addonId, AddonOption? option) {
    setState(() {
      selectedAddonOptions[addonId] = option;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Product product = widget.product;

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
                    child: product.imageUrl.isNotEmpty &&
                        product.imageUrl != 'https://placehold.co/1920x1080/png'
                        ? Image.network(
                      product.imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (context, error, stackTrace) {
                        return Image.asset(
                          'assets/images/product_default_image.jpeg',
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        );
                      },
                    )
                        : Image.asset(
                      'assets/images/product_default_image.jpeg',
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
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
                              formatCurrency((product.discountPrice ??
                                  product.originalPrice ??
                                  0)
                                  .toInt()),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
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
                        if (product.toppings != null &&
                            product.toppings!.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          const Text(
                            'Tambah Topping (Pilihan Ganda)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...product.toppings!
                              .map((topping) => CheckboxListTile(
                            title: Text(topping.name),
                            subtitle: Text(
                              formatCurrency(topping.price.toInt()),
                              style: TextStyle(color: primaryColor),
                            ),
                            value: selectedToppings.contains(topping),
                            activeColor: primaryColor,
                            controlAffinity:
                            ListTileControlAffinity.leading,
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            onChanged: (_) => toggleTopping(topping),
                          )),
                        ],

                        // Bagian Add-ons (Single Choice per Addon)
                        if (product.addons != null &&
                            product.addons!.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          const Text(
                            'Tambahan',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...product.addons!.map((addon) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(
                                      top: 8.0, bottom: 4.0),
                                  child: Text(
                                    addon.name,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                ...addon.options.map((option) =>
                                    RadioListTile<AddonOption>(
                                      title: Text(option.label),
                                      subtitle: Text(
                                        formatCurrency(option.price.toInt()),
                                        style: TextStyle(color: primaryColor),
                                      ),
                                      value: option,
                                      groupValue:
                                      selectedAddonOptions[addon.id],
                                      activeColor: primaryColor,
                                      dense: true,
                                      contentPadding: EdgeInsets.zero,
                                      onChanged: (value) =>
                                          selectAddonOption(addon.id, value),
                                    )),
                              ],
                            );
                          }),
                        ],

                        // Notes section - Added notes functionality
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.note_alt_outlined,
                                      color: primaryColor,
                                      size: 20
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Catatan (Opsional)',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: notesController,
                                decoration: InputDecoration(
                                  hintText: 'Tambahkan catatan khusus untuk pesanan ini...',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: Colors.grey.shade300),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: primaryColor),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                ),
                                maxLines: 3,
                                textInputAction: TextInputAction.done,
                              ),
                            ],
                          ),
                        ),
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
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
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
                    final cartProvider =
                    Provider.of<CartProvider>(context, listen: false);
                    final double totalPrice = calculateTotal();

// Gather selected topping names and prices
                    List<Map<String, dynamic>> toppingsList = selectedToppings
                        .map((topping) => {
                      "name": topping.name,
                      "price": topping
                          .price, // pastikan `topping` ada field `price`
                    })
                        .toList();

// Gather selected addon options names and prices
                    List<Map<String, dynamic>> addonList = [];
                    selectedAddonOptions.forEach((addonId, option) {
                      if (option != null) {
                        final addon = widget.product.addons!
                            .firstWhere((a) => a.id == addonId);
                        addonList.add({
                          "name": addon.name,
                          "label": option.label,
                          "price": option
                              .price, // pastikan `option` ada field `price`
                        });
                      }
                    });

// Membuat CartItem with notes
                    CartItem newItem = CartItem(
                      id: widget.product.id,
                      name: widget.product.name,
                      imageUrl: widget.product.imageUrl,
                      price: widget.product.originalPrice!.toInt(),
                      totalprice: totalPrice.toInt(),
                      addons: addonList,
                      toppings: toppingsList,
                      quantity: quantity,
                      notes: notesController.text.trim().isNotEmpty
                          ? notesController.text.trim()
                          : null, // Added notes support
                    );

                    cartProvider.addToCart(newItem);

                    print('${widget.product.name} ditambahkan ke keranjang');

                  },
                  child: const Text(
                    'Tambah ke Keranjang',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}