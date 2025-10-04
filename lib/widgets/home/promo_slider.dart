import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../models/promo_item.dart';

class PromoSlider extends StatefulWidget {
  final List<PromoItem> promoItems;
  final bool isLoading;

  const PromoSlider({
    super.key,
    required this.promoItems,
    this.isLoading = false,
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
    _autoSlide();
  }

  void _autoSlide() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && widget.promoItems.isNotEmpty) {
        final next = (currentPromoIndex + 1) % widget.promoItems.length;
        _pageController.animateToPage(
          next,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
        _autoSlide();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildSkeletonSlider() {
    return Container(
      height: 200,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(15),
          bottomRight: Radius.circular(15),
        ),
      ),
    );
  }

  Widget _buildSlider() {
    if (widget.promoItems.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('No promos available')),
      );
    }

    return Column(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(15),
            bottomRight: Radius.circular(15),
          ),
          child: SizedBox(
            height: 200,
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.promoItems.length,
              onPageChanged: (i) => setState(() => currentPromoIndex = i),
              itemBuilder: (_, i) {
                final promo = widget.promoItems[i];
                final url = promo.imageUrls.isNotEmpty
                    ? promo.imageUrls.first
                    : null;
                return url != null
                    ? Image.network(
                  url,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey,
                    child: const Icon(Icons.broken_image),
                  ),
                )
                    : Container(
                  color: Colors.grey,
                  child: const Icon(Icons.image_not_supported),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            widget.promoItems.length,
                (i) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: currentPromoIndex == i ? 10 : 8,
              height: currentPromoIndex == i ? 10 : 8,
              decoration: BoxDecoration(
                color: currentPromoIndex == i
                    ? Theme.of(context).primaryColor
                    : Colors.grey,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: widget.isLoading,
      child: widget.isLoading ? _buildSkeletonSlider() : _buildSlider(),
    );
  }
}
