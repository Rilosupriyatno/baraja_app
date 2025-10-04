import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'dart:async';
import '../../models/promo_item.dart';
import '../../services/promo_service.dart';

class PromoCarousel extends StatefulWidget {
  const PromoCarousel({super.key});

  @override
  State<PromoCarousel> createState() => _PromoCarouselState();
}

class _PromoCarouselState extends State<PromoCarousel> {
  final CarouselSliderController _promoController = CarouselSliderController();
  int _currentPromoIndex = 0;
  Timer? _timer;
  List<PromoItem> promos = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPromos();
  }

  Future<void> _fetchPromos() async {
    final data = await PromoService.fetchPromos();
    if (!mounted) return;
    setState(() {
      promos = data;
      isLoading = false;
    });

    if (promos.isNotEmpty) {
      _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
        if (_currentPromoIndex < promos.length - 1) {
          _currentPromoIndex++;
        } else {
          _currentPromoIndex = 0;
        }
        _promoController.animateToPage(_currentPromoIndex);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Widget _buildSkeletonCarousel() {
    return SizedBox(
      height: 150,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: MediaQuery.of(context).size.width * 0.9,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildCarousel() {
    if (promos.isEmpty) {
      return const SizedBox(
        height: 150,
        child: Center(child: Text('No promos available')),
      );
    }

    return Column(
      children: [
        CarouselSlider.builder(
          carouselController: _promoController,
          itemCount: promos.length,
          itemBuilder: (context, index, realIndex) {
            final imageUrl = promos[index].imageUrls.isNotEmpty
                ? promos[index].imageUrls.first
                : null;

            return ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: imageUrl != null
                  ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: 150,
                errorBuilder: (_, __, ___) =>
                const Icon(Icons.broken_image, color: Colors.grey),
              )
                  : Container(
                color: Colors.grey,
                height: 150,
                child: const Center(
                  child: Icon(Icons.image_not_supported),
                ),
              ),
            );
          },
          options: CarouselOptions(
            height: 150,
            viewportFraction: 0.95,
            enlargeCenterPage: true,
            onPageChanged: (i, _) => setState(() => _currentPromoIndex = i),
          ),
        ),
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

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: isLoading,
      child: isLoading ? _buildSkeletonCarousel() : _buildCarousel(),
    );
  }
}
