import 'package:flutter/cupertino.dart';
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

  static BaseScreenWrapper? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_BaseScreenScope>()?.wrapper;
  }

  @override
  Widget build(BuildContext context) {
    return _BaseScreenScope(
      wrapper: this,
      child: PopScope(
        canPop: canPop,
        onPopInvoked: (didPop) async {
          if (!didPop) {
            await _handleBackNavigation(context);
          }
        },
        child: child,
      ),
    );
  }


  Future<void> _handleBackNavigation(BuildContext context) async {
    if (onBackPressed != null) {
      onBackPressed!();
      return;
    }

    if (customBackRoute != null) {
      if (context.mounted) {
        final Map<String, int> tabMapping = {
          '/home': 0,
          '/event': 1,
          '/qrscanner': 2,
          '/history': 3,
          '/profile': 4,
        };

        if (tabMapping.containsKey(customBackRoute)) {
          context.go('/main', extra: {'initialTab': tabMapping[customBackRoute]});
        } else {
          context.go(customBackRoute!);
        }
      }
      return;
    }


    if (context.mounted) {
      final router = GoRouter.of(context);
      final currentLocation = router.routerDelegate.currentConfiguration.uri.toString();

      final Map<String, String> navigationHierarchy = {
        '/menu': '/main',
        '/product': '/menu',
        '/cart': '/menu',
        '/checkout': '/cart',
        '/paymentMethod': '/checkout',
        '/voucher': '/checkout',
        '/paymentConfirmation': '/main',
        '/orderDetail': '/main',
        '/notification': '/main',
        '/favorite': '/main',
        '/settings': '/main',
        '/reservation': '/main',
        '/qrscanner': '/main',
      };

      String backRoute = '/main';

      for (var route in navigationHierarchy.keys) {
        if (currentLocation.startsWith(route)) {
          backRoute = navigationHierarchy[route]!;
          break;
        }
      }

      if (currentLocation.startsWith('/orderDetail')) {
        context.go('/main', extra: {'initialTab': 3});
        return;
      }

      context.go(backRoute);
    }
  }
}

class _BaseScreenScope extends InheritedWidget {
  final BaseScreenWrapper wrapper;

  const _BaseScreenScope({
    required this.wrapper,
    required super.child,
  });

  @override
  bool updateShouldNotify(covariant _BaseScreenScope oldWidget) {
    return wrapper != oldWidget.wrapper;
  }
}
