import 'package:flutter/material.dart';
import '../../models/cart_item.dart';
import '../../utils/currency_formatter.dart';

class CartItemWidget extends StatelessWidget {
  final CartItem item;
  // final VoidCallback onIncrease;
  // final VoidCallback onDecrease;
  // final VoidCallback onRemove;

  const CartItemWidget({
    super.key,
    required this.item,
    // required this.onIncrease,
    // required this.onDecrease,
    // required this.onRemove,
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
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.shade200,
                ),
                clipBehavior: Clip.antiAlias,
                child: _buildImage(item.imageUrl),
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
                  // Tombol +/-
                  Row(
                    children: [
                      // Tombol kurangi
                      // GestureDetector(
                      //   onTap: onDecrease,
                      //   child: Container(
                      //     padding: const EdgeInsets.all(4),
                      //     decoration: BoxDecoration(
                      //       color: Colors.grey.shade200,
                      //       borderRadius: BorderRadius.circular(4),
                      //     ),
                      //     child: const Icon(Icons.remove, size: 16),
                      //   ),
                      // ),

                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        // decoration: BoxDecoration(
                        //   border: Border.all(color: Colors.grey.shade300),
                        //   borderRadius: BorderRadius.circular(4),
                        // ),
                        child: Text(
                          "x ${item.quantity}",
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),

                      // Tombol tambah
                      // GestureDetector(
                      //   onTap: onIncrease,
                      //   child: Container(
                      //     padding: const EdgeInsets.all(4),
                      //     decoration: BoxDecoration(
                      //       color: Colors.grey.shade200,
                      //       borderRadius: BorderRadius.circular(4),
                      //     ),
                      //     child: const Icon(Icons.add, size: 16),
                      //   ),
                      // ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // // Tombol hapus
                  // GestureDetector(
                  //   onTap: onRemove,
                  //   child: Text(
                  //     "Hapus",
                  //     style: TextStyle(
                  //       fontSize: 12,
                  //       color: Colors.red[600],
                  //       fontWeight: FontWeight.w500,
                  //     ),
                  //   ),
                  // ),
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
                Icon(Icons.add_circle_outline, size: 16, color: Colors.blue),
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
                Icon(Icons.cake, size: 16, color: Colors.deepOrange),
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
              child: item.toppings is List<Map<String, Object>>
                  ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: (item.toppings as List<Map<String, Object>>).map((topping) => Padding(
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
                )).toList(),
              )
                  : Row(
                children: [
                  const Icon(Icons.circle, size: 6, color: Colors.deepOrange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.toppings is String
                          ? item.toppings as String
                      // ignore: unnecessary_type_check
                          : item.toppings is List
                          ? (item.toppings as List).join(', ')
                          : '',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],

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
                formatCurrency(item.totalprice),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}