import 'package:flutter/material.dart';
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
  final Color primaryColor = const Color(0xFF076A3B);

  @override
  void initState() {
    super.initState();

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
    super.dispose();
  }

  // Calculate total price
  double calculateTotal() {
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
    setState(() {
      quantity = newQuantity;
    });
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

    CartItem newItem = CartItem(
      id: widget.product.id,
      name: widget.product.name,
      imageUrl: widget.product.imageUrl,
      price: widget.product.originalPrice!.toInt(),
      totalprice: totalPrice.toInt(),
      addons: addonList,
      toppings: toppingsList,
      quantity: quantity,
      notes: notesController.text.trim().isNotEmpty ? notesController.text.trim() : null,
    );

    cartProvider.addToCart(newItem);

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.product.name} ditambahkan ke keranjang'),
        duration: const Duration(seconds: 2),
        backgroundColor: primaryColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Product product = widget.product;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Tambah Pesanan'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Product summary card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Product image
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: product.imageColor ?? Colors.grey.shade300,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: product.imageUrl.isNotEmpty
                      ? Image.network(
                          product.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Image.asset(
                              'assets/images/product_default_image.jpeg',
                              fit: BoxFit.cover,
                            );
                          },
                        )
                      : Image.asset(
                          'assets/images/product_default_image.jpeg',
                          fit: BoxFit.cover,
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatCurrency((product.discountPrice ??
                                product.originalPrice ??
                                0)
                            .toInt()),
                        style: TextStyle(
                          fontSize: 14,
                          color: primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quantity section
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Jumlah',
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
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
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
                  ),

                  // Toppings section
                  if (product.toppings != null && product.toppings!.isNotEmpty) ...[
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.add_circle_outline,
                                color: primaryColor,
                                size: 20
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Tambah Topping (Opsional)',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...product.toppings!.map((topping) => Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: CheckboxListTile(
                                  title: Text(topping.name),
                                  subtitle: Text(
                                    formatCurrency(topping.price.toInt()),
                                    style: TextStyle(color: primaryColor),
                                  ),
                                  value: selectedToppings.contains(topping),
                                  activeColor: primaryColor,
                                  controlAffinity: ListTileControlAffinity.leading,
                                  contentPadding: EdgeInsets.zero,
                                  onChanged: (_) => toggleTopping(topping),
                                ),
                              )),
                        ],
                      ),
                    ),
                  ],

                  // Addons section
                  if (product.addons != null && product.addons!.isNotEmpty) ...[
                    ...product.addons!.map((addon) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.tune,
                                    color: primaryColor,
                                    size: 20
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    addon.name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ...addon.options.map((option) => Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: RadioListTile<AddonOption>(
                                      title: Text(option.label),
                                      subtitle: Text(
                                        formatCurrency(option.price.toInt()),
                                        style: TextStyle(color: primaryColor),
                                      ),
                                      value: option,
                                      groupValue: selectedAddonOptions[addon.id],
                                      activeColor: primaryColor,
                                      contentPadding: EdgeInsets.zero,
                                      onChanged: (value) =>
                                          selectAddonOption(addon.id, value),
                                    ),
                                  )),
                            ],
                          ),
                        )),
                  ],

                  // Notes section
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
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

                  const SizedBox(height: 100), // Space for bottom button
                ],
              ),
            ),
          ),
        ],
      ),

      // Bottom button
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Pesanan:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    formatCurrency(calculateTotal().toInt()),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: addToCart,
                  child: Text(
                    'Tambah ke Keranjang • ${formatCurrency(calculateTotal().toInt())}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
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