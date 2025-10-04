// home_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../services/product_service.dart';
import '../services/auth_service.dart';
import '../services/notification_count_service.dart';
import '../theme/app_theme.dart';
import '../widgets/detail_product/checkout_button.dart';
import '../widgets/home/action_button.dart';
import '../widgets/home/product_slider.dart';
import '../widgets/home/promo_carousel.dart';
import '../widgets/common/notification_badge.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final authService = Provider.of<AuthService>(context, listen: false);
    final notificationCountService =
    Provider.of<NotificationCountService>(context, listen: false);
    final productService = ProductService();

    try {
      // Load semua data
      final products = await productService.getProducts();

      // Load profil & notifikasi
      await authService.fetchUserProfile();
      final userId = authService.user?['_id'];
      if (userId != null) {
        await notificationCountService.fetchUnreadCount(userId);
      }

      if (mounted) {
        setState(() {
          _products = products;
          _discountedProducts =
              products.where((p) => p.discountPercentage != null).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Failed to load data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Dummy data untuk skeleton
  List<Product> _getDummyProducts() {
    return List.generate(
      3,
          (index) => Product(
        id: 'dummy_$index',
        name: 'Loading Product Name',
        category: 'Loading',
        mainCategory: 'Loading',
        subCategory: 'Loading',
        imageUrl: '',
        originalPrice: 50000.0,
        discountPrice: 45000.0,
        description: 'Loading description text here',
        discountPercentage: '10%',
        toppings: [],
        addons: [],
        averageRating: 4.5,
        reviewCount: 100,
        availableAt: [
          Outlet(
            outletId: 'dummy_outlet',
            name: 'Loading Outlet',
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonAppBar() {
    return AppBar(
      backgroundColor: AppTheme.whitePrimary.scaffoldBackgroundColor,
      elevation: 0,
      title: Row(
        children: [
          Skeletonizer(
            enabled: true,
            child: Container(
              width: 120,
              height: 18,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.waving_hand, color: Colors.grey),
        ],
      ),
      actions: [
        Skeletonizer(
          enabled: true,
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildRealAppBar() {
    final authService = Provider.of<AuthService>(context);
    final userData = authService.user;

    return AppBar(
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
        Consumer<NotificationCountService>(
          builder: (context, notificationService, child) {
            return NotificationBadge(
              count: notificationService.unreadCount,
              child: IconButton(
                icon: const Icon(Icons.notifications),
                color: Colors.amber,
                onPressed: () async {
                  final authService =
                  Provider.of<AuthService>(context, listen: false);
                  final userId = authService.user?['_id'];

                  if (userId != null) {
                    await context.push('/notification', extra: {'userId': userId});
                    notificationService.fetchUnreadCount(userId);
                  }
                },
              ),
            );
          },
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildSkeletonPromoCarousel() {
    return Skeletonizer(
      enabled: true,
      child: Container(
        height: 166, // 150 + 8 + 8 (tinggi carousel + spacing + indicator)
        margin: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          children: [
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                3,
                    (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Skeletonizer(
        enabled: true,
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonSectionTitle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 1.0),
      child: Skeletonizer(
        enabled: true,
        child: Container(
          width: 120,
          height: 20,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.whitePrimary.scaffoldBackgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: _isLoading ? _buildSkeletonAppBar() : _buildRealAppBar(),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          children: [
            // Promo Carousel
            _isLoading ? _buildSkeletonPromoCarousel() : const PromoCarousel(),

            const SizedBox(height: 16),

            // Action Buttons
            _isLoading ? _buildSkeletonActionButtons() : const ActionButtons(),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 18.0),
              child: Column(
                children: [
                  // Section: Untuk Kamu
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_isLoading) _buildSkeletonSectionTitle(),
                      const SizedBox(height: 10),
                      Skeletonizer(
                        enabled: _isLoading,
                        enableSwitchAnimation: true,
                        child: ProductSlider(
                          products: _isLoading
                              ? _getDummyProducts()
                              : (_discountedProducts.isNotEmpty
                              ? _discountedProducts
                              : _products),
                          formatPrice: formatCurrency,
                          title: _isLoading ? '' : 'Untuk Kamu',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Section: Rekomendasi
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_isLoading) _buildSkeletonSectionTitle(),
                      const SizedBox(height: 10),
                      Skeletonizer(
                        enabled: _isLoading,
                        enableSwitchAnimation: true,
                        child: ProductSlider(
                          products: _isLoading ? _getDummyProducts() : _products,
                          title: _isLoading ? '' : 'Rekomendasi',
                          isBundle: true,
                          formatPrice: formatCurrency,
                        ),
                      ),
                    ],
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