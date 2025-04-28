import 'package:flutter/material.dart';
import '../../models/cart_item.dart';
import '../../utils/currency_formatter.dart';

class CartItemCard extends StatelessWidget {
  final CartItem item;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;

  // Tidak lagi memerlukan NumberFormat currencyFormatter

  const CartItemCard({
    super.key,
    required this.item,
    required this.onIncrease,
    required this.onDecrease,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1), // Menggunakan withOpacity sebagai pengganti withValues
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              item.imageUrl,
              width: 80,
              height: 110,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 80,
                  height: 110,
                  color: Colors.grey[300],
                  child: const Icon(Icons.image_not_supported),
                );
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text('Tambahan:', style: TextStyle(fontWeight: FontWeight.bold)),
                ...item.addons.map((addon) => Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Row(
                    children: [
                      const Icon(Icons.sports_volleyball_sharp, size: 16), // Pointer icon
                      const SizedBox(width: 8), // Spacing between pointer and text
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${addon["name"]}: ', style: const TextStyle(fontSize: 14)),
                          Text(' ${addon["label"]}', style: const TextStyle(fontSize: 14)),
                          Text(
                            '  ${formatCurrency(addon["price"])}',
                            style: const TextStyle(fontSize: 12),
                          ),

                        ],
                      ),
                    ],
                  ),
                )),
                Text('Topping: ${item.toppings}'),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Menggunakan formatCurrency langsung daripada currencyFormatter
                    Text(
                      formatCurrency(item.price * item.quantity),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: onDecrease,
                        ),
                        Text('${item.quantity}'),
                        IconButton(
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: onIncrease,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}