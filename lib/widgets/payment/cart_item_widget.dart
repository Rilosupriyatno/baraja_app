import 'package:flutter/material.dart';
import '../../models/cart_item.dart';
import '../../utils/currency_formatter.dart';

class CartItemWidget extends StatelessWidget {
  final CartItem item;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onRemove;

  const CartItemWidget({
    super.key,
    required this.item,
    required this.onIncrease,
    required this.onDecrease,
    required this.onRemove,
  });

  Widget _buildImage(String url) {
    // Check if url is empty or null first
    if (url.isEmpty) {
      return Container(
        color: Colors.grey[300],
        child: const Icon(Icons.image_not_supported),
      );
    }

    // Then check if it's a valid URL
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return Container(
        color: Colors.grey[300],
        child: const Icon(Icons.image_not_supported),
      );
    }

    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.grey[300],
          child: const Icon(Icons.image_not_supported),
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gambar produk
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(child: _buildImage(item.imageUrl),
            ),
          ),

          const SizedBox(width: 12),

          // Detail produk
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
                Text(
                  "Topping: ${item.toppings}",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),

          // Harga dan kuantitas
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatCurrency(item.price),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  // Tombol kurangi
                  GestureDetector(
                    onTap: onDecrease,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(Icons.remove, size: 16),
                    ),
                  ),

                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      "${item.quantity}",
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),

                  // Tombol tambah
                  GestureDetector(
                    onTap: onIncrease,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(Icons.add, size: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Tombol hapus
              GestureDetector(
                onTap: onRemove,
                child: Text(
                  "Hapus",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}