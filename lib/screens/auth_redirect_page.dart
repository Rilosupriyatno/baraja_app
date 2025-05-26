import 'package:baraja_app/screens/login_screen.dart';
import 'package:baraja_app/widgets/utils/navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class AuthRedirectPage extends StatelessWidget {
  const AuthRedirectPage({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: Provider.of<AuthService>(context, listen: false).checkLoginStatus(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          final isLoggedIn = snapshot.data ?? false;
          return isLoggedIn ? const MainNavigationBar() : const LoginScreen();
        }
        return const Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}
