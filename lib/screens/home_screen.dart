import 'package:flutter/material.dart';

import '../data/product_data.dart';
import '../theme/app_theme.dart';
import '../widgets/detail_product/checkout_button.dart';
import '../widgets/home/action_button.dart';
import '../widgets/home/product_slider.dart';
import '../widgets/home/promo_carousel.dart';
import '../utils/currency_formatter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final coffeeProducts = ProductData.getProducts();
    // final promoItems = ProductData.getPromoItems();

    return Scaffold(
      backgroundColor: AppTheme.whitePrimary.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.whitePrimary.scaffoldBackgroundColor,
        title: const Row(
          children: [
            Text(
              'Hai, Rilo',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.waving_hand, color: Colors.amber),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            color: Colors.black,
            onPressed: () {},
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await Future.delayed(const Duration(seconds: 1));
            // Bisa diganti dengan fungsi fetch data dari API atau DB
          },
          child: ListView(
            // padding: const EdgeInsets.only(bottom: 100),
            children: [
              // Promo Carousel
              const PromoCarousel(),

              const Padding(padding: EdgeInsets.all(16.0)),

              // Action Buttons
              const ActionButtons(),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 18.0), // ⬅️ Tambahkan jarak kanan kiri
                child: Column(
                  children: [
                    ProductSlider(
                      products: coffeeProducts,
                      formatPrice: formatCurrency,
                      title: 'Untuk Kamu',
                    ),
                    const SizedBox(height: 16),
                    ProductSlider(
                      products: coffeeProducts,
                      title: 'Rekomendasi',
                      isBundle: true,
                      formatPrice: formatCurrency,
                    ),
                  ],
                ),
              ),

            ],
          ),
        ),
      ),
      floatingActionButton: const CheckoutButton(),
    );
  }
}
