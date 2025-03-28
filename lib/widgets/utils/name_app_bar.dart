// File: lib/widgets/custom_app_bar.dart
import 'package:flutter/material.dart';

/// Custom AppBar
class NameAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const NameAppBar({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 18,
        ),
      ),
      centerTitle: true,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}