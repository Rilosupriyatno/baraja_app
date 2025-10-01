import 'package:baraja_amphitheater_app/screens/marketing_dashboard_screen.dart';
import 'package:baraja_amphitheater_app/screens/order_history_screen.dart';
import 'package:baraja_amphitheater_app/screens/scanner.dart';
import 'package:baraja_amphitheater_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:persistent_bottom_nav_bar_v2/persistent_bottom_nav_bar_v2.dart';
import 'package:provider/provider.dart';
import '../../screens/event_screen.dart';
import '../../screens/home_screen.dart';
import '../../screens/jro_dashboard_screen.dart';
import '../../screens/profile_screen.dart';
import '../../services/auth_service.dart';


class NavigationBarMenu extends StatelessWidget {
  final int? initialTab;

  const NavigationBarMenu({super.key, this.initialTab});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, _) {
        // Determine navigation based on user role
        if (authService.isMarketing()) {
          return MarketingNavigationBar(initialTab: initialTab);
        } else if (authService.getUserRole() == 'jro') {
          return JroNavigationBar(initialTab: initialTab);
        } else {
          return CustomerNavigationBar(initialTab: initialTab);
        }
      },
    );
  }
}

// Customer Navigation Bar
class CustomerNavigationBar extends StatefulWidget {
  final int? initialTab;

  const CustomerNavigationBar({super.key, this.initialTab});

  @override
  State<CustomerNavigationBar> createState() => _CustomerNavigationBarState();
}

class _CustomerNavigationBarState extends State<CustomerNavigationBar> {
  late PersistentTabController _controller;
  final GlobalKey<QRScannerState> _qrScannerKey = GlobalKey<QRScannerState>();
  int _previousIndex = 0;
  DateTime? _lastBackPressed;

  @override
  void initState() {
    super.initState();
    final initialIndex = widget.initialTab ?? 0;
    _controller = PersistentTabController(initialIndex: initialIndex);
    _previousIndex = initialIndex;
  }

  void _onTabChanged(int index) {
    if (_previousIndex == 2 && index != 2) {
      _qrScannerKey.currentState?.setVisibility(false);
    } else if (index == 2 && _previousIndex != 2) {
      Future.delayed(const Duration(milliseconds: 200), () {
        _qrScannerKey.currentState?.setVisibility(true);
      });
    }
    _previousIndex = index;
  }

  bool _handleBackPress() {
    if (_controller.index != 0) {
      _controller.jumpToTab(0);
      return false;
    }

    final now = DateTime.now();
    const backPressDuration = Duration(seconds: 2);

    if (_lastBackPressed == null ||
        now.difference(_lastBackPressed!) > backPressDuration) {
      _lastBackPressed = now;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.exit_to_app, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                'Tekan sekali lagi untuk keluar',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          backgroundColor: Colors.grey[800],
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 6,
          duration: const Duration(seconds: 2),
        ),
      );
      return false;
    }

    SystemNavigator.pop();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          _handleBackPress();
        }
      },
      child: PersistentTabView(
        controller: _controller,
        backgroundColor: Colors.white,
        handleAndroidBackButtonPress: false,
        resizeToAvoidBottomInset: true,
        stateManagement: true,
        avoidBottomPadding: true,
        navBarOverlap: const NavBarOverlap.full(),
        onTabChanged: _onTabChanged,
        tabs: [
          PersistentTabConfig(
            screen: const HomeScreen(),
            item: ItemConfig(
              icon: const Icon(Icons.home),
              title: "Home",
              activeForegroundColor: AppTheme.barajaPrimary.primaryColor,
            ),
          ),
          PersistentTabConfig(
            screen: const EventScreen(),
            item: ItemConfig(
              icon: const Icon(Icons.event),
              title: "Event",
              activeForegroundColor: AppTheme.barajaPrimary.primaryColor,
            ),
          ),
          PersistentTabConfig(
            screen: QRScanner(key: _qrScannerKey),
            item: ItemConfig(
              icon: const Icon(Icons.qr_code_2, size: 35, color: Colors.white),
              activeForegroundColor: AppTheme.barajaPrimary.primaryColor,
            ),
          ),
          PersistentTabConfig(
            screen: const OrderHistoryScreen(),
            item: ItemConfig(
              icon: const Icon(Icons.history_edu_outlined),
              title: "History",
              activeForegroundColor: AppTheme.barajaPrimary.primaryColor,
            ),
          ),
          PersistentTabConfig(
            screen: const ProfileScreen(),
            item: ItemConfig(
              icon: const Icon(Icons.person),
              title: "Profile",
              activeForegroundColor: AppTheme.barajaPrimary.primaryColor,
            ),
          ),
        ],
        navBarBuilder: (navBarConfig) => Style13BottomNavBar(
          navBarConfig: navBarConfig,
          navBarDecoration: const NavBarDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: Offset(0, -2),
              )
            ],
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// Marketing Navigation Bar
class MarketingNavigationBar extends StatefulWidget {
  final int? initialTab;

  const MarketingNavigationBar({super.key, this.initialTab});

  @override
  State<MarketingNavigationBar> createState() => _MarketingNavigationBarState();
}

class _MarketingNavigationBarState extends State<MarketingNavigationBar> {
  late PersistentTabController _controller;
  DateTime? _lastBackPressed;

  @override
  void initState() {
    super.initState();
    final initialIndex = widget.initialTab ?? 0;
    _controller = PersistentTabController(initialIndex: initialIndex);
  }

  bool _handleBackPress() {
    if (_controller.index != 0) {
      _controller.jumpToTab(0);
      return false;
    }

    final now = DateTime.now();
    const backPressDuration = Duration(seconds: 2);

    if (_lastBackPressed == null ||
        now.difference(_lastBackPressed!) > backPressDuration) {
      _lastBackPressed = now;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.exit_to_app, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                'Tekan sekali lagi untuk keluar',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          backgroundColor: Colors.grey[800],
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 6,
          duration: const Duration(seconds: 2),
        ),
      );
      return false;
    }

    SystemNavigator.pop();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          _handleBackPress();
        }
      },
      child: PersistentTabView(
        controller: _controller,
        backgroundColor: Colors.white,
        handleAndroidBackButtonPress: false,
        resizeToAvoidBottomInset: true,
        stateManagement: true,
        avoidBottomPadding: true,
        navBarOverlap: const NavBarOverlap.full(),
        tabs: [
          // Marketing Dashboard instead of regular Home
          PersistentTabConfig(
            screen: const MarketingDashboardScreen(), // Marketing dashboard
            item: ItemConfig(
              icon: const Icon(Icons.dashboard),
              title: "Dashboard",
              activeForegroundColor: AppTheme.barajaPrimary.primaryColor,
            ),
          ),
          // Event Management for Marketing
          PersistentTabConfig(
            screen: const EventScreen(),
            item: ItemConfig(
              icon: const Icon(Icons.event),
              title: "Events",
              activeForegroundColor: AppTheme.barajaPrimary.primaryColor,
            ),
          ),
          // Voucher Management (Marketing specific)
          PersistentTabConfig(
            screen: const VoucherManagementScreen(),
            item: ItemConfig(
              icon: const Icon(Icons.card_giftcard),
              title: "Voucher",
              activeForegroundColor: AppTheme.barajaPrimary.primaryColor,
            ),
          ),
          // Profile
          PersistentTabConfig(
            screen: const ProfileScreen(),
            item: ItemConfig(
              icon: const Icon(Icons.person),
              title: "Profile",
              activeForegroundColor: AppTheme.barajaPrimary.primaryColor,
            ),
          ),
        ],
        navBarBuilder: (navBarConfig) => Style1BottomNavBar(
          navBarConfig: navBarConfig,
          navBarDecoration: const NavBarDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: Offset(0, -2),
              )
            ],
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// JRO Navigation Bar
class JroNavigationBar extends StatefulWidget {
  final int? initialTab;

  const JroNavigationBar({super.key, this.initialTab});

  @override
  State<JroNavigationBar> createState() => _JroNavigationBarState();
}

class _JroNavigationBarState extends State<JroNavigationBar> {
  late PersistentTabController _controller;
  DateTime? _lastBackPressed;

  @override
  void initState() {
    super.initState();
    final initialIndex = widget.initialTab ?? 0;
    _controller = PersistentTabController(initialIndex: initialIndex);
  }

  bool _handleBackPress() {
    if (_controller.index != 0) {
      _controller.jumpToTab(0);
      return false;
    }

    final now = DateTime.now();
    const backPressDuration = Duration(seconds: 2);

    if (_lastBackPressed == null ||
        now.difference(_lastBackPressed!) > backPressDuration) {
      _lastBackPressed = now;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.exit_to_app, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                'Tekan sekali lagi untuk keluar',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          backgroundColor: Colors.grey[800],
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 6,
          duration: const Duration(seconds: 2),
        ),
      );
      return false;
    }

    SystemNavigator.pop();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          _handleBackPress();
        }
      },
      child: PersistentTabView(
        controller: _controller,
        backgroundColor: Colors.white,
        handleAndroidBackButtonPress: false,
        resizeToAvoidBottomInset: true,
        stateManagement: true,
        avoidBottomPadding: true,
        navBarOverlap: const NavBarOverlap.full(),
        tabs: [
          // JRO Dashboard
          PersistentTabConfig(
            screen: const JroDashboardScreen(),
            item: ItemConfig(
              icon: const Icon(Icons.dashboard),
              title: "Dashboard",
              activeForegroundColor: AppTheme.barajaPrimary.primaryColor,
            ),
          ),
          // Reservation Management
          // PersistentTabConfig(
          //   screen: const JroDashboardScreen(),
          //   item: ItemConfig(
          //     icon: const Icon(Icons.event_seat),
          //     title: "Reservasi",
          //     activeForegroundColor: AppTheme.barajaPrimary.primaryColor,
          //   ),
          // ),
          // PersistentTabConfig(
          //   screen: const JroDashboardScreen(),
          //   item: ItemConfig(
          //     icon: const Icon(Icons.analytics),
          //     title: "Laporan",
          //     activeForegroundColor: AppTheme.barajaPrimary.primaryColor,
          //   ),
          // ),
          // Profile
          PersistentTabConfig(
            screen: const ProfileScreen(),
            item: ItemConfig(
              icon: const Icon(Icons.person),
              title: "Profile",
              activeForegroundColor: AppTheme.barajaPrimary.primaryColor,
            ),
          ),
        ],
        navBarBuilder: (navBarConfig) => Style1BottomNavBar(
          navBarConfig: navBarConfig,
          navBarDecoration: const NavBarDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: Offset(0, -2),
              )
            ],
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// Placeholder screens for Marketing role
class PromoManagementScreen extends StatelessWidget {
  const PromoManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        title: const Text(
          'Manajemen Promo',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_offer,
              size: 80,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Manajemen Promo',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Kelola semua promo dan penawaran khusus',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to add promo screen
        },
        backgroundColor: AppTheme.barajaPrimary.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class VoucherManagementScreen extends StatelessWidget {
  const VoucherManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        title: const Text(
          'Manajemen Voucher',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.card_giftcard,
              size: 80,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Manajemen Voucher',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Kelola semua voucher dan kupon diskon',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to add voucher screen
        },
        backgroundColor: AppTheme.barajaPrimary.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}