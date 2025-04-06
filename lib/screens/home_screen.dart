import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/product_data.dart';
import '../services/auth_service.dart';
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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    await authService.fetchUserProfile();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final userData = authService.user;
    final coffeeProducts = ProductData.getProducts();

    return Scaffold(
      backgroundColor: AppTheme.whitePrimary.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.whitePrimary.scaffoldBackgroundColor,
        elevation: 0,
        title: Row(
          children: [
            Text(
              'Hai, ${userData?['username'] ?? 'User'}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.waving_hand, color: Colors.amber),
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
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
          onRefresh: () async {
            await _loadUserData();
          },
          child: ListView(
            children: [
              const PromoCarousel(),
              const SizedBox(height: 16),
              const ActionButtons(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 18.0),
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
