import 'package:flutter/material.dart';
import 'package:baraja_app/models/product.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../utils/currency_formatter.dart'; // Import fungsi formatCurrency

class ProductCard extends StatelessWidget {
  final Product product;
  final bool isActive;
  final String? bundleText;

  // Removed the NumberFormat parameter as we're now using formatCurrency directly
  const ProductCard({
    super.key,
    required this.product,
    this.isActive = false,
    this.bundleText,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0.0),
      child: SizedBox(
        width: 210, // Set width to 210 for square shape
        height: 210, // Set height to 210 for square shape
        child: GestureDetector(
          onTap: () {
            context.push('/product/${product.id}');
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
                  offset: const Offset(2, 0), // Bayangan ke kanan
                ),
              ]
                  : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 2,
                  spreadRadius: 1,
                  offset: const Offset(2, 0), // Bayangan ke kanan
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

                        // Bundle indicator if applicable
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
                        Text(
                          product.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                        // Original price
                        // Text(
                        //   formatCurrency(product.originalPrice?.round() ?? 0)
                        //   , // Changed to use formatCurrency directly
                        //   style: const TextStyle(
                        //     fontSize: 12,
                        //     decoration: TextDecoration.lineThrough,
                        //   ),
                        // ),

                        // Discount price
                        Text(
                          formatCurrency(product.discountPrice?.round() ?? 0), // Changed to use formatCurrency directly
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