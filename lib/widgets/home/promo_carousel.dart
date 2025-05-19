import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'dart:async';
import '../../data/product_data.dart';

class PromoCarousel extends StatefulWidget {
  const PromoCarousel({super.key});

  @override
  State<PromoCarousel> createState() => _PromoCarouselState();
}

class _PromoCarouselState extends State<PromoCarousel> {
  final CarouselSliderController _promoController = CarouselSliderController();
  int _currentPromoIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Set up auto sliding for promo carousel setiap 5 detik
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_currentPromoIndex < ProductData.getPromoItems().length - 1) {
        _currentPromoIndex++;
      } else {
        _currentPromoIndex = 0;
      }
      _promoController.animateToPage(_currentPromoIndex);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final promos = ProductData.getPromoItems();

    return Column(
      children: [
        CarouselSlider.builder(
          carouselController: _promoController,
          itemCount: promos.length,
          itemBuilder: (context, index, realIndex) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                promos[index].imagePath, // Ganti dengan Image.asset jika lokal
                fit: BoxFit.cover,
                width: double.infinity,
                height: 150, // Ukuran sama seperti sebelumnya
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey,
                  child: const Center(
                    child: Icon(Icons.broken_image, color: Colors.white),
                  ),
                ),
              ),
            );
          },
          options: CarouselOptions(
            height: 150,
            viewportFraction: 0.95,
            enlargeCenterPage: true,
            enableInfiniteScroll: true,
            onPageChanged: (index, reason) {
              setState(() {
                _currentPromoIndex = index;
              });
            },
          ),
        ),

        // CarouselSlider.builder(
        //   carouselController: _promoController,
        //   itemCount: promos.length,
        //   itemBuilder: (context, index, realIndex) {
        //     return Container(
        //       // margin: const EdgeInsets.all(2.0),
        //       decoration: BoxDecoration(
        //         color: promos[index].color,
        //         borderRadius: BorderRadius.circular(12),
        //       ),
        //       child: Center(
        //         child: Padding(
        //           padding: const EdgeInsets.all(16.0),
        //           child: SingleChildScrollView(
        //             physics: const NeverScrollableScrollPhysics(),
        //             child: Column(
        //               mainAxisSize: MainAxisSize.min,
        //               mainAxisAlignment: MainAxisAlignment.center,
        //               children: [
        //                 if (index == 0) ... [
        //                   const Text(
        //                     'Special Offer',
        //                     style: TextStyle(
        //                       color: Colors.white,
        //                       fontSize: 16,
        //                     ),
        //                   ),
        //                   const SizedBox(height: 8),
        //                   const Text(
        //                     'Buy 1 Get 1',
        //                     style: TextStyle(
        //                       color: Colors.white,
        //                       fontSize: 22,
        //                       fontWeight: FontWeight.bold,
        //                     ),
        //                   ),
        //                   const SizedBox(height: 4),
        //                   const Text(
        //                     'Valid until 31 Jan 2025',
        //                     style: TextStyle(
        //                       color: Colors.white,
        //                       fontSize: 12,
        //                     ),
        //                   ),
        //                 ] else ... [
        //                   Text(
        //                     promos[index].title,
        //                     style: const TextStyle(
        //                       color: Colors.white,
        //                       fontSize: 20,
        //                       fontWeight: FontWeight.bold,
        //                     ),
        //                   ),
        //                 ]
        //               ],
        //             ),
        //           ),
        //         ),
        //       ),
        //     );
        //   },
        //   options: CarouselOptions(
        //     height: 150,
        //     viewportFraction: 0.95,
        //     enlargeCenterPage: true,
        //     enableInfiniteScroll: true,
        //     onPageChanged: (index, reason) {
        //       setState(() {
        //         _currentPromoIndex = index;
        //       });
        //     },
        //   ),
        // ),
        const SizedBox(height: 8),
        AnimatedSmoothIndicator(
          activeIndex: _currentPromoIndex,
          count: promos.length,
          effect: WormEffect(
            dotWidth: 8,
            dotHeight: 8,
            activeDotColor: Theme.of(context).primaryColor,
            dotColor: Colors.grey.shade300,
          ),
        ),
      ],
    );
  }
}