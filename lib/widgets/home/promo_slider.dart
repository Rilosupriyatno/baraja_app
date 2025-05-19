import 'package:flutter/material.dart';
import 'package:baraja_app/models/product.dart';

class PromoSlider extends StatefulWidget {
  final List<PromoItem> promoItems;

  const PromoSlider({
    super.key,
    required this.promoItems,
  });

  @override
  State<PromoSlider> createState() => _PromoSliderState();
}

class _PromoSliderState extends State<PromoSlider> {
  int currentPromoIndex = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _startPromoAutoSlider();
  }

  void _startPromoAutoSlider() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        int nextPage = (currentPromoIndex + 1) % widget.promoItems.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
        // Don't call setState here - the onPageChanged callback will handle it
        _startPromoAutoSlider();
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
      mainAxisSize: MainAxisSize.min,
      children: [
        // Container tetap - tidak bergerak
        Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            // Warna background default jika diinginkan
            color: Colors.grey[200],
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(15),
              bottomRight: Radius.circular(15),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          // Stack untuk menempatkan PageView di atas container tetap
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(15),
              bottomRight: Radius.circular(15),
            ),
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.promoItems.length,
              onPageChanged: (index) {
                setState(() {
                  currentPromoIndex = index;
                });
              },
              itemBuilder: (context, index) {
                return ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(15),
                    bottomRight: Radius.circular(15),
                  ),
                  child: Image.asset(
                    widget.promoItems[index].imagePath,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 200,
                  ),
                );
              },
            ),

            // child: PageView.builder(
            //   controller: _pageController,
            //   itemCount: widget.promoItems.length,
            //   onPageChanged: (index) {
            //     setState(() {
            //       currentPromoIndex = index;
            //     });
            //   },
            //   itemBuilder: (context, index) {
            //     return Container(
            //       color: widget.promoItems[index].color,
            //       alignment: Alignment.center,
            //       child: Row(
            //         mainAxisAlignment: MainAxisAlignment.center,
            //         children: [
            //           const Icon(
            //             Icons.coffee,
            //             color: Colors.white,
            //             size: 36,
            //           ),
            //           const SizedBox(width: 10),
            //           Text(
            //             widget.promoItems[index].title,
            //             style: const TextStyle(
            //               color: Colors.white,
            //               fontSize: 22,
            //               fontWeight: FontWeight.bold,
            //             ),
            //           ),
            //         ],
            //       ),
            //     );
            //   },
            ),
          ),

      ],
    );
  }
}