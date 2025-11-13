import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../utils/currency_formatter.dart';

class AddOrderPage extends StatefulWidget {
  final Product product;

  const AddOrderPage({super.key, required this.product});

  @override
  AddOrderPageState createState() => AddOrderPageState();
}

class AddOrderPageState extends State<AddOrderPage> {
  int quantity = 1;
  List<Topping> selectedToppings = [];
  Map<String, AddonOption?> selectedAddonOptions = {};
  final TextEditingController notesController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final Color primaryColor = const Color(0xFF076A3B);

  @override
  void initState() {
    super.initState();

    // Initialize quantity controller
    quantityController.text = quantity.toString();
    for (var outlet in widget.product.availableAt) {
      print('${outlet.outletId} - ${outlet.name}');
    }
    // Initialize default addon options if available
    if (widget.product.addons != null) {
      for (var addon in widget.product.addons!) {
        AddonOption? defaultOption;
        try {
          defaultOption = addon.options.firstWhere((option) => option.isDefault);
        } catch (e) {
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
    notesController.dispose();
    quantityController.dispose();
    super.dispose();
  }

  // Calculate total price
  double calculateTotal() {
    // PERBAIKAN: Gunakan discountPrice jika ada
    double basePrice = widget.product.discountPrice ?? widget.product.originalPrice ?? 0;
    double toppingsTotal = selectedToppings.fold(0, (sum, topping) => sum + topping.price);

    double addonOptionsTotal = 0;
    selectedAddonOptions.forEach((addonId, option) {
      if (option != null) {
        addonOptionsTotal += option.price;
      }
    });

    return (basePrice + toppingsTotal + addonOptionsTotal) * quantity;
  }

  void updateQuantity(int newQuantity) {
    if (newQuantity < 1) return;
    setState(() {
      quantity = newQuantity;
      quantityController.text = quantity.toString();
    });
  }

  void updateQuantityFromInput(String value) {
    if (value.isEmpty) return;
    int? newQuantity = int.tryParse(value);
    if (newQuantity != null && newQuantity > 0) {
      setState(() {
        quantity = newQuantity;
      });
    } else {
      // Reset to current quantity if invalid input
      quantityController.text = quantity.toString();
    }
  }

  void toggleTopping(Topping topping) {
    setState(() {
      if (selectedToppings.contains(topping)) {
        selectedToppings.remove(topping);
      } else {
        selectedToppings.add(topping);
      }
    });
  }

  void selectAddonOption(String addonId, AddonOption? option) {
    setState(() {
      selectedAddonOptions[addonId] = option;
    });
  }

  void addToCart() {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    // 🔒 SAFETY CHECK: Verifikasi user sudah login
    try {
      final _ = cartProvider.items; // Test akses
    } catch (e) {
      // User belum login
      debugPrint('❌ AddOrderPage: User not logged in - $e');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan login terlebih dahulu'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );

      Navigator.pop(context);
      context.go('/login');
      return;
    }

    final double totalPrice = calculateTotal();

    List<Map<String, dynamic>> toppingsList = selectedToppings
        .map((topping) => {
      "name": topping.name,
      "price": topping.price,
    })
        .toList();

    List<Map<String, dynamic>> addonList = [];
    selectedAddonOptions.forEach((addonId, option) {
      if (option != null) {
        final addon = widget.product.addons!.firstWhere((a) => a.id == addonId);
        addonList.add({
          "name": addon.name,
          "label": option.label,
          "price": option.price,
        });
      }
    });

    // ✅ Ambil outlet pertama (atau bisa dibuat pilihan outlet)
    String? outletId;
    String? outletName;
    if (widget.product.availableAt.isNotEmpty) {
      outletId = widget.product.availableAt.first.outletId;
      outletName = widget.product.availableAt.first.name;
    }

    double basePrice = widget.product.discountPrice ?? widget.product.originalPrice ?? 0;

    CartItem newItem = CartItem(
      id: widget.product.id,
      name: widget.product.name,
      imageUrl: widget.product.imageUrl,
      price: basePrice.toInt(),
      totalprice: totalPrice.toInt(),
      addons: addonList,
      toppings: toppingsList,
      quantity: quantity,
      notes: notesController.text.trim().isNotEmpty
          ? notesController.text.trim()
          : null,
      outletId: outletId,
      outletName: outletName,
    );

    cartProvider.addToCart(newItem);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.product.name} ditambahkan ke keranjang'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final Product product = widget.product;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Tambah Pesanan'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                children: [
                  // Product image and basic info
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Product image
                        Container(
                          width: 120,
                          height: 120,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: product.imageUrl.isNotEmpty
                              ? Image.network(
                            product.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Image.asset(
                                'assets/images/product_default_image.png',
                                fit: BoxFit.cover,
                              );
                            },
                          )
                              : Image.asset(
                            'assets/images/product_default_image.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Product name and price
                        Text(
                          product.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),

                        // PERBAIKAN: Tampilkan harga diskon dan harga asli jika ada diskon
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              formatCurrency((product.discountPrice ?? product.originalPrice ?? 0).toInt()),
                              style: TextStyle(
                                fontSize: 18,
                                color: primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (product.discountPrice != null && product.originalPrice != null)
                              Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: Text(
                                  formatCurrency(product.originalPrice!.toInt()),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              ),
                          ],
                        ),

                        // Discount badge jika ada
                        if (product.discountPercentage != null)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Diskon ${product.discountPercentage}%',
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),

                        // Rating (if available)
                        const SizedBox(height: 8),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.star, color: Colors.orange, size: 16),
                            SizedBox(width: 4),
                            Text(
                              '4.8 (21) • 3 ratings and reviews',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Content with padding
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(),
                        const SizedBox(height: 16),

                        // Quantity selector - moved here
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Jumlah Pesanan',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    onPressed: quantity > 1
                                        ? () => updateQuantity(quantity - 1)
                                        : null,
                                    icon: const Icon(Icons.remove),
                                    iconSize: 18,
                                    color: quantity > 1 ? primaryColor : Colors.grey,
                                  ),
                                  Container(
                                    width: 50,
                                    alignment: Alignment.center,
                                    child: Text(
                                      quantity.toString(),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => updateQuantity(quantity + 1),
                                    icon: const Icon(Icons.add),
                                    iconSize: 18,
                                    color: primaryColor,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Addons section
                        if (product.addons != null && product.addons!.isNotEmpty) ...[
                          ...product.addons!.map((addon) => Container(
                            margin: const EdgeInsets.only(bottom: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  addon.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: addon.options.map((option) {
                                    bool isSelected = selectedAddonOptions[addon.id] == option;
                                    return GestureDetector(
                                      onTap: () => selectAddonOption(addon.id, option),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isSelected ? primaryColor : Colors.grey.shade100,
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: isSelected ? primaryColor : Colors.grey.shade300,
                                          ),
                                        ),
                                        child: Text(
                                          option.label,
                                          style: TextStyle(
                                            color: isSelected ? Colors.white : Colors.black,
                                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          )),
                        ],

                        // Toppings section
                        if (product.toppings != null && product.toppings!.isNotEmpty) ...[
                          const Text(
                            'Extra Toppings',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...product.toppings!.map((topping) => Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: selectedToppings.contains(topping),
                                  onChanged: (_) => toggleTopping(topping),
                                  activeColor: primaryColor,
                                ),
                                Expanded(
                                  child: Text(
                                    topping.name,
                                    style: const TextStyle(fontSize: 15),
                                  ),
                                ),
                                Text(
                                  formatCurrency(topping.price.toInt()),
                                  style: TextStyle(
                                    color: primaryColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          )),
                          const SizedBox(height: 20),
                        ],

                        // Notes section
                        const Text(
                          'Catatan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: notesController,
                          decoration: InputDecoration(
                            hintText: 'Tambahkan catatan...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: primaryColor),
                            ),
                            contentPadding: const EdgeInsets.all(12),
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
          ),
        ],
      ),

      // Bottom section - simplified, only total and button
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    formatCurrency(calculateTotal().toInt()),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                onPressed: addToCart,
                child: const Text(
                  'Tambah Order',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
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