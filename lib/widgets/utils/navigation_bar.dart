import 'package:baraja_app/screens/order_history_screen.dart';
import 'package:baraja_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar_v2/persistent_bottom_nav_bar_v2.dart';

import '../../screens/home_screen.dart';
import '../../screens/profile_screen.dart';

class PersistentNavigationBar extends StatelessWidget {
  const PersistentNavigationBar({super.key});

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
        controller: _controller,  // Gunakan controller
        backgroundColor: Colors.white,
        handleAndroidBackButtonPress: false, // Nonaktifkan default back handler
        resizeToAvoidBottomInset: true,
        stateManagement: true,
        avoidBottomPadding: true,
        navBarOverlap: const NavBarOverlap.full(),
        tabs: [
          PersistentTabConfig(
            screen: const HomeScreen(),
            item: ItemConfig(
              icon: const Icon(Icons.home),
              title: "Home",
              activeForegroundColor: AppTheme.primaryColor,
            ),
          ),
          PersistentTabConfig(
            screen: const OrderHistoryScreen(),
            item: ItemConfig(
              icon: const Icon(Icons.history_edu),
              title: "History",
              activeForegroundColor: AppTheme.primaryColor,
            ),
          ),
          // PersistentTabConfig(
          //   screen: const OrderHistoryScreen(),
          //   item: ItemConfig(
          //     icon: const Icon(Icons.add, size: 40, color: Colors.white),
          //     activeForegroundColor: Colors.orange,
          //   ),
          // ),
          PersistentTabConfig(
            screen: const ProfileScreen(),
            item: ItemConfig(
              icon: const Icon(Icons.person),
              title: "Profile",
              activeForegroundColor: AppTheme.primaryColor,
            ),
          ),
        ],
        navBarBuilder: (navBarConfig) => Style1BottomNavBar(
          navBarConfig: navBarConfig,
          navBarDecoration: const NavBarDecoration(
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}