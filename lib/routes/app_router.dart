import 'package:baraja_app/screens/checkout_page.dart';
import 'package:baraja_app/screens/reservation_screen.dart';
import 'package:baraja_app/screens/scanner.dart';
import 'package:baraja_app/screens/auth_redirect_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/cart_item.dart';
import '../models/order_type.dart';
import '../models/product.dart';
import '../models/reservation_data.dart';
import '../pages/account_settings_page.dart';
import '../pages/favorit_page.dart';
import '../pages/notification_page.dart';
import '../screens/cart_screen.dart';
import '../screens/login_screen.dart';
import '../screens/menu_screen.dart';
import '../screens/order_history_screen.dart';
import '../screens/payment_confirmation_screen.dart';
import '../screens/payment_method_screen.dart';
import '../screens/product_detail_screen.dart';
import '../screens/register_screen.dart';
import '../screens/tracking_detail_order_screen.dart';
import '../screens/voucher_screen.dart';
import '../services/product_service.dart';
import '../widgets/checkout/payment_type_widget.dart';
import '../widgets/utils/navigation_bar.dart';

class AppRouter {
  static final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

  static GoRouter getRouter() {
    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: '/',
      routes: [
        // Auth routes
        GoRoute(
          path: '/',
          builder: (context, state) => const AuthRedirectPage(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen(),
        ),

        // Main navigation route
        GoRoute(
          path: '/main',
          builder: (context, state) => const MainNavigationBar(),
        ),

        // Other routes that should have proper back navigation
        GoRoute(
          path: '/menu',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const MenuScreen(),
        ),

        GoRoute(
          path: '/qrscanner',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const QRScanner(),
        ),

        // Product detail route
        GoRoute(
          path: '/product/:id',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            final productId = state.pathParameters['id']!;
            final productService = ProductService();

            return FutureBuilder<Product?>(
              future: productService.getProductById(productId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.hasError) {
                  return Scaffold(
                    appBar: AppBar(title: const Text("Error")),
                    body: Center(child: Text('Terjadi kesalahan: ${snapshot.error}')),
                  );
                }

                final product = snapshot.data;

                if (product == null) {
                  return Scaffold(
                    appBar: AppBar(title: const Text("Produk Tidak Ditemukan")),
                    body: const Center(child: Text("Produk tidak ditemukan.")),
                  );
                }

                return ProductDetailScreen(product: product);
              },
            );
          },
        ),

        // Profile routes
        GoRoute(
          path: '/favorite',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const FavoritePage(),
        ),
        GoRoute(
          path: '/notification',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const NotificationPage(),
        ),
        GoRoute(
          path: '/settings',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const AccountSettingsPage(),
        ),

        // Cart route
        GoRoute(
          path: '/cart',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            return CartScreen(
              isReservation: extra?['isReservation'] ?? false,
              reservationData: extra?['reservationData'],
              isDineIn: extra?['isDineIn'] ?? false,
              tableNumber: extra?['tableNumber'],
            );
          },
        ),

        // Checkout route
        GoRoute(
          path: '/checkout',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            return CheckoutPage(
              isReservation: extra?['isReservation'] ?? false,
              reservationData: extra?['reservationData'],
              isDineIn: extra?['isDineIn'] ?? false,
              tableNumber: extra?['tableNumber'],
            );
          },
        ),

        // Payment method selection page
        GoRoute(
          path: '/paymentMethod',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const PaymentMethodScreen(),
        ),

        GoRoute(
          path: '/voucher',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            final appliedVoucherCode = state.extra as String?;
            return VoucherScreen(appliedVoucherCode: appliedVoucherCode);
          },
        ),

        // Payment confirmation page
        GoRoute(
          path: '/paymentConfirmation',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            final Map<String, dynamic> extras = state.extra as Map<String, dynamic>;

            return PaymentConfirmationScreen(
              items: (extras['items'] as List).cast<CartItem>(),
              orderType: extras['orderType'] as OrderType,
              tableNumber: extras['tableNumber'] as String,
              deliveryAddress: extras['deliveryAddress'] as String,
              pickupTime: extras['pickupTime'] as TimeOfDay?,
              paymentDetails: (extras['paymentDetails'] as Map<String, String?>),
              subtotal: extras['subtotal'] as int,
              discount: extras['discount'] as int,
              total: extras['total'] as int,
              voucherCode: extras['voucherCode'] as String?,
              orderId: extras['orderId'] as String,
              id: extras['id'] as String,
              userId: extras['userId'] as String?,
              userName: extras['userName'] as String?,
              paymentType: extras['paymentType'] as PaymentType?,
              amountToPay: extras['amountToPay'] as int,
              reservationData: extras['reservationData'] as ReservationData?,
              isReservation: extras['isReservation'] as bool? ?? false,
              downPaymentAmount: extras['downPaymentAmount'] as int? ?? 0,
              remainingPayment: extras['remainingPayment'] as int? ?? 0,
              isDownPayment: extras['isDownPayment'] as bool? ?? false,
            );
          },
        ),

        // Order tracking page
        GoRoute(
          path: '/orderDetail',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            final id = state.extra as String;
            return TrackingDetailOrderScreen(id: id);
          },
        ),

        // Order history page
        GoRoute(
          path: '/history',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const OrderHistoryScreen(),
        ),

        // Reservation
        GoRoute(
          path: '/reservation',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const ReservationScreen(),
        ),
      ],
    );
  }
}