import 'package:flutter/material.dart';
import '../../models/cart_item.dart';
import '../../models/product.dart';
import '../../services/product_service.dart';
import '../../utils/currency_formatter.dart';

class CartItemEditDialog extends StatefulWidget {
  final CartItem item;
  final Function(CartItem) onSave;

  const CartItemEditDialog({
    super.key,
    required this.item,
    required this.onSave,
  });

  @override
  State<CartItemEditDialog> createState() => _CartItemEditDialogState();
}

class _CartItemEditDialogState extends State<CartItemEditDialog> {
  final ProductService _productService = ProductService();
  final TextEditingController _notesController = TextEditingController();

  Product? _product;
  bool _isLoading = true;
  int _quantity = 1;
  // ignore: prefer_final_fields
  List<Topping> _selectedToppings = [];
  // ignore: prefer_final_fields
  Map<String, AddonOption?> _selectedAddonOptions = {};

  final Color primaryColor = const Color(0xFF076A3B);

  @override
  void initState() {
    super.initState();
    _quantity = widget.item.quantity;
    _notesController.text = widget.item.notes ?? '';
    _loadProductData();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadProductData() async {
    try {
      final product = await _productService.getProductById(widget.item.id);

      if (product != null) {
        setState(() {
          _product = product;
          _initializeSelections();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading product: $e');
      setState(() => _isLoading = false);
    }
  }

  void _initializeSelections() {
    if (_product == null) return;

    // Initialize toppings
    if (_product!.toppings != null && widget.item.toppings is List) {
      for (var selectedTopping in widget.item.toppings as List) {
        if (selectedTopping is Map) {
          final toppingName = selectedTopping['name'] as String;
          try {
            final topping = _product!.toppings!.firstWhere(
                  (t) => t.name == toppingName,
            );
            _selectedToppings.add(topping);
          } catch (e) {
            debugPrint('Topping not found: $toppingName');
          }
        }
      }
    }

    // Initialize addons
    if (_product!.addons != null) {
      for (var selectedAddon in widget.item.addons as List) {
        if (selectedAddon is Map) {
          final addonName = selectedAddon['name'] as String;
          final addonLabel = selectedAddon['label'] as String;

          try {
            final addon = _product!.addons!.firstWhere(
                  (a) => a.name == addonName,
            );

            try {
              final option = addon.options.firstWhere(
                    (o) => o.label == addonLabel,
              );
              _selectedAddonOptions[addon.id] = option;
            } catch (e) {
              debugPrint('Addon option not found: $addonLabel');
            }
          } catch (e) {
            debugPrint('Addon not found: $addonName');
          }
        }
      }
    }
  }

  double _calculateTotal() {
    if (_product == null) return 0;

    double basePrice = _product!.discountPrice ?? _product!.originalPrice ?? 0;
    double toppingsTotal = _selectedToppings.fold(0, (sum, topping) => sum + topping.price);

    double addonOptionsTotal = 0;
    _selectedAddonOptions.forEach((addonId, option) {
      if (option != null) {
        addonOptionsTotal += option.price;
      }
    });

    return (basePrice + toppingsTotal + addonOptionsTotal) * _quantity;
  }

  void _toggleTopping(Topping topping) {
    setState(() {
      if (_selectedToppings.contains(topping)) {
        _selectedToppings.remove(topping);
      } else {
        _selectedToppings.add(topping);
      }
    });
  }

  void _selectAddonOption(String addonId, AddonOption? option) {
    setState(() {
      _selectedAddonOptions[addonId] = option;
    });
  }

  void _saveChanges() {
    if (_product == null) return;

    // Prepare toppings list
    List<Map<String, dynamic>> toppingsList = _selectedToppings
        .map((topping) => {
      "name": topping.name,
      "price": topping.price,
    })
        .toList();

    // Prepare addons list
    List<Map<String, dynamic>> addonList = [];
    _selectedAddonOptions.forEach((addonId, option) {
      if (option != null) {
        final addon = _product!.addons!.firstWhere((a) => a.id == addonId);
        addonList.add({
          "name": addon.name,
          "label": option.label,
          "price": option.price,
        });
      }
    });

    // Calculate total price per item (base + addons + toppings)
    double basePrice = _product!.discountPrice ?? _product!.originalPrice ?? 0;
    double toppingsTotal = _selectedToppings.fold(0, (sum, topping) => sum + topping.price);
    double addonOptionsTotal = 0;
    _selectedAddonOptions.forEach((addonId, option) {
      if (option != null) {
        addonOptionsTotal += option.price;
      }
    });
    int totalPricePerItem = (basePrice + toppingsTotal + addonOptionsTotal).toInt();

    // Create updated cart item
    // ✅ FIX: Sesuaikan dengan constructor CartItem Anda
    CartItem updatedItem = CartItem(
      id: widget.item.id,
      name: widget.item.name,
      imageUrl: widget.item.imageUrl,
      price: (_product!.originalPrice ?? _product!.discountPrice ?? 0).toInt(),
      totalprice: totalPricePerItem,
      addons: addonList,
      toppings: toppingsList,
      quantity: _quantity,
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      outletId: widget.item.outletId,
      outletName: widget.item.outletName,
    );

    widget.onSave(updatedItem);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Edit Pesanan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Content
            if (_isLoading)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_product == null)
              const Expanded(
                child: Center(child: Text('Produk tidak ditemukan')),
              )
            else
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product info
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              color: Colors.white,
                              width: 60,
                              height: 60,
                              child: Image.network(
                                widget.item.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Image.asset(
                                    'assets/images/product_default_image.png',
                                    fit: BoxFit.cover,
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.item.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  formatCurrency(widget.item.price),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Quantity selector
                      const Text(
                        'Jumlah',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          IconButton(
                            onPressed: _quantity > 1
                                ? () => setState(() => _quantity--)
                                : null,
                            icon: Icon(
                              Icons.remove_circle,
                              color: _quantity > 1 ? Colors.red : Colors.grey,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$_quantity',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => setState(() => _quantity++),
                            icon: const Icon(
                              Icons.add_circle,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),

                      // Toppings
                      if (_product!.toppings != null && _product!.toppings!.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        const Text(
                          'Tambah Topping',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ..._product!.toppings!.map((topping) => CheckboxListTile(
                          title: Text(topping.name),
                          subtitle: Text(
                            formatCurrency(topping.price.toInt()),
                            style: TextStyle(color: primaryColor),
                          ),
                          value: _selectedToppings.contains(topping),
                          activeColor: primaryColor,
                          controlAffinity: ListTileControlAffinity.leading,
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          onChanged: (_) => _toggleTopping(topping),
                        )),
                      ],

                      // Addons
                      if (_product!.addons != null && _product!.addons!.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        const Text(
                          'Tambahan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ..._product!.addons!.map((addon) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
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
                                    groupValue: _selectedAddonOptions[addon.id],
                                    activeColor: primaryColor,
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                    onChanged: (value) =>
                                        _selectAddonOption(addon.id, value),
                                  )),
                            ],
                          );
                        }),
                      ],

                      // Notes
                      const SizedBox(height: 24),
                      const Text(
                        'Catatan (Opsional)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _notesController,
                        decoration: InputDecoration(
                          hintText: 'Tambahkan catatan khusus...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: primaryColor),
                          ),
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),

            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border(
                  top: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        formatCurrency(_calculateTotal().toInt()),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Batal'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _saveChanges,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text(
                            'Simpan',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}