// File: lib/widgets/utils/classic_app_bar.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Custom AppBar with configurable back navigation
class ClassicAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onBackPressed;
  final String? customBackRoute;
  final bool showBackButton;
  final Widget? customLeading;
  final List<Widget>? actions;

  const ClassicAppBar({
    super.key,
    required this.title,
    this.onBackPressed,
    this.customBackRoute,
    this.showBackButton = true,
    this.customLeading,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      leading: _buildLeading(context),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 18,
        ),
      ),
      centerTitle: true,
      actions: actions,
    );
  }

  Widget? _buildLeading(BuildContext context) {
    // If custom leading is provided, use it
    if (customLeading != null) {
      return customLeading;
    }

    // If showBackButton is false, don't show back button
    if (!showBackButton) {
      return null;
    }

    return IconButton(
      icon: const Icon(Icons.arrow_back, color: Colors.black),
      onPressed: () => _handleBackPress(context),
    );
  }

  void _handleBackPress(BuildContext context) {
    // Priority 1: Custom onBackPressed callback
    if (onBackPressed != null) {
      onBackPressed!();
      return;
    }

    // Priority 2: Custom route
    if (customBackRoute != null) {
      if (customBackRoute == '/history') {
        context.go('/main', extra: {'initialTab': 3});
      } else {
        context.go(customBackRoute!);
      }
      return;
    }


    // Priority 3: Default behavior
    if (Navigator.canPop(context)) {
      Navigator.of(context).pop();
    } else {
      context.go('/main');
    }
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

// Extension untuk kemudahan penggunaan
extension ClassicAppBarExtension on ClassicAppBar {
  /// Factory constructor untuk navigasi kustom dengan route
  static ClassicAppBar withCustomRoute({
    required String title,
    required String backRoute,
    List<Widget>? actions,
  }) {
    return ClassicAppBar(
      title: title,
      customBackRoute: backRoute,
      actions: actions,
    );
  }

  /// Factory constructor untuk navigasi kustom dengan callback
  static ClassicAppBar withCustomAction({
    required String title,
    required VoidCallback onBackPressed,
    List<Widget>? actions,
  }) {
    return ClassicAppBar(
      title: title,
      onBackPressed: onBackPressed,
      actions: actions,
    );
  }

  /// Factory constructor untuk halaman tanpa back button
  static ClassicAppBar withoutBackButton({
    required String title,
    Widget? customLeading,
    List<Widget>? actions,
  }) {
    return ClassicAppBar(
      title: title,
      showBackButton: false,
      customLeading: customLeading,
      actions: actions,
    );
  }
}