import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import '../screens/account_settings_screen.dart';
import '../screens/auth_redirect_page.dart';
import '../screens/checkout_page.dart';
import '../screens/favorit_screen.dart';
import '../screens/gro_management_reservation_screen.dart';
import '../screens/gro_reservation_detail_screen.dart';
import '../screens/gro_table_avaibility_screen.dart';
import '../screens/notification_screen.dart';
import '../screens/cart_screen.dart';
import '../screens/login_screen.dart';
import '../screens/menu_screen.dart';
import '../screens/payment_confirmation_screen.dart';
import '../screens/payment_method_screen.dart';
import '../screens/product_detail_screen.dart';
import '../screens/register_screen.dart';
import '../screens/reservation_screen.dart';
import '../screens/scanner.dart';
import '../screens/ticket_payment_confirmation_screen.dart';
import '../screens/tracking_detail_order_screen.dart';
import '../screens/voucher_screen.dart';
import '../services/product_service.dart';
import '../widgets/utils/navigation_bar.dart';
import '../widgets/utils/ticket_payment_instruction_screen.dart';

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

        // ✅ PERBAIKAN: Main navigation route dengan support untuk initialTab
        GoRoute(
          path: '/main',
          builder: (context, state) {
            // Ambil parameter initialTab dari extra
            final extra = state.extra as Map<String, dynamic>?;
            final initialTab = extra?['initialTab'] as int?;

            return NavigationBarMenu(initialTab: initialTab);
          },
        ),

        // ✅ HAPUS: Route /history karena history screen sudah menjadi bagian dari navigation bar
        // Order history sekarang diakses melalui /main dengan initialTab: 3

        // Route force NavigationBarMenu
        GoRoute(
          path: '/home',
          builder: (context, state) {
            // Ambil parameter initialTab dari extra
            final extra = state.extra as Map<String, dynamic>?;
            final initialTab = extra?['initialTab'] as int?;

            return NavigationBarMenu(initialTab: initialTab);
          },
        ),
        GoRoute(
          path: '/events',
          builder: (context, state) {
            // Ambil parameter initialTab dari extra
            final extra = state.extra as Map<String, dynamic>?;
            final initialTab = extra?['initialTab'] as int?;

            return NavigationBarMenu(initialTab: initialTab);
          },
        ),
        GoRoute(
          path: '/qrscanner',
          builder: (context, state) {
            // Ambil parameter initialTab dari extra
            final extra = state.extra as Map<String, dynamic>?;
            final initialTab = extra?['initialTab'] as int?;

            return NavigationBarMenu(initialTab: initialTab);
          },
        ),
        GoRoute(
          path: '/history',
          builder: (context, state) {
            // Ambil parameter initialTab dari extra
            final extra = state.extra as Map<String, dynamic>?;
            final initialTab = extra?['initialTab'] as int?;

            return NavigationBarMenu(initialTab: initialTab);
          },
        ),

        GoRoute(
          path: '/profile',
          builder: (context, state) {
            // Ambil parameter initialTab dari extra
            final extra = state.extra as Map<String, dynamic>?;
            final initialTab = extra?['initialTab'] as int?;

            return NavigationBarMenu(initialTab: initialTab);
          },
        ),

        // End route force NavigationBarMenu



        // Other routes that should have proper back navigation
        GoRoute(
          path: '/menu',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            return MenuScreen(
              isReservation: extra?['isReservation'] ?? false,
              reservationData: extra?['reservationData'],
              isDineIn: extra?['isDineIn'] ?? false,
              tableNumber: extra?['tableNumber'],
              isOpenBill: extra?['isOpenBill'] ?? false,
              openBillData: extra?['openBillData'],
              isGroMode: extra?['isGroMode'] ?? false, // ADD
            );
          },
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
          builder: (context, state) => const FavoriteScreen(),
        ),
        GoRoute(
          path: '/notification',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            final userId = extra?['userId'] ?? '';

            return NotificationScreen(userId: userId);
          },
        ),

        GoRoute(
          path: '/settings',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const AccountSettingsScreen(),
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
              isOpenBill: extra?['isOpenBill'] ?? false,
              openBillData: extra?['openBillData'],
              isGroMode: extra?['isGroMode'] ?? false, // ADD
            );
          },
        ),

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
              isOpenBill: extra?['isOpenBill'] ?? false,
              openBillData: extra?['openBillData'],
              isGroMode: extra?['isGroMode'] ?? false, // ADD
            );
          },
        ),

        // Payment method selection page
        // GoRoute(
        //   path: '/paymentMethod',
        //   parentNavigatorKey: _rootNavigatorKey,
        //   builder: (context, state) => const PaymentMethodScreen(),
        // ),
        // Add these routes to your GoRouter configuration

        GoRoute(
          path: '/paymentMethod',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            return PaymentMethodScreen(
              source: extra?['source'],
              eventData: extra?['eventData'],
            );
          },
        ),

        GoRoute(
          path: '/ticketPaymentConfirmation',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>;
            return TicketPaymentConfirmationScreen(
              eventData: extra['eventData'],
              paymentData: extra['paymentData'],
            );
          },
        ),

        GoRoute(
          path: '/ticketPaymentInstructions',
          builder: (context, state) {
            // Ambil data dari extra
            final extra = state.extra as Map<String, dynamic>?;
            final paymentResult = extra?['paymentResult'];
            final eventData = extra?['eventData'];
            final paymentData = extra?['paymentData'];

            return TicketPaymentInstructionsScreen(
              paymentResult: paymentResult,
              eventData: eventData,
              paymentData: paymentData,
            );
          },
        ),

        GoRoute(
          path: '/voucher',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            final extras = state.extra as Map<String, dynamic>?;

            return VoucherScreen(
              appliedVoucherCode: extras?['appliedVoucherCode'] as String?,
              readonly: extras?['readonly'] ?? false,
            );
          },
        ),


        // Payment confirmation page
        GoRoute(
          path: '/paymentConfirmation',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>;
            return PaymentConfirmationScreen(
              items: (extra['items'] as List<dynamic>).cast<CartItem>(),
              userId: extra['userId'],
              userName: extra['userName'],
              orderType: extra['orderType'],
              tableNumber: extra['tableNumber'] ?? '',
              deliveryAddress: extra['deliveryAddress'] ?? '',
              pickupTime: extra['pickupTime'],
              paymentDetails: extra['paymentDetails'],
              subtotal: extra['subtotal'],
              discount: extra['discount'],
              total: extra['total'],
              grandTotal: extra['grandTotal'],
              paymentType: extra['paymentType'],
              amountToPay: extra['amountToPay'],
              voucherCode: extra['voucherCode'],
              orderId: extra['orderId'],
              id: extra['id'],
              reservationData: extra['reservationData'],
              isReservation: extra['isReservation'] ?? false,
              downPaymentAmount: extra['downPaymentAmount'],
              remainingPayment: extra['remainingPayment'] ?? 0,
              isDownPayment: extra['isDownPayment'] ?? false,
              taxAmount: extra['taxAmount'] ?? 0,
              taxDetails: (extra['taxDetails'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [],
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

        // Reservation
        GoRoute(
          path: '/reservation',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const ReservationScreen(),
        ),

        // GoRoute(
        //   path: '/gro-dashboard',
        //   name: 'gro-dashboard',
        //   builder: (context, state) => const GroDashboardScreen(),
        // ),

        // Setup route dengan query parameter
        GoRoute(
          path: '/gro-reservation-management',
          builder: (context, state) {
            final filter = state.uri.queryParameters['filter'] ?? 'all';
            return GroReservationManagementScreen(filter: filter);
          },
        ),

        GoRoute(
          path: '/gro-reservation-detail/:id',
          name: 'gro-reservation-detail',
          builder: (context, state) {
            // Ambil path parameter 'id' dari URL
            // Contoh URL: /gro-reservation-detail/123abc
            final reservationId = state.pathParameters['id'] ?? '';

            return GroReservationDetailScreen(
              reservationId: reservationId,
            );
          },
        ),

        GoRoute(
          path: '/gro-table-availability',
          name: 'gro-table-availability',
          builder: (context, state) => const GroTableAvailabilityScreen(),
        ),
      ],
    );
  }
}