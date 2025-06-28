import 'package:flutter/material.dart';
import 'package:baraja_app/models/product.dart';
// Remove the go_router import since we're not using navigation anymore
// import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../utils/currency_formatter.dart';
import '../../screens/product_detail_modal.dart'; // Import the new modal

class ProductCard extends StatelessWidget {
  final Product product;
  final bool isActive;
  final String? bundleText;

  const ProductCard({
    super.key,
    required this.product,
    this.isActive = false,
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0.0),
      child: SizedBox(
        width: 210,
        height: 210,
        child: GestureDetector(
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
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: isActive
                  ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 3,
                  spreadRadius: 1,
                  offset: const Offset(2, 0),
                ),
              ]
                  : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 2,
                  spreadRadius: 1,
                  offset: const Offset(2, 0),
                ),
              ],
            ),
            child: Column(
              children: [
                // Product image
                Expanded(
                  flex: 2,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: product.imageColor ?? AppTheme.primaryColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Coffee cup image representation
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

                        // Bundle indicator if applicable
                        if (bundleText != null)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
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

                // Product details
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Product name
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            product.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),


                        // Discount price
                        Text(
                          formatCurrency(
                              product.discountPrice?.round() ?? 0),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.red[700],
                          ),
                        ),

                        // Description
                        Text(
                          product.description,
                          style: const TextStyle(
                            fontSize: 10,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Widget rating yang sudah diperbaiki
                        if (product.averageRating > 0)
                          _buildRatingWidget(product.averageRating),
                      ],
                    )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}