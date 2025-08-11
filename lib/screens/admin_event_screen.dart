import 'package:flutter/material.dart';
import '../widgets/home/action_button.dart';
import '../widgets/home/promo_carousel.dart';

class AdminEventScreen extends StatelessWidget {
  const AdminEventScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        title: const Text(
          'Admin Event',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Center(
        child: ListView(
          children: const [
            PromoCarousel(),
            SizedBox(height: 16),
            ActionButtons(),
          ],
        ),
      ),
    );
  }

}
