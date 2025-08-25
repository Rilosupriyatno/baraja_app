import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';
import '../services/favorite_service.dart';
import '../utils/currency_formatter.dart';
import 'add_order_page.dart';

class ProductDetailModal extends StatefulWidget {
  final Product product;

  const ProductDetailModal({super.key, required this.product});

  @override
  ProductDetailModalState createState() => ProductDetailModalState();

  // Static method untuk menampilkan modal
  static void show(BuildContext context, Product product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProductDetailModal(product: product),
    );
  }
}

class ProductDetailModalState extends State<ProductDetailModal> {
  final Color primaryColor = const Color(0xFF076A3B);
  final FavoriteService favoriteService = FavoriteService();

  bool isFavorite = false;
  bool isToggling = false;

  @override
  void initState() {
    super.initState();
    _loadFavoriteStatusInstant();
  }

  // Method untuk load status favorit dengan cache dan instant UI
  void _loadFavoriteStatusInstant() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString('userId');

      if (userId == null || userId.isEmpty) {
        print("⚠️ User ID belum ada, tidak bisa cek status favorit");
        return;
      }

      // 1. Cek cache dulu (instant)
      final cachedFavorites = prefs.getStringList('cached_favorites_$userId') ?? [];
      bool isCached = cachedFavorites.contains(widget.product.id);

      // Update UI instant dari cache
      if (mounted) {
        setState(() {
          isFavorite = isCached;
        });
      }

      // 2. Background sync dengan backend untuk update cache
      _syncFavoritesInBackground(userId);

    } catch (e) {
      print("Error loading favorite status: $e");
    }
  }

  // Background sync tanpa ganggu UI
  void _syncFavoritesInBackground(String userId) async {
    try {
      final favorites = await favoriteService.getFavorites(userId);
      final favoriteIds = favorites.map((fav) => fav['_id'].toString()).toList();

      // Update cache
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('cached_favorites_$userId', favoriteIds);

      // Update UI jika ada perubahan
      bool actualFavoriteStatus = favoriteIds.contains(widget.product.id);
      if (mounted && actualFavoriteStatus != isFavorite) {
        setState(() {
          isFavorite = actualFavoriteStatus;
        });
      }
    } catch (e) {
      print("Error syncing favorites: $e");
    }
  }

  void toggleFavorite() async {
    final prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');
    final menuItemId = widget.product.id;

    if (userId == null || userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan login terlebih dahulu'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Optimistic UI update - langsung update tampilan dulu
    final newFavoriteState = !isFavorite;
    setState(() {
      isFavorite = newFavoriteState;
      isToggling = true;
    });

    // Update cache langsung
    final cachedFavorites = prefs.getStringList('cached_favorites_$userId') ?? [];
    if (newFavoriteState) {
      if (!cachedFavorites.contains(menuItemId)) {
        cachedFavorites.add(menuItemId);
      }
    } else {
      cachedFavorites.remove(menuItemId);
    }
    await prefs.setStringList('cached_favorites_$userId', cachedFavorites);

    try {
      bool success;
      if (newFavoriteState) {
        success = await favoriteService.addFavorite(userId, menuItemId);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ditambahkan ke favorit'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 1),
            ),
          );
        }
      } else {
        success = await favoriteService.removeFavorite(userId, menuItemId);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Dihapus dari favorit'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 1),
            ),
          );
        }
      }

      // Jika gagal, kembalikan state dan cache ke semula
      if (!success) {
        setState(() {
          isFavorite = !newFavoriteState;
        });

        // Rollback cache
        final rollbackFavorites = prefs.getStringList('cached_favorites_$userId') ?? [];
        if (!newFavoriteState) {
          if (!rollbackFavorites.contains(menuItemId)) {
            rollbackFavorites.add(menuItemId);
          }
        } else {
          rollbackFavorites.remove(menuItemId);
        }
        await prefs.setStringList('cached_favorites_$userId', rollbackFavorites);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Terjadi kesalahan, coba lagi'),
            backgroundColor: Colors.red,
          ),
        );
      }

    } catch (e) {
      print("Error toggling favorite: $e");
      // Kembalikan state dan cache jika ada error
      setState(() {
        isFavorite = !newFavoriteState;
      });

      // Rollback cache
      final rollbackFavorites = prefs.getStringList('cached_favorites_$userId') ?? [];
      if (!newFavoriteState) {
        if (!rollbackFavorites.contains(menuItemId)) {
          rollbackFavorites.add(menuItemId);
        }
      } else {
        rollbackFavorites.remove(menuItemId);
      }
      await prefs.setStringList('cached_favorites_$userId', rollbackFavorites);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Terjadi kesalahan, coba lagi'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isToggling = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Product product = widget.product;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header with close button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Detail Produk',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  iconSize: 24,
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product image
                  Container(
                    height: 200,
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: product.imageColor ?? Colors.grey.shade300,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: product.imageUrl.isNotEmpty &&
                        product.imageUrl != 'https://placehold.co/1920x1080/png'
                        ? Image.network(
                      product.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Image.asset(
                          'assets/images/product_default_image.jpeg',
                          fit: BoxFit.cover,
                        );
                      },
                    )
                        : Image.asset(
                      'assets/images/product_default_image.jpeg',
                      fit: BoxFit.cover,
                    ),
                  ),

                  // Product information
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                product.name,
                                style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold
                                ),
                              ),
                            ),
                            // Favorite button tanpa loading UI yang mengganggu
                            IconButton(
                              icon: Icon(
                                isFavorite ? Icons.favorite : Icons.favorite_border,
                                color: Colors.red,
                              ),
                              onPressed: isToggling ? null : toggleFavorite,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              formatCurrency((product.discountPrice ??
                                  product.originalPrice ??
                                  0)
                                  .toInt()),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (product.discountPercentage != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '-${product.discountPercentage}%',
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          product.description,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom navigation bar - hanya tombol tambah pesanan
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        'Mulai dari: ',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        formatCurrency((product.discountPrice ??
                            product.originalPrice ??
                            0)
                            .toInt()),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context); // Close modal first
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddOrderPage(product: product),
                          ),
                        );
                      },
                      child: const Text(
                        'Tambah Pesanan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}