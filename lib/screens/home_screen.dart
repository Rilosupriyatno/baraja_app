// home_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../services/product_service.dart';
import '../services/auth_service.dart';
import '../services/notification_count_service.dart'; // Import NotificationCountService
import '../theme/app_theme.dart';
import '../widgets/detail_product/checkout_button.dart';
import '../widgets/home/action_button.dart';
import '../widgets/home/product_slider.dart';
import '../widgets/home/promo_carousel.dart';
import '../widgets/common/notification_badge.dart'; // Import NotificationBadge
import '../utils/currency_formatter.dart';
import '../models/product.dart';

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
      final authService = Provider.of<AuthService>(context, listen: false);
      final notificationCountService = Provider.of<NotificationCountService>(context, listen: false);
      final productService = ProductService();

      // Get user ID
      final userId = authService.user?['_id'];

      await Future.wait([
        authService.fetchUserProfile(),
        _fetchProducts(productService),
        if (userId != null) notificationCountService.fetchUnreadCount(userId),
      ]);
    } catch (e) {
      print('Failed to load data: $e');
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

  Widget _buildNotificationIcon() {
    return Consumer<NotificationCountService>(
      builder: (context, notificationService, child) {
        return NotificationBadge(
          count: notificationService.unreadCount,
          child: IconButton(
            icon: const Icon(Icons.notifications),
            color: Colors.amber,
            onPressed: () async {
              final authService = Provider.of<AuthService>(context, listen: false);
              final userId = authService.user?['_id'];

              if (userId != null) {
                await context.push('/notification', extra: {'userId': userId});

                // Refresh notification count after returning from notification page
                notificationService.fetchUnreadCount(userId);
              }
            },
          ),
        );
      },
    );
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
          _buildNotificationIcon(),
          const SizedBox(width: 16),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          children: [
            const PromoCarousel(),
            const SizedBox(height: 16),
            const ActionButtons(),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 4.0, vertical: 18.0),
              child: Column(
                children: [
                  ProductSlider(
                    products: _discountedProducts.isNotEmpty
                        ? _discountedProducts
                        : _products,
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
      floatingActionButton: const CheckoutButton(),
    );
  }
}