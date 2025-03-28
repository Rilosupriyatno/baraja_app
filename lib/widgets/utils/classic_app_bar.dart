// File: lib/widgets/custom_app_bar.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Custom AppBar
class ClassicAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const ClassicAppBar({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          } else {
            // Navigasi ke halaman utama atau lakukan aksi lain
            GoRouter.of(context).go('/main'); // Sesuaikan dengan rute yang benar
          }
        },
      ),
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