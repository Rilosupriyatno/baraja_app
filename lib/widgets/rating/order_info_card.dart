import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/currency_formatter.dart';

class OrderInfoCard extends StatelessWidget {
  final Map<String, dynamic> orderData;

  const OrderInfoCard({
    super.key,
    required this.orderData,
  });

  @override
  Widget build(BuildContext context) {
    final item = orderData['items']?[0] ?? {};

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Order Number
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.barajaPrimary.primaryColor.withOpacity(0.1),
                  AppTheme.barajaPrimary.primaryColor.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: AppTheme.barajaPrimary.primaryColor.withOpacity(0.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.receipt_outlined,
                  size: 14,
                  color: AppTheme.barajaPrimary.primaryColor,
                ),
                const SizedBox(width: 6),
                Text(
                  orderData['orderNumber']?.toString() ?? 'N/A',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.barajaPrimary.primaryColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Product Info
          Row(
            children: [
              // Product Image
              _buildProductImage(item),
              const SizedBox(width: 20),

              // Product Details
              Expanded(
                child: _buildProductDetails(item),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductImage(Map<String, dynamic> item) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: (item['imageUrl'] != null &&
            item['imageUrl'].toString().isNotEmpty &&
            item['imageUrl'] != 'https://placehold.co/1920x1080/png')
            ? Image.network(
          item['imageUrl'].toString(),
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
    );
  }

  Widget _buildProductDetails(Map<String, dynamic> item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item['name']?.toString() ?? 'Produk',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
            letterSpacing: -0.3,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                'x${item['quantity']?.toString() ?? '0'}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.black54,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                formatCurrency((item['price'] as num?) ?? 0),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.barajaPrimary.primaryColor,
                  letterSpacing: -0.3,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }
}