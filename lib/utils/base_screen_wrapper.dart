import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BaseScreenWrapper extends StatelessWidget {
  final Widget child;
  final String? customBackRoute;
  final bool canPop;
  final VoidCallback? onBackPressed;

  const BaseScreenWrapper({
    super.key,
    required this.child,
    this.customBackRoute,
    this.canPop = true,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: canPop,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          await _handleBackNavigation(context);
        }
      },
      child: child,
    );
  }

  Future<void> _handleBackNavigation(BuildContext context) async {
    if (onBackPressed != null) {
      onBackPressed!();
      return;
    }

    if (customBackRoute != null) {
      if (context.mounted) {
        context.go(customBackRoute!);
      }
      return;
    }

    // Smart back navigation logic
    if (context.mounted) {
      final router = GoRouter.of(context);
      final currentLocation = router.routerDelegate.currentConfiguration.uri.toString();

      // Define your navigation hierarchy
      final Map<String, String> navigationHierarchy = {
        '/menu': '/main',
        '/product': '/menu',
        '/cart': '/menu',
        '/checkout': '/cart',
        '/paymentMethod': '/checkout',
        '/voucher': '/checkout',
        '/paymentConfirmation': '/main',
        '/orderDetail': '/history',
        '/notification': '/main',
        '/favorite': '/main',
        '/settings': '/main',
        '/reservation': '/main',
        '/history': '/main',
        '/qrscanner': '/main',
      };

      // Find the appropriate back route
      String backRoute = '/main'; // Default fallback

      for (var route in navigationHierarchy.keys) {
        if (currentLocation.startsWith(route)) {
          backRoute = navigationHierarchy[route]!;
          break;
        }
      }

      // Navigate to the determined back route
      context.go(backRoute);
    }
  }
}

// Extension to make it easier to use
extension ContextExtension on BuildContext {
  void smartPop() {
    final router = GoRouter.of(this);
    router.routerDelegate.currentConfiguration.uri.toString();

    // If we can go back in history, do it
    if (router.canPop()) {
      router.pop();
    } else {
      // Otherwise, go to main
      go('/main');
    }
  }
}