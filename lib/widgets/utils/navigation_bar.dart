import 'package:baraja_app/screens/home_screen.dart';
import 'package:baraja_app/screens/order_history_screen.dart';
import 'package:baraja_app/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar_v2/persistent_bottom_nav_bar_v2.dart';

class PersistentNavigationBar extends StatelessWidget {
  const PersistentNavigationBar({super.key});

  @override
  Widget build(BuildContext context) {
    return PersistentTabView(
        tabs: [
          PersistentTabConfig(
            screen: const HomeScreen(),
            item: ItemConfig(
              icon: const Icon(Icons.home),
              title: "Home",
            ),
          ),
          PersistentTabConfig(
            screen: const OrderHistoryScreen(),
            item: ItemConfig(
              icon: const Icon(Icons.home),
              title: "History",
            ),
          ),
          PersistentTabConfig(
            screen: const ProfileScreen(),
            item: ItemConfig(
              icon: const Icon(Icons.person),
              title: "Profile",
            ),
          ),
        ],
        navBarBuilder: (navBarConfig) => Style1BottomNavBar(
          navBarConfig: navBarConfig,
        ),
      );
  }
}