import 'package:baraja_app/pages/account_settings_page.dart';
import 'package:baraja_app/pages/favorit_page.dart';
import 'package:baraja_app/pages/notification_page.dart';
import 'package:baraja_app/providers/cart_provider.dart';
import 'package:baraja_app/screens/cart_screen.dart';
import 'package:baraja_app/screens/checkout_screen.dart';
import 'package:baraja_app/screens/menu_screen.dart';
import 'package:baraja_app/screens/product_detail_screen.dart';
import 'package:baraja_app/widgets/navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'data/product_data.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp( MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (context) => CartProvider()),
    ],
    child: const MyApp(),
  ),);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Coffee Shop App',
      theme: AppTheme.themeData,
      routerConfig: _router,
    );
  }
}

// Konfigurasi GoRouter
final GoRouter _router = GoRouter(
  routes: [
    // main routes
    GoRoute(
      path: '/',
      builder: (context, state) => const PersistentNavigationBar(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/menu',
      builder: (context, state) => const MenuScreen(),
    ),
    GoRoute(
      path: '/product/:id',
      builder: (context, state) {
        final productId = state.pathParameters['id']!;
        final product = ProductData.getProductById(productId);

        if (product == null) {
          return Scaffold(
            appBar: AppBar(title: const Text("Produk Tidak Ditemukan")),
            body: const Center(child: Text("Produk tidak ditemukan.")),
          );
        }

        return ProductDetailScreen(product: product);
      },
    ),

    // payment route
    GoRoute(
        path: '/cart',
        builder: (context, state) => const CartScreen(),
    ),
    GoRoute(
      path: '/checkout',
      builder: (context, state) => const CheckoutScreen(),
    ),

  //   profile routes
    GoRoute(
        path: '/favorite',
        builder: (context, state) => const FavoritePage(),
    ),
    GoRoute(
        path: '/notification',
        builder: (context, state) => const NotificationPage(),
    ),
    GoRoute(
        path: '/settings',
        builder: (context, state) => const AccountSettingsPage(),
    ),
  ],
  navigatorKey: GlobalKey<NavigatorState>(),
);
