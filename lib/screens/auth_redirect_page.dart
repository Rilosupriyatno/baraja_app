import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../screens/login_screen.dart';
import '../widgets/utils/navigation_bar.dart';

class AuthRedirectPage extends StatelessWidget {
  const AuthRedirectPage({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: Provider.of<AuthService>(context, listen: false).checkLoginStatus(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          final isLoggedIn = snapshot.data ?? false;
          if (isLoggedIn) {
            // Return the NavigationBarMenu which will determine the correct navigation based on role
            return const NavigationBarMenu();
          } else {
            return const LoginScreen();
          }
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