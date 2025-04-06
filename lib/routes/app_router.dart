import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/product_data.dart';
import '../models/cart_item.dart';
import '../models/order_type.dart';
import '../pages/account_settings_page.dart';
import '../pages/favorit_page.dart';
import '../pages/notification_page.dart';
import '../screens/cart_screen.dart';
import '../screens/checkout_page.dart';
import '../screens/menu_screen.dart';
import '../screens/order_history_screen.dart';
import '../screens/order_success_screen.dart';
import '../screens/order_tracking_screen.dart';
import '../screens/payment_confirmation_screen.dart';
import '../screens/payment_method_screen.dart';
import '../screens/product_detail_screen.dart';
import '../screens/register_screen.dart';
import '../screens/voucher_screen.dart';
import '../widgets/utils/navigation_bar.dart';

class AppRouter {
  static GoRouter getRouter() {
    return GoRouter(
      initialLocation: '/',
      routes: [
        // Existing routes (home, cart, etc.)


        // auth routes
        GoRoute(
          path: '/',
          builder: (context, state) => const MainNavigationBar(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen(),
        ),



        // main routes
        GoRoute(
          path: '/main',
          builder: (context, state) => const MainNavigationBar(),
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
        GoRoute(
          path: '/cart',
          builder: (context, state) => const CartScreen(),
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



        // Checkout page
        GoRoute(
          path: '/checkout',
          builder: (context, state) => const CheckoutPage(),
        ),

        // Payment method selection page
        GoRoute(
          path: '/paymentMethod',
          builder: (context, state) => const PaymentMethodScreen(),
        ),

        GoRoute(
          path: '/voucher',
          builder: (context, state) {
            // Ambil parameter dari GoRouter
            final appliedVoucherCode = state.extra as String?;
            return VoucherScreen(appliedVoucherCode: appliedVoucherCode);
          },
        ),



        // Payment confirmation page
        GoRoute(
          path: '/paymentConfirmation',
          builder: (context, state) {
            final Map<String, dynamic> extras = state.extra as Map<String, dynamic>;

            return PaymentConfirmationScreen(
              items: extras['items'] as List<CartItem>,
              orderType: extras['orderType'] as OrderType,
              tableNumber: extras['tableNumber'] as String,
              deliveryAddress: extras['deliveryAddress'] as String,
              pickupTime: extras['pickupTime'] as TimeOfDay?,
              paymentMethod: extras['paymentMethod'] as String,
              subtotal: extras['subtotal'] as int,
              discount: extras['discount'] as int,
              total: extras['total'] as int,
              voucherCode: extras['voucherCode'] as String?,
            );
          },
        ),

        // Order success page
        // GoRoute(
        //   path: '/orderSuccess',
        //   builder: (context, state) {
        //     final String orderId = state.extra as String;
        //     return OrderSuccessScreen(orderId: orderId);
        //   },
        // ),
        GoRoute(
          path: '/orderSuccess',
          builder: (context, state) {
            final orderId = state.uri.queryParameters['id'] ?? '';
            return OrderSuccessScreen(orderId: orderId);
          },
        ),

        // Order tracking page
        GoRoute(
          path: '/tracking',
          builder: (context, state) {
            final String orderId = state.extra as String;
            return OrderTrackingScreen(orderId: orderId);
          },
        ),

        // Order history page
        GoRoute(
          path: '/history',
          builder: (context, state) => const OrderHistoryScreen(),
        ),
      ],
      navigatorKey: GlobalKey<NavigatorState>(),
    );
  }
}