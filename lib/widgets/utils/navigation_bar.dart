import 'package:baraja_app/screens/marketing_dashboard_screen.dart';
import 'package:baraja_app/screens/order_history_screen.dart';
import 'package:baraja_app/screens/scanner.dart';
import 'package:baraja_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:persistent_bottom_nav_bar_v2/persistent_bottom_nav_bar_v2.dart';
import 'package:provider/provider.dart';
import '../../screens/event_screen.dart';
import '../../screens/home_screen.dart';
import '../../screens/gro_dashboard_screen.dart';
import '../../screens/profile_screen.dart';
import '../../services/auth_service.dart';

class NavigationBarMenu extends StatelessWidget {
  final int? initialTab;

  const NavigationBarMenu({super.key, this.initialTab});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, _) {
        if (authService.isMarketing()) {
          return MarketingNavigationBar(initialTab: initialTab);
        } else if (authService.getUserRole() == 'gro') {
          return GroNavigationBar(initialTab: initialTab);
        } else {
          return CustomerNavigationBar(initialTab: initialTab);
        }
      },
    );
  }
}

// ================= CUSTOMER NAVIGATION =================
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
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        if (!didPop) _handleBackPress();
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

// ================= MARKETING NAVIGATION =================
class MarketingNavigationBar extends StatefulWidget {
  final int? initialTab;

  const MarketingNavigationBar({super.key, this.initialTab});

  @override
  State<MarketingNavigationBar> createState() =>
      _MarketingNavigationBarState();
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
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        if (!didPop) _handleBackPress();
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
          PersistentTabConfig(
            screen: const MarketingDashboardScreen(),
            item: ItemConfig(
              icon: const Icon(Icons.dashboard),
              title: "Dashboard",
              activeForegroundColor: AppTheme.barajaPrimary.primaryColor,
            ),
          ),
          PersistentTabConfig(
            screen: const EventScreen(),
            item: ItemConfig(
              icon: const Icon(Icons.event),
              title: "Events",
              activeForegroundColor: AppTheme.barajaPrimary.primaryColor,
            ),
          ),
          PersistentTabConfig(
            screen: const VoucherManagementScreen(),
            item: ItemConfig(
              icon: const Icon(Icons.card_giftcard),
              title: "Voucher",
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

// ================= GRO NAVIGATION =================
// ✅ GRO langsung tampilkan dashboard tanpa bottom navigation bar
class GroNavigationBar extends StatelessWidget {
  final int? initialTab;

  const GroNavigationBar({super.key, this.initialTab});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          // Dialog konfirmasi untuk keluar aplikasi
          final shouldExit = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.exit_to_app,
                      color: Colors.orange,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text('Keluar Aplikasi?'),
                ],
              ),
              content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Keluar'),
                ),
              ],
            ),
          );

          if (shouldExit == true) {
            SystemNavigator.pop();
          }
        }
      },
      child: const GroDashboardScreen(),
    );
  }
}

// ================= PLACEHOLDER SCREENS =================
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
        child: Text('Manajemen Promo Placeholder'),
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
        child: Text('Manajemen Voucher Placeholder'),
      ),
    );
  }
}