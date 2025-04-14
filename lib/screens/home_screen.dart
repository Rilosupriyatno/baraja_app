import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/product_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/detail_product/checkout_button.dart';
import '../widgets/home/action_button.dart';
import '../widgets/home/product_slider.dart';
import '../widgets/home/promo_carousel.dart';
import '../models/product.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;
  List<Product> _products = [];
  List<Product> _recommendedProducts = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.fetchUserProfile();

      // Dapatkan semua produk
      final products = await ProductService.fetchMenuItems();

      // Contoh untuk mendapatkan rekomendasi produk
      // Bisa dimodifikasi sesuai dengan kebutuhan bisnis Anda
      // Misalnya bisa menggunakan kategori tertentu dengan:
      // final recommended = await ProductService.getProductsByCategory('recommended');

      // Untuk sementara gunakan produk yang sama
      final recommended = List<Product>.from(products);

      if (mounted) {
        setState(() {
          _products = products;
          _recommendedProducts = recommended;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
        setState(() {
          _isLoading = false;
        });
      }
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
          onRefresh: _loadUserData,
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
                      products: _products,
                      title: 'Untuk Kamu',
                    ),
                    const SizedBox(height: 16),
                    ProductSlider(
                      products: _recommendedProducts,
                      title: 'Rekomendasi',
                      isBundle: true,
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