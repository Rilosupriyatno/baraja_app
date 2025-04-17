// product_slider.dart
import 'package:flutter/material.dart';
import 'package:baraja_app/widgets/home/product_card.dart';
import '../../models/product.dart';

class ProductSlider extends StatefulWidget {
  final List<Product> products;
  final String title;
  final bool isBundle;
  final Function(int) formatPrice;

  const ProductSlider({
    super.key,
    required this.products,
    required this.title,
    this.isBundle = false,
    required this.formatPrice,
  });

  @override
  State<ProductSlider> createState() => _ProductSliderState();
}

class _ProductSliderState extends State<ProductSlider> {
  final PageController _pageController = PageController(viewportFraction: 0.4);
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      int? next = _pageController.page!.round();
      if (_currentPage != next) {
        setState(() {
          _currentPage = next;
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.products.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 1.0),
            child: Text(
              widget.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 10),
          const SizedBox(
            height: 210,
            child: Center(
              child: Text("No products available"),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 1.0),
          child: Text(
            widget.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 210,
          child: PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.horizontal,
            itemCount: widget.products.length,
            padEnds: false,
            itemBuilder: (context, index) {
              int productIndex = widget.isBundle
                  ? widget.products.length - 1 - index
                  : index;

              // Check to prevent index out of bounds
              if (productIndex < 0 || productIndex >= widget.products.length) {
                return const SizedBox.shrink();
              }

              bool isActive = index == _currentPage;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0.0),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 4
                  ),
                  width: 210,
                  child: ProductCard(
                    product: widget.products[productIndex],
                    isActive: isActive,
                    bundleText: widget.isBundle ? '2 Items' : null,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}