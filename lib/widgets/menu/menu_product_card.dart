import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
import '../../models/product.dart';
import '../../screens/product_detail_modal.dart';
import '../../theme/app_theme.dart';
import '../../utils/currency_formatter.dart'; // Import fungsi formatCurrency

class MenuProductCard extends StatelessWidget {
  final Product product;
  final String? bundleText;

  const MenuProductCard({
    super.key,
    required this.product,
    this.bundleText,
  });

  // Widget untuk menampilkan rating dengan bintang yang presisi
  Widget _buildRatingWidget(double rating) {
    List<Widget> stars = [];

    for (int i = 1; i <= 5; i++) {
      if (i <= rating.floor()) {
        // Bintang penuh
        stars.add(const Icon(
          Icons.star,
          color: Colors.amber,
          size: 16,
        ));
      } else if (i == rating.floor() + 1 && rating % 1 != 0) {
        // Bintang setengah
        stars.add(const Icon(
          Icons.star_half,
          color: Colors.amber,
          size: 16,
        ));
      } else {
        // Bintang kosong
        stars.add(Icon(
          Icons.star_border,
          color: Colors.grey[400],
          size: 16,
        ));
      }
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...stars,
        const SizedBox(width: 4),
        Text(
          rating.toStringAsFixed(1),
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Tidak perlu lagi membuat NumberFormat currencyFormatter
    return GestureDetector(
      // onTap: () {
      //   context.push('/product/${product.id}');
      // },
      onTap: () {
        print('Product card tapped: ${product.name}'); // Debug print
        try {
          ProductDetailModal.show(context, product);
        } catch (e) {
          print('Error showing modal: $e');
          // Fallback - show simple dialog for debugging
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(product.name),
              content: const Text('Modal error, but tap detected!'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
          );
        }
      },
      child: Container(
        height: 250,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),

              child: Container(
                width: double.infinity,
                height: 120,
                decoration: const BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
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
                    //   child: product.imageUrl.isNotEmpty
                    //       ? Image.network(
                    //     product.imageUrl,
                    //     fit: BoxFit.cover,
                    //     width: double.infinity,
                    //     height: double.infinity,
                    //     errorBuilder: (context, error, stackTrace) {
                    //       return Image.asset(
                    //         'assets/images/product_default_image.jpeg',
                    //         fit: BoxFit.cover,
                    //         width: double.infinity,
                    //         height: double.infinity,
                    //       );
                    //     },
                    //   )
                    //       : Image.asset(
                    //     'assets/images/product_default_image.jpeg',
                    //     fit: BoxFit.cover,
                    //     width: double.infinity,
                    //     height: double.infinity,
                    //   ),
                    // ),
                    if (bundleText != null)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            bundleText!,
                            style: TextStyle(
                              color: Colors.brown[800],
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Harga coret jika ada diskon
                    // if (product.discountPrice != 0)
                    //   Text(
                    //     formatCurrency(product.originalPrice?.round() ?? 0),
                    //     style: TextStyle(
                    //       decoration: TextDecoration.lineThrough,
                    //       color: Colors.grey[600],
                    //       fontSize: 14,
                    //     ),
                    //   ),
                    Text(
                      formatCurrency(product.discountPrice?.round() ?? 0), // Menggunakan formatCurrency
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Text(
                        product.description,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Widget rating yang sudah diperbaiki
                        if (product.averageRating > 0)
                          _buildRatingWidget(product.averageRating),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}