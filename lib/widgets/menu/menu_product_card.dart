import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/product.dart';
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

  @override
  Widget build(BuildContext context) {
    // Tidak perlu lagi membuat NumberFormat currencyFormatter
    return GestureDetector(
      onTap: () {
        context.push('/product/${product.id}');
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
                      child: product.imageUrl.isNotEmpty
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