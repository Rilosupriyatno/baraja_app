import 'package:baraja_app/providers/cart_provider.dart';
import 'package:baraja_app/screens/cart_page.dart';
import 'package:baraja_app/screens/menu_page.dart';
import 'package:baraja_app/screens/product_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'data/product_data.dart';
import 'screens/home_page.dart';
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
    GoRoute(
      path: '/',
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: '/menu',
      builder: (context, state) => const MenuPage(),
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
    GoRoute(
        path: '/cart',
        builder: (context, state) => const CartPage(),
    )
  ],
  navigatorKey: GlobalKey<NavigatorState>(),
);
