import 'package:baraja_app/screens/admin_event_screen.dart';
import 'package:baraja_app/screens/order_history_screen.dart';
import 'package:baraja_app/screens/scanner.dart';
import 'package:baraja_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:persistent_bottom_nav_bar_v2/persistent_bottom_nav_bar_v2.dart';
import '../../screens/event_screen.dart';
import '../../screens/home_screen.dart';
import '../../screens/profile_screen.dart';

class NavigationBarMenu extends StatelessWidget {
  // ✅ TAMBAHAN: Parameter untuk set initial tab
  final int? initialTab;

  const NavigationBarMenu({super.key, this.initialTab});

  @override
  Widget build(BuildContext context) {
    return MainNavigationBar(initialTab: initialTab);
  }
}

class MainNavigationBar extends StatefulWidget {
  // ✅ TAMBAHAN: Parameter untuk set initial tab
  final int? initialTab;

  const MainNavigationBar({super.key, this.initialTab});

  @override
  State<MainNavigationBar> createState() => _MainNavigationBarState();
}

class _MainNavigationBarState extends State<MainNavigationBar> {
  late PersistentTabController _controller;
  final GlobalKey<QRScannerState> _qrScannerKey = GlobalKey<QRScannerState>();
  int _previousIndex = 0;
  DateTime? _lastBackPressed;

  @override
  void initState() {
    super.initState();
    // ✅ PERBAIKAN: Gunakan initialTab jika tersedia, default 0
    final initialIndex = widget.initialTab ?? 0;
    _controller = PersistentTabController(initialIndex: initialIndex);
    _previousIndex = initialIndex;
  }

  void _onTabChanged(int index) {
    // Handle QR Scanner visibility
    if (_previousIndex == 2 && index != 2) {
      // Pindah dari tab scanner ke tab lain - pause camera
      _qrScannerKey.currentState?.setVisibility(false);
    } else if (index == 2 && _previousIndex != 2) {
      // Pindah ke tab scanner dari tab lain - resume camera
      Future.delayed(const Duration(milliseconds: 200), () {
        _qrScannerKey.currentState?.setVisibility(true);
      });
    }

    _previousIndex = index;
  }

  bool _handleBackPress() {
    // Jika tidak di Home tab, pindah ke Home tab
    if (_controller.index != 0) {
      _controller.jumpToTab(0);
      return false; // Don't exit
    }

    // Jika sudah di Home tab, implementasi double back to exit
    final now = DateTime.now();
    const backPressDuration = Duration(seconds: 2);

    if (_lastBackPressed == null ||
        now.difference(_lastBackPressed!) > backPressDuration) {
      _lastBackPressed = now;

      // Show custom snackbar notification with better design
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.exit_to_app,
                color: Colors.white,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Tekan sekali lagi untuk keluar',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          backgroundColor: Colors.grey[800],
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 6,
          duration: const Duration(seconds: 2),
        ),
      );
      return false; // Don't exit yet
    }

    // Exit the app
    SystemNavigator.pop();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent automatic pop
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
        onTabChanged: _onTabChanged, // Tambahkan callback ini
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
            screen: QRScanner(key: _qrScannerKey), // Tambahkan key
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