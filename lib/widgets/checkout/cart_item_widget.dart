import 'package:flutter/material.dart';
import '../../models/cart_item.dart';
import '../../utils/currency_formatter.dart';

class CartItemWidget extends StatelessWidget {
  final CartItem item;

  const CartItemWidget({
    super.key,
    required this.item,
  });

  // Method untuk menghitung total harga item termasuk addons dan toppings
  // SAMA PERSIS dengan cart_item_card.dart
  int _calculateItemTotalPrice() {
    int totalPrice = item.price;

    // Add toppings price
    if (item.toppings != null && item.toppings is List) {
      for (var topping in item.toppings as List) {
        if (topping is Map && topping.containsKey('price')) {
          totalPrice += (topping['price'] as num).toInt();
        }
      }
    }

    // Add addons price
    for (var addon in item.addons as List) {
      if (addon is Map && addon.containsKey('price')) {
        totalPrice += (addon['price'] as num).toInt();
      }
    }

    return totalPrice;
  }

  @override
  Widget build(BuildContext context) {
    // ✅ PERBAIKAN: Gunakan perhitungan yang sama dengan cart_item_card
    final itemTotalPrice = _calculateItemTotalPrice();
    final totalForItem = itemTotalPrice * item.quantity;

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header section (image, name, price, controls)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Gambar produk
              Container(
                width: 70,
                height: 70,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: item.imageUrl.isNotEmpty
                    ? Image.network(
                  item.imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
                    return Image.asset(
                      'assets/images/product_default_image.png',
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    );
                  },
                )
                    : Image.asset(
                  'assets/images/product_default_image.png',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),

              const SizedBox(width: 12),

              // Nama dan harga produk
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatCurrency(item.price),
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
              ),

              // Kontrol kuantitas
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Quantity display
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      "x${item.quantity}",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),
          Divider(color: Colors.grey[200], thickness: 1),
          const SizedBox(height: 8),

          // Tambahan (Addons) Section
          if (item.addons.isNotEmpty) ...[
            const Row(
              children: [
                SizedBox(width: 4),
                Text(
                  'Tambahan:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(left: 8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: item.addons.map((addon) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(Icons.circle, size: 6, color: Colors.blue),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${addon["name"]}: ${addon["label"]}',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        formatCurrency(addon["price"]),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                )).toList(),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Topping Section
          if ((item.toppings is String && (item.toppings as String).isNotEmpty) ||
              ((item.toppings as List).isNotEmpty)) ...[
            const Row(
              children: [
                SizedBox(width: 4),
                Text(
                  'Topping:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(left: 8),
              decoration: BoxDecoration(
                color: Colors.deepOrange.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.deepOrange.withOpacity(0.2)),
              ),
              child: _buildToppingsWidget(item.toppings),
            ),
            const SizedBox(height: 8),
          ],

          // Notes Section
          if (item.notes != null && item.notes!.isNotEmpty) ...[
            const Row(
              children: [
                Icon(Icons.note_outlined, size: 16, color: Colors.amber),
                SizedBox(width: 4),
                Text(
                  'Catatan:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(left: 8),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.withOpacity(0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.format_quote, size: 14, color: Colors.amber),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.notes!,
                      style: const TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],

          // ✅ PERBAIKAN: Gunakan perhitungan yang sama dengan cart_item_card
          // Total price at the bottom
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Total: ',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
              Text(
                formatCurrency(totalForItem), // Gunakan totalForItem yang sudah dihitung
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ✅ TAMBAHKAN: Helper method yang sama dengan cart_item_card.dart
  Widget _buildToppingsWidget(dynamic toppings) {
    if (toppings is List && toppings.isNotEmpty && toppings.first is Map<String, dynamic>) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: (toppings).map<Widget>((topping) {
          if (topping is Map) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.circle, size: 6, color: Colors.deepOrange),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${topping["name"]}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (topping.containsKey("price") && topping["price"] != null)
                    Text(
                      formatCurrency(topping["price"] as num),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.deepOrange,
                      ),
                    ),
                ],
              ),
            );
          } else {
            return const SizedBox.shrink();
          }
        }).toList(),
      );
    } else {
      return Row(
        children: [
          const Icon(Icons.circle, size: 6, color: Colors.deepOrange),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              toppings is String
                  ? toppings
                  : toppings is List
                  ? (toppings).join(', ')
                  : '',
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      );
    }
  }
}