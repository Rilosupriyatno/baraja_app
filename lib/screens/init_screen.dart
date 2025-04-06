import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class InitScreen extends StatefulWidget {
  const InitScreen({super.key});

  @override
  State<InitScreen> createState() => _InitScreenState();
}

class _InitScreenState extends State<InitScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final authService = Provider.of<AuthService>(context, listen: false);

    // Check if user is already logged in
    final isLoggedIn = await authService.isLoggedIn();

    if (mounted) {
      if (isLoggedIn) {
        // User is logged in, navigate to main screen
        context.go('/main');
      } else {
        // User is not logged in, navigate to login screen
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // This screen is just a placeholder while we check the login status
    // It should match your native splash screen for a seamless transition
    return const Scaffold(
      backgroundColor: Color(0xFF076A3B), // Match your splash screen color
      body: Center(
        child: SizedBox(), // Empty, will be replaced quickly
      ),
    );
  }
}