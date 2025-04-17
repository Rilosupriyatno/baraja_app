// home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/product_service.dart'; // Import ProductService
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/detail_product/checkout_button.dart';
import '../widgets/home/action_button.dart';
import '../widgets/home/product_slider.dart';
import '../widgets/home/promo_carousel.dart';
import '../utils/currency_formatter.dart';
import '../models/product.dart'; // Import Product model

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;
  List<Product> _products = [];
  List<Product> _discountedProducts = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load user data and products in parallel
      final authService = Provider.of<AuthService>(context, listen: false);
      final productService = ProductService();

      await Future.wait([
        authService.fetchUserProfile(),
        _fetchProducts(productService),
      ]);
    } catch (e) {
      // Handle error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load data: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchProducts(ProductService productService) async {
    try {
      final products = await productService.getProducts();
      print(products);
      final discountedProducts = await productService.getDiscountedProducts();

      if (mounted) {
        setState(() {
          _products = products;
          _discountedProducts = discountedProducts;
        });
      }
    } catch (e) {
      throw Exception('Failed to fetch products: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final userData = authService.user;

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
          onRefresh: _loadData,
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
                      products: _discountedProducts.isNotEmpty ? _discountedProducts : _products,
                      formatPrice: formatCurrency,
                      title: 'Untuk Kamu',
                    ),
                    const SizedBox(height: 16),
                    ProductSlider(
                      products: _products,
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