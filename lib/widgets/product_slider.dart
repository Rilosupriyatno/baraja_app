import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/product.dart';
import 'product_card.dart';

class ProductSlider extends StatefulWidget {
  final List<Product> products;
  final String title;
  final bool isBundle;
  final NumberFormat currencyFormatter;


  const ProductSlider({
    super.key,
    required this.products,
    required this.title,
    this.isBundle = false,
    required this.currencyFormatter,
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
          height: 210, // Keep height at 210
          child: PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.horizontal,
            itemCount: widget.products.length,
            padEnds: false,
            itemBuilder: (context, index) {
              int productIndex = widget.isBundle
                  ? widget.products.length - 1 - index
                  : index;

              bool isActive = index == _currentPage;

              return Padding(
                // padding: EdgeInsets.only(left: index == 0 ? 5.0 : 1.0, right: 0.0),
                padding: const EdgeInsets.symmetric(horizontal: 0.0),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(
                    horizontal: 4,
                    // vertical: isActive ? 0 : 15,
                  ),
                  width: 210, // Set width to 210 for square shape
                  child: ProductCard(
                    product: widget.products[productIndex],
                    isActive: isActive,
                    bundleText: widget.isBundle ? '2 Items' : null,
                      currencyFormatter: widget.currencyFormatter,
                    // currencyFormatter: null,
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