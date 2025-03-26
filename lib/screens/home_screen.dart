import 'package:baraja_app/widgets/checkout_button.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../data/product_data.dart';
import '../theme/app_theme.dart';
import '../widgets/product_slider.dart';
import '../widgets/promo_slider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final NumberFormat currencyFormatter =
    NumberFormat.currency(locale: 'id_ID', symbol: 'Rp.', decimalDigits: 0);
    final coffeeProducts = ProductData.getProducts();
    final promoItems = ProductData.getPromoItems();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Promo banner
              SizedBox(
                height: 200,
                child: PromoSlider(promoItems: promoItems),
              ),
              Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Positioned(
                    top: 65, // Naikkan ke atas
                    left: 0,
                    right: 0,
                    child: Container(
                      // padding: const EdgeInsets.symmetric(horizontal: 2),
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(10),
                          topRight: Radius.circular(10),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),

                  Container(
                    width: double.infinity,
                    // padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    padding: const EdgeInsets.only(left: 16, right: 30, top: 10, bottom: 10),
                    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 3,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Hai, Rilo',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Row(
                              children: [
                                const Text(
                                  'Point 200',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.amber[300],
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.star,
                                    color: AppTheme.primaryColor,
                                    size: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Container(
                          width: 1, // Lebar garis
                          height: 40, // Tinggi garis
                          color: Colors.white, // Warna garis
                          // margin: const EdgeInsets.symmetric(horizontal: 5), // Jarak antara teks dan garis
                        ),
                        InkWell(
                          onTap: () {
                            context.push('/menu');
                          },
                          child: const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.grid_view,
                                color: Colors.white,
                                size: 30,
                              ),
                              SizedBox(height: 2),
                              Text(
                                'All Menu',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
              Transform.translate(
                offset: const Offset(0, -10), // Geser ke atas 10 pixel
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(left: 2, right: 2, bottom: 10),
                  // margin: const EdgeInsets.only(left: 6, right: 6), // Hapus margin bottom
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 16,),
                      ProductSlider(
                        products: coffeeProducts,
                        currencyFormatter:currencyFormatter,
                        title: 'Untuk Kamu',
                      ),
                      const SizedBox(height: 16),
                      ProductSlider(
                        products: coffeeProducts,
                        title: 'Rekomendasi',
                        isBundle: true,
                        currencyFormatter: currencyFormatter,
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
      floatingActionButton: const CheckoutButton(),
    );
  }
}
