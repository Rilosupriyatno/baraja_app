import 'package:flutter/material.dart';
import 'package:baraja_amphitheater_app/models/product.dart';
import '../../utils/currency_formatter.dart';
import '../../screens/product_detail_modal.dart';

class ProductCard extends StatefulWidget {
  final Product product;
  final bool isActive;
  final String? bundleText;

  const ProductCard({
    super.key,
    required this.product,
    this.isActive = false,
    this.bundleText,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _imageLoaded = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    // Reset state saat widget pertama kali dibuat
    _imageLoaded = false;
    _hasError = false;
  }

  @override
  void didUpdateWidget(ProductCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset jika product berubah
    if (oldWidget.product.id != widget.product.id) {
      setState(() {
        _imageLoaded = false;
        _hasError = false;
      });
    }
  }

  Widget _buildRatingWidget(double rating) {
    List<Widget> stars = [];

    for (int i = 1; i <= 5; i++) {
      if (i <= rating.floor()) {
        stars.add(const Icon(
          Icons.star,
          color: Colors.amber,
          size: 16,
        ));
      } else if (i == rating.floor() + 1 && rating % 1 != 0) {
        stars.add(const Icon(
          Icons.star_half,
          color: Colors.amber,
          size: 16,
        ));
      } else {
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

  Widget _buildShimmerSkeleton() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.grey[300]!,
                Colors.grey[100]!.withOpacity(value),
                Colors.grey[300]!,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          child: Center(
            child: Icon(
              Icons.image_outlined,
              size: 40,
              color: Colors.grey[400],
            ),
          ),
        );
      },
      onEnd: () {
        // Loop animation hanya jika gambar belum loaded
        if (mounted && !_imageLoaded && !_hasError) {
          setState(() {});
        }
      },
    );
  }

  Widget _buildImageContent() {
    final hasValidUrl = widget.product.imageUrl.isNotEmpty &&
        widget.product.imageUrl != 'https://placehold.co/1920x1080/png';

    // Jika tidak ada URL atau sudah error, langsung tampilkan placeholder
    if (!hasValidUrl || _hasError) {
      return Image.asset(
        'assets/images/product_default_image.png',
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }

    // Ada URL valid, tampilkan dengan skeleton
    return Stack(
      fit: StackFit.expand,
      children: [
        // Layer 1: Skeleton (tampil sampai image loaded)
        if (!_imageLoaded) _buildShimmerSkeleton(),

        // Layer 2: Actual Image
        AnimatedOpacity(
          opacity: _imageLoaded ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: Image.network(
            widget.product.imageUrl,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            // Tambahkan cache headers
            headers: const {
              'Cache-Control': 'max-age=3600',
            },
            loadingBuilder: (context, child, loadingProgress) {
              // Jika loadingProgress == null, artinya gambar sudah selesai load
              if (loadingProgress == null) {
                // Tandai sebagai loaded setelah frame berikutnya
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && !_imageLoaded) {
                    setState(() {
                      _imageLoaded = true;
                    });
                  }
                });
                return child;
              }

              // Masih loading - return empty (skeleton di bawah akan tampil)
              return const SizedBox.shrink();
            },
            errorBuilder: (context, error, stackTrace) {
              print('❌ Image load error for ${widget.product.name}: $error');

              // Tandai error dan tampilkan placeholder
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && !_hasError) {
                  setState(() {
                    _hasError = true;
                  });
                }
              });

              return Image.asset(
                'assets/images/product_default_image.png',
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              );
            },
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
            print('Product card tapped: ${widget.product.name}');
            try {
              ProductDetailModal.show(context, widget.product);
            } catch (e) {
              print('Error showing modal: $e');
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(widget.product.name),
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
              boxShadow: widget.isActive
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
                // Product image with persistent skeleton
                Expanded(
                  flex: 2,
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Image dengan skeleton
                        _buildImageContent(),

                        // Bundle indicator
                        if (widget.bundleText != null)
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
                                widget.bundleText!,
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
                            widget.product.name,
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
                              widget.product.discountPrice?.round() ?? 0),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.red[700],
                          ),
                        ),

                        // Description
                        Text(
                          widget.product.description,
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
                            if (widget.product.averageRating > 0)
                              _buildRatingWidget(widget.product.averageRating),
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