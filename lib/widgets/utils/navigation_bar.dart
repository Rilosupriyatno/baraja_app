import 'package:baraja_app/screens/order_history_screen.dart';
import 'package:baraja_app/screens/scanner.dart';
import 'package:baraja_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar_v2/persistent_bottom_nav_bar_v2.dart';
import '../../screens/home_screen.dart';
import '../../screens/profile_screen.dart';

class NavigationBarMenu extends StatelessWidget {
  const NavigationBarMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return const MainNavigationBar();
  }
}

class MainNavigationBar extends StatefulWidget {
  const MainNavigationBar({super.key});

  @override
  State<MainNavigationBar> createState() => _MainNavigationBarState();
}

class _MainNavigationBarState extends State<MainNavigationBar> {
  final PersistentTabController _controller = PersistentTabController(initialIndex: 0);
  final GlobalKey<QRScannerState> _qrScannerKey = GlobalKey<QRScannerState>();
  int _previousIndex = 0;

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

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_controller.index == 0) {
          // Jika sudah di Home, biarkan tombol back keluar aplikasi
          return true;
        } else {
          // Jika tidak di Home, pindah ke tab Home
          _controller.jumpToTab(0);
          return false;
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
            screen: const HomeScreen(),
            item: ItemConfig(
              icon: const Icon(Icons.card_membership_outlined),
              title: "Voucher",
              activeForegroundColor: AppTheme.barajaPrimary.primaryColor,
            ),
          ),
          // PersistentTabConfig(
          //   screen: QRScanner(key: _qrScannerKey), // Tambahkan key
          //   item: ItemConfig(
          //     icon: const Icon(Icons.qr_code_2, size: 35, color: Colors.white),
          //     activeForegroundColor: AppTheme.barajaPrimary.primaryColor,
          //   ),
          // ),
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